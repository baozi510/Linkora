import {
  RandomAccessSource,
  RandomAccessSourceSessionAdapter,
  RemoteReadSession,
  StorageEntry,
  StorageEntryKind,
  StorageListOptions
} from 'linkora_core';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind } from '../models/NetworkDirectoryState';
import { createDefaultNetworkStorageProviderRegistry } from 'entry/ets/services/DefaultNetworkStorageProviders';
import {
  NetworkStorageOpenOptions,
  NetworkStorageProvider,
  NetworkStorageProviderRegistry
} from './NetworkStorageProvider';
import { NetworkServerEntry } from './NetworkServerStore';

export class NetworkDirectoryService {
  private readonly provider: NetworkStorageProvider;

  constructor(server: NetworkServerEntry,
    registry: NetworkStorageProviderRegistry = createDefaultNetworkStorageProviderRegistry()) {
    this.provider = registry.create(server);
  }

  initialPath(): string {
    return this.provider.initialPath();
  }

  displayPath(path: string): string {
    return this.provider.displayPath(path);
  }

  directoryPath(path: string): string {
    return this.provider.directoryPath(path);
  }

  async list(path: string, forceRefresh: boolean = false): Promise<NetworkDirectoryEntry[]> {
    const entries: StorageEntry[] =
      await this.provider.list(path, new StorageListOptions(forceRefresh));
    return entries.map((entry: StorageEntry): NetworkDirectoryEntry =>
      new NetworkDirectoryEntry(
        entry.displayName,
        entry.locator,
        entry.kind === StorageEntryKind.DIRECTORY ?
          NetworkDirectoryEntryKind.DIRECTORY : NetworkDirectoryEntryKind.FILE,
        entry.sizeBytes,
        entry.modifiedAt
      ));
  }

  download(path: string, localPath: string): Promise<number> {
    return this.provider.download(path, localPath);
  }

  directFileUrl(path: string): string {
    return this.provider.directFileUrl(path);
  }

  openSource(path: string, expectedFingerprint: string = '',
    setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RandomAccessSource> {
    return this.provider.openWithOptions(
      path,
      new NetworkStorageOpenOptions(expectedFingerprint, setupObserver)
    );
  }

  async openReader(path: string, expectedFingerprint: string = '',
    setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RemoteReadSession> {
    const source: RandomAccessSource =
      await this.openSource(path, expectedFingerprint, setupObserver);
    return new RandomAccessSourceSessionAdapter(source);
  }

  cachePrefix(): string {
    return this.provider.id();
  }

  cancel(): void {
    this.provider.cancel();
  }
}
