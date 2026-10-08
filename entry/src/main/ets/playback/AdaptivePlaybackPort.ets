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
  PortPlaybackState,
  PortTrack,
  PortVideoInfo
} from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { MpvPlaybackPort } from './MpvPlaybackPort';
import { NetworkPlaybackSourceResolver, ResolvedPlaybackSource } from './NetworkPlaybackSourceResolver';
import { SystemPlaybackPort } from './SystemPlaybackPort';

type BackendFactory = (observer: PlaybackPortObserver) => Promise<PlaybackBackend>;

interface PreparedCandidate {
  backend: PlaybackBackend;
  gate: CandidateObserver;
}

class CandidateObserver {
  committed: boolean = false;
  error: PlaybackPortError | null = null;
  private readonly target: PlaybackPortObserver;
  private duration: number = 0;
  private videoWidth: number = 0;
  private videoHeight: number = 0;
  private tracks: PortTrack[] = [];
  private videoInfo: PortVideoInfo = new PortVideoInfo();
  readonly observer: PlaybackPortObserver;

  constructor(target: PlaybackPortObserver) {
    this.target = target;
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
        this.duration = value;
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
        this.videoWidth = width;
        this.videoHeight = height;
        if (this.committed) target.onVideoSizeChange(width, height);
      },
      () => {
        if (this.committed) target.onInterruptionPause();
      },
      (position: number) => {
        if (this.committed) target.onSeekComplete(position);
      },
      (tracks: PortTrack[]) => {
        this.tracks = tracks.slice();
        if (this.committed) target.onTracksChange(tracks);
      },
      (info: PortVideoInfo) => {
        this.videoInfo = info;
        if (this.committed) target.onVideoInfoChange(info);
      },
      (backend: string) => {
        if (this.committed) target.onBackendChange(backend);
      }
    );
  }

  commit(backend: string): void {
    this.committed = true;
    this.target.onBackendChange(backend);
    if (this.duration > 0) this.target.onDurationChange(this.duration);
    if (this.videoWidth > 0 && this.videoHeight > 0) {
      this.target.onVideoSizeChange(this.videoWidth, this.videoHeight);
    }
    if (this.tracks.length > 0) this.target.onTracksChange(this.tracks);
    this.target.onVideoInfoChange(this.videoInfo);
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
  // Own the candidate until its preparation has finished and it is committed.
  private pendingCandidate: PlaybackBackend | null = null;
  private released: boolean = false;
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;

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
      throw this.cancelledError();
    }

    // Resolver completion can also race with a page leave. Never retain a
    // source lease returned after release().
    const resolved: ResolvedPlaybackSource = await this.resolver.resolve(source);
    if (this.released) {
      await resolved.release().catch(() => {});
      throw this.cancelledError();
    }
    this.resolved = resolved;
    const selected: PlayerBackendKind = this.selector.select(source, this.preference);
    let candidate: PreparedCandidate;
    try {
      candidate = await this.prepareBackend(selected, resolved.source);
    } catch (firstError) {
      if (this.released || this.preference !== PlayerBackendPreference.AUTO) {
        await this.releaseResolved();
        throw this.asPortError(firstError);
      }
      const fallback: PlayerBackendKind = this.selector.fallback(selected);
      try {
        candidate = await this.prepareBackend(fallback, resolved.source);
      } catch (secondError) {
        await this.releaseResolved();
        throw this.asPortError(secondError);
      }
    }

    // release() claims the pending candidate first. Recheck after await:
    // no stale observer commit, synthetic PREPARED or implicit Auto fallback.
    if (this.released) {
      throw this.cancelledError();
    }
    this.pendingCandidate = null;
    this.backend = candidate.backend;
    candidate.gate.commit(candidate.backend.backendKind());
    if (!this.released) {
      this.observer.onStateChange(PortPlaybackState.PREPARED);
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
    if (this.released) {
      return;
    }
    this.released = true;
    const backend: PlaybackBackend | null = this.backend;
    const pending: PlaybackBackend | null = this.pendingCandidate;
    this.backend = null;
    this.pendingCandidate = null;
    // Stop an in-flight native prepare before releasing its source lease.
    if (pending !== null && pending !== backend) {
      await pending.release().catch(() => {});
    }
    await backend?.release().catch(() => {});
    await this.releaseResolved();
    if (backend === null) {
      this.observer.onStateChange(PortPlaybackState.RELEASED);
    }
  }

  private async prepareBackend(kind: PlayerBackendKind, source: MediaSource): Promise<PreparedCandidate> {
    const gate = new CandidateObserver(this.observer);
    const factory: BackendFactory =
      kind === PlayerBackendKind.MPV ? this.mpvFactory : this.systemFactory;
    const backend: PlaybackBackend = await factory(gate.observer);
    // The factory can itself resolve after a release. Own the new object
    // immediately so the cancellation/error path disposes of it.
    this.pendingCandidate = backend;
    try {
      if (this.released) {
        throw this.cancelledError();
      }
      backend.configure(source, this.surfaceId);
      if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
        backend.setSurfaceSize(this.surfaceWidth, this.surfaceHeight);
      }
      await backend.prepare();
      if (this.released) {
        throw this.cancelledError();
      }
      if (gate.error !== null) {
        throw gate.error;
      }
      return { backend, gate };
    } catch (error) {
      // release() takes exclusive disposal ownership by clearing this slot.
      // Never concurrently call native release() twice for the same candidate.
      if (this.pendingCandidate === backend) {
        this.pendingCandidate = null;
        await backend.release().catch(() => {});
      }
      throw error as Error;
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

  private cancelledError(): PlaybackPortError {
    return new PlaybackPortError(5400104, 'Playback preparation cancelled');
  }

  private asPortError(error: Object): PlaybackPortError {
    return error instanceof PlaybackPortError ?
      error : new PlaybackPortError(0, String(error));
  }
}
