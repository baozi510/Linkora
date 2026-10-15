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

export enum VideoDisplayMode {
  FIT = 'fit',
  CROP = 'crop',
  STRETCH = 'stretch'
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

export enum PortStreamEndReason {
  EOF = 'eof',
  STOP = 'stop',
  UNKNOWN = 'unknown'
}

export class PortStreamEnd {
  readonly reason: PortStreamEndReason;
  readonly looping: boolean;
  readonly detail: string;
  constructor(reason: PortStreamEndReason, looping: boolean = false, detail: string = '') {
    this.reason = reason;
    this.looping = looping;
    this.detail = detail;
  }
}

export enum PortInterruptionHint {
  UNKNOWN = 'unknown',
  RESUME = 'resume',
  PAUSE = 'pause',
  STOP = 'stop',
  DUCK = 'duck',
  UNDUCK = 'unduck'
}

export class PortAudioInterruption {
  readonly hint: PortInterruptionHint;
  readonly forced: boolean;
  readonly eventType: number;
  constructor(hint: PortInterruptionHint, forced: boolean, eventType: number) {
    this.hint = hint;
    this.forced = forced;
    this.eventType = eventType;
  }
}

export class PortAudioOutputChange {
  readonly deviceTypes: number[];
  readonly reason: number;
  constructor(deviceTypes: number[], reason: number) {
    this.deviceTypes = deviceTypes.slice();
    this.reason = reason;
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
export type PortBooleanObserver = (value: boolean) => void;
export type PortStreamEndObserver = (event: PortStreamEnd) => void;
export type PortInterruptionObserver = (event: PortAudioInterruption) => void;
export type PortAudioOutputObserver = (event: PortAudioOutputChange) => void;
export type PortWarningObserver = (operation: string, error: PlaybackPortError) => void;
export type PortDisplayModeObserver = (mode: VideoDisplayMode) => void;

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
  readonly onPlaybackRateChange: PortNumberObserver;
  readonly onVolumeChange: PortNumberObserver;
  readonly onLoopChange: PortBooleanObserver;
  readonly onStreamEnd: PortStreamEndObserver;
  readonly onAudioInterruption: PortInterruptionObserver;
  readonly onAudioOutputChange: PortAudioOutputObserver;
  readonly onWarning: PortWarningObserver;
  readonly onDisplayModeChange: PortDisplayModeObserver;

  constructor(onStateChange: PortStateObserver, onError: PortErrorObserver,
    onDurationChange: PortNumberObserver, onPositionChange: PortNumberObserver,
    onBufferingChange: PortBufferingObserver, onFirstFrame: PortVoidObserver,
    onVideoSizeChange: PortVideoSizeObserver, onInterruptionPause: PortVoidObserver,
    onSeekComplete: PortNumberObserver = () => {},
    onTracksChange: PortTrackObserver = () => {},
    onVideoInfoChange: PortVideoInfoObserver = () => {},
    onBackendChange: PortStringObserver = () => {},
    onPlaybackRateChange: PortNumberObserver = () => {},
    onVolumeChange: PortNumberObserver = () => {},
    onLoopChange: PortBooleanObserver = () => {},
    onStreamEnd: PortStreamEndObserver = () => {},
    onAudioInterruption: PortInterruptionObserver = () => {},
    onAudioOutputChange: PortAudioOutputObserver = () => {},
    onWarning: PortWarningObserver = () => {},
    onDisplayModeChange: PortDisplayModeObserver = () => {}) {
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
    this.onPlaybackRateChange = onPlaybackRateChange;
    this.onVolumeChange = onVolumeChange;
    this.onLoopChange = onLoopChange;
    this.onStreamEnd = onStreamEnd;
    this.onAudioInterruption = onAudioInterruption;
    this.onAudioOutputChange = onAudioOutputChange;
    this.onWarning = onWarning;
    this.onDisplayModeChange = onDisplayModeChange;
  }
}

export interface PlaybackPort {
  configure(source: MediaSource, surfaceId: string): void;
  setSurfaceSize(width: number, height: number): void;
  getDuration(): number;
  prepare(): Promise<void>;
  play(): Promise<void>;
  pause(): Promise<void>;
  stop(): Promise<void>;
  seek(position: number): void;
  setPlaybackRate(rate: number): void;
  setVolume(volume: number): void;
  setLoop(loop: boolean): void;
  setDisplayMode(mode: VideoDisplayMode): void;
  selectAudioTrack(id: string): Promise<void>;
  release(): Promise<void>;
}

export type PlaybackPortFactory = (observer: PlaybackPortObserver) => Promise<PlaybackPort>;
