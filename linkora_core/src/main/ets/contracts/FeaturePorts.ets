import { LocalMediaAsset } from '../models/LocalMediaAsset';
import { LocalMediaFolder, LocalMediaScanOptions } from '../models/LocalMediaFolder';
import { LocalMediaPlaybackProgress } from '../models/LocalMediaPlaybackProgress';
import { MediaSource } from '../models/MediaSource';
import { PlaybackBookmark } from '../models/PlaybackBookmark';
import { RecentMediaItem } from '../models/RecentMediaItem';
import { AppSettings } from '../models/AppSettings';
import { LocalFileCategory, LocalFileFilter } from '../models/LocalFileFilter';

export class LocalMediaPermissionResult {
  readonly granted: boolean;
  readonly errorCode: number;

  constructor(granted: boolean, errorCode: number = 0) {
    this.granted = granted;
    this.errorCode = errorCode;
  }
}

export class LocalMediaScanResult {
  readonly items: LocalMediaAsset[];
  readonly folders: LocalMediaFolder[];
  readonly selectedFolderUri: string;
  readonly errorCode: number;
  readonly snapshotComplete: boolean;
  readonly generation: number;
  readonly completedAt: number;
  /** Lightweight source signature used to validate a cached snapshot after a cold start. */
  readonly fingerprint: string;
  /** False when fresh source data was returned but could not be committed to the local index. */
  readonly cachePersisted: boolean;

  constructor(items: LocalMediaAsset[], folders: LocalMediaFolder[] = [], selectedFolderUri: string = '',
    errorCode: number = 0, snapshotComplete: boolean = true, generation: number = 0,
    completedAt: number = 0, fingerprint: string = '', cachePersisted: boolean = true) {
    this.items = items;
    this.folders = folders;
    this.selectedFolderUri = selectedFolderUri;
    this.errorCode = errorCode;
    this.snapshotComplete = snapshotComplete;
    this.generation = Math.max(0, generation);
    this.completedAt = Math.max(0, completedAt);
    this.fingerprint = fingerprint;
    this.cachePersisted = cachePersisted;
  }

  succeeded(): boolean {
    return this.errorCode === 0;
  }
}

export class LocalMediaPickResult {
  readonly sources: MediaSource[];
  readonly errorCode: number;

  constructor(sources: MediaSource[] = [], errorCode: number = 0) {
    this.sources = sources;
    this.errorCode = errorCode;
  }

  succeeded(): boolean {
    return this.errorCode === 0;
  }
}

export interface MediaLibraryGateway {
  isAuthorized(): Promise<boolean>;
  requestAuthorization(): Promise<LocalMediaPermissionResult>;
  /** Loads the last completed media-library snapshot without accessing the system media library. */
  loadCached(): Promise<LocalMediaScanResult | null>;
  /** Loads one directory from the current completed index snapshot. An empty directory is a valid cache hit. */
  loadCachedDirectory(directoryUri: string): Promise<LocalMediaScanResult | null>;
  /** Reads a lightweight source signature without rebuilding the complete media index. */
  probeFingerprint(): Promise<string>;
  observeChanges(observer: () => void): void;
  stopObservingChanges(): void;
  /** Refreshes the media-library index. The result is source data, not a page projection. */
  scan(options?: LocalMediaScanOptions): Promise<LocalMediaScanResult>;
  /** Loads one directory. The current media-library adapter maps a directory to a system album. */
  scanDirectory(directoryUri: string, options?: LocalMediaScanOptions): Promise<LocalMediaScanResult>;
}

export interface LocalFilePickerGateway {
  pick(fileFilter?: LocalFileFilter,
    categories?: LocalFileCategory[], maxSelectNumber?: number): Promise<LocalMediaPickResult>;
}

export interface ManualMediaRepository {
  load(): Promise<LocalMediaAsset[]>;
  loadFolders(): Promise<LocalMediaFolder[]>;
  add(sources: MediaSource[], parentUri?: string): Promise<LocalMediaAsset[]>;
  reauthorize(uri: string, source: MediaSource): Promise<LocalMediaAsset[]>;
  createFolder(parentUri: string, name: string): Promise<LocalMediaFolder[]>;
  renameFolder(uri: string, name: string): Promise<LocalMediaFolder[]>;
  removeFolder(uri: string): Promise<void>;
  verify(): Promise<LocalMediaAsset[]>;
  remove(uri: string): Promise<LocalMediaAsset[]>;
  removeUnavailable(): Promise<LocalMediaAsset[]>;
}

export interface RecentMediaRepository {
  load(): Promise<RecentMediaItem[]>;
  record(source: MediaSource): Promise<RecentMediaItem[]>;
}

export interface PlaybackBookmarkRepository {
  load(source: MediaSource): Promise<PlaybackBookmark | null>;
  save(source: MediaSource, bookmark: PlaybackBookmark): Promise<void>;
  clear(source: MediaSource): Promise<void>;
}

export interface LocalMediaProgressRepository {
  loadFor(items: LocalMediaAsset[]): Promise<LocalMediaPlaybackProgress[]>;
}

export interface SettingsRepository {
  load(): Promise<AppSettings>;
  save(settings: AppSettings): Promise<void>;
}

export interface PlayerBrightnessPort {
  initialize(): Promise<void>;
  currentValue(): number;
  set(value: number): void;
  restore(): void;
}
