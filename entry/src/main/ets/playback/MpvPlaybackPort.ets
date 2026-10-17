import {
  EventObserver,
  Media,
  MpvEvent,
  MpvFormat,
  Playlist,
  Player,
  Track,
  Tracks
} from '@mpv-ohos/mpv-arkts';
import {
  MediaSource,
  MediaSourceKind,
  PlaybackPlaylist,
  PlaybackBackend,
  PlaybackPortError,
  PlaybackPortObserver,
  PlayerBackendCapabilities,
  PlayerBackendKind,
  PortBufferingEvent,
  PortPlaybackState,
  PortStreamEnd,
  PortStreamEndReason,
  PortTrack,
  PortTrackKind,
  PortVideoInfo,
  VideoDisplayMode,
  PlaybackLoopMode
} from 'linkora_core';

const MPV_PREPARE_TIMEOUT_MS: number = 12000;

export class MpvPlaybackPort implements PlaybackBackend, EventObserver {
  private readonly observer: PlaybackPortObserver;
  private readonly player: Player;
  private source: MediaSource | null = null;
  private playlist: PlaybackPlaylist | null = null;
  private playlistIndex: number = -1;
  private playlistHandoff: boolean = false;
  private surfaceAttached: boolean = false;
  private released: boolean = false;
  private prepared: boolean = false;
  private completed: boolean = false;
  private firstFrameSignaled: boolean = false;
  private prepareResolve: (() => void) | null = null;
  private prepareReject: ((error: PlaybackPortError) => void) | null = null;
  private prepareTimer: number = -1;
  private seekPending: boolean = false;
  private latestErrorLog: string = '';
  private loopMode: PlaybackLoopMode = PlaybackLoopMode.SEQUENCE;
  private stopRequested: boolean = false;
  private endSignaled: boolean = false;
  private releasePromise: Promise<void> | null = null;

  private constructor(observer: PlaybackPortObserver) {
    this.observer = observer;
    this.player = new Player();
    this.player.native.addEventObserver(this);
    this.player.native.observeProperty('idle-active', MpvFormat.MPV_FORMAT_FLAG);
    this.player.native.observeProperty('loop-file', MpvFormat.MPV_FORMAT_STRING);
    this.player.native.observeProperty('loop-playlist', MpvFormat.MPV_FORMAT_STRING);
    this.bindStreams();
  }

  static async create(observer: PlaybackPortObserver): Promise<PlaybackBackend> {
    try {
      return new MpvPlaybackPort(observer);
    } catch (error) {
      throw new PlaybackPortError(0, `Unable to create MPV backend: ${String(error)}`);
    }
  }

  backendKind(): PlayerBackendKind {
    return PlayerBackendKind.MPV;
  }

  capabilities(): PlayerBackendCapabilities {
    // Advanced output/subtitle capabilities await target-device validation.
    return new PlayerBackendCapabilities();
  }

  configure(source: MediaSource, surfaceId: string, playlist: PlaybackPlaylist | null = null): void {
    if (this.released || surfaceId.length === 0) {
      throw new PlaybackPortError(0, 'MPV backend is unavailable');
    }
    if (source.kind === MediaSourceKind.REMOTE_FILE) {
      throw new PlaybackPortError(0, 'Remote file must be resolved before MPV configure');
    }
    this.source = source;
    this.playlist = playlist;
    try {
      this.player.native.attachSurface(surfaceId);
      this.surfaceAttached = true;
      this.observer.onStateChange(PortPlaybackState.INITIALIZED);
    } catch (error) {
      throw new PlaybackPortError(0, `Unable to attach MPV surface: ${String(error)}`);
    }
  }

  setSurfaceSize(width: number, height: number): void {
    const safeWidth: number = Math.max(1, Math.round(width));
    const safeHeight: number = Math.max(1, Math.round(height));
    if (!this.released && this.surfaceAttached) {
      this.player.native.setProperty('ohos-surface-size', `${safeWidth}x${safeHeight}`);
    }
  }

  getDuration(): number {
    return Math.max(0, Math.round(this.player.state.duration * 1000));
  }

  async prepare(): Promise<void> {
    const source: MediaSource | null = this.source;
    if (this.released || source === null || !this.surfaceAttached) {
      throw new PlaybackPortError(0, 'MPV backend is not configured');
    }
    if (this.prepared) {
      return;
    }
    const waiting: Promise<void> = new Promise<void>((resolve, reject) => {
      this.prepareResolve = resolve;
      this.prepareReject = reject;
    });
    this.prepareTimer = setTimeout(() => {
      const diagnostic: string = this.latestErrorLog.length > 0 ? `: ${this.latestErrorLog}` : '';
      this.failPrepare(new PlaybackPortError(0, `MPV prepare timed out${diagnostic}`));
    }, MPV_PREPARE_TIMEOUT_MS);
    try {
      if (this.playlist === null) {
        this.player.open(new Media(source.locator), false);
      } else {
        this.player.open(new Playlist(this.playlist.items.map((item) => new Media(item.source.locator)),
          this.playlist.startIndex), false);
      }
      await waiting;
    } finally {
      this.clearPrepareTimer();
    }
  }

  async play(): Promise<void> {
    this.ensureReady();
    this.completed = false;
    this.player.play();
    // mpv-arkts may emit its START_FILE playing=true before FILE_LOADED/commit,
    // and setting pause=false again does not guarantee another property callback.
    // A successful explicit play command is therefore also the adapter's
    // authoritative unified-state transition.
    this.observer.onStateChange(PortPlaybackState.PLAYING);
  }

  async pause(): Promise<void> {
    this.ensureReady();
    this.player.pause();
    if (!this.completed) {
      this.observer.onStateChange(PortPlaybackState.PAUSED);
    }
  }

  async selectPlaylistItem(index: number): Promise<void> {
    this.ensureReady();
    if (this.playlist === null || !Number.isInteger(index) || index < 0 || index >= this.playlist.items.length) {
      throw new PlaybackPortError(401, 'Unavailable playlist item');
    }
    this.player.jump(index);
  }

  async stop(): Promise<void> {
    this.ensureReady();
    this.stopRequested = true;
    this.endSignaled = false;
    this.player.stop();
    this.prepared = false;
    this.observer.onStateChange(PortPlaybackState.STOPPED);
  }

  seek(position: number): void {
    this.ensureReady();
    this.completed = false;
    this.seekPending = true;
    this.player.seek(Math.max(0, position) / 1000);
  }

  setPlaybackRate(rate: number): void {
    this.ensureReady();
    if (!Number.isFinite(rate) || rate < 0.5 || rate > 2) throw new PlaybackPortError(401, 'Invalid playback rate');
    this.player.setSpeed(rate);
  }

  setVolume(volume: number): void {
    this.ensureReady();
    if (!Number.isFinite(volume)) throw new PlaybackPortError(401, 'Invalid volume');
    this.player.setVolume(Math.max(0, Math.min(volume, 1)) * 100);
  }

  setLoopMode(mode: PlaybackLoopMode): void {
    this.ensureReady();
    if (mode !== PlaybackLoopMode.SEQUENCE && mode !== PlaybackLoopMode.SINGLE && mode !== PlaybackLoopMode.LIST) {
      throw new PlaybackPortError(401, 'Invalid loop mode');
    }
    this.player.native.setProperty('loop-file', mode === PlaybackLoopMode.SINGLE ? 'inf' : 'no');
    this.player.native.setProperty('loop-playlist', mode === PlaybackLoopMode.LIST ? 'inf' : 'no');
  }

  setDisplayMode(mode: VideoDisplayMode): void {
    this.ensureReady();
    if (mode !== VideoDisplayMode.FIT && mode !== VideoDisplayMode.CROP && mode !== VideoDisplayMode.STRETCH) {
      throw new PlaybackPortError(401, 'Invalid display mode');
    }
    const keepAspect: boolean = mode !== VideoDisplayMode.STRETCH;
    const pan: number = mode === VideoDisplayMode.CROP ? 1 : 0;
    this.player.native.setProperty('keepaspect', keepAspect);
    this.player.native.setProperty('panscan', pan);
    this.player.native.setProperty('video-unscaled', 'no');
    if (this.player.native.getPropertyBool('keepaspect') !== keepAspect ||
      this.player.native.getProperty('panscan') !== pan ||
      this.player.native.getPropertyString('video-unscaled') !== 'no') {
      throw new PlaybackPortError(5400102, 'Display mode not applied');
    }
    this.observer.onDisplayModeChange(mode);
  }

  async selectAudioTrack(id: string): Promise<void> {
    this.ensureReady();
    if (id === 'auto') {
      this.player.native.setProperty('aid', 'auto');
      return;
    }
    const track = this.player.state.tracks.audio.find((item) => item.id === id);
    if (track === undefined) throw new PlaybackPortError(401, 'Audio track is unavailable');
    this.player.setAudioTrack(track);
  }

  release(): Promise<void> {
    if (this.releasePromise !== null) return this.releasePromise;
    this.released = true;
    this.clearPrepareTimer();
    this.failPrepare(new PlaybackPortError(0, 'MPV backend released'));
    this.releasePromise = Promise.resolve().then(() => this.releaseNative());
    return this.releasePromise;
  }

  private releaseNative(): void {
    let failure: PlaybackPortError | null = null;
    try {
      this.player.native.removeEventObserver(this);
    } catch (error) {
      failure = new PlaybackPortError(0, `Unable to remove MPV observer: ${String(error)}`);
    }
    if (this.surfaceAttached) {
      try {
        this.player.native.detachSurface();
      } catch (error) {
        failure = failure ?? new PlaybackPortError(0, `Unable to detach MPV surface: ${String(error)}`);
      }
      this.surfaceAttached = false;
    }
    try {
      this.player.destroy();
    } catch (error) {
      failure = failure ?? new PlaybackPortError(0, `Unable to destroy MPV player: ${String(error)}`);
    }
    if (failure !== null) throw failure;
    this.observer.onStateChange(PortPlaybackState.RELEASED);
  }

  onPropertyChanged(property: string, value?: string | number | boolean): void {
    if (this.released) return;
    if (property === 'loop-file' || property === 'loop-playlist') {
      try {
        const file: string = this.player.native.getPropertyString('loop-file');
        const list: string = this.player.native.getPropertyString('loop-playlist');
        if ((file !== 'no' && file !== 'inf') || (list !== 'no' && list !== 'inf')) return;
        this.loopMode = file === 'inf' ? PlaybackLoopMode.SINGLE :
          (list === 'inf' ? PlaybackLoopMode.LIST : PlaybackLoopMode.SEQUENCE);
        this.observer.onLoopModeChange(this.loopMode);
      } catch (error) {
        this.observer.onWarning('loop', new PlaybackPortError(0, String(error)));
      }
      return;
    }
    if (property === 'idle-active' && value === true) {
      this.failIdlePlaylist();
      return;
    }
    if (this.released || this.playlist === null || property !== 'playlist-playing-pos' ||
      typeof value !== 'number' || !Number.isInteger(value) || value < 0 ||
      value >= this.playlist.items.length || value === this.playlistIndex) return;
    this.playlistIndex = value;
    this.completed = false;
    this.endSignaled = false;
    this.firstFrameSignaled = false;
    this.seekPending = false;
    this.observer.onPlaylistIndexChange(value);
  }

  onEvent(id: number, _name: string): void {
    if (this.released) {
      return;
    }
    if (id === MpvEvent.MPV_EVENT_FILE_LOADED) {
      this.prepared = true;
      this.endSignaled = false;
      this.stopRequested = false;
      this.playlistHandoff = false;
      const resolve: (() => void) | null = this.prepareResolve;
      this.prepareResolve = null;
      this.prepareReject = null;
      this.clearPrepareTimer();
      this.observer.onStateChange(PortPlaybackState.PREPARED);
      if (resolve === null && this.playlist !== null && !this.player.native.getPropertyBool('pause')) {
        this.observer.onStateChange(PortPlaybackState.PLAYING);
      }
      resolve?.();
    } else if (id === MpvEvent.MPV_EVENT_END_FILE) {
      if (this.prepareReject !== null) {
        this.failPrepare(new PlaybackPortError(0, `MPV file ended before preparation: ${this.latestErrorLog}`));
      } else if (this.stopRequested) {
        this.stopRequested = false;
        this.emitEnd(PortStreamEndReason.STOP);
      } else if (this.completed || this.player.state.eof) {
        this.emitEnd(PortStreamEndReason.EOF);
      } else {
        // The current ArkTS binding supplies no END_FILE reason/error payload.
        this.prepared = false;
        this.emitEnd(PortStreamEndReason.UNKNOWN);
        if (this.playlist === null) {
          this.observer.onStateChange(PortPlaybackState.STOPPED);
        } else {
          this.playlistHandoff = true;
          if (this.player.native.getPropertyBool('idle-active')) this.failIdlePlaylist();
        }
      }
    } else if (id === MpvEvent.MPV_EVENT_SHUTDOWN) {
      const error = new PlaybackPortError(5400105, 'MPV unexpectedly shut down');
      this.failPrepare(error);
      this.observer.onError(error);
    } else if (id === MpvEvent.MPV_EVENT_SEEK) {
      this.seekPending = true;
    } else if (id === MpvEvent.MPV_EVENT_PLAYBACK_RESTART) {
      if (!this.firstFrameSignaled) {
        this.firstFrameSignaled = true;
        this.observer.onFirstFrame();
      }
      if (this.seekPending) {
        this.seekPending = false;
        this.observer.onSeekComplete(Math.max(0, Math.round(this.player.state.position * 1000)));
      }
    }
  }

  private bindStreams(): void {
    this.player.stream.duration.listen((seconds: number) => {
      if (this.released) return;
      this.observer.onDurationChange(Math.max(0, Math.round(seconds * 1000)));
    });
    this.player.stream.position.listen((seconds: number) => {
      if (this.released) return;
      this.observer.onPositionChange(Math.max(0, Math.round(seconds * 1000)));
    });
    this.player.stream.playing.listen((playing: boolean) => {
      if (!this.prepared || this.released) {
        return;
      }
      // mpv-arkts emits eof=true and then playing=false. Once EOF is terminal,
      // that trailing false must not downgrade COMPLETED to PAUSED.
      if (!playing && (this.completed || (this.isLooping() && this.endSignaled))) {
        return;
      }
      this.observer.onStateChange(playing ? PortPlaybackState.PLAYING : PortPlaybackState.PAUSED);
    });
    this.player.stream.eof.listen((eof: boolean) => {
      if (this.released || this.stopRequested || !this.prepared) {
        return;
      }
      this.completed = eof && !this.isLooping();
      if (eof) {
        this.emitEnd(PortStreamEndReason.EOF);
        if (!this.isLooping()) this.observer.onStateChange(PortPlaybackState.COMPLETED);
      } else this.endSignaled = false;
    });
    this.player.stream.buffering.listen((buffering: boolean) => {
      if (this.released) return;
      this.observer.onBufferingChange(
        buffering ? PortBufferingEvent.START : PortBufferingEvent.END,
        0
      );
    });
    this.player.stream.bufferingPercentage.listen((percent: number) => {
      if (this.released) return;
      this.observer.onBufferingChange(
        PortBufferingEvent.PERCENT,
        Math.max(0, Math.min(100, percent))
      );
    });
    this.player.stream.buffer.listen((seconds: number) => {
      if (this.released) return;
      this.observer.onBufferingChange(
        PortBufferingEvent.CACHED_DURATION,
        Math.max(0, Math.round(seconds * 1000))
      );
    });
    this.player.stream.videoParams.listen((params) => {
      if (this.released) return;
      const width: number = params.dw > 0 ? params.dw : params.w;
      const height: number = params.dh > 0 ? params.dh : params.h;
      if (width > 0 && height > 0) {
        this.observer.onVideoSizeChange(width, height);
      }
      this.observer.onVideoInfoChange(new PortVideoInfo(
        params.pixelFormat,
        params.hwPixelFormat,
        params.colormatrix,
        params.colorLevels,
        params.primaries,
        params.gamma,
        params.light
      ));
    });
    this.player.stream.tracks.listen((tracks: Tracks) => {
      if (this.released) return;
      this.observer.onTracksChange(this.mapTracks(tracks, this.player.state.track));
    });
    this.player.stream.track.listen((track: Track) => {
      if (this.released) return;
      this.observer.onTracksChange(this.mapTracks(this.player.state.tracks, track));
    });
    this.player.stream.speed.listen((rate: number) => {
      if (!this.released) this.observer.onPlaybackRateChange(rate);
    });
    this.player.stream.volume.listen((volume: number) => {
      if (!this.released) this.observer.onVolumeChange(Math.max(0, Math.min(1, volume / 100)));
    });
    this.player.stream.error.listen((detail: string) => {
      // The wrapper emits error-level log lines, not structured fatal errors.
      if (!this.released) {
        this.latestErrorLog = detail;
        this.observer.onWarning('native-log', new PlaybackPortError(0, detail));
      }
    });
  }

  private failIdlePlaylist(): void {
    if (this.released || !this.playlistHandoff) return;
    this.playlistHandoff = false;
    this.observer.onError(new PlaybackPortError(5400105, 'MPV became idle before the next playlist item loaded'));
  }

  private emitEnd(reason: PortStreamEndReason): void {
    if (this.endSignaled) return;
    this.endSignaled = true;
    this.observer.onStreamEnd(new PortStreamEnd(reason, this.isLooping(),
      reason === PortStreamEndReason.UNKNOWN ? this.latestErrorLog : ''));
  }

  private isLooping(): boolean {
    return this.loopMode !== PlaybackLoopMode.SEQUENCE;
  }

  private mapTracks(tracks: Tracks, selected: Track): PortTrack[] {
    const result: PortTrack[] = [];
    const details: Map<string, PortTrack> = this.audioTrackDetails();
    for (const track of tracks.video) {
      result.push(new PortTrack(track.id, PortTrackKind.VIDEO, track.codec, track.lang,
        track.title, selected.video.id === track.id));
    }
    for (const track of tracks.audio) {
      const info: PortTrack | undefined = details.get(track.id);
      result.push(new PortTrack(track.id, PortTrackKind.AUDIO, track.codec, track.lang,
        track.title, selected.audio.id === track.id, info?.channels ?? 0, info?.sampleRate ?? 0,
        info?.bitrate ?? 0, info?.isDefault ?? null));
    }
    for (const track of tracks.subs) {
      result.push(new PortTrack(track.id, PortTrackKind.SUBTITLE, track.codec, track.lang,
        track.title, selected.subs.id === track.id));
    }
    return result;
  }

  private audioTrackDetails(): Map<string, PortTrack> {
    const result: Map<string, PortTrack> = new Map();
    const count: number = this.audioPropertyNumber('track-list/count');
    if (!Number.isInteger(count) || count > 512) return result;
    for (let index: number = 0; index < count; index++) {
      const prefix: string = `track-list/${index}/`;
      if (this.audioPropertyText(`${prefix}type`) !== 'audio') continue;
      const id: string = this.audioPropertyText(`${prefix}id`);
      const flag: string = this.audioPropertyText(`${prefix}default`);
      result.set(id, new PortTrack(id, PortTrackKind.AUDIO, '', '', '', false,
        this.audioPropertyNumber(`${prefix}demux-channel-count`),
        this.audioPropertyNumber(`${prefix}demux-samplerate`), this.audioPropertyNumber(`${prefix}demux-bitrate`),
        flag === 'yes' ? true : (flag === 'no' ? false : null)));
    }
    return result;
  }

  private audioPropertyText(name: string): string {
    try { return this.player.native.getPropertyString(name) ?? ''; } catch (_error) { return ''; }
  }

  private audioPropertyNumber(name: string): number {
    try { return this.player.native.getProperty(name) ?? 0; } catch (_error) { return 0; }
  }

  private failPrepare(error: PlaybackPortError): void {
    const reject: ((error: PlaybackPortError) => void) | null = this.prepareReject;
    this.prepareResolve = null;
    this.prepareReject = null;
    this.clearPrepareTimer();
    reject?.(error);
  }

  private clearPrepareTimer(): void {
    if (this.prepareTimer >= 0) {
      clearTimeout(this.prepareTimer);
      this.prepareTimer = -1;
    }
  }

  private ensureReady(): void {
    if (this.released || !this.prepared) {
      throw new PlaybackPortError(0, 'MPV backend is not prepared');
    }
  }
}
