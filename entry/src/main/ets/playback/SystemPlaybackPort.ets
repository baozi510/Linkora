import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { MediaSource, MediaSourceKind, PlaybackBackend, PlaybackPortError, PlaybackPortObserver,
  PlayerBackendCapabilities, PlayerBackendKind, PortAudioInterruption, PortAudioOutputChange,
  PortBufferingEvent, PortInterruptionHint, PortPlaybackState, PortStreamEnd, PortStreamEndReason,
  PortTrack, PortTrackKind, VideoDisplayMode, PlaybackPlaylist } from 'linkora_core';
import { ProgressiveDownloadRegistry, ProgressiveDownloadTask } from './ProgressiveDownloadRegistry';

const INITIALIZATION_TIMEOUT: number = 12000;
const ERROR_EVENT_GRACE_PERIOD: number = 80;
const PREPARATION_TIMEOUT: number = 20000;

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
  private resolvePreparation: (() => void) | null = null;
  private rejectPreparation: ((error: PlaybackPortError) => void) | null = null;
  private preparationTimer: number = -1;
  private nativePrepareCompleted: boolean = false;
  private nativePreparedNotified: boolean = false;
  private released: boolean = false;
  private releasePromise: Promise<void> | null = null;
  private tracks: PortTrack[] = [];
  private trackRequestId: number = 0;
  private playlist: PlaybackPlaylist | null = null;
  private playlistIds: string[] = [];
  private playlistFiles: fileIo.File[] = [];
  private pendingContentId: string = '';
  private reportedContentId: string = '';
  private playlistReady: boolean = false;
  private initialSelectionId: string = '';
  private loopRequestId: number = 0;

  private constructor(player: media.AVPlayer, observer: PlaybackPortObserver) {
    this.player = player;
    this.observer = observer;
    this.initializationPromise = new Promise<void>((resolve: () => void,
      reject: (error: PlaybackPortError) => void) => {
      this.resolveInitialization = resolve;
      this.rejectInitialization = reject;
    });
    // Cancellation can precede the first await on initializationPromise.
    // Handle an early rejection without consuming it for the actual awaiter.
    this.initializationPromise.catch((_error: PlaybackPortError) => {});
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

  configure(source: MediaSource, surfaceId: string, playlist: PlaybackPlaylist | null = null): void {
    try {
      this.pendingSurfaceId = surfaceId;
      if (playlist !== null) {
        if (deviceInfo.sdkApiVersion < 26 || playlist.items.length === 0) {
          throw new PlaybackPortError(801, 'Native System playlists require API26 and a nonempty list');
        }
        this.playlist = playlist;
        this.player.onPlaybackContentChanged((id: string) => {
          if (this.released) return;
          this.pendingContentId = id;
          this.notifyPlaylistIndex();
        });
        return;
      }
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

  setSurfaceSize(_width: number, _height: number): void {
    // AVPlayer uses the XComponent surface size directly.
  }

  getDuration(): number {
    return this.player.duration;
  }

  async prepare(): Promise<void> {
    try {
      if (this.playlist !== null) await this.preparePlaylist(this.playlist);
      await this.initializationPromise;
      if (this.released) {
        throw new PlaybackPortError(5400104, 'AVPlayer released before preparation');
      }
      // A resolved native prepare Promise is not necessarily a prepared state.
      // The API26 simulator HLS case observed play rejected while initialized.
      // Require both the native call and the native state notification before
      // AdaptivePlaybackPort can commit/emit PREPARED.
      const preparation: Promise<void> = new Promise<void>((resolve: () => void,
        reject: (error: PlaybackPortError) => void) => {
        this.resolvePreparation = resolve;
        this.rejectPreparation = reject;
      });
      this.startPreparationTimeout();
      try {
        this.player.prepare().then(
          () => {
            this.nativePrepareCompleted = true;
            this.completePreparation();
          },
          (error: Object) => {
            this.waitForErrorEvent().then(() => {
              this.failPreparation(this.lastError ?? SystemPlaybackPort.platformError(error));
            });
          }
        );
      } catch (error) {
        this.failPreparation(SystemPlaybackPort.platformError(error));
      }
      await preparation;
      if (this.playlist !== null) {
        await this.selectInitialPlaylistItem(this.playlist.startIndex);
        this.playlistReady = true;
        this.pendingContentId = this.player.getCurrentMediaSource()?.getID() ?? this.pendingContentId;
        this.notifyPlaylistIndex();
      }
      // Optional metadata must not delay the prepared/play path.
      this.refreshTracks().catch(() => {});
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
      if (this.player.state === 'playing') {
        this.observer.onStateChange(PortPlaybackState.PLAYING);
        return;
      }
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

  async selectPlaylistItem(index: number): Promise<void> {
    if (this.released || !this.playlistReady || !Number.isInteger(index) ||
      index < 0 || index >= this.playlistIds.length) {
      throw new PlaybackPortError(401, 'Unavailable playlist item');
    }
    try {
      await this.player.advanceToMediaSource(this.playlistIds[index]);
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    }
  }

  private async preparePlaylist(playlist: PlaybackPlaylist): Promise<void> {
    const items = playlist.items;
    this.playlistIds = new Array<string>(items.length).fill('');
    this.startInitializationTimeout();
    this.player.playlistLoopMode = media.PlaylistLoopMode.PLAYLIST_LOOP_MODE_NONE;
    for (let index: number = 0; index < items.length; index++) {
      if (this.released) throw new PlaybackPortError(5400104, 'Playlist preparation cancelled');
      const source = items[index].source;
      let nativeSource: media.MediaSource;
      if (source.kind === MediaSourceKind.NETWORK_LINK) {
        nativeSource = media.createMediaSourceWithUrl(source.locator);
      } else if (source.kind === MediaSourceKind.LOCAL_DOCUMENT && source.progressiveKey.length === 0) {
        const file = fileIo.openSync(source.locator, fileIo.OpenMode.READ_ONLY);
        this.playlistFiles.push(file);
        const size: number = fileIo.statSync(file.fd).size;
        const value = media.createMediaSourceWithFd({ fd: file.fd, offset: 0, length: size });
        if (size <= 0 || value === undefined) throw new PlaybackPortError(5400103, 'Invalid playlist file');
        nativeSource = value;
      } else {
        throw new PlaybackPortError(801, 'Playlist source must be resolved before native preparation');
      }
      this.playlistIds[index] = await this.player.addPlaybackMediaSource(nativeSource);
    }
    if (this.released) throw new PlaybackPortError(5400104, 'Playlist preparation cancelled');
  }

  private async selectInitialPlaylistItem(index: number): Promise<void> {
    const id: string = this.playlistIds[index];
    if (this.player.getCurrentMediaSource()?.getID() === id) return;
    // API26 prepare selects the first native item. Move to the clicked ID
    // before the engine's play/seek path, waiting for real native readiness.
    this.initialSelectionId = id;
    this.nativePrepareCompleted = false;
    this.nativePreparedNotified = false;
    const waiting: Promise<void> = new Promise<void>((resolve, reject) => {
      this.resolvePreparation = resolve;
      this.rejectPreparation = reject;
    });
    this.startPreparationTimeout();
    Promise.resolve().then(() => this.player.advanceToMediaSource(id)).then(() => {
      this.nativePrepareCompleted = true;
      this.completePreparation();
    }, (error: Object) => this.failPreparation(SystemPlaybackPort.platformError(error)));
    try { await waiting; } finally { this.initialSelectionId = ''; }
  }

  private notifyPlaylistIndex(): void {
    if (this.initialSelectionId.length > 0) this.completePreparation();
    if (!this.playlistReady || this.released || this.pendingContentId === this.reportedContentId) return;
    const index: number = this.playlistIds.indexOf(this.pendingContentId);
    if (index < 0) return;
    this.reportedContentId = this.pendingContentId;
    ++this.trackRequestId;
    this.tracks = [];
    this.observer.onPlaylistIndexChange(index);
    this.observer.onDurationChange(Math.max(0, this.player.duration));
    this.observer.onStateChange(this.portState(this.player.state));
    if (this.player.state === 'playing' || this.player.state === 'paused' || this.player.state === 'prepared') {
      this.refreshTracks().catch(() => {});
    }
  }

  async stop(): Promise<void> {
    try {
      await this.player.stop();
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    }
  }

  seek(position: number): void {
    this.player.seek(position, media.SeekMode.SEEK_CLOSEST);
  }

  setPlaybackRate(rate: number): void {
    if (!Number.isFinite(rate) || rate < 0.5 || rate > 2 || this.released) {
      throw new PlaybackPortError(401, 'Invalid playback rate or released player');
    }
    this.player.setPlaybackRate(rate);
  }

  setVolume(volume: number): void {
    if (!Number.isFinite(volume) || this.released) {
      throw new PlaybackPortError(401, 'Invalid volume or released player');
    }
    this.player.setVolume(Math.max(0, Math.min(1, volume)));
  }

  setLoop(loop: boolean): void {
    if (this.released) throw new PlaybackPortError(5400104, 'Player released');
    if (this.playlist !== null) {
      const requestId: number = ++this.loopRequestId;
      this.player.playlistLoopMode = loop ? media.PlaylistLoopMode.PLAYLIST_LOOP_MODE_ONE :
        media.PlaylistLoopMode.PLAYLIST_LOOP_MODE_NONE;
      // This read-only native task is queued after the asynchronous mode setter.
      this.player.getTrackDescription().then(() => {
        if (!this.released && requestId === this.loopRequestId) this.observer.onLoopChange(this.isLooping());
      }).catch((error: Object) => {
        if (!this.released && requestId === this.loopRequestId) {
          this.observer.onWarning('loop', SystemPlaybackPort.platformError(error));
        }
      });
    } else {
      this.player.loop = loop;
      this.observer.onLoopChange(this.player.loop);
    }
  }

  setDisplayMode(mode: VideoDisplayMode): void {
    if (this.released) throw new PlaybackPortError(5400104, 'Player released');
    if (mode !== VideoDisplayMode.FIT && mode !== VideoDisplayMode.CROP && mode !== VideoDisplayMode.STRETCH) {
      throw new PlaybackPortError(401, 'Invalid display mode');
    }
    // SDK FIT means stretch; SCALED_ASPECT is the proportional letterbox mode.
    const scale: media.VideoScaleType = mode === VideoDisplayMode.FIT ?
      media.VideoScaleType.VIDEO_SCALE_TYPE_SCALED_ASPECT : (mode === VideoDisplayMode.CROP ?
        media.VideoScaleType.VIDEO_SCALE_TYPE_FIT_CROP : media.VideoScaleType.VIDEO_SCALE_TYPE_FIT);
    try {
      this.player.videoScaleType = scale;
      if (this.player.videoScaleType !== scale) throw new PlaybackPortError(5400102, 'Display mode not applied');
      this.observer.onDisplayModeChange(mode);
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    }
  }

  async selectAudioTrack(id: string): Promise<void> {
    if (this.released || !this.tracks.some((track: PortTrack) =>
      track.id === id && track.kind === PortTrackKind.AUDIO)) {
      throw new PlaybackPortError(401, 'Audio track is unavailable');
    }
    try {
      await this.player.selectTrack(Number(id));
      await this.refreshTracks();
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    }
  }

  release(): Promise<void> {
    if (this.releasePromise !== null) return this.releasePromise;
    this.releasePromise = this.releasePlayer();
    return this.releasePromise;
  }

  private async releasePlayer(): Promise<void> {
    this.released = true;
    ++this.trackRequestId;
    const cancelled: PlaybackPortError = new PlaybackPortError(5400104,
      'AVPlayer released during preparation');
    this.failInitialization(cancelled);
    this.failPreparation(cancelled);
    try {
      if (this.player.state !== 'released') {
        await this.player.release();
      }
    } catch (error) {
      throw SystemPlaybackPort.platformError(error);
    } finally {
      this.clearInitializationTimeout();
      this.clearPreparationTimeout();
      this.closeSourceFile();
      for (const file of this.playlistFiles) {
        try { fileIo.closeSync(file.fd); } catch (_error) {}
      }
      this.playlistFiles = [];
      this.progressiveTask = null;
      this.progressiveCursor = 0;
    }
  }

  private registerEvents(): void {
    this.player.on('stateChange', (state: media.AVPlayerState, _reason: media.StateChangeReason) => {
      if (this.released && state !== 'released') return;
      if (state === 'initialized') {
        this.completeInitialization();
      } else if (state === 'prepared') {
        this.nativePreparedNotified = true;
        this.completePreparation();
      } else if (state === 'error' || state === 'released') {
        this.failPreparation(this.lastError ?? new PlaybackPortError(5400104,
          'AVPlayer left preparation without becoming prepared'));
      }
      if (state === 'stopped') this.observer.onStreamEnd(new PortStreamEnd(PortStreamEndReason.STOP, this.isLooping()));
      if (this.initialSelectionId.length > 0) this.completePreparation();
      this.observer.onStateChange(this.portState(state));
    });
    this.player.on('error', (error) => {
      if (this.released) return;
      console.error(`[SystemPlaybackPort] AVPlayer error code=${error.code}, message=${error.message}`);
      const portError: PlaybackPortError = new PlaybackPortError(error.code, error.message);
      this.lastError = portError;
      this.failInitialization(portError);
      this.failPreparation(portError);
      this.observer.onError(portError);
    });
    this.player.on('durationUpdate', (duration: number) => {
      if (this.released) return;
      this.observer.onDurationChange(duration);
    });
    this.player.on('timeUpdate', (position: number) => {
      if (this.released) return;
      this.observer.onPositionChange(position);
    });
    this.player.on('seekDone', (position: number) => {
      if (this.released) return;
      this.observer.onSeekComplete(position);
    });
    this.player.on('bufferingUpdate', (type: media.BufferingInfoType, value: number) => {
      if (this.released) return;
      this.observer.onBufferingChange(this.bufferingEvent(type), value);
    });
    this.player.on('startRenderFrame', () => {
      if (this.released) return;
      this.observer.onFirstFrame();
    });
    this.player.on('videoSizeChange', (width: number, height: number) => {
      if (this.released) return;
      this.observer.onVideoSizeChange(width, height);
    });
    this.player.on('volumeChange', (volume: number) => {
      if (!this.released) this.observer.onVolumeChange(volume);
    });
    this.player.on('playbackRateDone', (rate: number) => {
      if (!this.released) this.observer.onPlaybackRateChange(rate);
    });
    this.player.on('speedDone', (speed: number) => {
      const rates: number[] = [0.75, 1, 1.25, 1.75, 2, 0.5, 1.5, 3, 0.25, 0.125];
      if (!this.released && Number.isInteger(speed) && speed >= 0 && speed < rates.length) {
        this.observer.onPlaybackRateChange(rates[speed]);
      }
    });
    this.player.on('endOfStream', () => {
      if (!this.released) this.observer.onStreamEnd(new PortStreamEnd(PortStreamEndReason.EOF, this.isLooping()));
    });
    this.player.on('trackInfoUpdate', (descriptions: media.MediaDescription[]) => {
      this.refreshTracks(descriptions).catch(() => {});
    });
    this.player.on('trackChange', (_index: number, _selected: boolean) => {
      this.refreshTracks().catch(() => {});
    });
    this.player.on('audioOutputDeviceChangeWithInfo', (event: audio.AudioStreamDeviceChangeInfo) => {
      if (this.released) return;
      const types: number[] = [];
      for (const device of event.devices) types.push(device.deviceType);
      this.observer.onAudioOutputChange(new PortAudioOutputChange(types, event.changeReason));
    });
    this.player.on('audioInterrupt', (event: audio.InterruptEvent) => {
      if (this.released) return;
      let hint: PortInterruptionHint = PortInterruptionHint.UNKNOWN;
      if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE) hint = PortInterruptionHint.PAUSE;
      else if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP) hint = PortInterruptionHint.STOP;
      else if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_RESUME) hint = PortInterruptionHint.RESUME;
      else if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_DUCK) hint = PortInterruptionHint.DUCK;
      else if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_UNDUCK) hint = PortInterruptionHint.UNDUCK;
      this.observer.onAudioInterruption(new PortAudioInterruption(hint,
        event.forceType === audio.InterruptForceType.INTERRUPT_FORCE, event.eventType));
      if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE ||
        event.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP) {
        this.observer.onInterruptionPause();
      }
    });
  }

  private isLooping(): boolean {
    return this.playlist !== null ?
      this.player.playlistLoopMode === media.PlaylistLoopMode.PLAYLIST_LOOP_MODE_ONE : this.player.loop;
  }

  private async refreshTracks(descriptions?: media.MediaDescription[]): Promise<void> {
    if (this.released) return;
    const requestId: number = ++this.trackRequestId;
    try {
      const description: media.MediaDescription[] = descriptions ?? await this.player.getTrackDescription();
      const selected: number[] = await this.player.getSelectedTracks();
      if (this.released || requestId !== this.trackRequestId) return;
      const tracks: PortTrack[] = [];
      for (const item of description) {
        const index: number = item['track_index'] as number;
        const type: number = item['track_type'] as number;
        if (!Number.isInteger(index) || index < 0 || (type !== 0 && type !== 1 && type !== 2)) continue;
        const kind: PortTrackKind = type === 0 ? PortTrackKind.AUDIO :
          (type === 1 ? PortTrackKind.VIDEO : PortTrackKind.SUBTITLE);
        tracks.push(new PortTrack(index.toString(), kind, this.trackText(item, 'codec_mime'),
          this.trackText(item, 'language'), this.trackText(item, 'track_name'), selected.includes(index)));
      }
      this.tracks = tracks;
      this.observer.onTracksChange(tracks);
    } catch (error) {
      if (!this.released && requestId === this.trackRequestId) {
        this.observer.onWarning('tracks', SystemPlaybackPort.platformError(error));
      }
    }
  }

  private trackText(description: media.MediaDescription, key: string): string {
    const value: Object = description[key];
    return typeof value === 'string' ? value : '';
  }

  private completeInitialization(): void {
    if (this.released) {
      return;
    }
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

  private completePreparation(): void {
    const selecting: boolean = this.initialSelectionId.length > 0;
    const ready: boolean = selecting ? this.pendingContentId === this.initialSelectionId &&
      (this.player.state === 'playing' || this.player.state === 'paused' ||
        (this.nativePreparedNotified && this.player.state === 'prepared')) &&
      this.player.getCurrentMediaSource()?.getID() === this.initialSelectionId :
      this.nativePreparedNotified && this.player.state === 'prepared';
    if (this.released || !this.nativePrepareCompleted || !ready) {
      return;
    }
    const resolve: (() => void) | null = this.resolvePreparation;
    if (resolve === null) {
      return;
    }
    this.clearPreparationTimeout();
    this.resolvePreparation = null;
    this.rejectPreparation = null;
    resolve();
  }

  private failPreparation(error: PlaybackPortError): void {
    const reject: ((error: PlaybackPortError) => void) | null = this.rejectPreparation;
    if (reject === null) {
      return;
    }
    this.clearPreparationTimeout();
    this.resolvePreparation = null;
    this.rejectPreparation = null;
    reject(error);
  }

  private startPreparationTimeout(): void {
    this.clearPreparationTimeout();
    this.preparationTimer = setTimeout(() => {
      this.failPreparation(new PlaybackPortError(5400104,
        'AVPlayer prepared state not confirmed before timeout'));
    }, PREPARATION_TIMEOUT);
  }

  private clearPreparationTimeout(): void {
    if (this.preparationTimer < 0) {
      return;
    }
    clearTimeout(this.preparationTimer);
    this.preparationTimer = -1;
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
