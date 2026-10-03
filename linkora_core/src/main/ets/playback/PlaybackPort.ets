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

export enum PortTrackKind {
  VIDEO = 'video',
  AUDIO = 'audio',
  SUBTITLE = 'subtitle'
}

export class PortTrack {
  readonly id: string;
  readonly kind: PortTrackKind;
  readonly codec: string;
  readonly language: string;
  readonly title: string;
  readonly selected: boolean;

  constructor(id: string, kind: PortTrackKind, codec: string = '',
    language: string = '', title: string = '', selected: boolean = false) {
    this.id = id;
    this.kind = kind;
    this.codec = codec;
    this.language = language;
    this.title = title;
    this.selected = selected;
  }
}

export class PortVideoInfo {
  readonly pixelFormat: string;
  readonly hardwarePixelFormat: string;
  readonly colorMatrix: string;
  readonly colorLevels: string;
  readonly colorPrimaries: string;
  readonly transfer: string;
  readonly light: string;

  constructor(pixelFormat: string = '', hardwarePixelFormat: string = '',
    colorMatrix: string = '', colorLevels: string = '', colorPrimaries: string = '',
    transfer: string = '', light: string = '') {
    this.pixelFormat = pixelFormat;
    this.hardwarePixelFormat = hardwarePixelFormat;
    this.colorMatrix = colorMatrix;
    this.colorLevels = colorLevels;
    this.colorPrimaries = colorPrimaries;
    this.transfer = transfer;
    this.light = light;
  }

  hdrLabel(): string {
    const transfer: string = this.transfer.toLowerCase();
    if (transfer.includes('pq') || transfer.includes('2084')) {
      return 'HDR10';
    }
    if (transfer.includes('hlg')) {
      return 'HLG';
    }
    return '';
  }
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
export type PortStringObserver = (value: string) => void;
export type PortBufferingObserver = (event: PortBufferingEvent, value: number) => void;
export type PortVideoSizeObserver = (width: number, height: number) => void;
export type PortTrackObserver = (tracks: PortTrack[]) => void;
export type PortVideoInfoObserver = (info: PortVideoInfo) => void;
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
  readonly onSeekComplete: PortNumberObserver;
  readonly onTracksChange: PortTrackObserver;
  readonly onVideoInfoChange: PortVideoInfoObserver;
  readonly onBackendChange: PortStringObserver;

  constructor(onStateChange: PortStateObserver, onError: PortErrorObserver,
    onDurationChange: PortNumberObserver, onPositionChange: PortNumberObserver,
    onBufferingChange: PortBufferingObserver, onFirstFrame: PortVoidObserver,
    onVideoSizeChange: PortVideoSizeObserver, onInterruptionPause: PortVoidObserver,
    onSeekComplete: PortNumberObserver = () => {},
    onTracksChange: PortTrackObserver = () => {},
    onVideoInfoChange: PortVideoInfoObserver = () => {},
    onBackendChange: PortStringObserver = () => {}) {
    this.onStateChange = onStateChange;
    this.onError = onError;
    this.onDurationChange = onDurationChange;
    this.onPositionChange = onPositionChange;
    this.onBufferingChange = onBufferingChange;
    this.onFirstFrame = onFirstFrame;
    this.onVideoSizeChange = onVideoSizeChange;
    this.onInterruptionPause = onInterruptionPause;
    this.onSeekComplete = onSeekComplete;
    this.onTracksChange = onTracksChange;
    this.onVideoInfoChange = onVideoInfoChange;
    this.onBackendChange = onBackendChange;
  }
}

export interface PlaybackPort {
  configure(source: MediaSource, surfaceId: string): void;
  setSurfaceSize(width: number, height: number): void;
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
