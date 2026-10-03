import {
  EventObserver,
  Media,
  MpvEvent,
  Player,
  Track,
  Tracks
} from '@mpv-ohos/mpv-arkts';
import {
  MediaSource,
  MediaSourceKind,
  PlaybackBackend,
  PlaybackPortError,
  PlaybackPortObserver,
  PlayerBackendCapabilities,
  PlayerBackendKind,
  PortBufferingEvent,
  PortPlaybackState,
  PortTrack,
  PortTrackKind,
  PortVideoInfo
} from 'linkora_core';

const MPV_PREPARE_TIMEOUT_MS: number = 12000;

export class MpvPlaybackPort implements PlaybackBackend, EventObserver {
  private readonly observer: PlaybackPortObserver;
  private readonly player: Player;
  private source: MediaSource | null = null;
  private surfaceAttached: boolean = false;
  private released: boolean = false;
  private prepared: boolean = false;
  private firstFrameSignaled: boolean = false;
  private prepareResolve: (() => void) | null = null;
  private prepareReject: ((error: PlaybackPortError) => void) | null = null;
  private prepareTimer: number = -1;
  private seekPending: boolean = false;
  private latestErrorLog: string = '';

  private constructor(observer: PlaybackPortObserver) {
    this.observer = observer;
    this.player = new Player();
    this.player.native.addEventObserver(this);
    this.bindStreams();
  }

  static async create(observer: PlaybackPortObserver): Promise<PlaybackBackend> {
    try {
      return new MpvPlaybackPort(observer);
    } catch (error) {
      throw new PlaybackPortError(0, `Unable to create MPV backend: ${String(error)}`);
    }
  }

  backendKind(): PlayerBackendKind {
    return PlayerBackendKind.MPV;
  }

  capabilities(): PlayerBackendCapabilities {
    return new PlayerBackendCapabilities(
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      false,
      false
    );
  }

  configure(source: MediaSource, surfaceId: string): void {
    if (this.released || surfaceId.length === 0) {
      throw new PlaybackPortError(0, 'MPV backend is unavailable');
    }
    if (source.kind === MediaSourceKind.REMOTE_FILE) {
      throw new PlaybackPortError(0, 'Remote file must be resolved before MPV configure');
    }
    this.source = source;
    try {
      this.player.native.attachSurface(surfaceId);
      this.surfaceAttached = true;
      this.observer.onStateChange(PortPlaybackState.INITIALIZED);
    } catch (error) {
      throw new PlaybackPortError(0, `Unable to attach MPV surface: ${String(error)}`);
    }
  }

  setSurfaceSize(width: number, height: number): void {
    const safeWidth: number = Math.max(1, Math.round(width));
    const safeHeight: number = Math.max(1, Math.round(height));
    if (!this.released && this.surfaceAttached) {
      this.player.native.setProperty('ohos-surface-size', `${safeWidth}x${safeHeight}`);
    }
  }

  getDuration(): number {
    return Math.max(0, Math.round(this.player.state.duration * 1000));
  }

  async prepare(): Promise<void> {
    const source: MediaSource | null = this.source;
    if (this.released || source === null || !this.surfaceAttached) {
      throw new PlaybackPortError(0, 'MPV backend is not configured');
    }
    if (this.prepared) {
      return;
    }
    const waiting: Promise<void> = new Promise<void>((resolve, reject) => {
      this.prepareResolve = resolve;
      this.prepareReject = reject;
    });
    this.prepareTimer = setTimeout(() => {
      const diagnostic: string = this.latestErrorLog.length > 0 ? `: ${this.latestErrorLog}` : '';
      this.failPrepare(new PlaybackPortError(0, `MPV prepare timed out${diagnostic}`));
    }, MPV_PREPARE_TIMEOUT_MS);
    try {
      this.player.open(new Media(source.locator), false);
      await waiting;
    } finally {
      this.clearPrepareTimer();
    }
  }

  async play(): Promise<void> {
    this.ensureReady();
    this.player.play();
  }

  async pause(): Promise<void> {
    this.ensureReady();
    this.player.pause();
  }

  seek(position: number): void {
    this.ensureReady();
    this.seekPending = true;
    this.player.seek(Math.max(0, position) / 1000);
  }

  setPlaybackRate(rate: number): void {
    this.ensureReady();
    this.player.setSpeed(Math.max(0.1, rate));
  }

  setVolume(volume: number): void {
    this.ensureReady();
    this.player.setVolume(Math.max(0, Math.min(volume, 1)) * 100);
  }

  async release(): Promise<void> {
    if (this.released) {
      return;
    }
    this.released = true;
    this.clearPrepareTimer();
    this.failPrepare(new PlaybackPortError(0, 'MPV backend released'));
    try {
      this.player.native.removeEventObserver(this);
    } catch (_error) {
    }
    if (this.surfaceAttached) {
      try {
        this.player.native.detachSurface();
      } catch (_error) {
      }
      this.surfaceAttached = false;
    }
    try {
      this.player.destroy();
    } catch (_error) {
    }
    this.observer.onStateChange(PortPlaybackState.RELEASED);
  }

  onPropertyChanged(_property: string, _value?: string | number | boolean): void {
  }

  onEvent(id: number, _name: string): void {
    if (this.released) {
      return;
    }
    if (id === MpvEvent.MPV_EVENT_FILE_LOADED) {
      this.prepared = true;
      const resolve: (() => void) | null = this.prepareResolve;
      this.prepareResolve = null;
      this.prepareReject = null;
      this.clearPrepareTimer();
      this.observer.onStateChange(PortPlaybackState.PREPARED);
      resolve?.();
    } else if (id === MpvEvent.MPV_EVENT_PLAYBACK_RESTART) {
      if (!this.firstFrameSignaled) {
        this.firstFrameSignaled = true;
        this.observer.onFirstFrame();
      }
      if (this.seekPending) {
        this.seekPending = false;
        this.observer.onSeekComplete(Math.max(0, Math.round(this.player.state.position * 1000)));
      }
    }
  }

  private bindStreams(): void {
    this.player.stream.duration.listen((seconds: number) => {
      this.observer.onDurationChange(Math.max(0, Math.round(seconds * 1000)));
    });
    this.player.stream.position.listen((seconds: number) => {
      this.observer.onPositionChange(Math.max(0, Math.round(seconds * 1000)));
    });
    this.player.stream.playing.listen((playing: boolean) => {
      if (!this.prepared || this.released) {
        return;
      }
      this.observer.onStateChange(playing ? PortPlaybackState.PLAYING : PortPlaybackState.PAUSED);
    });
    this.player.stream.eof.listen((eof: boolean) => {
      if (eof && !this.released) {
        this.observer.onStateChange(PortPlaybackState.COMPLETED);
      }
    });
    this.player.stream.buffering.listen((buffering: boolean) => {
      this.observer.onBufferingChange(
        buffering ? PortBufferingEvent.START : PortBufferingEvent.END,
        0
      );
    });
    this.player.stream.bufferingPercentage.listen((percent: number) => {
      this.observer.onBufferingChange(
        PortBufferingEvent.PERCENT,
        Math.max(0, Math.min(100, percent))
      );
    });
    this.player.stream.buffer.listen((seconds: number) => {
      this.observer.onBufferingChange(
        PortBufferingEvent.CACHED_DURATION,
        Math.max(0, Math.round(seconds * 1000))
      );
    });
    this.player.stream.videoParams.listen((params) => {
      const width: number = params.dw > 0 ? params.dw : params.w;
      const height: number = params.dh > 0 ? params.dh : params.h;
      if (width > 0 && height > 0) {
        this.observer.onVideoSizeChange(width, height);
      }
      this.observer.onVideoInfoChange(new PortVideoInfo(
        params.pixelFormat,
        params.hwPixelFormat,
        params.colormatrix,
        params.colorLevels,
        params.primaries,
        params.gamma,
        params.light
      ));
    });
    this.player.stream.tracks.listen((tracks: Tracks) => {
      this.observer.onTracksChange(this.mapTracks(tracks, this.player.state.track));
    });
    this.player.stream.track.listen((track: Track) => {
      this.observer.onTracksChange(this.mapTracks(this.player.state.tracks, track));
    });
    this.player.stream.error.listen((detail: string) => {
      // The wrapper emits error-level log lines, not structured fatal errors.
      if (!this.released) {
        this.latestErrorLog = detail;
      }
    });
  }

  private mapTracks(tracks: Tracks, selected: Track): PortTrack[] {
    const result: PortTrack[] = [];
    for (const track of tracks.video) {
      result.push(new PortTrack(track.id, PortTrackKind.VIDEO, track.codec, track.lang,
        track.title, selected.video.id === track.id));
    }
    for (const track of tracks.audio) {
      result.push(new PortTrack(track.id, PortTrackKind.AUDIO, track.codec, track.lang,
        track.title, selected.audio.id === track.id));
    }
    for (const track of tracks.subs) {
      result.push(new PortTrack(track.id, PortTrackKind.SUBTITLE, track.codec, track.lang,
        track.title, selected.subs.id === track.id));
    }
    return result;
  }

  private failPrepare(error: PlaybackPortError): void {
    const reject: ((error: PlaybackPortError) => void) | null = this.prepareReject;
    this.prepareResolve = null;
    this.prepareReject = null;
    this.clearPrepareTimer();
    reject?.(error);
  }

  private clearPrepareTimer(): void {
    if (this.prepareTimer >= 0) {
      clearTimeout(this.prepareTimer);
      this.prepareTimer = -1;
    }
  }

  private ensureReady(): void {
    if (this.released || !this.prepared) {
      throw new PlaybackPortError(0, 'MPV backend is not prepared');
    }
  }
}
