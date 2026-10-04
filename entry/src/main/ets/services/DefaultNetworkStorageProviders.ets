import {
  RandomAccessSource,
  RemoteProtocol,
  RemoteReadSession,
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
import {
  NetworkStorageOpenOptions,
  NetworkStorageProvider,
  NetworkStorageProviderRegistry
} from './NetworkStorageProvider';
import { NetworkServerEntry } from './NetworkServerStore';
import {
  BaseNetworkStorageProvider,
  registerSharedNetworkStorageProviders,
  statFromEntries
} from './SharedNetworkStorageProviders';
import { SftpBrowserEntry, SftpBrowserService, SftpEntryKind } from './SftpBrowserService';
import { SmbBrowserEntry, SmbBrowserService, SmbEntryKind } from './SmbBrowserService';

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
    return statFromEntries(await this.list(this.browser.parent(path)), path);
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

export function createDefaultNetworkStorageProviderRegistry(): NetworkStorageProviderRegistry {
  const registry = new NetworkStorageProviderRegistry();

  registerSharedNetworkStorageProviders(registry);

  registry.register(RemoteProtocol.SMB,
    (server: NetworkServerEntry): NetworkStorageProvider => new SmbStorageProvider(server));
  registry.register(RemoteProtocol.SFTP,
    (server: NetworkServerEntry): NetworkStorageProvider => new SftpStorageProvider(server));
  registry.register(RemoteProtocol.FTP,
    (server: NetworkServerEntry): NetworkStorageProvider => new FtpStorageProvider(server));
  registry.register(RemoteProtocol.NFS,
    (server: NetworkServerEntry): NetworkStorageProvider => new NfsStorageProvider(server));

  return registry;
}
