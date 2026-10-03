import {
  RandomAccessSource,
  RemoteProtocol,
  StorageListOptions,
  StorageProvider
} from 'linkora_core';
import { NetworkServerEntry } from './NetworkServerStore';

export class NetworkStorageOpenOptions {
  readonly expectedFingerprint: string;
  readonly setupObserver: (settled: Promise<void>) => void;

  constructor(expectedFingerprint: string = '',
    setupObserver: (settled: Promise<void>) => void = () => {}) {
    this.expectedFingerprint = expectedFingerprint;
    this.setupObserver = setupObserver;
  }
}

export interface NetworkStorageProvider extends StorageProvider {
  protocol(): RemoteProtocol;
  initialPath(): string;
  displayPath(path: string): string;
  directoryPath(path: string): string;
  openWithOptions(path: string, options: NetworkStorageOpenOptions): Promise<RandomAccessSource>;
  download(path: string, localPath: string): Promise<number>;
  directFileUrl(path: string): string;
  cancel(): void;
}

export type NetworkStorageProviderFactory =
  (server: NetworkServerEntry) => NetworkStorageProvider;

export class NetworkStorageProviderRegistry {
  private readonly protocols: RemoteProtocol[] = [];
  private readonly factories: NetworkStorageProviderFactory[] = [];

  register(protocol: RemoteProtocol, factory: NetworkStorageProviderFactory): void {
    if (this.protocols.includes(protocol)) {
      throw new Error(`Network storage provider already registered: ${protocol}`);
    }
    this.protocols.push(protocol);
    this.factories.push(factory);
  }

  create(server: NetworkServerEntry): NetworkStorageProvider {
    const index: number = this.protocols.indexOf(server.protocol);
    if (index < 0) {
      throw new Error(`No network storage provider registered for: ${server.protocol}`);
    }
    return this.factories[index](server);
  }

  registeredProtocols(): RemoteProtocol[] {
    return this.protocols.slice();
  }
}

export function storageListOptions(forceRefresh: boolean): StorageListOptions {
  return new StorageListOptions(forceRefresh);
}
