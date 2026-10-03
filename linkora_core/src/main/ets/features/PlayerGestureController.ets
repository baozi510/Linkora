export enum PlayerGestureMode {
  IDLE = 'idle',
  SEEK = 'seek',
  BRIGHTNESS = 'brightness',
  VOLUME = 'volume',
  FAST_PLAYBACK = 'fast_playback'
}

export enum PlayerTapZone {
  LEFT = 'left',
  CENTER = 'center',
  RIGHT = 'right'
}

export class PlayerGestureState {
  readonly mode: PlayerGestureMode;
  readonly visible: boolean;
  readonly value: number;
  readonly position: number;
  readonly duration: number;

  constructor(mode: PlayerGestureMode = PlayerGestureMode.IDLE, visible: boolean = false,
    value: number = 0, position: number = 0, duration: number = 0) {
    this.mode = mode;
    this.visible = visible;
    this.value = value;
    this.position = position;
    this.duration = duration;
  }
}

export class PlayerGestureCallbacks {
  onToggleControls: () => void;
  onTogglePlayback: () => void;
  onSeekPreview: (position: number, begin: boolean) => void;
  onSeekCommit: (position: number) => void;
  onSeekCancel: () => void;
  onSeekBy: (offset: number) => void;
  onVolumeChange: (value: number) => void;
  onBrightnessChange: (value: number) => void;
  onTemporaryRate: (enabled: boolean) => void;

  constructor(onToggleControls: () => void = () => {}, onTogglePlayback: () => void = () => {},
    onSeekPreview: (position: number, begin: boolean) => void = () => {},
    onSeekCommit: (position: number) => void = () => {}, onSeekCancel: () => void = () => {},
    onSeekBy: (offset: number) => void = () => {}, onVolumeChange: (value: number) => void = () => {},
    onBrightnessChange: (value: number) => void = () => {},
    onTemporaryRate: (enabled: boolean) => void = () => {}) {
    this.onToggleControls = onToggleControls;
    this.onTogglePlayback = onTogglePlayback;
    this.onSeekPreview = onSeekPreview;
    this.onSeekCommit = onSeekCommit;
    this.onSeekCancel = onSeekCancel;
    this.onSeekBy = onSeekBy;
    this.onVolumeChange = onVolumeChange;
    this.onBrightnessChange = onBrightnessChange;
    this.onTemporaryRate = onTemporaryRate;
  }
}

export class PlayerGestureConfig {
  readonly directionRatio: number;
  readonly edgeInset: number;
  readonly doubleTapSeekOffset: number;
  readonly minimumBrightness: number;

  constructor(directionRatio: number = 1.2, edgeInset: number = 24,
    doubleTapSeekOffset: number = 10000, minimumBrightness: number = 0.05) {
    this.directionRatio = directionRatio;
    this.edgeInset = edgeInset;
    this.doubleTapSeekOffset = doubleTapSeekOffset;
    this.minimumBrightness = minimumBrightness;
  }
}

export type PlayerGestureObserver = (state: PlayerGestureState) => void;

export class PlayerGestureController {
  private callbacks: PlayerGestureCallbacks;
  private observer: PlayerGestureObserver;
  private config: PlayerGestureConfig;
  private state: PlayerGestureState = new PlayerGestureState();
  private enabled: boolean = true;
  private panActive: boolean = false;
  private seekStarted: boolean = false;
  private startX: number = 0;
  private surfaceWidth: number = 1;
  private surfaceHeight: number = 1;
  private startPosition: number = 0;
  private duration: number = 0;
  private startVolume: number = 1;
  private startBrightness: number = 0.5;

  constructor(callbacks: PlayerGestureCallbacks, observer: PlayerGestureObserver,
    config: PlayerGestureConfig = new PlayerGestureConfig()) {
    this.callbacks = callbacks;
    this.observer = observer;
    this.config = config;
  }

  setEnabled(enabled: boolean): void {
    if (this.enabled === enabled) {
      return;
    }
    this.enabled = enabled;
    if (!enabled) {
      this.cancelPan();
      this.endLongPress();
    }
  }

  singleTap(): void {
    if (this.enabled) {
      this.callbacks.onToggleControls();
    }
  }

  doubleTap(localX: number, surfaceWidth: number): void {
    if (!this.enabled) {
      return;
    }
    const zone: PlayerTapZone = this.tapZone(localX, surfaceWidth);
    if (zone === PlayerTapZone.LEFT) {
      this.callbacks.onSeekBy(-this.config.doubleTapSeekOffset);
      return;
    }
    if (zone === PlayerTapZone.RIGHT) {
      this.callbacks.onSeekBy(this.config.doubleTapSeekOffset);
      return;
    }
    this.callbacks.onTogglePlayback();
  }

  beginLongPress(): void {
    if (!this.enabled || this.state.mode === PlayerGestureMode.FAST_PLAYBACK) {
      return;
    }
    this.callbacks.onTemporaryRate(true);
    this.publish(new PlayerGestureState(PlayerGestureMode.FAST_PLAYBACK, true, 2));
  }

  endLongPress(): void {
    if (this.state.mode !== PlayerGestureMode.FAST_PLAYBACK) {
      return;
    }
    this.callbacks.onTemporaryRate(false);
    this.publish(new PlayerGestureState());
  }

  beginPan(startX: number, surfaceWidth: number, surfaceHeight: number, position: number,
    duration: number, volume: number, brightness: number): void {
    if (!this.enabled) {
      return;
    }
    this.panActive = true;
    this.seekStarted = false;
    this.startX = startX;
    this.surfaceWidth = Math.max(1, surfaceWidth);
    this.surfaceHeight = Math.max(1, surfaceHeight);
    this.startPosition = Math.max(0, position);
    this.duration = Math.max(0, duration);
    this.startVolume = this.clamp(volume, 0, 1);
    this.startBrightness = this.clamp(brightness, this.config.minimumBrightness, 1);
    this.publish(new PlayerGestureState());
  }

  updatePan(offsetX: number, offsetY: number): void {
    if (!this.enabled || !this.panActive) {
      return;
    }
    let mode: PlayerGestureMode = this.state.mode;
    if (mode === PlayerGestureMode.IDLE) {
      mode = this.resolveMode(offsetX, offsetY);
      if (mode === PlayerGestureMode.IDLE) {
        return;
      }
    }
    if (mode === PlayerGestureMode.SEEK) {
      this.updateSeek(offsetX);
      return;
    }
    const delta: number = -offsetY / this.surfaceHeight;
    if (mode === PlayerGestureMode.BRIGHTNESS) {
      const brightness: number = this.clamp(this.startBrightness + delta, this.config.minimumBrightness, 1);
      this.callbacks.onBrightnessChange(brightness);
      this.publish(new PlayerGestureState(mode, true, brightness));
      return;
    }
    const volume: number = this.clamp(this.startVolume + delta, 0, 1);
    this.callbacks.onVolumeChange(volume);
    this.publish(new PlayerGestureState(mode, true, volume));
  }

  endPan(): void {
    if (!this.panActive) {
      return;
    }
    if (this.state.mode === PlayerGestureMode.SEEK && this.seekStarted) {
      this.callbacks.onSeekCommit(this.state.position);
    }
    this.resetPan();
  }

  cancelPan(): void {
    if (!this.panActive) {
      return;
    }
    if (this.state.mode === PlayerGestureMode.SEEK && this.seekStarted) {
      this.callbacks.onSeekCancel();
    }
    this.resetPan();
  }

  currentState(): PlayerGestureState {
    return this.state;
  }

  private tapZone(localX: number, surfaceWidth: number): PlayerTapZone {
    const width: number = Math.max(1, surfaceWidth);
    if (localX < width / 3) {
      return PlayerTapZone.LEFT;
    }
    if (localX > width * 2 / 3) {
      return PlayerTapZone.RIGHT;
    }
    return PlayerTapZone.CENTER;
  }

  private resolveMode(offsetX: number, offsetY: number): PlayerGestureMode {
    const horizontal: number = Math.abs(offsetX);
    const vertical: number = Math.abs(offsetY);
    if (horizontal >= vertical * this.config.directionRatio) {
      return this.duration > 0 ? PlayerGestureMode.SEEK : PlayerGestureMode.IDLE;
    }
    if (vertical < horizontal * this.config.directionRatio) {
      return PlayerGestureMode.IDLE;
    }
    if (this.startX <= this.config.edgeInset ||
      this.startX >= this.surfaceWidth - this.config.edgeInset) {
      return PlayerGestureMode.IDLE;
    }
    return this.startX < this.surfaceWidth / 2 ?
      PlayerGestureMode.BRIGHTNESS : PlayerGestureMode.VOLUME;
  }

  private updateSeek(offsetX: number): void {
    const position: number = this.clamp(
      this.startPosition + offsetX / this.surfaceWidth * this.duration, 0, this.duration
    );
    this.callbacks.onSeekPreview(position, !this.seekStarted);
    this.seekStarted = true;
    this.publish(new PlayerGestureState(PlayerGestureMode.SEEK, true, 0, position, this.duration));
  }

  private resetPan(): void {
    this.panActive = false;
    this.seekStarted = false;
    this.publish(new PlayerGestureState());
  }

  private publish(state: PlayerGestureState): void {
    this.state = state;
    this.observer(state);
  }

  private clamp(value: number, minimum: number, maximum: number): number {
    return Math.max(minimum, Math.min(value, maximum));
  }
}
