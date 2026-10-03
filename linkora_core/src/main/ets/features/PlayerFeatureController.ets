import { PlaybackBookmarkRepository } from '../contracts/FeaturePorts';
import { MediaSource } from '../models/MediaSource';
import { PlaybackBookmark } from '../models/PlaybackBookmark';
import { AppSettings } from '../models/AppSettings';
import { PlaybackEngine } from '../playback/PlaybackEngine';
import { PlaybackObserver, PlaybackSnapshot, PlaybackStatus } from '../playback/PlaybackModels';
import { NetworkAccessPolicyPort } from '../contracts/NetworkPorts';
import { AppFailure } from '../errors/AppFailure';
import { MediaSourceKind } from '../models/MediaSource';

export type PlaybackEngineFactory = (observer: PlaybackObserver) => PlaybackEngine;

export class PlayerFeatureState {
  readonly playback: PlaybackSnapshot;
  readonly sliderPosition: number;
  readonly seeking: boolean;
  readonly playbackRate: number;
  readonly volume: number;
  readonly keepScreenOn: boolean;

  constructor(playback: PlaybackSnapshot, sliderPosition: number = 0, seeking: boolean = false,
    playbackRate: number = 1, volume: number = 1, keepScreenOn: boolean = false) {
    this.playback = playback;
    this.sliderPosition = sliderPosition;
    this.seeking = seeking;
    this.playbackRate = playbackRate;
    this.volume = volume;
    this.keepScreenOn = keepScreenOn;
  }
}

export type PlayerFeatureObserver = (state: PlayerFeatureState) => void;

export class PlayerFeatureController {
  private source: MediaSource;
  private bookmarkRepository: PlaybackBookmarkRepository;
  private settings: AppSettings;
  private accessPolicy: NetworkAccessPolicyPort | null;
  private observer: PlayerFeatureObserver;
  private engine: PlaybackEngine;
  private state: PlayerFeatureState;
  private active: boolean = true;
  private surfaceId: string = '';
  private requestId: number = 0;
  private lastSavedPosition: number = 0;

  constructor(source: MediaSource, engineFactory: PlaybackEngineFactory,
    bookmarkRepository: PlaybackBookmarkRepository, settings: AppSettings,
    observer: PlayerFeatureObserver, accessPolicy: NetworkAccessPolicyPort | null = null) {
    this.source = source;
    this.bookmarkRepository = bookmarkRepository;
    this.settings = settings;
    this.accessPolicy = accessPolicy;
    this.observer = observer;
    const initial: PlaybackSnapshot = new PlaybackSnapshot(
      PlaybackStatus.IDLE, 0, 0, 0, 0, 0, null, false
    );
    this.state = new PlayerFeatureState(initial);
    this.engine = engineFactory((snapshot: PlaybackSnapshot) => {
      this.applyPlayback(snapshot);
    });
  }

  attachSurface(surfaceId: string): void {
    if (!this.active || surfaceId.length === 0) {
      return;
    }
    this.surfaceId = surfaceId;
    const requestId: number = ++this.requestId;
    this.open(requestId).catch(() => {});
  }

  detachSurface(): void {
    ++this.requestId;
    this.surfaceId = '';
    this.engine.release().catch(() => {});
  }

  togglePlayback(): void {
    this.engine.togglePlayback().catch(() => {});
  }

  beginSeek(position: number): void {
    this.update(this.state.playback, position, true, this.state.playbackRate,
      this.state.volume, this.state.keepScreenOn);
  }

  moveSeek(position: number): void {
    this.update(this.state.playback, position, true, this.state.playbackRate,
      this.state.volume, this.state.keepScreenOn);
  }

  commitSeek(position: number): void {
    this.engine.seek(position);
    this.update(this.state.playback, position, false, this.state.playbackRate,
      this.state.volume, this.state.keepScreenOn);
  }

  cancelSeek(): void {
    this.update(this.state.playback, this.state.playback.position, false, this.state.playbackRate,
      this.state.volume, this.state.keepScreenOn);
  }

  seekBy(offset: number): void {
    const duration: number = this.state.playback.duration;
    if (duration <= 0) {
      return;
    }
    const position: number = Math.max(0, Math.min(this.state.playback.position + offset, duration));
    this.engine.seek(position);
    this.update(this.state.playback, position, false, this.state.playbackRate,
      this.state.volume, this.state.keepScreenOn);
  }

  cyclePlaybackRate(): void {
    let rate: number = 1;
    if (this.state.playbackRate === 1) {
      rate = 1.25;
    } else if (this.state.playbackRate === 1.25) {
      rate = 1.5;
    } else if (this.state.playbackRate === 1.5) {
      rate = 2;
    }
    this.setPlaybackRate(rate);
  }

  setPlaybackRate(rate: number): void {
    const normalized: number = Math.max(0.5, Math.min(rate, 2));
    this.engine.setPlaybackRate(normalized);
    this.update(this.state.playback, this.state.sliderPosition, this.state.seeking,
      normalized, this.state.volume, this.state.keepScreenOn);
  }

  setVolume(volume: number): void {
    const normalized: number = Math.max(0, Math.min(volume, 1));
    this.engine.setVolume(normalized);
    this.update(this.state.playback, this.state.sliderPosition, this.state.seeking,
      this.state.playbackRate, normalized, this.state.keepScreenOn);
  }

  handleBackground(): void {
    this.persistBookmark(this.state.playback, true);
    if (this.state.playback.status === PlaybackStatus.PLAYING ||
      this.state.playback.status === PlaybackStatus.BUFFERING) {
      this.togglePlayback();
    }
  }

  retry(): void {
    if (this.surfaceId.length > 0) {
      const requestId: number = ++this.requestId;
      this.open(requestId).catch(() => {});
    }
  }

  currentState(): PlayerFeatureState {
    return this.state;
  }

  stop(): void {
    if (!this.active) {
      return;
    }
    this.active = false;
    ++this.requestId;
    this.persistBookmark(this.state.playback, true);
    this.engine.release().catch(() => {});
  }

  private async open(requestId: number): Promise<void> {
    if (this.source.kind === MediaSourceKind.NETWORK_LINK && this.accessPolicy !== null) {
      const failure: AppFailure | null = await this.accessPolicy.check();
      if (!this.active || requestId !== this.requestId) {
        return;
      }
      if (failure !== null) {
        const playback: PlaybackSnapshot = new PlaybackSnapshot(
          PlaybackStatus.ERROR, 0, 0, 0, 0, 0, failure, false
        );
        this.update(playback, 0, false, this.state.playbackRate, this.state.volume, false);
        return;
      }
    }
    const bookmark: PlaybackBookmark | null = this.settings.rememberPlaybackPosition ?
      await this.bookmarkRepository.load(this.source) : null;
    if (!this.active || requestId !== this.requestId || this.surfaceId.length === 0) {
      return;
    }
    const resumePosition: number = bookmark === null ? 0 : bookmark.resumePosition();
    this.lastSavedPosition = resumePosition;
    await this.engine.open(this.source, this.surfaceId, resumePosition);
  }

  private applyPlayback(playback: PlaybackSnapshot): void {
    if (!this.active) {
      return;
    }
    if (playback.status === PlaybackStatus.COMPLETED) {
      this.bookmarkRepository.clear(this.source).catch(() => {});
      this.lastSavedPosition = 0;
    } else {
      this.persistBookmark(playback, false);
    }
    const sliderPosition: number = this.state.seeking ? this.state.sliderPosition : playback.position;
    const keepScreenOn: boolean = this.settings.keepScreenOnDuringPlayback &&
      (playback.status === PlaybackStatus.PLAYING || playback.status === PlaybackStatus.BUFFERING);
    this.update(playback, sliderPosition, this.state.seeking, this.state.playbackRate,
      this.state.volume, keepScreenOn);
  }

  private persistBookmark(playback: PlaybackSnapshot, force: boolean): void {
    if (!this.settings.rememberPlaybackPosition) {
      return;
    }
    if (playback.duration <= 0) {
      return;
    }
    if (!force && Math.abs(playback.position - this.lastSavedPosition) < 10000) {
      return;
    }
    this.lastSavedPosition = playback.position;
    this.bookmarkRepository.save(this.source,
      new PlaybackBookmark(playback.position, playback.duration, Date.now())).catch(() => {});
  }

  private update(playback: PlaybackSnapshot, sliderPosition: number, seeking: boolean,
    playbackRate: number, volume: number, keepScreenOn: boolean): void {
    this.state = new PlayerFeatureState(playback, sliderPosition, seeking,
      playbackRate, volume, keepScreenOn);
    if (this.active) {
      this.observer(this.state);
    }
  }
}
