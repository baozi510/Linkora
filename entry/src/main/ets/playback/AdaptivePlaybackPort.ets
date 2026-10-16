import { common } from '@kit.AbilityKit';
import {
  MediaSource,
  PlaybackPlaylist,
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
  PortVideoInfo,
  PortStreamEnd, PortAudioInterruption, PortAudioOutputChange, VideoDisplayMode
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
  private playlistIndex: number = -1;
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
      },
      (rate: number) => { if (this.committed) target.onPlaybackRateChange(rate); },
      (volume: number) => { if (this.committed) target.onVolumeChange(volume); },
      (loop: boolean) => { if (this.committed) target.onLoopChange(loop); },
      (end: PortStreamEnd) => { if (this.committed) target.onStreamEnd(end); },
      (event: PortAudioInterruption) => { if (this.committed) target.onAudioInterruption(event); },
      (event: PortAudioOutputChange) => { if (this.committed) target.onAudioOutputChange(event); },
      (operation: string, error: PlaybackPortError) => {
        if (this.committed) target.onWarning(operation, error);
      },
      (mode: VideoDisplayMode) => {
        if (this.committed) target.onDisplayModeChange(mode);
      },
      (index: number) => {
        this.playlistIndex = index;
        if (this.committed) target.onPlaylistIndexChange(index);
      }
    );
  }

  commit(backend: string): void {
    this.committed = true;
    this.target.onBackendChange(backend);
    if (this.committed && this.playlistIndex >= 0) this.target.onPlaylistIndexChange(this.playlistIndex);
    if (this.committed && this.duration > 0) this.target.onDurationChange(this.duration);
    if (this.committed && this.videoWidth > 0 && this.videoHeight > 0) {
      this.target.onVideoSizeChange(this.videoWidth, this.videoHeight);
    }
    if (this.committed && this.tracks.length > 0) this.target.onTracksChange(this.tracks);
    if (this.committed) this.target.onVideoInfoChange(this.videoInfo);
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
  private playlist: PlaybackPlaylist | null = null;
  private surfaceId: string = '';
  private resolved: ResolvedPlaybackSource | null = null;
  private backend: PlaybackBackend | null = null;
  private committedGate: CandidateObserver | null = null;
  // Own the candidate until its preparation has finished and it is committed.
  private pendingCandidate: PlaybackBackend | null = null;
  private released: boolean = false;
  private releasePromise: Promise<void> | null = null;
  private releaseFailure: PlaybackPortError | null = null;
  private candidateRelease: Promise<void> | null = null;
  private resolvedRelease: Promise<void> | null = null;
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

  configure(source: MediaSource, surfaceId: string, playlist: PlaybackPlaylist | null = null): void {
    if (this.released || surfaceId.length === 0) {
      throw new PlaybackPortError(0, 'Adaptive playback backend is unavailable');
    }
    this.source = source;
    this.playlist = playlist;
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
      try {
        await resolved.release();
      } catch (error) {
        this.releaseFailure = this.asPortError(error);
        throw this.releaseFailure;
      }
      throw this.cancelledError();
    }
    this.resolved = resolved;
    const selected: PlayerBackendKind = this.selector.select(source, this.preference);
    let candidate: PreparedCandidate;
    try {
      candidate = await this.prepareBackend(selected, resolved.source);
    } catch (firstError) {
      if (this.released || this.releaseFailure !== null || this.preference !== PlayerBackendPreference.AUTO) {
        if (this.released) await this.release();
        else await this.releaseResolved();
        throw this.releaseFailure ?? this.asPortError(firstError);
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
    this.committedGate = candidate.gate;
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

  async stop(): Promise<void> {
    await this.requireBackend().stop();
  }

  async selectPlaylistItem(index: number): Promise<void> {
    await this.requireBackend().selectPlaylistItem(index);
  }

  setLoop(loop: boolean): void {
    this.requireBackend().setLoop(loop);
  }

  setDisplayMode(mode: VideoDisplayMode): void {
    this.requireBackend().setDisplayMode(mode);
  }

  async selectAudioTrack(id: string): Promise<void> {
    await this.requireBackend().selectAudioTrack(id);
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

  release(): Promise<void> {
    if (this.releasePromise !== null) {
      return this.releasePromise.then(() => {
        if (this.releaseFailure !== null) throw this.releaseFailure;
      });
    }
    this.releasePromise = this.releaseResources().catch((error: PlaybackPortError) => {
      this.releaseFailure = this.asPortError(error);
      throw this.releaseFailure;
    });
    return this.releasePromise;
  }

  private async releaseResources(): Promise<void> {
    this.released = true;
    if (this.committedGate !== null) {
      this.committedGate.committed = false;
      this.committedGate = null;
    }
    const backend: PlaybackBackend | null = this.backend;
    const pending: PlaybackBackend | null = this.pendingCandidate;
    this.backend = null;
    this.pendingCandidate = null;
    // Stop an in-flight native prepare before releasing its source lease.
    try {
      try {
        await this.candidateRelease;
        if (pending !== null && pending !== backend) {
          await pending.release();
        }
      } finally {
        await backend?.release();
      }
    } finally {
      await this.releaseResolved();
    }
    if (this.releaseFailure !== null) throw this.releaseFailure;
    this.observer.onStateChange(PortPlaybackState.RELEASED);
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
      backend.configure(source, this.surfaceId, this.playlist);
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
        this.candidateRelease = Promise.resolve().then(() => backend.release())
          .catch((releaseError: PlaybackPortError) => {
          this.releaseFailure = this.asPortError(releaseError);
          throw this.releaseFailure;
          });
        await this.candidateRelease;
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

  private releaseResolved(): Promise<void> {
    if (this.resolvedRelease !== null) return this.resolvedRelease;
    const resolved: ResolvedPlaybackSource | null = this.resolved;
    this.resolved = null;
    if (resolved === null) return Promise.resolve();
    this.resolvedRelease = Promise.resolve().then(() => resolved.release());
    return this.resolvedRelease;
  }

  private cancelledError(): PlaybackPortError {
    return new PlaybackPortError(5400104, 'Playback preparation cancelled');
  }

  private asPortError(error: Object): PlaybackPortError {
    return error instanceof PlaybackPortError ?
      error : new PlaybackPortError(0, String(error));
  }
}
