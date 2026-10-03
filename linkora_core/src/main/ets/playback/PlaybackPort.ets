import { MediaSource } from '../models/MediaSource';

export enum PortPlaybackState {
  IDLE = 'idle',
  INITIALIZED = 'initialized',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  STOPPED = 'stopped',
  RELEASED = 'released',
  ERROR = 'error'
}

export enum PortBufferingEvent {
  START = 'start',
  END = 'end',
  PERCENT = 'percent',
  CACHED_DURATION = 'cached_duration'
}

export class PlaybackPortError extends Error {
  readonly code: number;
  readonly detail: string;

  constructor(code: number, detail: string = '') {
    super('Playback platform operation failed');
    this.code = code;
    this.detail = detail;
  }
}

export type PortStateObserver = (state: PortPlaybackState) => void;
export type PortErrorObserver = (error: PlaybackPortError) => void;
export type PortNumberObserver = (value: number) => void;
export type PortBufferingObserver = (event: PortBufferingEvent, value: number) => void;
export type PortVideoSizeObserver = (width: number, height: number) => void;
export type PortVoidObserver = () => void;

export class PlaybackPortObserver {
  readonly onStateChange: PortStateObserver;
  readonly onError: PortErrorObserver;
  readonly onDurationChange: PortNumberObserver;
  readonly onPositionChange: PortNumberObserver;
  readonly onBufferingChange: PortBufferingObserver;
  readonly onFirstFrame: PortVoidObserver;
  readonly onVideoSizeChange: PortVideoSizeObserver;
  readonly onInterruptionPause: PortVoidObserver;

  constructor(onStateChange: PortStateObserver, onError: PortErrorObserver,
    onDurationChange: PortNumberObserver, onPositionChange: PortNumberObserver,
    onBufferingChange: PortBufferingObserver, onFirstFrame: PortVoidObserver,
    onVideoSizeChange: PortVideoSizeObserver, onInterruptionPause: PortVoidObserver) {
    this.onStateChange = onStateChange;
    this.onError = onError;
    this.onDurationChange = onDurationChange;
    this.onPositionChange = onPositionChange;
    this.onBufferingChange = onBufferingChange;
    this.onFirstFrame = onFirstFrame;
    this.onVideoSizeChange = onVideoSizeChange;
    this.onInterruptionPause = onInterruptionPause;
  }
}

export interface PlaybackPort {
  configure(source: MediaSource, surfaceId: string): void;
  getDuration(): number;
  prepare(): Promise<void>;
  play(): Promise<void>;
  pause(): Promise<void>;
  seek(position: number): void;
  setPlaybackRate(rate: number): void;
  setVolume(volume: number): void;
  release(): Promise<void>;
}

export type PlaybackPortFactory = (observer: PlaybackPortObserver) => Promise<PlaybackPort>;
