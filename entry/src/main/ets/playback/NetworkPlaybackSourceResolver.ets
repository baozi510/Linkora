import { common } from '@kit.AbilityKit';
import {
  MediaFormat,
  MediaSource,
  MediaSourceKind,
  PlaybackPlaylist,
  PlaybackPlaylistItem
} from 'linkora_core';
import { NetworkFileProxy, NetworkFileProxyConfig, ProxyUrlLease } from 'linkora_proxy';
import { NetworkDirectoryService } from '../services/NetworkDirectoryService';
import { NetworkServerEntry, NetworkServerStore } from '../services/NetworkServerStore';
import { NetworkMediaSourceFactory } from '../services/NetworkMediaSourceFactory';
import { NetworkPlaylistSources } from './NetworkPlaylistSources';

export class ResolvedPlaybackSource {
  readonly source: MediaSource;
  readonly playlist: PlaybackPlaylist | null;
  private readonly releaseAction: () => Promise<void>;
  private released: boolean = false;

  constructor(source: MediaSource, releaseAction: () => Promise<void> = async () => {},
    playlist: PlaybackPlaylist | null = null) {
    this.source = source;
    this.releaseAction = releaseAction;
    this.playlist = playlist;
  }

  async release(): Promise<void> {
    if (this.released) {
      return;
    }
    this.released = true;
    await this.releaseAction();
  }
}

export class NetworkPlaybackSourceResolver {
  private readonly context: common.UIAbilityContext;
  private readonly proxy: NetworkFileProxy;

  constructor(context: common.UIAbilityContext, proxy: NetworkFileProxy) {
    this.context = context;
    this.proxy = proxy;
  }

  async resolve(source: MediaSource, playlist: PlaybackPlaylist | null = null): Promise<ResolvedPlaybackSource> {
    if (playlist !== null && source.kind === MediaSourceKind.REMOTE_FILE) {
      return this.resolvePlaylist(playlist);
    }
    if (source.kind !== MediaSourceKind.REMOTE_FILE) {
      return new ResolvedPlaybackSource(source);
    }

    const serverId: number = NetworkMediaSourceFactory.serverId(source);
    if (serverId <= 0) {
      throw new Error('Remote media source has no valid server identity');
    }
    const servers: NetworkServerEntry[] = await new NetworkServerStore(this.context).load();
    const server: NetworkServerEntry | undefined =
      servers.find((entry: NetworkServerEntry): boolean => entry.id === serverId);
    if (server === undefined) {
      throw new Error('Remote media server no longer exists');
    }

    const service = new NetworkDirectoryService(server);
    const randomAccess = await service.openSource(source.locator);
    let lease: ProxyUrlLease | null = null;
    try {
      lease = await this.proxy.buildSourceUrl(randomAccess, this.contentType(source.format));
      const resolved: MediaSource = this.withUrl(source, lease.url);
      return new ResolvedPlaybackSource(resolved, () => lease!.release());
    } catch (error) {
      randomAccess.cancel();
      await randomAccess.close().catch(() => {});
      throw error as Error;
    }
  }

  private async resolvePlaylist(playlist: PlaybackPlaylist): Promise<ResolvedPlaybackSource> {
    const items: PlaybackPlaylistItem[] = playlist.items;
    const serverId: number = items.length === 0 ? 0 : NetworkMediaSourceFactory.serverId(items[0].source);
    if (serverId <= 0 || items.some((item) => item.source.kind !== MediaSourceKind.REMOTE_FILE ||
      NetworkMediaSourceFactory.serverId(item.source) !== serverId)) {
      throw new Error('Network playlist must belong to one saved server');
    }
    const servers: NetworkServerEntry[] = await new NetworkServerStore(this.context).load();
    const server: NetworkServerEntry | undefined = servers.find((entry) => entry.id === serverId);
    if (server === undefined) throw new Error('Remote media server no longer exists');
    const service = new NetworkDirectoryService(server);
    const owner = new NetworkPlaylistSources(items.map((item) => item.source),
      (index: number, setupObserver: (settled: Promise<void>) => void) =>
        service.openSource(items[index].source.locator, '', setupObserver));
    // Slots are metadata-only URLs. The owner, not this slot count, bounds live upstream readers to one.
    const proxy = new NetworkFileProxy(new NetworkFileProxyConfig(256 * 1024, 8000, items.length));
    const close = async (): Promise<void> => {
      try { await owner.release(); } finally { await proxy.close(); }
    };
    try {
      const sources = owner.sources();
      const resolved: PlaybackPlaylistItem[] = [];
      for (let index: number = 0; index < items.length; index++) {
        const lease = await proxy.buildSourceUrl(sources[index], this.contentType(items[index].source.format));
        resolved.push(new PlaybackPlaylistItem(items[index].id, this.withUrl(items[index].source, lease.url)));
      }
      const queue = new PlaybackPlaylist(resolved, playlist.startIndex, playlist.complete);
      return new ResolvedPlaybackSource(resolved[playlist.startIndex].source, close, queue);
    } catch (error) {
      await close();
      throw error as Error;
    }
  }

  private withUrl(source: MediaSource, url: string): MediaSource {
    return new MediaSource(MediaSourceKind.NETWORK_LINK, url, source.displayName, source.originLabel,
      source.format, source.localCategory, source.sizeBytes, '', source.sourceId, source.credentialRef, source.fingerprint);
  }

  private contentType(format: MediaFormat): string {
    if (format === MediaFormat.MP4) return 'video/mp4';
    if (format === MediaFormat.MATROSKA) return 'video/x-matroska';
    if (format === MediaFormat.MPEG_TS) return 'video/mp2t';
    if (format === MediaFormat.HLS) return 'application/vnd.apple.mpegurl';
    if (format === MediaFormat.DASH) return 'application/dash+xml';
    if (format === MediaFormat.AUDIO) return 'audio/mpeg';
    return 'application/octet-stream';
  }
}
