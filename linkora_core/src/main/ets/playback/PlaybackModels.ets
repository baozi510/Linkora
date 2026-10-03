import { AppFailure } from '../errors/AppFailure';

export enum PlaybackStatus {
  IDLE = 'idle',
  PREPARING = 'preparing',
  READY = 'ready',
  PLAYING = 'playing',
  PAUSED = 'paused',
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

  constructor(status: PlaybackStatus, position: number, duration: number, bufferedPercent: number,
    videoWidth: number, videoHeight: number, failure: AppFailure | null, firstFrameRendered: boolean) {
    this.status = status;
    this.position = position;
    this.duration = duration;
    this.bufferedPercent = bufferedPercent;
    this.videoWidth = videoWidth;
    this.videoHeight = videoHeight;
    this.failure = failure;
    this.firstFrameRendered = firstFrameRendered;
  }
}

export type PlaybackObserver = (snapshot: PlaybackSnapshot) => void;
