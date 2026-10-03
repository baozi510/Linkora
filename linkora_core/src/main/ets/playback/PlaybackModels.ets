import { AppFailure } from '../errors/AppFailure';
import { PortTrack, PortVideoInfo } from './PlaybackPort';

export enum PlaybackStatus {
  IDLE = 'idle',
  PREPARING = 'preparing',
  READY = 'ready',
  PLAYING = 'playing',
  PAUSED = 'paused',
  SEEKING = 'seeking',
  BUFFERING = 'buffering',
  COMPLETED = 'completed',
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

  constructor(status: PlaybackStatus, position: number, duration: number, bufferedPercent: number,
    videoWidth: number, videoHeight: number, failure: AppFailure | null, firstFrameRendered: boolean,
    bufferedDuration: number = 0, backend: string = '', tracks: PortTrack[] = [],
    videoInfo: PortVideoInfo = new PortVideoInfo()) {
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
  }
}

export type PlaybackObserver = (snapshot: PlaybackSnapshot) => void;
