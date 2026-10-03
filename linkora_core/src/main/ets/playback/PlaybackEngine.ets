import { MediaSource } from '../models/MediaSource';
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
  PortVideoInfo
} from './PlaybackPort';
import { PlaybackObserver, PlaybackSnapshot, PlaybackStatus } from './PlaybackModels';

export class PlaybackEngine {
  private port: PlaybackPort | null = null;
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

  constructor(observer: PlaybackObserver, portFactory: PlaybackPortFactory) {
    this.observer = observer;
    this.portFactory = portFactory;
  }

  async open(source: MediaSource, surfaceId: string, startPosition: number = 0): Promise<void> {
    const sessionId: number = ++this.sessionId;
    await this.releaseCurrentPort();
    this.resetSnapshot();
    this.status = PlaybackStatus.PREPARING;
    this.notify();

    try {
      const port: PlaybackPort = await this.portFactory(this.createPortObserver(sessionId));
      if (!this.isCurrent(sessionId)) {
        await port.release();
        return;
      }

      this.port = port;
      port.configure(source, surfaceId);
      if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
        port.setSurfaceSize(this.surfaceWidth, this.surfaceHeight);
      }
      await port.prepare();
      if (!this.isCurrent(sessionId) || this.port !== port) {
        return;
      }
      this.duration = Math.max(this.duration, port.getDuration());
      if (startPosition > 0 && this.duration > 0) {
        port.seek(Math.min(Math.round(startPosition), this.duration));
      }
      await port.play();
    } catch (error) {
      if (this.isCurrent(sessionId)) {
        await this.releaseCurrentPort();
        this.fail(this.portError(error));
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
    const port: PlaybackPort | null = this.port;
    if (port === null) {
      return;
    }

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
      this.failActivePort(this.portError(error));
    }
  }

  seek(position: number): void {
    const port: PlaybackPort | null = this.port;
    if (port === null || this.duration <= 0) {
      return;
    }
    const target: number = Math.max(0, Math.min(Math.round(position), this.duration));
    try {
      this.statusBeforeSeeking = this.status === PlaybackStatus.BUFFERING ?
        this.statusBeforeBuffering : this.status;
      this.status = PlaybackStatus.SEEKING;
      port.seek(target);
      this.position = target;
      this.notify();
    } catch (error) {
      this.failActivePort(this.portError(error));
    }
  }

  setPlaybackRate(rate: number): void {
    const port: PlaybackPort | null = this.port;
    if (port === null) {
      return;
    }
    try {
      port.setPlaybackRate(rate);
    } catch (error) {
      this.failActivePort(this.portError(error));
    }
  }

  setVolume(volume: number): void {
    const port: PlaybackPort | null = this.port;
    if (port === null) {
      return;
    }
    try {
      port.setVolume(Math.max(0, Math.min(volume, 1)));
    } catch (error) {
      this.failActivePort(this.portError(error));
    }
  }

  async release(): Promise<void> {
    ++this.sessionId;
    await this.releaseCurrentPort();
    this.status = PlaybackStatus.RELEASED;
    this.notify();
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
      }
    );
  }

  private pauseForInterruption(): void {
    const port: PlaybackPort | null = this.port;
    if (port === null || (this.status !== PlaybackStatus.PLAYING &&
      !(this.status === PlaybackStatus.BUFFERING && this.statusBeforeBuffering === PlaybackStatus.PLAYING))) {
      return;
    }
    this.status = PlaybackStatus.PAUSED;
    this.notify();
    port.pause().catch((error: PlaybackPortError) => {
      this.failActivePort(error);
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
        this.statusBeforeSeeking = PlaybackStatus.PLAYING;
      }
    } else if (state === PortPlaybackState.PAUSED) {
      if (this.status !== PlaybackStatus.SEEKING) {
        this.status = PlaybackStatus.PAUSED;
      } else {
        this.statusBeforeSeeking = PlaybackStatus.PAUSED;
      }
    } else if (state === PortPlaybackState.COMPLETED) {
      this.status = PlaybackStatus.COMPLETED;
      this.position = this.duration;
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
        this.statusBeforeSeeking = PlaybackStatus.BUFFERING;
      } else {
        this.statusBeforeBuffering = this.status;
        this.status = PlaybackStatus.BUFFERING;
      }
    } else if (event === PortBufferingEvent.END && this.status === PlaybackStatus.BUFFERING) {
      this.status = this.statusBeforeBuffering;
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

  private failActivePort(error: PlaybackPortError): void {
    ++this.sessionId;
    const port: PlaybackPort | null = this.port;
    this.port = null;
    this.failWith(error);
    if (port !== null) {
      port.release().catch(() => {});
    }
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

  private async releaseCurrentPort(): Promise<void> {
    const port: PlaybackPort | null = this.port;
    this.port = null;
    if (port === null) {
      return;
    }
    try {
      await port.release();
    } catch (_error) {
    }
  }

  private resetSnapshot(): void {
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
      this.videoInfo
    ));
  }
}
