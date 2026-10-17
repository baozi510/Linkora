import { PlaybackBookmarkRepository } from '../contracts/FeaturePorts';
import { MediaSource } from '../models/MediaSource';
import { PlaybackPlaylist } from '../models/PlaybackPlaylist';
import { PlaybackBookmark } from '../models/PlaybackBookmark';
import { AppSettings } from '../models/AppSettings';
import { PlaybackEngine } from '../playback/PlaybackEngine';
import { PlaybackObserver, PlaybackSnapshot, PlaybackStatus } from '../playback/PlaybackModels';
import { NetworkAccessPolicyPort } from '../contracts/NetworkPorts';
import { AppFailure } from '../errors/AppFailure';
import { MediaSourceKind } from '../models/MediaSource';
import { VideoDisplayMode, PlaybackLoopMode } from '../playback/PlaybackPort';
import { PortTrack, PortTrackKind } from '../playback/PlaybackPort';
import { AudioTrackChoice, AudioTrackPreferences, AudioTrackRepository } from '../playback/AudioTrackPreferences';

class PendingAudioSelection {
  accepted: boolean = false;
  readonly source: MediaSource;
  readonly backend: string;
  readonly id: string;
  readonly manual: boolean;
  readonly automatic: boolean;
  readonly reset: boolean;
  constructor(source: MediaSource, backend: string, id: string, manual: boolean, automatic: boolean, reset: boolean) {
    this.source = source; this.backend = backend; this.id = id;
    this.manual = manual; this.automatic = automatic; this.reset = reset;
  }
}

export type PlaybackEngineFactory = (observer: PlaybackObserver) => PlaybackEngine;

export class PlayerFeatureState {
  readonly playback: PlaybackSnapshot;
  readonly sliderPosition: number;
  readonly seeking: boolean;
  readonly playbackRate: number;
  readonly volume: number;
  readonly keepScreenOn: boolean;
  readonly audioPreferences: AudioTrackPreferences;
  readonly audioSelection: string;
  readonly audioBusy: boolean;
  readonly audioError: boolean;

  constructor(playback: PlaybackSnapshot, sliderPosition: number = 0, seeking: boolean = false,
    playbackRate: number = 1, volume: number = 1, keepScreenOn: boolean = false,
    audioPreferences: AudioTrackPreferences = new AudioTrackPreferences(), audioSelection: string = 'auto',
    audioBusy: boolean = false, audioError: boolean = false) {
    this.playback = playback;
    this.sliderPosition = sliderPosition;
    this.seeking = seeking;
    this.playbackRate = playbackRate;
    this.volume = volume;
    this.keepScreenOn = keepScreenOn;
    this.audioPreferences = audioPreferences;
    this.audioSelection = audioSelection;
    this.audioBusy = audioBusy;
    this.audioError = audioError;
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
  private readonly playlist: PlaybackPlaylist | null;
  private readonly audioRepository: AudioTrackRepository | null;
  private audioPreferences: AudioTrackPreferences = new AudioTrackPreferences();
  private audioMemory: AudioTrackChoice | null = null;
  private audioSelection: string = 'auto';
  private audioLoaded: boolean = false;
  private audioPreferencesLoaded: boolean = false;
  private audioGeneration: number = 0;
  private audioAttempt: string = '';
  private audioError: boolean = false;
  private audioStorageError: boolean = false;
  private pendingAudio: PendingAudioSelection | null = null;
  private audioTimer: number = -1;

  constructor(source: MediaSource, engineFactory: PlaybackEngineFactory,
    bookmarkRepository: PlaybackBookmarkRepository, settings: AppSettings,
    observer: PlayerFeatureObserver, accessPolicy: NetworkAccessPolicyPort | null = null,
    playlist: PlaybackPlaylist | null = null, audioRepository: AudioTrackRepository | null = null) {
    this.source = source;
    this.playlist = playlist;
    this.audioRepository = audioRepository;
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

  setSurfaceSize(width: number, height: number): void {
    if (this.active) {
      this.engine.setSurfaceSize(width, height);
    }
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
    ++this.audioGeneration;
    this.cancelAudioSelection();
    this.engine.release().catch(() => {});
  }

  togglePlayback(): void {
    if (this.state.playback.status === PlaybackStatus.STOPPED && this.surfaceId.length > 0) {
      this.open(++this.requestId, false).catch(() => {});
      return;
    }
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
    if (!Number.isFinite(rate)) return;
    const normalized: number = Math.max(0.5, Math.min(rate, 2));
    this.engine.setPlaybackRate(normalized);
  }

  setVolume(volume: number): void {
    if (!Number.isFinite(volume)) return;
    const normalized: number = Math.max(0, Math.min(volume, 1));
    this.engine.setVolume(normalized);
  }

  cycleLoopMode(): void {
    const mode: PlaybackLoopMode = this.state.playback.loopMode;
    this.setLoopMode(mode === PlaybackLoopMode.SEQUENCE ? PlaybackLoopMode.SINGLE :
      (mode === PlaybackLoopMode.SINGLE ? PlaybackLoopMode.LIST : PlaybackLoopMode.SEQUENCE));
  }

  setLoopMode(mode: PlaybackLoopMode): void {
    if (this.active) this.engine.setLoopMode(mode);
  }

  nextPlaylistItem(): void {
    this.selectPlaylistItem(this.state.playback.playlistIndex + 1);
  }

  previousPlaylistItem(): void {
    this.selectPlaylistItem(this.state.playback.playlistIndex - 1);
  }

  selectPlaylistItem(index: number): void {
    if (this.active && this.state.playback.playlistIndex >= 0) {
      this.engine.selectPlaylistItem(index).catch(() => {});
    }
  }

  cycleDisplayMode(): void {
    const mode: VideoDisplayMode | null = this.state.playback.displayMode;
    this.engine.setDisplayMode(mode === VideoDisplayMode.FIT ? VideoDisplayMode.CROP :
      (mode === VideoDisplayMode.CROP ? VideoDisplayMode.STRETCH : VideoDisplayMode.FIT));
  }

  stopPlayback(): void {
    this.persistBookmark(this.state.playback, true);
    this.engine.stop().catch(() => {});
  }

  selectAudioTrack(id: string): void {
    if (!this.active || !this.audioLoaded || this.pendingAudio !== null) return;
    if (id === 'auto') {
      const preferred: PortTrack | null = this.audioPreferences.choose(this.state.playback.tracks, null);
      this.startAudioSelection(preferred?.id ?? 'auto', false, true, true);
    } else {
      this.startAudioSelection(id, true, false, false);
    }
  }

  setAudioPreferences(languages: string, remember: boolean): void {
    if (!this.active || this.pendingAudio !== null) return;
    try {
      const value: AudioTrackPreferences = new AudioTrackPreferences(
        languages.trim().length === 0 ? [] : languages.split(','), remember);
      this.audioPreferences = value;
      this.audioPreferencesLoaded = true;
      this.audioError = false;
      this.audioAttempt = '';
      this.audioRepository?.savePreferences(value).then(() => {
        if (this.active) { this.audioStorageError = false; this.refreshAudioState(); }
      }).catch(() => { if (this.active) { this.audioStorageError = true; this.refreshAudioState(); } });
      if (!this.audioLoaded) {
        this.loadAudioPreferences(this.source).then(() => this.applyAudioPreference(this.state.playback));
      } else {
        const preferred: PortTrack | null = value.choose(this.state.playback.tracks, this.audioMemory);
        this.startAudioSelection(preferred?.id ?? 'auto', false, true, false);
      }
      this.refreshAudioState();
    } catch (_error) {
      this.audioError = true;
      this.refreshAudioState();
    }
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
    ++this.audioGeneration;
    this.cancelAudioSelection();
    ++this.requestId;
    this.persistBookmark(this.state.playback, true);
    this.engine.release().catch(() => {});
  }

  private async open(requestId: number, resumeBookmark: boolean = true): Promise<void> {
    await this.loadAudioPreferences(this.source);
    if (!this.active || requestId !== this.requestId) return;
    if ((this.source.kind === MediaSourceKind.NETWORK_LINK || this.source.kind === MediaSourceKind.REMOTE_FILE) &&
      this.accessPolicy !== null) {
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
    const bookmark: PlaybackBookmark | null = this.settings.rememberPlaybackPosition && resumeBookmark ?
      await this.bookmarkRepository.load(this.source) : null;
    if (!this.active || requestId !== this.requestId || this.surfaceId.length === 0) {
      return;
    }
    const resumePosition: number = bookmark === null ? 0 : bookmark.resumePosition();
    this.lastSavedPosition = resumePosition;
    const index: number = this.state.playback.playlistIndex;
    const playlist: PlaybackPlaylist | null = this.playlist === null ? null :
      new PlaybackPlaylist(this.playlist.items, index >= 0 ? index : this.playlist.startIndex, this.playlist.complete);
    await this.engine.open(this.source, this.surfaceId, resumePosition, playlist);
  }

  private applyPlayback(playback: PlaybackSnapshot): void {
    if (!this.active) {
      return;
    }
    const changed: boolean = this.playlist !== null && playback.playlistIndex >= 0 &&
      playback.playlistIndex !== this.state.playback.playlistIndex;
    if (changed && this.playlist !== null) {
      this.persistBookmark(this.state.playback, true);
      this.source = this.playlist.items[playback.playlistIndex].source;
      this.lastSavedPosition = 0;
      this.loadAudioPreferences(this.source).then(() => this.applyAudioPreference(this.state.playback));
    } else if (playback.backend !== this.state.playback.backend) {
      this.cancelAudioSelection();
      this.audioSelection = 'auto';
      this.audioAttempt = '';
    }
    if (playback.status === PlaybackStatus.COMPLETED) {
      this.bookmarkRepository.clear(this.source).catch(() => {});
      this.lastSavedPosition = 0;
    } else {
      this.persistBookmark(playback, false);
    }
    const seeking: boolean = this.state.seeking && !changed;
    const sliderPosition: number = seeking ? this.state.sliderPosition : playback.position;
    const keepScreenOn: boolean = this.settings.keepScreenOnDuringPlayback &&
      (playback.status === PlaybackStatus.PLAYING || playback.status === PlaybackStatus.BUFFERING);
    this.update(playback, sliderPosition, seeking, playback.playbackRate,
      playback.volume, keepScreenOn);
    this.completeAudioSelection();
    this.applyAudioPreference(playback);
  }

  private async loadAudioPreferences(source: MediaSource): Promise<void> {
    const generation: number = ++this.audioGeneration;
    this.cancelAudioSelection();
    this.audioLoaded = false;
    this.audioSelection = 'auto';
    this.audioMemory = null;
    this.audioAttempt = '';
    this.refreshAudioState();
    try {
      const preferences: AudioTrackPreferences = this.audioPreferencesLoaded ? this.audioPreferences :
        await this.audioRepository?.loadPreferences() ?? new AudioTrackPreferences();
      const memory: AudioTrackChoice | null = preferences.remember ?
        await this.audioRepository?.loadChoice(source) ?? null : null;
      if (!this.active || generation !== this.audioGeneration || source !== this.source) return;
      this.audioPreferences = preferences;
      this.audioPreferencesLoaded = true;
      this.audioMemory = memory;
    } catch (_error) {
      if (!this.active || generation !== this.audioGeneration) return;
      this.audioStorageError = true;
    }
    if (generation === this.audioGeneration) {
      this.audioLoaded = true;
      this.refreshAudioState();
    }
  }

  private applyAudioPreference(playback: PlaybackSnapshot): void {
    if (!this.active || !this.audioLoaded || this.pendingAudio !== null || this.audioSelection !== 'auto') return;
    const tracks: PortTrack[] = playback.tracks.filter((track: PortTrack) => track.kind === PortTrackKind.AUDIO);
    if (tracks.length === 0) return;
    const signature: string = playback.backend + JSON.stringify(tracks.map((track: PortTrack) =>
      [track.id, track.language, track.title, track.channels, track.isDefault]));
    if (signature === this.audioAttempt) return;
    this.audioAttempt = signature;
    const preferred: PortTrack | null = this.audioPreferences.choose(tracks, this.audioMemory);
    const restored: boolean = this.audioPreferences.remember && preferred !== null &&
      this.audioMemory?.match(tracks)?.id === preferred.id;
    this.startAudioSelection(preferred?.id ?? 'auto', false, !restored, false);
  }

  private startAudioSelection(id: string, manual: boolean, automatic: boolean, reset: boolean): void {
    if (!this.audioLoaded || this.pendingAudio !== null) return;
    const pending: PendingAudioSelection = new PendingAudioSelection(this.source, this.state.playback.backend,
      id, manual, automatic, reset);
    this.pendingAudio = pending;
    this.audioError = false;
    this.audioTimer = setTimeout(() => {
      if (this.pendingAudio !== pending) return;
      this.cancelAudioSelection(); this.audioError = true; this.refreshAudioState();
    }, 5000);
    this.refreshAudioState();
    this.engine.selectAudioTrack(id).then((accepted: boolean) => {
      if (!this.active || this.pendingAudio !== pending || this.source !== pending.source) return;
      if (!accepted) {
        this.cancelAudioSelection(); this.audioError = true; this.refreshAudioState(); return;
      }
      pending.accepted = true;
      this.completeAudioSelection();
    }).catch(() => {
      if (this.pendingAudio === pending) {
        this.cancelAudioSelection(); this.audioError = true; this.refreshAudioState();
      }
    });
  }

  private completeAudioSelection(): void {
    const pending: PendingAudioSelection | null = this.pendingAudio;
    if (pending === null || !pending.accepted || pending.source !== this.source ||
      pending.backend !== this.state.playback.backend) return;
    const selected: PortTrack | undefined = this.state.playback.tracks.find((track: PortTrack) =>
      track.kind === PortTrackKind.AUDIO && track.selected && track.id === pending.id);
    if (pending.id !== 'auto' && selected === undefined) return;
    this.cancelAudioSelection();
    this.audioSelection = pending.automatic ? 'auto' : pending.id;
    if (pending.reset || (pending.manual && this.audioPreferences.remember && selected !== undefined)) {
      this.audioMemory = pending.reset ? null : AudioTrackChoice.from(selected as PortTrack);
      this.audioRepository?.saveChoice(pending.source, this.audioMemory).catch(() => {
        if (this.active && this.source === pending.source) {
          this.audioStorageError = true; this.refreshAudioState();
        }
      });
    }
    this.refreshAudioState();
  }

  private cancelAudioSelection(): void {
    if (this.audioTimer !== -1) clearTimeout(this.audioTimer);
    this.audioTimer = -1;
    this.pendingAudio = null;
  }

  private refreshAudioState(): void {
    this.update(this.state.playback, this.state.sliderPosition, this.state.seeking,
      this.state.playbackRate, this.state.volume, this.state.keepScreenOn);
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
      playbackRate, volume, keepScreenOn, this.audioPreferences, this.audioSelection,
      !this.audioLoaded || this.pendingAudio !== null, this.audioError || this.audioStorageError);
    if (this.active) {
      this.observer(this.state);
    }
  }
}
