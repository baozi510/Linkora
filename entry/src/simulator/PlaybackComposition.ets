import { common } from '@kit.AbilityKit';
import {
  MediaSource,
  PlaybackBackend,
  PlaybackPort,
  PlaybackPortError,
  PlaybackPortObserver,
  PlayerBackendKind,
  PlayerBackendPreference
} from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import {
  NetworkPlaybackSourceResolver,
  ResolvedPlaybackSource
} from 'entry/ets/playback/NetworkPlaybackSourceResolver';
import { SystemPlaybackPort } from 'entry/ets/playback/SystemPlaybackPort';

/**
 * Simulator-only System backend wrapper.
 *
 * REMOTE_FILE still resolves through RandomAccessSource -> shared MediaProxy,
 * preserving the production WebDAV path while excluding MPV/native protocols.
 */
class SimulatorSystemPlaybackPort implements PlaybackPort {
  private readonly observer: PlaybackPortObserver;
  private readonly resolver: NetworkPlaybackSourceResolver;
  private source: MediaSource | null = null;
  private surfaceId: string = '';
  private resolved: ResolvedPlaybackSource | null = null;
  private backend: PlaybackBackend | null = null;
  private released: boolean = false;
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;

  constructor(context: common.UIAbilityContext, proxy: NetworkFileProxy, observer: PlaybackPortObserver) {
    this.observer = observer;
    this.resolver = new NetworkPlaybackSourceResolver(context, proxy);
  }

  configure(source: MediaSource, surfaceId: string): void {
    if (this.released || surfaceId.length === 0) {
      throw new PlaybackPortError(0, 'Simulator System backend is unavailable');
    }
    this.source = source;
    this.surfaceId = surfaceId;
  }

  setSurfaceSize(width: number, height: number): void {
    this.surfaceWidth = Math.max(0, Math.round(width));
    this.surfaceHeight = Math.max(0, Math.round(height));
    if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
      this.backend?.setSurfaceSize(this.surfaceWidth, this.surfaceHeight);
    }
  }

  getDuration(): number {
    return this.backend?.getDuration() ?? 0;
  }

  async prepare(): Promise<void> {
    const source: MediaSource | null = this.source;
    if (this.released || source === null || this.surfaceId.length === 0) {
      throw new PlaybackPortError(0, 'Simulator System backend is not configured');
    }

    try {
      this.resolved = await this.resolver.resolve(source);
      this.backend = await SystemPlaybackPort.create(this.observer);
      this.backend.configure(this.resolved.source, this.surfaceId);
      if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
        this.backend.setSurfaceSize(this.surfaceWidth, this.surfaceHeight);
      }
      await this.backend.prepare();
      this.observer.onBackendChange(PlayerBackendKind.SYSTEM);
    } catch (error) {
      await this.backend?.release().catch(() => {});
      this.backend = null;
      await this.releaseResolved();
      throw error instanceof PlaybackPortError ?
        error : new PlaybackPortError(0, String(error));
    }
  }

  async play(): Promise<void> {
    await this.requireBackend().play();
  }

  async pause(): Promise<void> {
    await this.requireBackend().pause();
  }

  seek(position: number): void {
    this.requireBackend().seek(position);
  }

  setPlaybackRate(rate: number): void {
    this.requireBackend().setPlaybackRate(rate);
  }

  setVolume(volume: number): void {
    this.requireBackend().setVolume(volume);
  }

  async release(): Promise<void> {
    if (this.released) return;
    this.released = true;
    const backend: PlaybackBackend | null = this.backend;
    this.backend = null;
    await backend?.release().catch(() => {});
    await this.releaseResolved();
  }

  private requireBackend(): PlaybackBackend {
    if (this.backend === null || this.released) {
      throw new PlaybackPortError(0, 'Simulator System backend is not prepared');
    }
    return this.backend;
  }

  private async releaseResolved(): Promise<void> {
    const resolved: ResolvedPlaybackSource | null = this.resolved;
    this.resolved = null;
    await resolved?.release().catch(() => {});
  }
}

export async function createPlaybackPort(context: common.UIAbilityContext, proxy: NetworkFileProxy,
  observer: PlaybackPortObserver, _preference: PlayerBackendPreference): Promise<PlaybackPort> {
  return new SimulatorSystemPlaybackPort(context, proxy, observer);
}
