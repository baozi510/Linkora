import {
  RandomAccessSource,
  RemoteProtocol,
  StorageEntry,
  StorageListOptions
} from 'linkora_core';
import {
  NetworkStorageOpenOptions,
  NetworkStorageProvider,
  NetworkStorageProviderRegistry
} from 'entry/ets/services/NetworkStorageProvider';
import { NetworkServerEntry } from 'entry/ets/services/NetworkServerStore';
import {
  BaseNetworkStorageProvider,
  registerSharedNetworkStorageProviders
} from 'entry/ets/services/SharedNetworkStorageProviders';

/**
 * Last-layer replacement for protocol transports that are arm64-native in production.
 *
 * Everything before this provider remains shared: UI, settings, database, registry,
 * routing, NetworkDirectoryService and error presentation.
 */
class SimulatorUnavailableNativeStorageProvider extends BaseNetworkStorageProvider {
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

  // These are the exact same ArkTS implementations used by the default target.
  registerSharedNetworkStorageProviders(registry);

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
