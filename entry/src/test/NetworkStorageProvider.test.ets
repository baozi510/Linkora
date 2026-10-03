import { describe, expect, it } from '@ohos/hypium';
import {
  RandomAccessSource,
  RemoteProtocol,
  SourceCapabilities,
  StorageEntry,
  StorageEntryKind,
  StorageListOptions
} from 'linkora_core';
import { NetworkDirectoryEntryKind } from '../main/ets/models/NetworkDirectoryState';
import { NetworkDirectoryService } from '../main/ets/services/NetworkDirectoryService';
import {
  NetworkStorageOpenOptions,
  NetworkStorageProvider,
  NetworkStorageProviderRegistry
} from '../main/ets/services/NetworkStorageProvider';
import { NetworkServerEntry } from '../main/ets/services/NetworkServerStore';

class FakeRandomAccessSource implements RandomAccessSource {
  cancelled: boolean = false;
  closed: boolean = false;

  id(): string { return 'fake-source'; }
  size(): number { return 2048; }
  capabilities(): SourceCapabilities {
    return new SourceCapabilities(true, true, true, true);
  }
  async readAt(_offset: number, length: number): Promise<ArrayBuffer> {
    return new ArrayBuffer(length);
  }
  cancel(): void { this.cancelled = true; }
  async close(): Promise<void> { this.closed = true; }
}

class FakeNetworkStorageProvider implements NetworkStorageProvider {
  readonly source: FakeRandomAccessSource = new FakeRandomAccessSource();
  forceRefresh: boolean = false;
  expectedFingerprint: string = '';

  id(): string { return RemoteProtocol.SMB; }
  protocol(): RemoteProtocol { return RemoteProtocol.SMB; }
  initialPath(): string { return 'Movies'; }
  displayPath(path: string): string { return `/Share/${path}`; }
  directoryPath(path: string): string { return path; }

  async stat(path: string): Promise<StorageEntry | null> {
    return new StorageEntry(path, 'movie.mkv', StorageEntryKind.FILE, 2048, 1234);
  }

  async list(_path: string, options: StorageListOptions = new StorageListOptions()): Promise<StorageEntry[]> {
    this.forceRefresh = options.forceRefresh;
    return [
      new StorageEntry('Movies/Sub', 'Sub', StorageEntryKind.DIRECTORY),
      new StorageEntry('Movies/movie.mkv', 'movie.mkv', StorageEntryKind.FILE, 2048, 1234)
    ];
  }

  async open(_path: string): Promise<RandomAccessSource> {
    return this.source;
  }

  async openWithOptions(_path: string, options: NetworkStorageOpenOptions): Promise<RandomAccessSource> {
    this.expectedFingerprint = options.expectedFingerprint;
    return this.source;
  }

  async download(_path: string, _localPath: string): Promise<number> { return 2048; }
  directFileUrl(_path: string): string { return ''; }
  cancel(): void { this.source.cancel(); }
}

export default function networkStorageProviderTest(): void {
  describe('NetworkStorageProvider', () => {
    it('resolvesProvidersThroughRegistry', 0, () => {
      const registry = new NetworkStorageProviderRegistry();
      const provider = new FakeNetworkStorageProvider();
      registry.register(RemoteProtocol.SMB,
        (_server: NetworkServerEntry): NetworkStorageProvider => provider);
      const server = new NetworkServerEntry(
        7, 'NAS', RemoteProtocol.SMB, '192.0.2.1', 445, '/Share/Movies'
      );

      expect(registry.create(server)).assertEqual(provider);
      expect(registry.registeredProtocols()[0]).assertEqual(RemoteProtocol.SMB);
    });

    it('routesDirectoryServiceThroughStorageProvider', 0, async () => {
      const registry = new NetworkStorageProviderRegistry();
      const provider = new FakeNetworkStorageProvider();
      registry.register(RemoteProtocol.SMB,
        (_server: NetworkServerEntry): NetworkStorageProvider => provider);
      const server = new NetworkServerEntry(
        7, 'NAS', RemoteProtocol.SMB, '192.0.2.1', 445, '/Share/Movies'
      );
      const service = new NetworkDirectoryService(server, registry);

      const entries = await service.list('Movies', true);
      const reader = await service.openReader('Movies/movie.mkv', 'sha256:fingerprint');
      const data = await reader.read(128, 256);

      expect(service.initialPath()).assertEqual('Movies');
      expect(service.displayPath('Movies')).assertEqual('/Share/Movies');
      expect(service.cachePrefix()).assertEqual(RemoteProtocol.SMB);
      expect(provider.forceRefresh).assertTrue();
      expect(provider.expectedFingerprint).assertEqual('sha256:fingerprint');
      expect(entries.length).assertEqual(2);
      expect(entries[0].kind).assertEqual(NetworkDirectoryEntryKind.DIRECTORY);
      expect(entries[1].size).assertEqual(2048);
      expect(data.byteLength).assertEqual(256);

      reader.cancel();
      await reader.close();
      expect(provider.source.cancelled).assertTrue();
      expect(provider.source.closed).assertTrue();
    });
  });
}
