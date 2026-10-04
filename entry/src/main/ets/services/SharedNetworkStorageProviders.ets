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
import { HttpRemoteReadSession } from './HttpRemoteReadSession';
import {
  NetworkStorageOpenOptions,
  NetworkStorageProvider,
  NetworkStorageProviderRegistry
} from './NetworkStorageProvider';
import { NetworkServerEntry } from './NetworkServerStore';
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
  if (value.length === 0) return '/';
  if (!value.startsWith('/')) value = `/${value}`;
  return value.endsWith('/') ? value : `${value}/`;
}

export function comparablePath(path: string): string {
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path.length === 0 ? '/' : path;
}

function webDavParent(path: string): string {
  const normalized: string = comparablePath(path);
  if (normalized === '/') return '/';
  const slash: number = normalized.lastIndexOf('/');
  return slash <= 0 ? '/' : `${normalized.substring(0, slash)}/`;
}

export async function statFromEntries(entries: StorageEntry[], path: string): Promise<StorageEntry | null> {
  const target: string = comparablePath(path);
  for (const entry of entries) {
    if (comparablePath(entry.locator) === target) return entry;
  }
  return null;
}

export abstract class BaseNetworkStorageProvider implements NetworkStorageProvider {
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

export class WebDavStorageProvider extends BaseNetworkStorageProvider {
  private readonly browser: WebDavBrowserService;

  constructor(server: NetworkServerEntry) {
    super(server);
    this.browser = new WebDavBrowserService(server);
  }

  id(): string { return RemoteProtocol.WEBDAV; }
  protocol(): RemoteProtocol { return RemoteProtocol.WEBDAV; }
  initialPath(): string { return webDavDirectory(this.server.rootPath); }
  displayPath(path: string): string { return path; }
  directoryPath(path: string): string { return webDavDirectory(path); }

  async stat(path: string): Promise<StorageEntry | null> {
    if (comparablePath(path) === '/') {
      return new StorageEntry('/', '/', StorageEntryKind.DIRECTORY);
    }
    return statFromEntries(await this.list(webDavParent(path)), path);
  }

  async list(path: string, options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    const entries: WebDavBrowserEntry[] =
      await this.browser.list(webDavDirectory(path), options.forceRefresh);
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

/**
 * HTTP entries are direct stream links, not browsable network storage.
 * Keeping this provider shared prevents target-specific behavior drift.
 */
export class DirectHttpCompatibilityProvider extends BaseNetworkStorageProvider {
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

export function registerSharedNetworkStorageProviders(registry: NetworkStorageProviderRegistry): void {
  registry.register(RemoteProtocol.WEBDAV,
    (server: NetworkServerEntry): NetworkStorageProvider => new WebDavStorageProvider(server));
  registry.register(RemoteProtocol.HTTP,
    (server: NetworkServerEntry): NetworkStorageProvider => new DirectHttpCompatibilityProvider(server));
}
