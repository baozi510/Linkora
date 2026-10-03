import linkoraSftp, { SftpNativeEntry } from 'liblinkora_sftp.so';
import { NetworkServerEntry, SftpAuthMode, SftpHostKeyPolicy } from './NetworkServerStore';
import { NetworkDirectorySummaryCache } from './NetworkDirectorySummaryCache';
import { RemoteReadSession } from 'linkora_core';
import { NativeRemoteFile, openNativeRemoteReader } from './NativeRemoteReadSession';

export enum SftpEntryKind {
  DIRECTORY = 'directory',
  FILE = 'file'
}

export class SftpBrowserEntry {
  readonly displayName: string;
  readonly path: string;
  readonly kind: SftpEntryKind;
  readonly size: number;
  readonly modifiedAt: number;

  constructor(displayName: string, path: string, kind: SftpEntryKind, size: number, modifiedAt: number) {
    this.displayName = displayName;
    this.path = path;
    this.kind = kind;
    this.size = size;
    this.modifiedAt = modifiedAt;
  }
}

export class SftpBrowserService {
  private static directoryCache: Map<string, SftpBrowserEntry[]> =
    new Map<string, SftpBrowserEntry[]>();
  private server: NetworkServerEntry;
  readonly initialPath: string;

  constructor(server: NetworkServerEntry) {
    this.server = server;
    this.initialPath = SftpBrowserService.normalizeAbsolute(server.rootPath);
  }

  async list(path: string, forceRefresh: boolean = false): Promise<SftpBrowserEntry[]> {
    const cacheKey: string = NetworkDirectorySummaryCache.keyForServer(this.server, path);
    const cached: SftpBrowserEntry[] | undefined = SftpBrowserService.directoryCache.get(cacheKey);
    if (!forceRefresh && cached !== undefined) {
      return cached.slice();
    }
    try {
      const nativeEntries: SftpNativeEntry[] = await linkoraSftp.list(
        this.server.host, this.server.port, SftpBrowserService.normalizeAbsolute(path),
        this.server.username, this.server.password, '', '', this.trustedFingerprint(),
        this.server.advancedOptions.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT ? 1 : 0,
        this.server.advancedOptions.sftpAuthMode === SftpAuthMode.PRIVATE_KEY ? 1 : 0);
      const entries: SftpBrowserEntry[] = nativeEntries.map((entry: SftpNativeEntry): SftpBrowserEntry =>
        new SftpBrowserEntry(entry.name, this.join(path, entry.name),
          entry.isDirectory ? SftpEntryKind.DIRECTORY : SftpEntryKind.FILE,
          entry.size, entry.modifiedAt));
      entries.sort((left: SftpBrowserEntry, right: SftpBrowserEntry): number => {
        if (left.kind !== right.kind) {
          return left.kind === SftpEntryKind.DIRECTORY ? -1 : 1;
        }
        return left.displayName.localeCompare(right.displayName);
      });
      if (!SftpBrowserService.directoryCache.has(cacheKey) &&
        SftpBrowserService.directoryCache.size >= 256) {
        SftpBrowserService.directoryCache.clear();
      }
      SftpBrowserService.directoryCache.set(cacheKey, entries.slice());
      return entries;
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  async download(remotePath: string, localPath: string): Promise<number> {
    try {
      return await linkoraSftp.download(
        this.server.host, this.server.port, this.initialPath,
        this.server.username, this.server.password, '', '', this.trustedFingerprint(),
        this.server.advancedOptions.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT ? 1 : 0,
        this.server.advancedOptions.sftpAuthMode === SftpAuthMode.PRIVATE_KEY ? 1 : 0,
        SftpBrowserService.normalizeAbsolute(remotePath), localPath);
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  async openReader(path: string, expectedFingerprint: string = '', setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RemoteReadSession> {
    return openNativeRemoteReader(this.server.host, async (host: string): Promise<NativeRemoteFile> => {
      const file = await linkoraSftp.openReader(host, this.server.port, this.initialPath,
        this.server.username, this.server.password, '', '', this.trustedFingerprint(expectedFingerprint),
        this.server.advancedOptions.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT ? 1 : 0,
        this.server.advancedOptions.sftpAuthMode === SftpAuthMode.PRIVATE_KEY ? 1 : 0,
        SftpBrowserService.normalizeAbsolute(path));
      return new NativeRemoteFile(file.handle, file.size);
    }, (handle: number, offset: number, length: number) => linkoraSftp.read(handle, offset, length),
      (handle: number) => linkoraSftp.cancel(handle), (handle: number) => linkoraSftp.closeReader(handle), setupObserver);
  }

  parent(path: string): string {
    const normalized: string = SftpBrowserService.normalizeAbsolute(path);
    if (normalized === '/') {
      return '/';
    }
    const slash: number = normalized.lastIndexOf('/');
    return slash <= 0 ? '/' : normalized.substring(0, slash);
  }

  private trustedFingerprint(expected: string = ''): string {
    const fingerprint: string = expected || this.server.advancedOptions.sftpFingerprint;
    if (this.server.advancedOptions.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT && !fingerprint) {
      throw new Error('严格匹配需要填写已信任的服务器指纹。');
    }
    return fingerprint;
  }

  displayPath(path: string): string {
    return SftpBrowserService.normalizeAbsolute(path);
  }

  private join(parent: string, name: string): string {
    const normalized: string = SftpBrowserService.normalizeAbsolute(parent);
    return normalized === '/' ? `/${name}` : `${normalized}/${name}`;
  }

  private friendlyError(error: Object): string {
    const raw: string = error instanceof Error ? error.message : `${error}`;
    const normalized: string = raw.toLowerCase();
    if (normalized.includes('hostkey') || normalized.includes('指纹')) {
      return raw.replace(/^SFTP_HOSTKEY:\s*/, '');
    }
    if (normalized.includes('auth') || normalized.includes('permission') ||
      normalized.includes('账号') || normalized.includes('密码')) {
      return '账号或密码不正确，或者当前账号没有访问权限。';
    }
    if (normalized.includes('resolve')) {
      return '无法解析服务器地址，请检查主机名。';
    }
    if (normalized.includes('timeout') || normalized.includes('超时')) {
      return '连接超时，请检查服务器地址、端口和网络。';
    }
    if (normalized.includes('refused') || normalized.includes('connect')) {
      return '无法连接 SFTP 服务器，请检查地址和端口。';
    }
    if (normalized.includes('local_write')) {
      return '无法创建播放缓存，请检查设备存储空间。';
    }
    if (normalized.includes('no such') || normalized.includes('目录')) {
      return '远程目录不存在，请检查路径。';
    }
    return `SFTP 访问失败：${raw.replace(/^Error:\s*/, '')}`;
  }

  private static normalizeAbsolute(path: string): string {
    const value: string = path.trim();
    if (value.length === 0 || value === '/') {
      return '/';
    }
    return `/${value.replace(/^\/+|\/+$/g, '')}`;
  }
}
