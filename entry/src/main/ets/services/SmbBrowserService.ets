import linkoraSmb, { SmbNativeEntry } from 'liblinkora_smb.so';
import { NetworkServerEntry } from './NetworkServerStore';
import { NetworkDirectorySummaryCache } from './NetworkDirectorySummaryCache';
import { RemoteReadSession } from 'linkora_core';
import { NativeRemoteFile, openNativeRemoteReader } from './NativeRemoteReadSession';

export enum SmbEntryKind {
  DIRECTORY = 'directory',
  FILE = 'file'
}

export class SmbBrowserEntry {
  readonly displayName: string;
  readonly path: string;
  readonly kind: SmbEntryKind;
  readonly size: number;
  readonly modifiedAt: number;

  constructor(displayName: string, path: string, kind: SmbEntryKind, size: number, modifiedAt: number) {
    this.displayName = displayName;
    this.path = path;
    this.kind = kind;
    this.size = size;
    this.modifiedAt = modifiedAt;
  }
}

export class SmbLocation {
  readonly share: string;
  readonly initialPath: string;

  constructor(share: string, initialPath: string) {
    this.share = share;
    this.initialPath = initialPath;
  }
}

class SmbResolvedPath {
  readonly share: string;
  readonly path: string;

  constructor(share: string, path: string) {
    this.share = share;
    this.path = path;
  }
}

export class SmbBrowserService {
  private static directoryCache: Map<string, SmbBrowserEntry[]> =
    new Map<string, SmbBrowserEntry[]>();
  readonly location: SmbLocation;
  private server: NetworkServerEntry;

  constructor(server: NetworkServerEntry) {
    this.server = server;
    this.location = SmbBrowserService.parseLocation(server.rootPath);
  }

  async list(path: string, forceRefresh: boolean = false): Promise<SmbBrowserEntry[]> {
    const cacheKey: string = NetworkDirectorySummaryCache.keyForServer(this.server, path);
    const cached: SmbBrowserEntry[] | undefined = SmbBrowserService.directoryCache.get(cacheKey);
    if (!forceRefresh && cached !== undefined) {
      return cached.slice();
    }
    try {
      const target: SmbResolvedPath = this.resolvePath(path);
      const nativeEntries: SmbNativeEntry[] = await linkoraSmb.list(
        this.server.host, this.server.port, target.share, target.path,
        this.server.username, this.server.password, this.server.advancedOptions.workgroup);
      const entries: SmbBrowserEntry[] = nativeEntries.map((entry: SmbNativeEntry): SmbBrowserEntry => {
        const entryPath: string = this.join(path, entry.name);
        return new SmbBrowserEntry(entry.name, entryPath,
          entry.isDirectory ? SmbEntryKind.DIRECTORY : SmbEntryKind.FILE,
          entry.size, entry.modifiedAt);
      });
      entries.sort((left: SmbBrowserEntry, right: SmbBrowserEntry): number => {
        if (left.kind !== right.kind) {
          return left.kind === SmbEntryKind.DIRECTORY ? -1 : 1;
        }
        return left.displayName.localeCompare(right.displayName);
      });
      if (!SmbBrowserService.directoryCache.has(cacheKey) && SmbBrowserService.directoryCache.size >= 256) {
        SmbBrowserService.directoryCache.clear();
      }
      SmbBrowserService.directoryCache.set(cacheKey, entries.slice());
      return entries;
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  async download(remotePath: string, localPath: string): Promise<number> {
    try {
      const target: SmbResolvedPath = this.resolvePath(remotePath);
      if (target.share.length === 0 || target.path.length === 0) {
        throw new Error('请选择共享目录中的文件。');
      }
      return await linkoraSmb.download(
        this.server.host, this.server.port, target.share, target.path,
        this.server.username, this.server.password, this.server.advancedOptions.workgroup,
        target.path, localPath);
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  async openReader(remotePath: string, setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RemoteReadSession> {
    const target: SmbResolvedPath = this.resolvePath(remotePath);
    return openNativeRemoteReader(this.server.host, async (host: string): Promise<NativeRemoteFile> => {
      const file = await linkoraSmb.openReader(host, this.server.port, target.share, target.path,
        this.server.username, this.server.password, this.server.advancedOptions.workgroup, target.path);
      return new NativeRemoteFile(file.handle, file.size);
    }, (handle: number, offset: number, length: number) => linkoraSmb.read(handle, offset, length),
      (handle: number) => linkoraSmb.cancel(handle), (handle: number) => linkoraSmb.closeReader(handle), setupObserver);
  }

  displayPath(path: string): string {
    const suffix: string = this.normalizePath(path);
    if (this.location.share.length === 0) {
      return suffix.length > 0 ? `/${suffix}` : '/';
    }
    return suffix.length > 0 ? `/${this.location.share}/${suffix}` : `/${this.location.share}`;
  }

  parent(path: string): string {
    const normalized: string = this.normalizePath(path);
    const slash: number = normalized.lastIndexOf('/');
    return slash < 0 ? '' : normalized.substring(0, slash);
  }

  private join(parent: string, name: string): string {
    const normalizedParent: string = this.normalizePath(parent);
    return normalizedParent.length === 0 ? name : `${normalizedParent}/${name}`;
  }

  private normalizePath(path: string): string {
    return path.trim().replace(/^\/+|\/+$/g, '');
  }

  private resolvePath(path: string): SmbResolvedPath {
    const normalized: string = this.normalizePath(path);
    if (this.location.share.length > 0) {
      return new SmbResolvedPath(this.location.share, normalized);
    }
    if (normalized.length === 0) {
      return new SmbResolvedPath('', '');
    }
    const slash: number = normalized.indexOf('/');
    return slash < 0 ? new SmbResolvedPath(normalized, '') :
      new SmbResolvedPath(normalized.substring(0, slash), normalized.substring(slash + 1));
  }

  private friendlyError(error: Object): string {
    const raw: string = error instanceof Error ? error.message : `${error}`;
    const normalized: string = raw.toLowerCase();
    if (this.location.share.length === 0 && normalized.includes('smb_share_enum')) {
      return '服务器不允许读取共享列表，请在配置中手动填写共享目录。';
    }
    if (normalized.includes('logon failure') || normalized.includes('access denied') ||
      normalized.includes('permission denied') || normalized.includes('status_logon_failure') ||
      normalized.includes('0xc000006d') || normalized.includes('0xc0000022') ||
      (this.server.username.length > 0 && normalized.includes('errno:9'))) {
      return '账号或密码不正确，或者当前账号没有访问权限。';
    }
    if (normalized.includes('bad network name') || normalized.includes('status_bad_network_name') ||
      normalized.includes('no such file') || normalized.includes('0xc00000cc') ||
      normalized.includes('0xc0000034')) {
      return '共享目录不存在，请检查共享名称和目录路径。';
    }
    if (normalized.includes('timed out') || normalized.includes('timeout')) {
      return '连接超时，请检查服务器地址、端口和网络。';
    }
    if (normalized.includes('refused') || normalized.includes('unreachable') || normalized.includes('resolve')) {
      return '无法连接服务器，请检查地址、端口和网络。';
    }
    if (normalized.includes('local_write')) {
      return '无法创建播放缓存，请检查设备存储空间。';
    }
    return `SMB 访问失败：${raw.replace(/^Error:\s*/, '')}`;
  }

  static parseLocation(rootPath: string): SmbLocation {
    const normalized: string = rootPath.trim().replace(/^\/+|\/+$/g, '');
    if (normalized.length === 0) {
      return new SmbLocation('', '');
    }
    const slash: number = normalized.indexOf('/');
    if (slash < 0) {
      return new SmbLocation(normalized, '');
    }
    return new SmbLocation(normalized.substring(0, slash), normalized.substring(slash + 1));
  }
}
