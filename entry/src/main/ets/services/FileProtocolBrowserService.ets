import { NetworkServerEntry, FtpSecurityMode, FtpPassiveMode } from './NetworkServerStore';
import linkoraFtp, { FtpNativeEntry } from 'liblinkora_ftp.so';
import linkoraNfs, { NfsNativeEntry } from 'liblinkora_nfs.so';
import { NetworkDirectorySummaryCache } from './NetworkDirectorySummaryCache';
import { RemoteReadSession } from 'linkora_core';
import { NativeRemoteFile, openNativeRemoteReader } from './NativeRemoteReadSession';

export enum RemoteEntryKind {
  DIRECTORY = 'directory',
  FILE = 'file'
}

export class RemoteBrowserEntry {
  readonly displayName: string;
  readonly path: string;
  readonly kind: RemoteEntryKind;
  readonly size: number;
  readonly modifiedAt: number;

  constructor(displayName: string, path: string, kind: RemoteEntryKind,
    size: number, modifiedAt: number) {
    this.displayName = displayName;
    this.path = path;
    this.kind = kind;
    this.size = size;
    this.modifiedAt = modifiedAt;
  }
}

export interface FileProtocolBrowserService {
  openReader(path: string, setupObserver?: (settled: Promise<void>) => void): Promise<RemoteReadSession>;
  list(path: string, forceRefresh?: boolean): Promise<RemoteBrowserEntry[]>;
  download(path: string, localPath: string): Promise<number>;
  displayPath(path: string): string;
  parent(path: string): string;
  initialPath(): string;
}

export function normalizeRemotePath(path: string, fallback: string = '/'): string {
  const value: string = path.trim();
  if (value.length === 0) {
    return fallback;
  }
  const normalized: string = `/${value.replace(/^\/+|\/+$/g, '')}`;
  return normalized === '/' ? '/' : normalized;
}

export function joinRemotePath(parent: string, name: string): string {
  const base: string = normalizeRemotePath(parent);
  return base === '/' ? `/${name}` : `${base}/${name}`;
}

export function parentRemotePath(path: string): string {
  const normalized: string = normalizeRemotePath(path);
  if (normalized === '/') {
    return '/';
  }
  const slash: number = normalized.lastIndexOf('/');
  return slash <= 0 ? '/' : normalized.substring(0, slash);
}

export class FtpBrowserService implements FileProtocolBrowserService {
  private static directoryCache: Map<string, RemoteBrowserEntry[]> =
    new Map<string, RemoteBrowserEntry[]>();
  private readonly server: NetworkServerEntry;
  private readonly root: string;

  constructor(server: NetworkServerEntry) {
    this.server = server;
    this.root = normalizeRemotePath(server.rootPath);
  }

  initialPath(): string {
    return this.root;
  }

  async list(path: string, forceRefresh: boolean = false): Promise<RemoteBrowserEntry[]> {
    const cacheKey: string = NetworkDirectorySummaryCache.keyForServer(this.server, path);
    const cached: RemoteBrowserEntry[] | undefined = FtpBrowserService.directoryCache.get(cacheKey);
    if (!forceRefresh && cached !== undefined) {
      return cached.slice();
    }
    try {
      const entries: FtpNativeEntry[] = await linkoraFtp.list(this.server.host, this.server.port,
        path, this.server.username, this.server.password, this.securityMode(),
        this.passiveMode(), this.server.advancedOptions.ftpEncoding);
      const result: RemoteBrowserEntry[] = entries.map((entry: FtpNativeEntry): RemoteBrowserEntry => {
        return new RemoteBrowserEntry(entry.name, joinRemotePath(path, entry.name),
          entry.isDirectory ? RemoteEntryKind.DIRECTORY : RemoteEntryKind.FILE,
          entry.size, entry.modifiedAt);
      }).sort((left: RemoteBrowserEntry, right: RemoteBrowserEntry): number => {
        if (left.kind !== right.kind) {
          return left.kind === RemoteEntryKind.DIRECTORY ? -1 : 1;
        }
        return left.displayName.localeCompare(right.displayName);
      });
      if (!FtpBrowserService.directoryCache.has(cacheKey) && FtpBrowserService.directoryCache.size >= 256) {
        FtpBrowserService.directoryCache.clear();
      }
      FtpBrowserService.directoryCache.set(cacheKey, result.slice());
      return result;
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  async download(path: string, localPath: string): Promise<number> {
    try {
      return await linkoraFtp.download(this.server.host, this.server.port, this.root,
        this.server.username, this.server.password, this.securityMode(), this.passiveMode(),
        this.server.advancedOptions.ftpEncoding, path, localPath);
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  displayPath(path: string): string {
    return normalizeRemotePath(path);
  }

  parent(path: string): string {
    const parent: string = parentRemotePath(path);
    return parent.length < this.root.length ? this.root : parent;
  }

  private securityMode(): number {
    const mode: FtpSecurityMode = this.server.advancedOptions.ftpSecurityMode;
    return mode === FtpSecurityMode.PLAIN ? 1 : mode === FtpSecurityMode.EXPLICIT_TLS ? 2 :
      mode === FtpSecurityMode.IMPLICIT_TLS ? 3 : 0;
  }

  async openReader(path: string, setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RemoteReadSession> {
    return openNativeRemoteReader(this.server.host, async (host: string): Promise<NativeRemoteFile> => {
      const file = await linkoraFtp.openReader(host, this.server.port, this.root,
        this.server.username, this.server.password, this.securityMode(), this.passiveMode(),
        this.server.advancedOptions.ftpEncoding, path);
      return new NativeRemoteFile(file.handle, file.size);
    }, (handle: number, offset: number, length: number) => linkoraFtp.read(handle, offset, length),
      (handle: number) => linkoraFtp.cancel(handle), (handle: number) => linkoraFtp.closeReader(handle), setupObserver);
  }

  private passiveMode(): number {
    const mode: FtpPassiveMode = this.server.advancedOptions.ftpPassiveMode;
    return mode === FtpPassiveMode.PASSIVE ? 1 : mode === FtpPassiveMode.ACTIVE ? 2 : 0;
  }

  private friendlyError(error: Object): string {
    const raw: string = error instanceof Error ? error.message : String(error);
    const lower: string = raw.toLowerCase();
    if (lower.includes('tls')) return '当前 FTP 安全模式暂不支持，请改用普通 FTP。';
    if (lower.includes('auth') || lower.includes('login') || lower.includes('password')) {
      return 'FTP 账号或密码不正确。';
    }
    if (lower.includes('timeout')) return 'FTP 连接超时，请检查主机和端口。';
    if (lower.includes('resolve')) return '无法解析 FTP 主机名。';
    if (lower.includes('local_write')) return '无法创建播放缓存，请检查设备存储空间。';
    return `FTP 访问失败：${raw.replace(/^Error:\s*/, '')}`;
  }
}

export class NfsBrowserService implements FileProtocolBrowserService {
  private static directoryCache: Map<string, RemoteBrowserEntry[]> =
    new Map<string, RemoteBrowserEntry[]>();
  private readonly server: NetworkServerEntry;
  private readonly root: string;

  constructor(server: NetworkServerEntry) {
    this.server = server;
    this.root = normalizeRemotePath(server.rootPath);
  }

  initialPath(): string {
    return this.root;
  }

  async list(path: string, forceRefresh: boolean = false): Promise<RemoteBrowserEntry[]> {
    const cacheKey: string = NetworkDirectorySummaryCache.keyForServer(this.server, path);
    const cached: RemoteBrowserEntry[] | undefined = NfsBrowserService.directoryCache.get(cacheKey);
    if (!forceRefresh && cached !== undefined) {
      return cached.slice();
    }
    try {
      const entries: NfsNativeEntry[] = await linkoraNfs.list(this.server.host, this.server.port,
        path, this.version());
      const result: RemoteBrowserEntry[] = entries.map((entry: NfsNativeEntry): RemoteBrowserEntry => {
        return new RemoteBrowserEntry(entry.name, joinRemotePath(path, entry.name),
          entry.isDirectory ? RemoteEntryKind.DIRECTORY : RemoteEntryKind.FILE,
          entry.size, entry.modifiedAt);
      }).sort((left: RemoteBrowserEntry, right: RemoteBrowserEntry): number => {
        if (left.kind !== right.kind) return left.kind === RemoteEntryKind.DIRECTORY ? -1 : 1;
        return left.displayName.localeCompare(right.displayName);
      });
      if (!NfsBrowserService.directoryCache.has(cacheKey) && NfsBrowserService.directoryCache.size >= 256) {
        NfsBrowserService.directoryCache.clear();
      }
      NfsBrowserService.directoryCache.set(cacheKey, result.slice());
      return result;
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  async download(path: string, localPath: string): Promise<number> {
    try {
      return await linkoraNfs.download(this.server.host, this.server.port,
        this.root, this.version(), path, localPath);
    } catch (error) {
      throw new Error(this.friendlyError(error));
    }
  }

  displayPath(path: string): string { return normalizeRemotePath(path); }

  parent(path: string): string {
    const parent: string = parentRemotePath(path);
    return parent.length < this.root.length ? this.root : parent;
  }

  private version(): number {
    return this.server.advancedOptions.nfsVersion === '3' ? 3 :
      this.server.advancedOptions.nfsVersion === '4' ? 4 : 0;
  }

  async openReader(path: string, setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RemoteReadSession> {
    return openNativeRemoteReader(this.server.host, async (host: string): Promise<NativeRemoteFile> => {
      const file = await linkoraNfs.openReader(host, this.server.port, this.root, this.version(), path);
      return new NativeRemoteFile(file.handle, file.size);
    }, (handle: number, offset: number, length: number) => linkoraNfs.read(handle, offset, length),
      (handle: number) => linkoraNfs.cancel(handle), (handle: number) => linkoraNfs.closeReader(handle), setupObserver);
  }

  private friendlyError(error: Object): string {
    const raw: string = error instanceof Error ? error.message : String(error);
    const lower: string = raw.toLowerCase();
    if (lower.includes('version')) return 'NFS 版本不兼容，请切换 NFSv3 或 NFSv4。';
    if (lower.includes('timeout')) return 'NFS 连接超时，请检查主机和端口。';
    if (lower.includes('permission')) return 'NFS 目录没有访问权限。';
    if (lower.includes('local_write')) return '无法创建播放缓存，请检查设备存储空间。';
    return `NFS 访问失败：${raw.replace(/^Error:\s*/, '')}`;
  }
}
