import {
  RandomAccessSource,
  RemoteProtocol,
  RemoteReadSession,
  RemoteReadSessionAdapter,
  SourceCapabilities,
  StorageEntry,
  StorageEntryKind,
  StorageListOptions
} from 'linkora_core';
import {
  FileProtocolBrowserService,
  FtpBrowserService,
  NfsBrowserService,
  RemoteBrowserEntry,
  RemoteEntryKind
} from './FileProtocolBrowserService';
import { HttpRemoteReadSession } from './HttpRemoteReadSession';
import {
  NetworkStorageOpenOptions,
  NetworkStorageProvider,
  NetworkStorageProviderRegistry
} from './NetworkStorageProvider';
import { NetworkServerEntry } from './NetworkServerStore';
import { SftpBrowserEntry, SftpBrowserService, SftpEntryKind } from './SftpBrowserService';
import { SmbBrowserEntry, SmbBrowserService, SmbEntryKind } from './SmbBrowserService';
import { WebDavBrowserEntry, WebDavBrowserService, WebDavEntryKind } from './WebDavBrowserService';

function sourceId(server: NetworkServerEntry, path: string): string {
  return `network:${server.id}:${server.protocol}:${path}`;
}

function nativeCapabilities(): SourceCapabilities {
  return new SourceCapabilities(true, true, true, true, false, false);
}

function webDavCapabilities(): SourceCapabilities {
  return new SourceCapabilities(true, true, true, true, true, false);
}

function webDavDirectory(path: string): string {
  let value: string = path.trim();
  if (value.length === 0) {
    return '/';
  }
  if (!value.startsWith('/')) {
    value = `/${value}`;
  }
  return value.endsWith('/') ? value : `${value}/`;
}

function comparablePath(path: string): string {
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path.length === 0 ? '/' : path;
}

function webDavParent(path: string): string {
  const normalized: string = comparablePath(path);
  if (normalized === '/') {
    return '/';
  }
  const slash: number = normalized.lastIndexOf('/');
  return slash <= 0 ? '/' : `${normalized.substring(0, slash)}/`;
}

async function statFromEntries(entries: StorageEntry[], path: string): Promise<StorageEntry | null> {
  const target: string = comparablePath(path);
  for (const entry of entries) {
    if (comparablePath(entry.locator) === target) {
      return entry;
    }
  }
  return null;
}

abstract class BaseNetworkStorageProvider implements NetworkStorageProvider {
  protected readonly server: NetworkServerEntry;

  constructor(server: NetworkServerEntry) {
    this.server = server;
  }

  abstract id(): string;
  abstract protocol(): RemoteProtocol;
  abstract initialPath(): string;
  abstract displayPath(path: string): string;
  abstract directoryPath(path: string): string;
  abstract stat(path: string): Promise<StorageEntry | null>;
  abstract list(path: string, options?: StorageListOptions): Promise<StorageEntry[]>;
  abstract openWithOptions(path: string, options: NetworkStorageOpenOptions): Promise<RandomAccessSource>;
  abstract download(path: string, localPath: string): Promise<number>;
  abstract directFileUrl(path: string): string;
  abstract cancel(): void;

  open(path: string): Promise<RandomAccessSource> {
    return this.openWithOptions(path, new NetworkStorageOpenOptions());
  }

  protected wrap(path: string, session: RemoteReadSession,
    capabilities: SourceCapabilities = nativeCapabilities()): RandomAccessSource {
    return new RemoteReadSessionAdapter(sourceId(this.server, path), session, capabilities);
  }
}

class WebDavStorageProvider extends BaseNetworkStorageProvider {
  private readonly browser: WebDavBrowserService;

  constructor(server: NetworkServerEntry) {
    super(server);
    this.browser = new WebDavBrowserService(server);
  }

  id(): string { return RemoteProtocol.WEBDAV; }
  protocol(): RemoteProtocol { return RemoteProtocol.WEBDAV; }

  initialPath(): string {
    return webDavDirectory(this.server.rootPath);
  }

  displayPath(path: string): string {
    return path;
  }

  directoryPath(path: string): string {
    return webDavDirectory(path);
  }

  async stat(path: string): Promise<StorageEntry | null> {
    if (comparablePath(path) === '/') {
      return new StorageEntry('/', '/', StorageEntryKind.DIRECTORY);
    }
    return statFromEntries(await this.list(webDavParent(path)), path);
  }

  async list(path: string, options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    const entries: WebDavBrowserEntry[] = await this.browser.list(webDavDirectory(path), options.forceRefresh);
    return entries.map((entry: WebDavBrowserEntry): StorageEntry =>
      new StorageEntry(entry.path, entry.displayName,
        entry.kind === WebDavEntryKind.DIRECTORY ? StorageEntryKind.DIRECTORY : StorageEntryKind.FILE,
        entry.size, entry.modifiedAt));
  }

  async openWithOptions(path: string, _options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    const session: RemoteReadSession =
      await HttpRemoteReadSession.open(this.browser.fileUrl(path), this.browser.fileHeaders());
    return this.wrap(path, session, webDavCapabilities());
  }

  async download(_path: string, _localPath: string): Promise<number> {
    throw new Error('当前协议不需要下载缓存');
  }

  directFileUrl(path: string): string {
    return this.browser.fileUrl(path);
  }

  cancel(): void {
    this.browser.cancel();
  }
}

class SmbStorageProvider extends BaseNetworkStorageProvider {
  private readonly browser: SmbBrowserService;

  constructor(server: NetworkServerEntry) {
    super(server);
    this.browser = new SmbBrowserService(server);
  }

  id(): string { return RemoteProtocol.SMB; }
  protocol(): RemoteProtocol { return RemoteProtocol.SMB; }
  initialPath(): string { return this.browser.location.initialPath; }
  displayPath(path: string): string { return this.browser.displayPath(path); }
  directoryPath(path: string): string { return path; }

  async stat(path: string): Promise<StorageEntry | null> {
    const parent: string = this.browser.parent(path);
    return statFromEntries(await this.list(parent), path);
  }

  async list(path: string, options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    const entries: SmbBrowserEntry[] = await this.browser.list(path, options.forceRefresh);
    return entries.map((entry: SmbBrowserEntry): StorageEntry =>
      new StorageEntry(entry.path, entry.displayName,
        entry.kind === SmbEntryKind.DIRECTORY ? StorageEntryKind.DIRECTORY : StorageEntryKind.FILE,
        entry.size, entry.modifiedAt));
  }

  async openWithOptions(path: string, options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    const session: RemoteReadSession = await this.browser.openReader(path, options.setupObserver);
    return this.wrap(path, session);
  }

  download(path: string, localPath: string): Promise<number> {
    return this.browser.download(path, localPath);
  }

  directFileUrl(_path: string): string { return ''; }
  cancel(): void {}
}

class SftpStorageProvider extends BaseNetworkStorageProvider {
  private readonly browser: SftpBrowserService;

  constructor(server: NetworkServerEntry) {
    super(server);
    this.browser = new SftpBrowserService(server);
  }

  id(): string { return RemoteProtocol.SFTP; }
  protocol(): RemoteProtocol { return RemoteProtocol.SFTP; }
  initialPath(): string { return this.browser.initialPath; }
  displayPath(path: string): string { return this.browser.displayPath(path); }
  directoryPath(path: string): string { return path; }

  async stat(path: string): Promise<StorageEntry | null> {
    return statFromEntries(await this.list(this.browser.parent(path)), path);
  }

  async list(path: string, options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    const entries: SftpBrowserEntry[] = await this.browser.list(path, options.forceRefresh);
    return entries.map((entry: SftpBrowserEntry): StorageEntry =>
      new StorageEntry(entry.path, entry.displayName,
        entry.kind === SftpEntryKind.DIRECTORY ? StorageEntryKind.DIRECTORY : StorageEntryKind.FILE,
        entry.size, entry.modifiedAt));
  }

  async openWithOptions(path: string, options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    const fingerprint: string =
      options.expectedFingerprint || this.server.advancedOptions.sftpFingerprint;
    const session: RemoteReadSession =
      await this.browser.openReader(path, fingerprint, options.setupObserver);
    return this.wrap(path, session);
  }

  download(path: string, localPath: string): Promise<number> {
    return this.browser.download(path, localPath);
  }

  directFileUrl(_path: string): string { return ''; }
  cancel(): void {}
}

abstract class FileStorageProvider extends BaseNetworkStorageProvider {
  protected readonly browser: FileProtocolBrowserService;

  constructor(server: NetworkServerEntry, browser: FileProtocolBrowserService) {
    super(server);
    this.browser = browser;
  }

  initialPath(): string { return this.browser.initialPath(); }
  displayPath(path: string): string { return this.browser.displayPath(path); }
  directoryPath(path: string): string { return path; }

  async stat(path: string): Promise<StorageEntry | null> {
    return statFromEntries(await this.list(this.browser.parent(path)), path);
  }

  async list(path: string, options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    const entries: RemoteBrowserEntry[] = await this.browser.list(path, options.forceRefresh);
    return entries.map((entry: RemoteBrowserEntry): StorageEntry =>
      new StorageEntry(entry.path, entry.displayName,
        entry.kind === RemoteEntryKind.DIRECTORY ? StorageEntryKind.DIRECTORY : StorageEntryKind.FILE,
        entry.size, entry.modifiedAt));
  }

  async openWithOptions(path: string, options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    const session: RemoteReadSession = await this.browser.openReader(path, options.setupObserver);
    return this.wrap(path, session);
  }

  download(path: string, localPath: string): Promise<number> {
    return this.browser.download(path, localPath);
  }

  directFileUrl(_path: string): string { return ''; }
  cancel(): void {}
}

class FtpStorageProvider extends FileStorageProvider {
  constructor(server: NetworkServerEntry) {
    super(server, new FtpBrowserService(server));
  }

  id(): string { return RemoteProtocol.FTP; }
  protocol(): RemoteProtocol { return RemoteProtocol.FTP; }
}

class NfsStorageProvider extends FileStorageProvider {
  constructor(server: NetworkServerEntry) {
    super(server, new NfsBrowserService(server));
  }

  id(): string { return RemoteProtocol.NFS; }
  protocol(): RemoteProtocol { return RemoteProtocol.NFS; }
}

/**
 * HTTP entries are direct stream links, not browsable network storage.
 * Registering this provider preserves the previous NetworkDirectoryService behavior
 * without leaving protocol branches in that service.
 */
class DirectHttpCompatibilityProvider extends BaseNetworkStorageProvider {
  id(): string { return RemoteProtocol.HTTP; }
  protocol(): RemoteProtocol { return RemoteProtocol.HTTP; }
  initialPath(): string { return '/'; }
  displayPath(path: string): string { return path; }
  directoryPath(path: string): string { return path; }
  async stat(_path: string): Promise<StorageEntry | null> { return null; }
  async list(_path: string, _options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    throw new Error('该服务器不支持目录浏览');
  }
  async openWithOptions(_path: string, _options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    throw new Error('This source uses a direct HTTP URL');
  }
  async download(_path: string, _localPath: string): Promise<number> {
    throw new Error('当前协议不需要下载缓存');
  }
  directFileUrl(_path: string): string { return ''; }
  cancel(): void {}
}

export function createDefaultNetworkStorageProviderRegistry(): NetworkStorageProviderRegistry {
  const registry = new NetworkStorageProviderRegistry();
  registry.register(RemoteProtocol.WEBDAV,
    (server: NetworkServerEntry): NetworkStorageProvider => new WebDavStorageProvider(server));
  registry.register(RemoteProtocol.SMB,
    (server: NetworkServerEntry): NetworkStorageProvider => new SmbStorageProvider(server));
  registry.register(RemoteProtocol.SFTP,
    (server: NetworkServerEntry): NetworkStorageProvider => new SftpStorageProvider(server));
  registry.register(RemoteProtocol.FTP,
    (server: NetworkServerEntry): NetworkStorageProvider => new FtpStorageProvider(server));
  registry.register(RemoteProtocol.NFS,
    (server: NetworkServerEntry): NetworkStorageProvider => new NfsStorageProvider(server));
  registry.register(RemoteProtocol.HTTP,
    (server: NetworkServerEntry): NetworkStorageProvider => new DirectHttpCompatibilityProvider(server));
  return registry;
}
