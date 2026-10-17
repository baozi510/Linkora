import { MediaSource } from '../models/MediaSource';
import { PlaybackPlaylist } from '../models/PlaybackPlaylist';
import { AppFailure } from '../errors/AppFailure';
import { FailureCatalog } from '../errors/FailureCatalog';
import {
  PlaybackPort,
  PlaybackPortError,
  PlaybackPortFactory,
  PlaybackPortObserver,
  PortBufferingEvent,
  PortPlaybackState,
  PortTrack,
  PortVideoInfo,
  PortTrackKind, PortStreamEnd, PortAudioInterruption, PortAudioOutputChange, VideoDisplayMode, PlaybackLoopMode
} from './PlaybackPort';
import { PlaybackObserver, PlaybackSnapshot, PlaybackStatus } from './PlaybackModels';

export class PlaybackEngine {
  private port: PlaybackPort | null = null;
  private releasePromise: Promise<void> | null = null;
  private observer: PlaybackObserver;
  private portFactory: PlaybackPortFactory;
  private sessionId: number = 0;
  private status: PlaybackStatus = PlaybackStatus.IDLE;
  private statusBeforeBuffering: PlaybackStatus = PlaybackStatus.READY;
  private statusBeforeSeeking: PlaybackStatus = PlaybackStatus.READY;
  private position: number = 0;
  private duration: number = 0;
  private bufferedPercent: number = 0;
  private bufferedDuration: number = 0;
  private videoWidth: number = 0;
  private videoHeight: number = 0;
  private failure: AppFailure | null = null;
  private firstFrameRendered: boolean = false;
  private backend: string = '';
  private tracks: PortTrack[] = [];
  private videoInfo: PortVideoInfo = new PortVideoInfo();
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;
  private source: MediaSource | null = null;
  private playlist: PlaybackPlaylist | null = null;
  private playlistIndex: number = -1;
  private surfaceId: string = '';
  private playbackRate: number = 1;
  private volume: number = 1;
  private loopMode: PlaybackLoopMode = PlaybackLoopMode.SEQUENCE;
  private requestedRate: number = 1;
  private requestedVolume: number = 1;
  private requestedLoopMode: PlaybackLoopMode = PlaybackLoopMode.SEQUENCE;
  private displayMode: VideoDisplayMode | null = null;
  private requestedDisplayMode: VideoDisplayMode = VideoDisplayMode.FIT;
  private streamEnd: PortStreamEnd | null = null;
  private audioInterruption: PortAudioInterruption | null = null;
  private audioOutput: PortAudioOutputChange | null = null;
  private warning: PlaybackPortError | null = null;
  private warningOperation: string = '';

  constructor(observer: PlaybackObserver, portFactory: PlaybackPortFactory) {
    this.observer = observer;
    this.portFactory = portFactory;
  }

  async open(source: MediaSource, surfaceId: string, startPosition: number = 0,
    playlist: PlaybackPlaylist | null = null): Promise<void> {
    const sessionId: number = ++this.sessionId;
    try {
      await this.releaseCurrentPort();
      // A later open() or release() can win while the previous port is closing.
      if (!this.isCurrent(sessionId)) {
        return;
      }
      this.resetSnapshot();
      this.source = source;
      this.playlist = playlist;
      this.surfaceId = surfaceId;
      this.status = PlaybackStatus.PREPARING;
      this.notify();

      const port: PlaybackPort = await this.portFactory(this.createPortObserver(sessionId));
      if (!this.isCurrent(sessionId)) {
        await port.release();
        return;
      }

      this.releasePromise = null;
      this.port = port;
      port.configure(source, surfaceId, playlist);
      if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
        port.setSurfaceSize(this.surfaceWidth, this.surfaceHeight);
      }
      await port.prepare();
      if (!this.isCurrent(sessionId) || this.port !== port) {
        return;
      }
      this.duration = Math.max(this.duration, port.getDuration());
      this.setDisplayMode(this.requestedDisplayMode);
      if (!this.isCurrent(sessionId) || this.port !== port) return;
      if (this.requestedLoopMode !== PlaybackLoopMode.SEQUENCE) this.setLoopMode(this.requestedLoopMode);
      if (!this.isCurrent(sessionId) || this.port !== port) return;
      if (this.requestedRate !== 1) this.setPlaybackRate(this.requestedRate);
      if (!this.isCurrent(sessionId) || this.port !== port) return;
      if (this.requestedVolume !== 1) this.setVolume(this.requestedVolume);
      if (!this.isCurrent(sessionId) || this.port !== port) return;
      if (Number.isFinite(startPosition) && startPosition > 0) {
        // Prepared backends can seek before duration metadata arrives.
        const position: number = Math.round(startPosition);
        port.seek(this.duration > 0 ? Math.min(position, this.duration) : position);
      }
      await port.play();
    } catch (error) {
      if (this.isCurrent(sessionId)) {
        let failure: PlaybackPortError = this.portError(error);
        try {
          await this.releaseCurrentPort();
        } catch (releaseError) {
          failure = this.portError(releaseError);
        }
        // Disposal may yield to a newer open() or release(): the old failure
        // must not overwrite its playback state after that newer session wins.
        if (this.isCurrent(sessionId)) {
          this.fail(failure);
        }
      }
    }
  }

  setSurfaceSize(width: number, height: number): void {
    this.surfaceWidth = Math.max(0, Math.round(width));
    this.surfaceHeight = Math.max(0, Math.round(height));
    if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
      try {
        this.port?.setSurfaceSize(this.surfaceWidth, this.surfaceHeight);
      } catch (_error) {
      }
    }
  }

  async togglePlayback(): Promise<void> {
    if (this.status === PlaybackStatus.STOPPED && this.source !== null) {
      const playlist: PlaybackPlaylist | null = this.playlist === null ? null :
        new PlaybackPlaylist(this.playlist.items, this.playlistIndex >= 0 ? this.playlistIndex :
          this.playlist.startIndex, this.playlist.complete);
      await this.open(this.source, this.surfaceId, 0, playlist);
      return;
    }
    const port: PlaybackPort | null = this.port;
    if (port === null) {
      return;
    }
    const sessionId: number = this.sessionId;

    try {
      if (this.status === PlaybackStatus.PLAYING ||
        (this.status === PlaybackStatus.BUFFERING && this.statusBeforeBuffering === PlaybackStatus.PLAYING)) {
        await port.pause();
      } else if (this.status === PlaybackStatus.READY || this.status === PlaybackStatus.PAUSED ||
        this.status === PlaybackStatus.COMPLETED) {
        if (this.status === PlaybackStatus.COMPLETED) {
          port.seek(0);
          this.position = 0;
        }
        await port.play();
      }
    } catch (error) {
      // An old pause/play may reject after a different session has started.
      if (this.isCurrent(sessionId) && this.port === port) {
        this.failActivePort(this.portError(error));
      }
    }
  }

  seek(position: number): void {
    const port: PlaybackPort | null = this.port;
    if (port === null || this.duration <= 0 || !Number.isFinite(position) ||
      this.status === PlaybackStatus.STOPPED) {
      return;
    }
    const target: number = Math.max(0, Math.min(Math.round(position), this.duration));
    try {
      if (this.status !== PlaybackStatus.SEEKING) {
        this.statusBeforeSeeking = this.status === PlaybackStatus.BUFFERING ?
          this.statusBeforeBuffering : this.status;
      }
      this.status = PlaybackStatus.SEEKING;
      port.seek(target);
      this.position = target;
      this.notify();
    } catch (error) {
      this.failActivePort(this.portError(error));
    }
  }

  async selectPlaylistItem(index: number): Promise<void> {
    const port: PlaybackPort | null = this.port;
    if (port === null || this.playlist === null || !Number.isInteger(index) ||
      index < 0 || index >= this.playlist.items.length) return;
    const sessionId: number = this.sessionId;
    try {
      await port.selectPlaylistItem(index);
    } catch (error) {
      if (this.isCurrent(sessionId) && this.port === port) this.warn('playlist', this.portError(error));
    }
  }

  setPlaybackRate(rate: number): void {
    const port: PlaybackPort | null = this.port;
    if (port === null || !Number.isFinite(rate) || rate < 0.5 || rate > 2) {
      return;
    }
    try {
      port.setPlaybackRate(rate);
      this.requestedRate = rate;
    } catch (error) {
      this.warn('rate', this.portError(error));
    }
  }

  setVolume(volume: number): void {
    const port: PlaybackPort | null = this.port;
    if (port === null || !Number.isFinite(volume)) {
      return;
    }
    try {
      port.setVolume(Math.max(0, Math.min(volume, 1)));
      this.requestedVolume = Math.max(0, Math.min(volume, 1));
    } catch (error) {
      this.warn('volume', this.portError(error));
    }
  }

  setLoopMode(mode: PlaybackLoopMode): void {
    if (this.port === null) return;
    try {
      if (mode !== PlaybackLoopMode.SEQUENCE && mode !== PlaybackLoopMode.SINGLE && mode !== PlaybackLoopMode.LIST) {
        throw new PlaybackPortError(401, 'Invalid loop mode');
      }
      this.port.setLoopMode(mode);
      this.requestedLoopMode = mode;
    } catch (error) {
      this.warn('loop', this.portError(error));
    }
  }

  async stop(): Promise<void> {
    const port: PlaybackPort | null = this.port;
    if (port === null) return;
    const sessionId: number = this.sessionId;
    try {
      await port.stop();
    } catch (error) {
      if (this.isCurrent(sessionId) && this.port === port) this.failActivePort(this.portError(error));
    }
  }

  setDisplayMode(mode: VideoDisplayMode): void {
    const port: PlaybackPort | null = this.port;
    if (port === null) return;
    try {
      port.setDisplayMode(mode);
      this.requestedDisplayMode = mode;
    } catch (error) {
      this.displayMode = null;
      this.warn('display-mode', this.portError(error));
    }
  }

  setAudioDelay(milliseconds: number): number | null {
    const port: PlaybackPort | null = this.port;
    if (port === null) return null;
    const sessionId: number = this.sessionId;
    try {
      if (!Number.isInteger(milliseconds) || Math.abs(milliseconds) > 10000) {
        throw new PlaybackPortError(401, 'Invalid audio delay');
      }
      if (port.setAudioDelay === undefined) throw new PlaybackPortError(801, 'Audio delay is unavailable');
      const actual: number = port.setAudioDelay(milliseconds);
      if (!Number.isFinite(actual) || Math.abs(actual - milliseconds) > 0.5) {
        throw new PlaybackPortError(5400102, 'Audio delay not applied');
      }
      if (!this.isCurrent(sessionId) || this.port !== port) return null;
      if (this.warningOperation === 'audio-delay') {
        this.warning = null; this.warningOperation = ''; this.notify();
      }
      return this.isCurrent(sessionId) && this.port === port ? actual : null;
    } catch (error) {
      if (this.isCurrent(sessionId) && this.port === port) this.warn('audio-delay', this.portError(error));
      return null;
    }
  }

  async selectAudioTrack(id: string): Promise<boolean> {
    const port: PlaybackPort | null = this.port;
    if (port === null) return false;
    const sessionId: number = this.sessionId;
    try {
      if (id !== 'auto' && !this.tracks.some((track: PortTrack) => track.kind === PortTrackKind.AUDIO && track.id === id)) {
        throw new PlaybackPortError(401, 'Unknown audio track');
      }
      await port.selectAudioTrack(id);
      return this.isCurrent(sessionId) && this.port === port;
    } catch (error) {
      if (this.isCurrent(sessionId) && this.port === port) this.warn('audio-track', this.portError(error));
      return false;
    }
  }

  async release(): Promise<void> {
    const sessionId: number = ++this.sessionId;
    try {
      await this.releaseCurrentPort();
    } catch (error) {
      if (this.isCurrent(sessionId)) this.fail(this.portError(error));
      throw error as Error;
    }
    // Do not replace a newer playback snapshot with an old release result.
    if (this.isCurrent(sessionId)) {
      this.status = PlaybackStatus.RELEASED;
      this.notify();
    }
  }

  private createPortObserver(sessionId: number): PlaybackPortObserver {
    return new PlaybackPortObserver(
      (state: PortPlaybackState) => {
        if (this.isCurrent(sessionId)) {
          this.handleStateChange(state);
        }
      },
      (error: PlaybackPortError) => {
        if (this.isCurrent(sessionId)) {
          this.failActivePort(error);
        }
      },
      (duration: number) => {
        if (this.isCurrent(sessionId)) {
          this.duration = Math.max(0, duration);
          this.notify();
        }
      },
      (position: number) => {
        if (this.isCurrent(sessionId)) {
          this.position = Math.max(0, position);
          this.notify();
        }
      },
      (event: PortBufferingEvent, value: number) => {
        if (this.isCurrent(sessionId)) {
          this.handleBufferingChange(event, value);
        }
      },
      () => {
        if (this.isCurrent(sessionId)) {
          this.firstFrameRendered = true;
          this.notify();
        }
      },
      (width: number, height: number) => {
        if (this.isCurrent(sessionId)) {
          this.videoWidth = Math.max(0, width);
          this.videoHeight = Math.max(0, height);
          this.notify();
        }
      },
      () => {
        if (this.isCurrent(sessionId)) {
          this.pauseForInterruption();
        }
      },
      (position: number) => {
        if (this.isCurrent(sessionId)) {
          this.position = Math.max(0, position);
          if (this.status === PlaybackStatus.SEEKING) {
            this.status = this.statusBeforeSeeking;
          }
          this.notify();
        }
      },
      (tracks: PortTrack[]) => {
        if (this.isCurrent(sessionId)) {
          this.tracks = tracks.slice();
          this.notify();
        }
      },
      (info: PortVideoInfo) => {
        if (this.isCurrent(sessionId)) {
          this.videoInfo = info;
          this.notify();
        }
      },
      (backend: string) => {
        if (this.isCurrent(sessionId)) {
          this.backend = backend;
          this.notify();
        }
      },
      (rate: number) => {
        if (this.isCurrent(sessionId) && Number.isFinite(rate) && rate > 0) {
          this.playbackRate = rate;
          this.notify();
        }
      },
      (volume: number) => {
        if (this.isCurrent(sessionId) && Number.isFinite(volume)) {
          this.volume = Math.max(0, Math.min(volume, 1));
          this.notify();
        }
      },
      (mode: PlaybackLoopMode) => {
        if (this.isCurrent(sessionId)) { this.loopMode = mode; this.notify(); }
      },
      (end: PortStreamEnd) => {
        if (this.isCurrent(sessionId)) { this.streamEnd = end; this.notify(); }
      },
      (event: PortAudioInterruption) => {
        if (this.isCurrent(sessionId)) { this.audioInterruption = event; this.notify(); }
      },
      (event: PortAudioOutputChange) => {
        if (this.isCurrent(sessionId)) { this.audioOutput = event; this.notify(); }
      },
      (operation: string, error: PlaybackPortError) => {
        if (this.isCurrent(sessionId)) {
          if (operation === 'display-mode') this.displayMode = null;
          this.warn(operation, error);
        }
      },
      (mode: VideoDisplayMode) => {
        if (this.isCurrent(sessionId)) {
          this.displayMode = mode;
          if (this.warningOperation === 'display-mode') {
            this.warning = null;
            this.warningOperation = '';
          }
          this.notify();
        }
      },
      (index: number) => {
        if (!this.isCurrent(sessionId) || this.playlist === null || !Number.isInteger(index) ||
          index < 0 || index >= this.playlist.items.length || index === this.playlistIndex) return;
        this.playlistIndex = index;
        this.source = this.playlist.items[index].source;
        this.position = 0;
        this.duration = 0;
        this.bufferedPercent = 0;
        this.bufferedDuration = 0;
        this.firstFrameRendered = false;
        this.videoWidth = 0;
        this.videoHeight = 0;
        this.tracks = [];
        this.videoInfo = new PortVideoInfo();
        this.streamEnd = null;
        this.failure = null;
        this.status = PlaybackStatus.PREPARING;
        this.notify();
      }
    );
  }

  private pauseForInterruption(): void {
    const port: PlaybackPort | null = this.port;
    if (port === null || (this.status !== PlaybackStatus.PLAYING &&
      !(this.status === PlaybackStatus.BUFFERING && this.statusBeforeBuffering === PlaybackStatus.PLAYING))) {
      return;
    }
    const sessionId: number = this.sessionId;
    this.status = PlaybackStatus.PAUSED;
    this.notify();
    port.pause().catch((error: PlaybackPortError) => {
      // The interrupted port may have been replaced while pause was pending.
      if (this.isCurrent(sessionId) && this.port === port) {
        this.failActivePort(error);
      }
    });
  }

  private handleStateChange(state: PortPlaybackState): void {
    if (state === PortPlaybackState.INITIALIZED) {
      this.status = PlaybackStatus.PREPARING;
    } else if (state === PortPlaybackState.PREPARED) {
      this.status = PlaybackStatus.READY;
    } else if (state === PortPlaybackState.PLAYING) {
      if (this.status !== PlaybackStatus.SEEKING) {
        this.status = PlaybackStatus.PLAYING;
      } else {
        if (this.statusBeforeSeeking === PlaybackStatus.BUFFERING) {
          this.statusBeforeBuffering = PlaybackStatus.PLAYING;
        } else {
          this.statusBeforeSeeking = PlaybackStatus.PLAYING;
        }
      }
    } else if (state === PortPlaybackState.PAUSED) {
      if (this.status !== PlaybackStatus.SEEKING) {
        this.status = PlaybackStatus.PAUSED;
      } else {
        if (this.statusBeforeSeeking === PlaybackStatus.BUFFERING) {
          this.statusBeforeBuffering = PlaybackStatus.PAUSED;
        } else {
          this.statusBeforeSeeking = PlaybackStatus.PAUSED;
        }
      }
    } else if (state === PortPlaybackState.COMPLETED) {
      this.status = PlaybackStatus.COMPLETED;
      this.position = this.duration;
    } else if (state === PortPlaybackState.STOPPED) {
      this.status = PlaybackStatus.STOPPED;
    } else if (state === PortPlaybackState.ERROR) {
      this.status = PlaybackStatus.ERROR;
      if (this.failure === null) {
        this.failure = FailureCatalog.fromPlaybackError(0);
      }
    } else if (state === PortPlaybackState.RELEASED) {
      this.status = PlaybackStatus.RELEASED;
    }
    this.notify();
  }

  private handleBufferingChange(event: PortBufferingEvent, value: number): void {
    if (event === PortBufferingEvent.START && this.status !== PlaybackStatus.BUFFERING) {
      if (this.status === PlaybackStatus.SEEKING) {
        if (this.statusBeforeSeeking !== PlaybackStatus.BUFFERING) {
          this.statusBeforeBuffering = this.statusBeforeSeeking;
          this.statusBeforeSeeking = PlaybackStatus.BUFFERING;
        }
      } else {
        this.statusBeforeBuffering = this.status;
        this.status = PlaybackStatus.BUFFERING;
      }
    } else if (event === PortBufferingEvent.END) {
      if (this.status === PlaybackStatus.BUFFERING) {
        this.status = this.statusBeforeBuffering;
      } else if (this.status === PlaybackStatus.SEEKING && this.statusBeforeSeeking === PlaybackStatus.BUFFERING) {
        this.statusBeforeSeeking = this.statusBeforeBuffering;
      }
    } else if (event === PortBufferingEvent.PERCENT) {
      this.bufferedPercent = Math.max(0, Math.min(value, 100));
    } else if (event === PortBufferingEvent.CACHED_DURATION) {
      this.bufferedDuration = Math.max(0, value);
    }
    this.notify();
  }

  private fail(error: PlaybackPortError): void {
    this.failWith(error);
  }

  private warn(operation: string, error: PlaybackPortError): void {
    this.warningOperation = operation;
    this.warning = error;
    this.notify();
  }

  private failActivePort(error: PlaybackPortError): void {
    ++this.sessionId;
    // Publish disposal ownership before an error observer can retry open().
    const release: Promise<void> = this.releaseCurrentPort();
    this.failWith(error);
    release.catch((_releaseError: PlaybackPortError) => {});
  }

  private failWith(error: PlaybackPortError): void {
    this.status = PlaybackStatus.ERROR;
    this.failure = FailureCatalog.fromPlaybackError(error.code, error.detail);
    this.notify();
  }

  private portError(error: Object): PlaybackPortError {
    if (error instanceof PlaybackPortError) {
      return error;
    }
    return new PlaybackPortError(0, String(error));
  }

  private isCurrent(sessionId: number): boolean {
    return sessionId === this.sessionId;
  }

  private releaseCurrentPort(): Promise<void> {
    if (this.releasePromise !== null) return this.releasePromise;
    const port: PlaybackPort | null = this.port;
    this.port = null;
    if (port === null) {
      return Promise.resolve();
    }
    // Keep the settled rejection too: a failed native close cannot become success.
    this.releasePromise = Promise.resolve().then(() => port.release())
      .catch((error: PlaybackPortError) => { throw this.portError(error); });
    return this.releasePromise;
  }

  private resetSnapshot(): void {
    this.playlistIndex = -1;
    this.status = PlaybackStatus.IDLE;
    this.statusBeforeBuffering = PlaybackStatus.READY;
    this.statusBeforeSeeking = PlaybackStatus.READY;
    this.position = 0;
    this.duration = 0;
    this.bufferedPercent = 0;
    this.bufferedDuration = 0;
    this.videoWidth = 0;
    this.videoHeight = 0;
    this.failure = null;
    this.firstFrameRendered = false;
    this.backend = '';
    this.tracks = [];
    this.videoInfo = new PortVideoInfo();
    this.playbackRate = 1;
    this.volume = 1;
    this.loopMode = PlaybackLoopMode.SEQUENCE;
    this.streamEnd = null;
    this.audioInterruption = null;
    this.audioOutput = null;
    this.warning = null;
    this.warningOperation = '';
    this.displayMode = null;
  }

  private notify(): void {
    this.observer(new PlaybackSnapshot(
      this.status,
      this.position,
      this.duration,
      this.bufferedPercent,
      this.videoWidth,
      this.videoHeight,
      this.failure,
      this.firstFrameRendered,
      this.bufferedDuration,
      this.backend,
      this.tracks,
      this.videoInfo,
      this.playbackRate, this.volume, this.loopMode, this.streamEnd,
      this.audioInterruption, this.audioOutput, this.warning, this.warningOperation, this.displayMode, this.playlistIndex
    ));
  }
}
