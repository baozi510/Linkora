import { AppFailure } from '../errors/AppFailure';
import { PlaybackPortError, PortAudioInterruption, PortAudioOutputChange, PortStreamEnd,
  PortTrack, PortVideoInfo, VideoDisplayMode, PlaybackLoopMode } from './PlaybackPort';

export enum PlaybackStatus {
  IDLE = 'idle',
  PREPARING = 'preparing',
  READY = 'ready',
  PLAYING = 'playing',
  PAUSED = 'paused',
  SEEKING = 'seeking',
  BUFFERING = 'buffering',
  COMPLETED = 'completed',
  STOPPED = 'stopped',
  ERROR = 'error',
  RELEASED = 'released'
}

export class PlaybackSnapshot {
  readonly status: PlaybackStatus;
  readonly position: number;
  readonly duration: number;
  readonly bufferedPercent: number;
  readonly videoWidth: number;
  readonly videoHeight: number;
  readonly failure: AppFailure | null;
  readonly firstFrameRendered: boolean;
  readonly bufferedDuration: number;
  readonly backend: string;
  readonly tracks: PortTrack[];
  readonly videoInfo: PortVideoInfo;
  readonly playbackRate: number;
  readonly volume: number;
  readonly loopMode: PlaybackLoopMode;
  readonly streamEnd: PortStreamEnd | null;
  readonly audioInterruption: PortAudioInterruption | null;
  readonly audioOutput: PortAudioOutputChange | null;
  readonly warning: PlaybackPortError | null;
  readonly warningOperation: string;
  readonly displayMode: VideoDisplayMode | null;
  readonly playlistIndex: number;

  constructor(status: PlaybackStatus, position: number, duration: number, bufferedPercent: number,
    videoWidth: number, videoHeight: number, failure: AppFailure | null, firstFrameRendered: boolean,
    bufferedDuration: number = 0, backend: string = '', tracks: PortTrack[] = [],
    videoInfo: PortVideoInfo = new PortVideoInfo(),
    playbackRate: number = 1, volume: number = 1, loopMode: PlaybackLoopMode = PlaybackLoopMode.SEQUENCE,
    streamEnd: PortStreamEnd | null = null, audioInterruption: PortAudioInterruption | null = null,
    audioOutput: PortAudioOutputChange | null = null, warning: PlaybackPortError | null = null,
    warningOperation: string = '', displayMode: VideoDisplayMode | null = null, playlistIndex: number = -1) {
    this.status = status;
    this.position = position;
    this.duration = duration;
    this.bufferedPercent = bufferedPercent;
    this.videoWidth = videoWidth;
    this.videoHeight = videoHeight;
    this.failure = failure;
    this.firstFrameRendered = firstFrameRendered;
    this.bufferedDuration = bufferedDuration;
    this.backend = backend;
    this.tracks = tracks;
    this.videoInfo = videoInfo;
    this.playbackRate = playbackRate;
    this.volume = volume;
    this.loopMode = loopMode;
    this.streamEnd = streamEnd;
    this.audioInterruption = audioInterruption;
    this.audioOutput = audioOutput;
    this.warning = warning;
    this.warningOperation = warningOperation;
    this.displayMode = displayMode;
    this.playlistIndex = playlistIndex;
  }
}

export type PlaybackObserver = (snapshot: PlaybackSnapshot) => void;
