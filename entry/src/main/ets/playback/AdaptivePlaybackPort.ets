import { common } from '@kit.AbilityKit';
import {
  MediaSource,
  PlaybackBackend,
  PlaybackBackendSelector,
  PlaybackPort,
  PlaybackPortError,
  PlaybackPortObserver,
  PlayerBackendKind,
  PlayerBackendPreference,
  PortBufferingEvent,
  PortPlaybackState
} from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { MpvPlaybackPort } from './MpvPlaybackPort';
import { NetworkPlaybackSourceResolver, ResolvedPlaybackSource } from './NetworkPlaybackSourceResolver';
import { SystemPlaybackPort } from './SystemPlaybackPort';

type BackendFactory = (observer: PlaybackPortObserver) => Promise<PlaybackBackend>;

class CandidateObserver {
  committed: boolean = false;
  error: PlaybackPortError | null = null;
  readonly observer: PlaybackPortObserver;

  constructor(target: PlaybackPortObserver) {
    this.observer = new PlaybackPortObserver(
      (state: PortPlaybackState) => {
        if (this.committed) target.onStateChange(state);
      },
      (error: PlaybackPortError) => {
        if (this.committed) {
          target.onError(error);
        } else {
          this.error = error;
        }
      },
      (value: number) => {
        if (this.committed) target.onDurationChange(value);
      },
      (value: number) => {
        if (this.committed) target.onPositionChange(value);
      },
      (event: PortBufferingEvent, value: number) => {
        if (this.committed) target.onBufferingChange(event, value);
      },
      () => {
        if (this.committed) target.onFirstFrame();
      },
      (width: number, height: number) => {
        if (this.committed) target.onVideoSizeChange(width, height);
      },
      () => {
        if (this.committed) target.onInterruptionPause();
      }
    );
  }
}

export class AdaptivePlaybackPort implements PlaybackPort {
  private readonly observer: PlaybackPortObserver;
  private readonly preference: PlayerBackendPreference;
  private readonly selector: PlaybackBackendSelector;
  private readonly resolver: NetworkPlaybackSourceResolver;
  private readonly systemFactory: BackendFactory;
  private readonly mpvFactory: BackendFactory;
  private source: MediaSource | null = null;
  private surfaceId: string = '';
  private resolved: ResolvedPlaybackSource | null = null;
  private backend: PlaybackBackend | null = null;
  private released: boolean = false;

  constructor(context: common.UIAbilityContext, proxy: NetworkFileProxy,
    observer: PlaybackPortObserver, preference: PlayerBackendPreference,
    selector: PlaybackBackendSelector = new PlaybackBackendSelector(),
    systemFactory: BackendFactory = (value: PlaybackPortObserver) => SystemPlaybackPort.create(value),
    mpvFactory: BackendFactory = (value: PlaybackPortObserver) => MpvPlaybackPort.create(value)) {
    this.observer = observer;
    this.preference = preference;
    this.selector = selector;
    this.resolver = new NetworkPlaybackSourceResolver(context, proxy);
    this.systemFactory = systemFactory;
    this.mpvFactory = mpvFactory;
  }

  configure(source: MediaSource, surfaceId: string): void {
    if (this.released || surfaceId.length === 0) {
      throw new PlaybackPortError(0, 'Adaptive playback backend is unavailable');
    }
    this.source = source;
    this.surfaceId = surfaceId;
    this.observer.onStateChange(PortPlaybackState.INITIALIZED);
  }

  getDuration(): number {
    return this.backend?.getDuration() ?? 0;
  }

  async prepare(): Promise<void> {
    const source: MediaSource | null = this.source;
    if (this.released || source === null || this.surfaceId.length === 0) {
      throw new PlaybackPortError(0, 'Adaptive playback backend is not configured');
    }

    this.resolved = await this.resolver.resolve(source);
    const selected: PlayerBackendKind = this.selector.select(source, this.preference);
    try {
      this.backend = await this.prepareBackend(selected, this.resolved.source);
    } catch (firstError) {
      if (this.preference !== PlayerBackendPreference.AUTO) {
        await this.releaseResolved();
        throw this.asPortError(firstError);
      }
      const fallback: PlayerBackendKind = this.selector.fallback(selected);
      try {
        this.backend = await this.prepareBackend(fallback, this.resolved.source);
      } catch (secondError) {
        await this.releaseResolved();
        throw this.asPortError(secondError);
      }
    }
    this.observer.onStateChange(PortPlaybackState.PREPARED);
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
    if (this.released) {
      return;
    }
    this.released = true;
    const backend: PlaybackBackend | null = this.backend;
    this.backend = null;
    await backend?.release().catch(() => {});
    await this.releaseResolved();
    this.observer.onStateChange(PortPlaybackState.RELEASED);
  }

  private async prepareBackend(kind: PlayerBackendKind, source: MediaSource): Promise<PlaybackBackend> {
    const gate = new CandidateObserver(this.observer);
    const factory: BackendFactory =
      kind === PlayerBackendKind.MPV ? this.mpvFactory : this.systemFactory;
    const backend: PlaybackBackend = await factory(gate.observer);
    try {
      backend.configure(source, this.surfaceId);
      await backend.prepare();
      if (gate.error !== null) {
        throw gate.error;
      }
      gate.committed = true;
      return backend;
    } catch (error) {
      await backend.release().catch(() => {});
      throw error;
    }
  }

  private requireBackend(): PlaybackBackend {
    if (this.backend === null || this.released) {
      throw new PlaybackPortError(0, 'Playback backend is not prepared');
    }
    return this.backend;
  }

  private async releaseResolved(): Promise<void> {
    const resolved: ResolvedPlaybackSource | null = this.resolved;
    this.resolved = null;
    await resolved?.release().catch(() => {});
  }

  private asPortError(error: Object): PlaybackPortError {
    return error instanceof PlaybackPortError ?
      error : new PlaybackPortError(0, String(error));
  }
}
