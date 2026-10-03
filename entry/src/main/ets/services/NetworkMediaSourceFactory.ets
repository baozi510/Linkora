import { MediaSource } from 'linkora_core';
import { NetworkDirectoryEntry } from '../models/NetworkDirectoryState';
import { NetworkServerEntry } from './NetworkServerStore';

const NETWORK_SERVER_PREFIX: string = 'network-server:';

export class NetworkMediaSourceFactory {
  static fromEntry(server: NetworkServerEntry, entry: NetworkDirectoryEntry): MediaSource {
    const identity: string = this.sourceId(server.id);
    const fingerprint: string =
      [server.updatedAt, entry.size, entry.modifiedAt].join(':');
    return MediaSource.fromRemoteFile(
      entry.path,
      entry.displayName,
      server.titleLabel(),
      entry.size,
      identity,
      identity,
      fingerprint
    );
  }

  static sourceId(serverId: number): string {
    return `${NETWORK_SERVER_PREFIX}${serverId}`;
  }

  static serverId(source: MediaSource): number {
    if (!source.sourceId.startsWith(NETWORK_SERVER_PREFIX)) {
      return 0;
    }
    const value: number =
      Number(source.sourceId.substring(NETWORK_SERVER_PREFIX.length));
    return Number.isSafeInteger(value) && value > 0 ? value : 0;
  }
}
