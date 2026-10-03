import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { MediaSource, MediaSourceKind, PlaybackBackend, PlaybackPortError, PlaybackPortObserver,
  PlayerBackendCapabilities, PlayerBackendKind, PortBufferingEvent, PortPlaybackState } from 'linkora_core';
import { ProgressiveDownloadRegistry, ProgressiveDownloadTask } from './ProgressiveDownloadRegistry';

const INITIALIZATION_TIMEOUT: number = 12000;
const ERROR_EVENT_GRACE_PERIOD: number = 80;

export class SystemPlaybackPort implements PlaybackBackend {
  private player: media.AVPlayer;
  private observer: PlaybackPortObserver;
  private sourceFile: fileIo.File | null = null;
  private progressiveTask: ProgressiveDownloadTask | null = null;
  private progressiveCursor: number = 0;
  private pendingSurfaceId: string = '';
  private initializationPromise: Promise<void>;
  private resolveInitialization: (() => void) | null = null;
  private rejectInitialization: ((error: PlaybackPortError) => void) | null = null;
  private initializationTimer: number = -1;
  private lastError: PlaybackPortError | null = null;

  private constructor(player: media.AVPlayer, observer: PlaybackPortObserver) {
    this.player = player;
    this.observer = observer;
    this.initializationPromise = new Promise<void>((resolve: () => void,
      reject: (error: PlaybackPortError) => void) => {
      this.resolveInitialization = resolve;
      this.rejectInitialization = reject;
    });
    this.registerEvents();
  }

  static async create(observer: PlaybackPortObserver): Promise<PlaybackBackend> {
    try {
      const player: media.AVPlayer = await media.createAVPlayer();
      return new SystemPlaybackPort(player, observer);
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    }
  }

  backendKind(): PlayerBackendKind {
    return PlayerBackendKind.SYSTEM;
  }

  capabilities(): PlayerBackendCapabilities {
    return new PlayerBackendCapabilities(true, true, true, false, false, false, false, false, false, false);
  }

  configure(source: MediaSource, surfaceId: string): void {
    try {
      this.pendingSurfaceId = surfaceId;
      this.startInitializationTimeout();
      if (source.kind === MediaSourceKind.NETWORK_LINK) {
        this.player.url = source.locator;
      } else if (source.progressiveKey.length > 0) {
        this.configureProgressiveDocument(source);
      } else {
        this.configureLocalDocument(source.locator);
      }
    } catch (error) {
      const portError: PlaybackPortError = SystemPlaybackPort.platformError(error);
      this.failInitialization(portError);
      throw portError;
    }
  }

  getDuration(): number {
    return this.player.duration;
  }

  async prepare(): Promise<void> {
    try {
      await this.initializationPromise;
      await this.player.prepare();
    } catch (error) {
      if (error instanceof PlaybackPortError) {
        throw error;
      }
      await this.waitForErrorEvent();
      throw this.lastError ?? SystemPlaybackPort.platformError(error);
    }
  }

  async play(): Promise<void> {
    try {
      await this.player.play();
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    }
  }

  async pause(): Promise<void> {
    try {
      await this.player.pause();
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    }
  }

  seek(position: number): void {
    this.player.seek(position, media.SeekMode.SEEK_CLOSEST);
  }

  setPlaybackRate(rate: number): void {
    this.player.setSpeed(this.playbackSpeed(rate));
  }

  setVolume(volume: number): void {
    this.player.setVolume(volume);
  }

  async release(): Promise<void> {
    try {
      if (this.player.state !== 'released') {
        await this.player.release();
      }
    } catch (_error) {
    } finally {
      this.clearInitializationTimeout();
      this.closeSourceFile();
      this.progressiveTask = null;
      this.progressiveCursor = 0;
    }
  }

  private registerEvents(): void {
    this.player.on('stateChange', (state: media.AVPlayerState, _reason: media.StateChangeReason) => {
      if (state === 'initialized') {
        this.completeInitialization();
      }
      this.observer.onStateChange(this.portState(state));
    });
    this.player.on('error', (error) => {
      console.error(`[SystemPlaybackPort] AVPlayer error code=${error.code}, message=${error.message}`);
      const portError: PlaybackPortError = new PlaybackPortError(error.code, error.message);
      this.lastError = portError;
      this.failInitialization(portError);
      this.observer.onError(portError);
    });
    this.player.on('durationUpdate', (duration: number) => {
      this.observer.onDurationChange(duration);
    });
    this.player.on('timeUpdate', (position: number) => {
      this.observer.onPositionChange(position);
    });
    this.player.on('bufferingUpdate', (type: media.BufferingInfoType, value: number) => {
      this.observer.onBufferingChange(this.bufferingEvent(type), value);
    });
    this.player.on('startRenderFrame', () => {
      this.observer.onFirstFrame();
    });
    this.player.on('videoSizeChange', (width: number, height: number) => {
      this.observer.onVideoSizeChange(width, height);
    });
    this.player.on('audioInterrupt', (event: audio.InterruptEvent) => {
      if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE ||
        event.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP) {
        this.observer.onInterruptionPause();
      }
    });
  }

  private completeInitialization(): void {
    const resolve: (() => void) | null = this.resolveInitialization;
    if (resolve === null) {
      return;
    }
    try {
      this.player.surfaceId = this.pendingSurfaceId;
      this.clearInitializationTimeout();
      this.resolveInitialization = null;
      this.rejectInitialization = null;
      resolve();
    } catch (error) {
      const portError: PlaybackPortError = SystemPlaybackPort.platformError(error);
      this.lastError = portError;
      this.failInitialization(portError);
      this.observer.onError(portError);
    }
  }

  private failInitialization(error: PlaybackPortError): void {
    const reject: ((error: PlaybackPortError) => void) | null = this.rejectInitialization;
    this.clearInitializationTimeout();
    this.resolveInitialization = null;
    this.rejectInitialization = null;
    if (reject !== null) {
      reject(error);
    }
  }

  private startInitializationTimeout(): void {
    this.clearInitializationTimeout();
    this.initializationTimer = setTimeout(() => {
      const timeoutError: PlaybackPortError = new PlaybackPortError(5400104, 'AVPlayer initialization timeout');
      this.lastError = timeoutError;
      this.failInitialization(timeoutError);
      this.observer.onError(timeoutError);
    }, INITIALIZATION_TIMEOUT);
  }

  private clearInitializationTimeout(): void {
    if (this.initializationTimer < 0) {
      return;
    }
    clearTimeout(this.initializationTimer);
    this.initializationTimer = -1;
  }

  private async waitForErrorEvent(): Promise<void> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, ERROR_EVENT_GRACE_PERIOD);
    });
  }

  private static platformError(error: Object): PlaybackPortError {
    if (error instanceof PlaybackPortError) {
      return error;
    }
    const businessError: BusinessError = error as BusinessError;
    return new PlaybackPortError(businessError.code ?? 0, businessError.message ?? String(error));
  }

  private configureLocalDocument(uri: string): void {
    let sourceFile: fileIo.File | null = null;
    try {
      sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat: fileIo.Stat = fileIo.statSync(sourceFile.fd);
      if (stat.size <= 0) {
        throw new Error('Empty media file');
      }
      this.sourceFile = sourceFile;
      this.player.fdSrc = {
        fd: sourceFile.fd,
        offset: 0,
        length: stat.size
      };
    } catch (_error) {
      if (sourceFile !== null) {
        try {
          fileIo.closeSync(sourceFile.fd);
        } catch (_closeError) {
        }
      }
      throw new PlaybackPortError(5400103);
    }
  }

  private configureProgressiveDocument(source: MediaSource): void {
    const task: ProgressiveDownloadTask | null = ProgressiveDownloadRegistry.get(source.progressiveKey);
    if (task === null) {
      throw new PlaybackPortError(5400103, '播放缓存已失效，请重新打开文件。');
    }
    this.progressiveTask = task;
    this.progressiveCursor = 0;
    const fileSize: number = source.sizeBytes > 0 ? source.sizeBytes :
      (task.sizeBytes > 0 ? task.sizeBytes : -1);
    this.player.dataSrc = {
      fileSize,
      callback: (buffer: ArrayBuffer, length: number, pos?: number): number =>
        this.readProgressiveData(task, buffer, length, pos)
    };
  }

  private readProgressiveData(task: ProgressiveDownloadTask, buffer: ArrayBuffer,
    length: number, pos?: number): number {
    const sequential: boolean = pos === undefined;
    const position: number = pos ?? this.progressiveCursor;
    if (length <= 0) {
      return 0;
    }
    try {
      const file: fileIo.File = fileIo.openSync(task.cachePath, fileIo.OpenMode.READ_ONLY);
      try {
        const available: number = fileIo.statSync(file.fd).size;
        if (position >= available) {
          if (task.isFailed()) {
            console.error(`[SystemPlaybackPort] progressive download failed: ${task.errorMessage()}`);
            return -2;
          }
          return task.isFinished() ? -1 : 0;
        }
        const requested: number = Math.min(length, available - position);
        fileIo.lseek(file.fd, position, fileIo.WhenceType.SEEK_SET);
        const bytesRead: number = fileIo.readSync(file.fd, buffer, { offset: 0, length: requested });
        if (sequential && bytesRead > 0) {
          this.progressiveCursor = position + bytesRead;
        }
        return bytesRead;
      } finally {
        fileIo.closeSync(file.fd);
      }
    } catch (_error) {
      return task.isFailed() ? -2 : 0;
    }
  }

  private closeSourceFile(): void {
    const sourceFile: fileIo.File | null = this.sourceFile;
    this.sourceFile = null;
    if (sourceFile === null) {
      return;
    }
    try {
      fileIo.closeSync(sourceFile.fd);
    } catch (_error) {
    }
  }

  private playbackSpeed(rate: number): media.PlaybackSpeed {
    if (rate >= 2) {
      return media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
    }
    if (rate >= 1.5) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_50_X;
    }
    if (rate >= 1.25) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
    }
    return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  }

  private portState(state: media.AVPlayerState): PortPlaybackState {
    if (state === 'initialized') {
      return PortPlaybackState.INITIALIZED;
    }
    if (state === 'prepared') {
      return PortPlaybackState.PREPARED;
    }
    if (state === 'playing') {
      return PortPlaybackState.PLAYING;
    }
    if (state === 'paused') {
      return PortPlaybackState.PAUSED;
    }
    if (state === 'completed') {
      return PortPlaybackState.COMPLETED;
    }
    if (state === 'stopped') {
      return PortPlaybackState.STOPPED;
    }
    if (state === 'released') {
      return PortPlaybackState.RELEASED;
    }
    if (state === 'error') {
      return PortPlaybackState.ERROR;
    }
    return PortPlaybackState.IDLE;
  }

  private bufferingEvent(type: media.BufferingInfoType): PortBufferingEvent {
    if (type === media.BufferingInfoType.BUFFERING_START) {
      return PortBufferingEvent.START;
    }
    if (type === media.BufferingInfoType.BUFFERING_END) {
      return PortBufferingEvent.END;
    }
    if (type === media.BufferingInfoType.BUFFERING_PERCENT) {
      return PortBufferingEvent.PERCENT;
    }
    return PortBufferingEvent.CACHED_DURATION;
  }
}
