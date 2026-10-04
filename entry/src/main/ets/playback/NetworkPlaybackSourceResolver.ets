import { common } from '@kit.AbilityKit';
import {
  MediaFormat,
  MediaSource,
  MediaSourceKind
} from 'linkora_core';
import { NetworkFileProxy, ProxyUrlLease } from 'linkora_proxy';
import { NetworkDirectoryService } from '../services/NetworkDirectoryService';
import { NetworkServerEntry, NetworkServerStore } from '../services/NetworkServerStore';
import { NetworkMediaSourceFactory } from '../services/NetworkMediaSourceFactory';

export class ResolvedPlaybackSource {
  readonly source: MediaSource;
  private readonly releaseAction: () => Promise<void>;
  private released: boolean = false;

  constructor(source: MediaSource, releaseAction: () => Promise<void> = async () => {}) {
    this.source = source;
    this.releaseAction = releaseAction;
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

  async resolve(source: MediaSource): Promise<ResolvedPlaybackSource> {
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
      const resolved = new MediaSource(
        MediaSourceKind.NETWORK_LINK,
        lease.url,
        source.displayName,
        source.originLabel,
        source.format,
        source.localCategory,
        source.sizeBytes,
        '',
        source.sourceId,
        source.credentialRef,
        source.fingerprint
      );
      return new ResolvedPlaybackSource(resolved, () => lease!.release());
    } catch (error) {
      randomAccess.cancel();
      await randomAccess.close().catch(() => {});
      throw error as Error;
    }
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
