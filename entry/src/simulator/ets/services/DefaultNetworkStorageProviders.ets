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
import { HttpRemoteReadSession } from 'entry/ets/services/HttpRemoteReadSession';
import {
  NetworkStorageOpenOptions,
  NetworkStorageProvider,
  NetworkStorageProviderRegistry
} from 'entry/ets/services/NetworkStorageProvider';
import { NetworkServerEntry } from 'entry/ets/services/NetworkServerStore';
import {
  WebDavBrowserEntry,
  WebDavBrowserService,
  WebDavEntryKind
} from 'entry/ets/services/WebDavBrowserService';

function sourceId(server: NetworkServerEntry, path: string): string {
  return `network:${server.id}:${server.protocol}:${path}`;
}

function sourceCapabilities(): SourceCapabilities {
  return new SourceCapabilities(true, true, true, true, true, false);
}

function directory(path: string): string {
  let value: string = path.trim();
  if (value.length === 0) return '/';
  if (!value.startsWith('/')) value = `/${value}`;
  return value.endsWith('/') ? value : `${value}/`;
}

function comparable(path: string): string {
  if (path.length > 1 && path.endsWith('/')) return path.substring(0, path.length - 1);
  return path.length === 0 ? '/' : path;
}

function parent(path: string): string {
  const normalized: string = comparable(path);
  if (normalized === '/') return '/';
  const slash: number = normalized.lastIndexOf('/');
  return slash <= 0 ? '/' : `${normalized.substring(0, slash)}/`;
}

class SimulatorWebDavStorageProvider implements NetworkStorageProvider {
  private readonly server: NetworkServerEntry;
  private readonly browser: WebDavBrowserService;

  constructor(server: NetworkServerEntry) {
    this.server = server;
    this.browser = new WebDavBrowserService(server);
  }

  id(): string { return RemoteProtocol.WEBDAV; }
  protocol(): RemoteProtocol { return RemoteProtocol.WEBDAV; }
  initialPath(): string { return directory(this.server.rootPath); }
  displayPath(path: string): string { return path; }
  directoryPath(path: string): string { return directory(path); }

  async stat(path: string): Promise<StorageEntry | null> {
    if (comparable(path) === '/') {
      return new StorageEntry('/', '/', StorageEntryKind.DIRECTORY);
    }
    const entries: StorageEntry[] = await this.list(parent(path));
    const target: string = comparable(path);
    for (const entry of entries) {
      if (comparable(entry.locator) === target) return entry;
    }
    return null;
  }

  async list(path: string, options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    const entries: WebDavBrowserEntry[] = await this.browser.list(directory(path), options.forceRefresh);
    return entries.map((entry: WebDavBrowserEntry): StorageEntry =>
      new StorageEntry(
        entry.path,
        entry.displayName,
        entry.kind === WebDavEntryKind.DIRECTORY ? StorageEntryKind.DIRECTORY : StorageEntryKind.FILE,
        entry.size,
        entry.modifiedAt
      ));
  }

  async open(path: string): Promise<RandomAccessSource> {
    return this.openWithOptions(path, new NetworkStorageOpenOptions());
  }

  async openWithOptions(path: string, _options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    const session: RemoteReadSession =
      await HttpRemoteReadSession.open(this.browser.fileUrl(path), this.browser.fileHeaders());
    return new RemoteReadSessionAdapter(sourceId(this.server, path), session, sourceCapabilities());
  }

  async download(_path: string, _localPath: string): Promise<number> {
    throw new Error('WebDAV simulator path uses random access instead of compatibility download.');
  }

  directFileUrl(path: string): string {
    return this.browser.fileUrl(path);
  }

  cancel(): void {
    this.browser.cancel();
  }
}

class SimulatorDirectHttpProvider implements NetworkStorageProvider {
  private readonly server: NetworkServerEntry;

  constructor(server: NetworkServerEntry) {
    this.server = server;
  }

  id(): string { return RemoteProtocol.HTTP; }
  protocol(): RemoteProtocol { return RemoteProtocol.HTTP; }
  initialPath(): string { return '/'; }
  displayPath(path: string): string { return path; }
  directoryPath(path: string): string { return path; }
  async stat(_path: string): Promise<StorageEntry | null> { return null; }

  async list(_path: string, _options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    throw new Error('HTTP direct links do not support directory browsing.');
  }

  async open(_path: string): Promise<RandomAccessSource> {
    throw new Error('HTTP direct links are opened directly by the player.');
  }

  async openWithOptions(_path: string, _options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    throw new Error('HTTP direct links are opened directly by the player.');
  }

  async download(_path: string, _localPath: string): Promise<number> {
    throw new Error('HTTP direct links do not require compatibility download.');
  }

  directFileUrl(_path: string): string {
    const scheme: string = this.server.secureTransport ? 'https' : 'http';
    const defaultPort: number = this.server.secureTransport ? 443 : 80;
    const port: string = this.server.port === defaultPort ? '' : `:${this.server.port}`;
    const path: string = this.server.rootPath.startsWith('/') ?
      this.server.rootPath : `/${this.server.rootPath}`;
    return `${scheme}://${this.server.host}${port}${path}`;
  }

  cancel(): void {}
}

class SimulatorUnavailableNativeStorageProvider implements NetworkStorageProvider {
  private readonly server: NetworkServerEntry;

  constructor(server: NetworkServerEntry) {
    this.server = server;
  }

  id(): string { return this.server.protocol; }
  protocol(): RemoteProtocol { return this.server.protocol; }

  initialPath(): string {
    const path: string = this.server.rootPath.trim();
    return path.length > 0 ? path : '/';
  }

  displayPath(path: string): string {
    return path.length > 0 ? path : '/';
  }

  directoryPath(path: string): string {
    return path.length > 0 ? path : '/';
  }

  async stat(_path: string): Promise<StorageEntry | null> {
    throw this.unavailable();
  }

  async list(_path: string, _options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    throw this.unavailable();
  }

  async open(_path: string): Promise<RandomAccessSource> {
    throw this.unavailable();
  }

  async openWithOptions(_path: string, _options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    throw this.unavailable();
  }

  async download(_path: string, _localPath: string): Promise<number> {
    throw this.unavailable();
  }

  directFileUrl(_path: string): string {
    return '';
  }

  cancel(): void {}

  private unavailable(): Error {
    return new Error(
      `SIMULATOR_NATIVE_TRANSPORT_UNAVAILABLE: ${this.server.protocol.toUpperCase()} requires the arm64 native transport.`
    );
  }
}

export function createDefaultNetworkStorageProviderRegistry(): NetworkStorageProviderRegistry {
  const registry = new NetworkStorageProviderRegistry();

  registry.register(RemoteProtocol.WEBDAV,
    (server: NetworkServerEntry): NetworkStorageProvider => new SimulatorWebDavStorageProvider(server));
  registry.register(RemoteProtocol.HTTP,
    (server: NetworkServerEntry): NetworkStorageProvider => new SimulatorDirectHttpProvider(server));

  for (const protocol of [
    RemoteProtocol.SMB,
    RemoteProtocol.SFTP,
    RemoteProtocol.FTP,
    RemoteProtocol.NFS
  ]) {
    registry.register(protocol,
      (server: NetworkServerEntry): NetworkStorageProvider =>
        new SimulatorUnavailableNativeStorageProvider(server));
  }

  return registry;
}
