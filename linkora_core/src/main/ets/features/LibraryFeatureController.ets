import { LocalFilePickerGateway, LocalMediaPickResult, LocalMediaPermissionResult,
  LocalMediaProgressRepository, ManualMediaRepository, MediaLibraryGateway, LocalMediaScanResult,
  RecentMediaRepository } from '../contracts/FeaturePorts';
import { AppFailure } from '../errors/AppFailure';
import { FailureCatalog } from '../errors/FailureCatalog';
import { LocalMediaAsset } from '../models/LocalMediaAsset';
import { LocalMediaCatalog, LocalMediaCatalogView } from '../models/LocalMediaCatalog';
import { LocalBrowseMode, LocalFileFilter } from '../models/LocalFileFilter';
import { LocalMediaFolder, LocalMediaFolderFilter,
  LocalMediaScanOptions } from '../models/LocalMediaFolder';
import { LocalMediaScanState } from '../models/LocalMediaScanState';
import { LocalMediaPlaybackProgress } from '../models/LocalMediaPlaybackProgress';
import { MediaSource } from '../models/MediaSource';
import { RecentMediaItem } from '../models/RecentMediaItem';

export class LibraryFeatureState {
  readonly recentItems: RecentMediaItem[];
  readonly localItems: LocalMediaAsset[];
  readonly localFolders: LocalMediaFolder[];
  readonly selectedFolderUri: string;
  readonly folderFilter: LocalMediaFolderFilter;
  readonly browseMode: LocalBrowseMode;
  readonly fileFilter: LocalFileFilter;
  readonly scanState: LocalMediaScanState;
  readonly localFailure: AppFailure | null;
  readonly scanFailure: AppFailure | null;
  readonly refreshing: boolean;
  readonly snapshotGeneration: number;
  readonly lastSyncedAt: number;
  readonly playbackProgress: LocalMediaPlaybackProgress[];

  constructor(recentItems: RecentMediaItem[] = [], localItems: LocalMediaAsset[] = [],
    scanState: LocalMediaScanState = LocalMediaScanState.IDLE,
    localFailure: AppFailure | null = null, scanFailure: AppFailure | null = null,
    localFolders: LocalMediaFolder[] = [], selectedFolderUri: string = '',
    folderFilter: LocalMediaFolderFilter = LocalMediaFolderFilter.VIDEO_ONLY,
    browseMode: LocalBrowseMode = LocalBrowseMode.DIRECTORY,
    fileFilter: LocalFileFilter = new LocalFileFilter(), refreshing: boolean = false,
    snapshotGeneration: number = 0, lastSyncedAt: number = 0,
    playbackProgress: LocalMediaPlaybackProgress[] = []) {
    this.recentItems = recentItems;
    this.localItems = localItems;
    this.localFolders = localFolders;
    this.selectedFolderUri = selectedFolderUri;
    this.folderFilter = folderFilter;
    this.browseMode = browseMode;
    this.fileFilter = fileFilter;
    this.scanState = scanState;
    this.localFailure = localFailure;
    this.scanFailure = scanFailure;
    this.refreshing = refreshing;
    this.snapshotGeneration = Math.max(0, snapshotGeneration);
    this.lastSyncedAt = Math.max(0, lastSyncedAt);
    this.playbackProgress = playbackProgress;
  }
}

export type LibraryFeatureObserver = (state: LibraryFeatureState) => void;

export class LibraryFeatureController {
  private static readonly CHANGE_DEBOUNCE_MS: number = 300;
  private static readonly FULL_RECONCILE_INTERVAL_MS: number = 6 * 60 * 60 * 1000;
  private mediaLibrary: MediaLibraryGateway;
  private filePicker: LocalFilePickerGateway;
  private recentRepository: RecentMediaRepository;
  private manualRepository: ManualMediaRepository | null;
  private progressRepository: LocalMediaProgressRepository | null;
  private observer: LibraryFeatureObserver;
  private state: LibraryFeatureState = new LibraryFeatureState();
  private catalogItems: LocalMediaAsset[] = [];
  private catalogFolders: LocalMediaFolder[] = [];
  private manualItems: LocalMediaAsset[] = [];
  private manualFolders: LocalMediaFolder[] = [];
  private cachedDirectoryUris: string[] = [];
  private cachedDirectoryItems: LocalMediaAsset[][] = [];
  private requestId: number = 0;
  private active: boolean = true;
  private observingChanges: boolean = false;
  private refreshAfterScan: boolean = false;
  private refreshQueued: boolean = false;
  private manualRequestId: number = 0;
  private progressRequestId: number = 0;
  private cachedFingerprint: string = '';
  private changeDebounceTimer: number = -1;

  constructor(mediaLibrary: MediaLibraryGateway, filePicker: LocalFilePickerGateway,
    recentRepository: RecentMediaRepository, observer: LibraryFeatureObserver,
    manualRepository: ManualMediaRepository | null = null,
    progressRepository: LocalMediaProgressRepository | null = null) {
    this.mediaLibrary = mediaLibrary;
    this.filePicker = filePicker;
    this.recentRepository = recentRepository;
    this.observer = observer;
    this.manualRepository = manualRepository;
    this.progressRepository = progressRepository;
  }

  async initialize(): Promise<void> {
    const requestId: number = ++this.requestId;
    const recentItems: RecentMediaItem[] = await this.recentRepository.load();
    if (!this.isCurrent(requestId)) {
      return;
    }
    this.update(recentItems, this.state.localItems, this.state.scanState,
      this.state.localFailure, this.state.scanFailure);
    await this.loadManualItems(requestId);
    if (!this.isCurrent(requestId)) {
      return;
    }
    this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
      this.state.browseMode, this.state.fileFilter, false);
    this.verifyManualItems();
    if (await this.mediaLibrary.isAuthorized() && this.isCurrent(requestId)) {
      this.startObservingChanges();
      const cacheLoaded: boolean = await this.loadCached(requestId);
      if (this.isCurrent(requestId)) {
        const refreshRequired: boolean = !cacheLoaded ||
          await this.cachedSnapshotNeedsRefresh(requestId);
        if (this.isCurrent(requestId) && refreshRequired) {
          await this.loadLocal(requestId, cacheLoaded);
        }
      }
    }
    await this.refreshPlaybackProgress();
  }

  async recordOpened(source: MediaSource): Promise<void> {
    const recentItems: RecentMediaItem[] = await this.recentRepository.record(source);
    if (this.active) {
      this.update(recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, this.state.scanFailure);
    }
  }

  async pickLocal(parentUri: string = this.state.selectedFolderUri,
    onCompleted: (added: number, skipped: number) => void = () => {}): Promise<number> {
    if (!this.canManageVirtualEntries(parentUri)) {
      return 0;
    }
    const result: LocalMediaPickResult = await this.filePicker.pick(this.state.fileFilter);
    if (!this.active) {
      return 0;
    }
    if (!result.succeeded()) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        FailureCatalog.fromLocalFileError(result.errorCode), this.state.scanFailure);
      return 0;
    }
    if (result.sources.length === 0) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        null, this.state.scanFailure);
      return 0;
    }
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (repository === null) {
      return 0;
    }
    const requestId: number = ++this.manualRequestId;
    try {
      const previousUris: Set<string> = new Set<string>(
        this.manualItems.map((item: LocalMediaAsset): string => item.uri));
      const sources: MediaSource[] = LocalMediaCatalog.newManualSources(result.sources, [], parentUri);
      const items: LocalMediaAsset[] = await repository.add(sources, parentUri);
      if (!this.active || requestId !== this.manualRequestId) {
        return 0;
      }
      this.manualItems = items;
      this.manualFolders = await repository.loadFolders();
      if (!this.active || requestId !== this.manualRequestId) {
        return 0;
      }
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        null, this.state.scanFailure);
      this.projectLocal(parentUri, this.state.folderFilter, this.state.browseMode,
        this.state.fileFilter, this.state.refreshing);
      this.refreshPlaybackProgress().catch(() => {});
      const added: number = items.filter((item: LocalMediaAsset): boolean =>
        item.parentUri === parentUri && !previousUris.has(item.uri)).length;
      onCompleted(added, result.sources.length - added);
      return added;
    } catch (_error) {
      if (this.active && requestId === this.manualRequestId) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(), this.state.scanFailure);
      }
      return 0;
    }
  }

  async reauthorizeManual(uri: string): Promise<boolean> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    const item: LocalMediaAsset | undefined = this.manualItems.find((entry: LocalMediaAsset): boolean =>
      entry.uri === uri);
    if (!this.active || repository === null || item === undefined) {
      return false;
    }
    const requestId: number = ++this.manualRequestId;
    try {
      const result: LocalMediaPickResult = await this.filePicker.pick(this.state.fileFilter,
        [item.category], 1);
      if (!this.active || requestId !== this.manualRequestId) {
        return false;
      }
      if (!result.succeeded()) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(result.errorCode), this.state.scanFailure);
        return false;
      }
      if (result.sources.length === 0) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          null, this.state.scanFailure);
        return false;
      }
      if (result.sources.length !== 1 || result.sources[0].localCategory !== item.category) {
        throw new Error('Choose one file of the original category');
      }
      const items: LocalMediaAsset[] = await repository.reauthorize(uri, result.sources[0]);
      const folders: LocalMediaFolder[] = await repository.loadFolders();
      if (!this.active || requestId !== this.manualRequestId) {
        return false;
      }
      this.manualItems = items;
      this.manualFolders = folders;
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        null, this.state.scanFailure);
      this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
        this.state.browseMode, this.state.fileFilter, this.state.refreshing);
      this.refreshPlaybackProgress().catch(() => {});
      return true;
    } catch (_error) {
      if (this.active && requestId === this.manualRequestId) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(), this.state.scanFailure);
      }
      return false;
    }
  }

  canManageVirtualEntries(folderUri: string = this.state.selectedFolderUri): boolean {
    return folderUri.length === 0 || this.isVirtualFolder(folderUri);
  }

  async createVirtualFolder(name: string,
    parentUri: string = this.state.selectedFolderUri): Promise<boolean> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (!this.active || repository === null || !this.canManageVirtualEntries(parentUri)) {
      return false;
    }
    const requestId: number = ++this.manualRequestId;
    try {
      this.manualFolders = await repository.createFolder(parentUri, name);
      if (!this.active || requestId !== this.manualRequestId) {
        return false;
      }
      this.projectLocal(parentUri, this.state.folderFilter, this.state.browseMode,
        this.state.fileFilter, this.state.refreshing);
      return true;
    } catch (_error) {
      if (this.active && requestId === this.manualRequestId) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(), this.state.scanFailure);
      }
      return false;
    }
  }

  async renameVirtualFolder(uri: string, name: string): Promise<boolean> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (!this.active || repository === null || !this.isVirtualFolder(uri)) {
      return false;
    }
    const requestId: number = ++this.manualRequestId;
    try {
      this.manualFolders = await repository.renameFolder(uri, name);
      if (!this.active || requestId !== this.manualRequestId) {
        return false;
      }
      this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
        this.state.browseMode, this.state.fileFilter, this.state.refreshing);
      return true;
    } catch (_error) {
      if (this.active && requestId === this.manualRequestId) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(), this.state.scanFailure);
      }
      return false;
    }
  }

  async removeVirtualFolder(uri: string): Promise<boolean> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (!this.active || repository === null || !this.isVirtualFolder(uri)) {
      return false;
    }
    const requestId: number = ++this.manualRequestId;
    try {
      await repository.removeFolder(uri);
      const items: LocalMediaAsset[] = await repository.load();
      const folders: LocalMediaFolder[] = await repository.loadFolders();
      if (!this.active || requestId !== this.manualRequestId) {
        return false;
      }
      this.manualItems = items;
      this.manualFolders = folders;
      const selectedUri: string = this.isVirtualFolder(this.state.selectedFolderUri) ?
        this.state.selectedFolderUri : '';
      this.projectLocal(selectedUri, this.state.folderFilter, this.state.browseMode,
        this.state.fileFilter, this.state.refreshing);
      this.refreshPlaybackProgress().catch(() => {});
      return true;
    } catch (_error) {
      if (this.active && requestId === this.manualRequestId) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(), this.state.scanFailure);
      }
      return false;
    }
  }

  async removeManual(uri: string): Promise<void> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (!this.active || repository === null) {
      return;
    }
    const requestId: number = ++this.manualRequestId;
    try {
      const items: LocalMediaAsset[] = await repository.remove(uri);
      const folders: LocalMediaFolder[] = await repository.loadFolders();
      if (!this.active || requestId !== this.manualRequestId) {
        return;
      }
      this.manualItems = items;
      this.manualFolders = folders;
      this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
        this.state.browseMode, this.state.fileFilter, this.state.refreshing);
      this.refreshPlaybackProgress().catch(() => {});
    } catch (_error) {
      if (this.active && requestId === this.manualRequestId) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(), this.state.scanFailure);
      }
    }
  }

  async removeUnavailableManual(): Promise<void> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (!this.active || repository === null) {
      return;
    }
    const requestId: number = ++this.manualRequestId;
    try {
      const items: LocalMediaAsset[] = await repository.removeUnavailable();
      const folders: LocalMediaFolder[] = await repository.loadFolders();
      if (!this.active || requestId !== this.manualRequestId) {
        return;
      }
      this.manualItems = items;
      this.manualFolders = folders;
      this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
        this.state.browseMode, this.state.fileFilter, this.state.refreshing);
      this.refreshPlaybackProgress().catch(() => {});
    } catch (_error) {
      if (this.active && requestId === this.manualRequestId) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          FailureCatalog.fromLocalFileError(), this.state.scanFailure);
      }
    }
  }

  async scanLocal(): Promise<void> {
    if (this.state.scanState === LocalMediaScanState.SCANNING || this.state.refreshing) {
      return;
    }
    const requestId: number = ++this.requestId;
    if (this.isVirtualFolder(this.state.selectedFolderUri)) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, null, this.state.localFolders, this.state.selectedFolderUri,
        this.state.folderFilter, this.state.browseMode, this.state.fileFilter, true);
      await this.reloadManualProjection(requestId);
      return;
    }
    const preserveExisting: boolean = this.state.scanState === LocalMediaScanState.READY ||
      this.state.scanState === LocalMediaScanState.EMPTY;
    if (preserveExisting) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, null, this.state.localFolders, this.state.selectedFolderUri,
        this.state.folderFilter, this.state.browseMode, this.state.fileFilter, true);
    } else {
      this.update(this.state.recentItems, this.state.localItems, LocalMediaScanState.SCANNING,
        this.state.localFailure, null, this.state.localFolders, this.state.selectedFolderUri,
        this.state.folderFilter, this.state.browseMode, this.state.fileFilter, true);
    }
    const permission: LocalMediaPermissionResult = await this.mediaLibrary.requestAuthorization();
    if (!this.isCurrent(requestId)) {
      return;
    }
    if (!permission.granted) {
      this.update(this.state.recentItems, this.state.localItems, LocalMediaScanState.PERMISSION_DENIED,
        this.state.localFailure, null,
        this.state.localFolders, this.state.selectedFolderUri, this.state.folderFilter,
        this.state.browseMode, this.state.fileFilter, false);
      return;
    }
    this.startObservingChanges();
    await this.loadCurrentLocal(requestId, preserveExisting);
  }

  async refreshPlaybackProgress(): Promise<void> {
    const repository: LocalMediaProgressRepository | null = this.progressRepository;
    if (!this.active || repository === null) {
      return;
    }
    const requestId: number = ++this.progressRequestId;
    const progress: LocalMediaPlaybackProgress[] = await repository.loadFor(this.state.localItems);
    if (!this.active || requestId !== this.progressRequestId ||
      LibraryFeatureController.sameProgress(this.state.playbackProgress, progress)) {
      return;
    }
    this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
      this.state.localFailure, this.state.scanFailure, this.state.localFolders,
      this.state.selectedFolderUri, this.state.folderFilter, this.state.browseMode,
      this.state.fileFilter, this.state.refreshing, this.state.snapshotGeneration,
      this.state.lastSyncedAt, progress);
  }

  async setFolderFilter(filter: LocalMediaFolderFilter): Promise<void> {
    if (!this.active || filter === this.state.folderFilter) {
      return;
    }
    if (this.state.scanState === LocalMediaScanState.IDLE ||
      this.state.scanState === LocalMediaScanState.PERMISSION_DENIED) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, this.state.scanFailure, this.state.localFolders,
        this.state.selectedFolderUri, filter);
      return;
    }
    this.projectLocal(this.state.selectedFolderUri, filter, this.state.browseMode,
      this.state.fileFilter);
  }

  async setBrowseMode(mode: LocalBrowseMode): Promise<void> {
    if (!this.active || mode === this.state.browseMode) {
      return;
    }
    if (this.state.scanState === LocalMediaScanState.IDLE ||
      this.state.scanState === LocalMediaScanState.PERMISSION_DENIED) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, this.state.scanFailure, this.state.localFolders, '',
        this.state.folderFilter, mode);
      return;
    }
    this.projectLocal('', this.state.folderFilter, mode, this.state.fileFilter);
  }

  async setFileFilter(filter: LocalFileFilter): Promise<void> {
    if (!this.active || LibraryFeatureController.sameFilter(filter, this.state.fileFilter)) {
      return;
    }
    if (this.state.scanState === LocalMediaScanState.IDLE ||
      this.state.scanState === LocalMediaScanState.PERMISSION_DENIED) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, this.state.scanFailure, this.state.localFolders,
        this.state.selectedFolderUri, this.state.folderFilter, this.state.browseMode, filter);
      return;
    }
    this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
      this.state.browseMode, filter);
  }

  async selectFolder(folderUri: string): Promise<void> {
    if (!this.active || this.state.browseMode !== LocalBrowseMode.DIRECTORY ||
      folderUri === this.state.selectedFolderUri) {
      return;
    }
    if (folderUri.length === 0) {
      ++this.requestId;
      this.projectLocal('', this.state.folderFilter, this.state.browseMode, this.state.fileFilter, false);
      return;
    }
    if (this.isVirtualFolder(folderUri) || folderUri === LocalMediaFolder.MEDIA_LIBRARY_URI) {
      ++this.requestId;
      this.projectLocal(folderUri, this.state.folderFilter, this.state.browseMode,
        this.state.fileFilter, false);
      return;
    }
    const options: LocalMediaScanOptions = new LocalMediaScanOptions(this.state.folderFilter,
      folderUri, 500, LocalBrowseMode.DIRECTORY, this.state.fileFilter);
    const selection: LocalMediaCatalogView = LocalMediaCatalog.createLibraryView(
      this.catalogItems.concat(this.manualItems), options,
      this.catalogFolders.concat(this.manualFolders));
    if (selection.selectedDirectoryUri.length === 0) {
      this.projectLocal('', this.state.folderFilter, this.state.browseMode, this.state.fileFilter);
      return;
    }
    const cachedItems: LocalMediaAsset[] | null = this.directoryItems(folderUri);
    if (cachedItems !== null) {
      this.projectLocal(folderUri, this.state.folderFilter, this.state.browseMode,
        this.state.fileFilter);
      return;
    }
    const requestId: number = ++this.requestId;
    let persistentItems: LocalMediaAsset[] | null = null;
    try {
      const cachedResult: LocalMediaScanResult | null =
        await this.mediaLibrary.loadCachedDirectory(folderUri);
      if (cachedResult !== null && cachedResult.succeeded()) {
        persistentItems = LibraryFeatureController.uniqueItems(cachedResult.items);
      }
    } catch (_error) {
    }
    if (!this.isCurrent(requestId)) {
      return;
    }
    if (persistentItems !== null) {
      this.cacheDirectory(folderUri, persistentItems);
      this.projectLocal(folderUri, this.state.folderFilter, this.state.browseMode,
        this.state.fileFilter, true);
    } else {
      this.update(this.state.recentItems, this.state.localItems, LocalMediaScanState.SCANNING,
        this.state.localFailure, null, this.state.localFolders, folderUri, this.state.folderFilter,
        this.state.browseMode, this.state.fileFilter, false);
    }
    const result: LocalMediaScanResult = await this.mediaLibrary.scanDirectory(folderUri, options);
    if (!this.isCurrent(requestId)) {
      return;
    }
    if (!result.succeeded()) {
      if (persistentItems !== null) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          this.state.localFailure, FailureCatalog.fromLocalScanError(result.errorCode),
          this.state.localFolders, folderUri, this.state.folderFilter, this.state.browseMode,
          this.state.fileFilter, false);
        return;
      }
      this.update(this.state.recentItems, [], LocalMediaScanState.FAILED, this.state.localFailure,
        FailureCatalog.fromLocalScanError(result.errorCode), this.state.localFolders, folderUri);
      return;
    }
    const nextItems: LocalMediaAsset[] = LibraryFeatureController.uniqueItems(result.items);
    const stableItems: LocalMediaAsset[] = persistentItems !== null &&
      LibraryFeatureController.sameItems(persistentItems, nextItems) ? persistentItems : nextItems;
    this.cacheDirectory(folderUri, stableItems);
    const generation: number = result.generation > 0 ?
      result.generation : this.state.snapshotGeneration;
    const completedAt: number = result.completedAt > 0 ? result.completedAt : this.state.lastSyncedAt;
    this.projectLocal(folderUri, this.state.folderFilter, this.state.browseMode,
      this.state.fileFilter, false, generation, completedAt,
      result.cachePersisted ? null : FailureCatalog.localCacheWriteFailed());
    this.runPendingRefresh();
  }

  dispose(): void {
    this.active = false;
    ++this.requestId;
    ++this.manualRequestId;
    ++this.progressRequestId;
    this.mediaLibrary.stopObservingChanges();
    this.observingChanges = false;
    this.refreshAfterScan = false;
    this.refreshQueued = false;
    if (this.changeDebounceTimer >= 0) {
      clearTimeout(this.changeDebounceTimer);
      this.changeDebounceTimer = -1;
    }
  }

  currentState(): LibraryFeatureState {
    return this.state;
  }

  async reloadCachedSnapshot(): Promise<void> {
    const requestId: number = ++this.requestId;
    await this.loadCached(requestId);
  }

  private async loadCached(requestId: number): Promise<boolean> {
    let result: LocalMediaScanResult | null = null;
    try {
      result = await this.mediaLibrary.loadCached();
    } catch (_error) {
      return false;
    }
    if (!this.isCurrent(requestId) || result === null || !result.succeeded()) {
      return false;
    }
    this.catalogItems = LibraryFeatureController.uniqueItems(result.items);
    this.catalogFolders = result.folders;
    this.cachedFingerprint = result.fingerprint;
    this.clearDirectoryCache();
    this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
      this.state.browseMode, this.state.fileFilter, false,
      result.generation, result.completedAt);
    return true;
  }

  private async loadLocal(requestId: number, preserveExisting: boolean = false): Promise<void> {
    if (preserveExisting) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, null, this.state.localFolders, this.state.selectedFolderUri,
        this.state.folderFilter, this.state.browseMode, this.state.fileFilter, true);
    } else {
      this.update(this.state.recentItems, this.state.localItems, LocalMediaScanState.SCANNING,
        this.state.localFailure, null, this.state.localFolders, this.state.selectedFolderUri,
        this.state.folderFilter, this.state.browseMode, this.state.fileFilter, true);
    }
    const result: LocalMediaScanResult = await this.mediaLibrary.scan(new LocalMediaScanOptions(
      this.state.folderFilter, this.state.selectedFolderUri, 500, this.state.browseMode,
      this.state.fileFilter));
    if (!this.isCurrent(requestId)) {
      return;
    }
    if (!result.succeeded()) {
      if (preserveExisting) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          this.state.localFailure, FailureCatalog.fromLocalScanError(result.errorCode),
          this.state.localFolders, this.state.selectedFolderUri, this.state.folderFilter,
          this.state.browseMode, this.state.fileFilter, false);
        this.refreshAfterScan = false;
        return;
      }
      this.catalogItems = [];
      this.catalogFolders = [];
      this.clearDirectoryCache();
      this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter, this.state.browseMode,
        this.state.fileFilter, false, this.state.snapshotGeneration, this.state.lastSyncedAt,
        FailureCatalog.fromLocalScanError(result.errorCode));
      this.refreshAfterScan = false;
      return;
    }
    const nextItems: LocalMediaAsset[] = LibraryFeatureController.uniqueItems(result.items);
    const nextFolders: LocalMediaFolder[] = result.folders;
    const contentChanged: boolean = !LibraryFeatureController.sameItems(this.catalogItems, nextItems) ||
      !LibraryFeatureController.sameFolders(this.catalogFolders, nextFolders);
    if (contentChanged) {
      this.catalogItems = nextItems;
      this.catalogFolders = nextFolders;
      this.clearDirectoryCache();
    }
    const generation: number = result.generation > 0 ?
      result.generation : this.state.snapshotGeneration;
    const completedAt: number = result.completedAt > 0 ? result.completedAt : this.state.lastSyncedAt;
    this.cachedFingerprint = result.fingerprint;
    this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
      this.state.browseMode, this.state.fileFilter, false,
      generation, completedAt, result.cachePersisted ? null : FailureCatalog.localCacheWriteFailed());
    this.runPendingRefresh();
  }

  private startObservingChanges(): void {
    if (this.observingChanges) {
      return;
    }
    this.mediaLibrary.observeChanges((): void => {
      this.onMediaLibraryChanged();
    });
    this.observingChanges = true;
  }

  private onMediaLibraryChanged(): void {
    if (!this.active) {
      return;
    }
    if (this.state.scanState === LocalMediaScanState.SCANNING || this.state.refreshing) {
      this.refreshAfterScan = true;
      return;
    }
    if (this.changeDebounceTimer >= 0) {
      clearTimeout(this.changeDebounceTimer);
    }
    this.refreshQueued = true;
    this.changeDebounceTimer = setTimeout((): void => {
      this.changeDebounceTimer = -1;
      this.refreshQueued = false;
      if (!this.active) {
        return;
      }
      if (this.state.scanState === LocalMediaScanState.SCANNING || this.state.refreshing) {
        this.refreshAfterScan = true;
        return;
      }
      const requestId: number = ++this.requestId;
      this.refreshChangedLocal(requestId).catch(() => {});
    }, LibraryFeatureController.CHANGE_DEBOUNCE_MS);
  }

  private runPendingRefresh(): void {
    if (!this.active || !this.refreshAfterScan) {
      return;
    }
    this.refreshAfterScan = false;
    // Change notifications for one operation can arrive from both the asset and album
    // observers. Re-enter the debounce window so trailing notifications are coalesced.
    this.onMediaLibraryChanged();
  }

  private async refreshChangedLocal(requestId: number): Promise<void> {
    // At the root or media-library entry, a completed scan records the resulting fingerprint. A
    // notification that arrives while that scan is finishing should not cause the
    // same full query to run again. Directory scans use their own album fingerprint,
    // so they conservatively keep the full refresh behavior.
    if ((this.state.selectedFolderUri.length === 0 ||
      this.state.selectedFolderUri === LocalMediaFolder.MEDIA_LIBRARY_URI) && this.cachedFingerprint.length > 0) {
      try {
        const currentFingerprint: string = await this.mediaLibrary.probeFingerprint();
        if (!this.isCurrent(requestId)) {
          return;
        }
        if (currentFingerprint.length > 0 && currentFingerprint === this.cachedFingerprint) {
          this.refreshAfterScan = false;
          return;
        }
      } catch (_error) {
        // Fall through to a full refresh when a lightweight probe is unavailable.
      }
    }
    await this.loadCurrentLocal(requestId, true);
  }

  private async loadCurrentLocal(requestId: number, preserveExisting: boolean = false): Promise<void> {
    if (this.state.browseMode === LocalBrowseMode.DIRECTORY &&
      this.state.selectedFolderUri.length > 0 &&
      this.state.selectedFolderUri !== LocalMediaFolder.MEDIA_LIBRARY_URI) {
      if (this.isVirtualFolder(this.state.selectedFolderUri)) {
        await this.reloadManualProjection(requestId);
        return;
      }
      await this.loadSelectedDirectory(requestId, preserveExisting);
      return;
    }
    await this.loadLocal(requestId, preserveExisting);
  }

  private async loadSelectedDirectory(requestId: number, preserveExisting: boolean = false): Promise<void> {
    const folderUri: string = this.state.selectedFolderUri;
    const options: LocalMediaScanOptions = new LocalMediaScanOptions(this.state.folderFilter,
      folderUri, 500, LocalBrowseMode.DIRECTORY, this.state.fileFilter);
    if (preserveExisting) {
      this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
        this.state.localFailure, null, this.state.localFolders, folderUri,
        this.state.folderFilter, this.state.browseMode, this.state.fileFilter, true);
    } else {
      this.update(this.state.recentItems, this.state.localItems, LocalMediaScanState.SCANNING,
        this.state.localFailure, null, this.state.localFolders, folderUri,
        this.state.folderFilter, this.state.browseMode, this.state.fileFilter, true);
    }
    const result: LocalMediaScanResult = await this.mediaLibrary.scanDirectory(folderUri, options);
    if (!this.isCurrent(requestId)) {
      return;
    }
    if (!result.succeeded()) {
      if (preserveExisting) {
        this.update(this.state.recentItems, this.state.localItems, this.state.scanState,
          this.state.localFailure, FailureCatalog.fromLocalScanError(result.errorCode),
          this.state.localFolders, folderUri, this.state.folderFilter,
          this.state.browseMode, this.state.fileFilter, false);
      } else {
        this.update(this.state.recentItems, [], LocalMediaScanState.FAILED, this.state.localFailure,
          FailureCatalog.fromLocalScanError(result.errorCode), this.state.localFolders, folderUri,
          this.state.folderFilter, this.state.browseMode, this.state.fileFilter, false);
      }
      this.refreshAfterScan = false;
      return;
    }
    const nextItems: LocalMediaAsset[] = LibraryFeatureController.uniqueItems(result.items);
    const cachedItems: LocalMediaAsset[] | null = this.directoryItems(folderUri);
    const stableItems: LocalMediaAsset[] = cachedItems !== null &&
      LibraryFeatureController.sameItems(cachedItems, nextItems) ? cachedItems : nextItems;
    this.cacheDirectory(folderUri, stableItems);
    const generation: number = result.generation > 0 ?
      result.generation : this.state.snapshotGeneration;
    const completedAt: number = result.completedAt > 0 ? result.completedAt : this.state.lastSyncedAt;
    this.projectLocal(folderUri, this.state.folderFilter, this.state.browseMode,
      this.state.fileFilter, false, generation, completedAt,
      result.cachePersisted ? null : FailureCatalog.localCacheWriteFailed());
    this.runPendingRefresh();
  }

  private projectLocal(selectedDirectoryUri: string, folderFilter: LocalMediaFolderFilter,
    browseMode: LocalBrowseMode, fileFilter: LocalFileFilter,
    refreshing: boolean = this.state.refreshing,
    snapshotGeneration: number = this.state.snapshotGeneration,
    lastSyncedAt: number = this.state.lastSyncedAt,
    scanFailure: AppFailure | null = null): void {
    const options: LocalMediaScanOptions = new LocalMediaScanOptions(folderFilter,
      selectedDirectoryUri, 500, browseMode, fileFilter);
    const catalogView: LocalMediaCatalogView = LocalMediaCatalog.createLibraryView(
      this.catalogItems.concat(this.manualItems), options,
      this.catalogFolders.concat(this.manualFolders));
    let items: LocalMediaAsset[] = catalogView.items;
    if (catalogView.selectedDirectoryUri.length > 0 &&
      !this.isVirtualFolder(catalogView.selectedDirectoryUri)) {
      const cachedItems: LocalMediaAsset[] | null = this.directoryItems(catalogView.selectedDirectoryUri);
      if (cachedItems !== null) {
        items = LocalMediaCatalog.createView(cachedItems, options,
          this.catalogFolders.concat(this.manualFolders)).items;
      }
    }
    const hasVisibleContent: boolean = catalogView.selectedDirectoryUri.length > 0 ?
      items.length > 0 || catalogView.childFolders.length > 0 :
      items.length > 0 || catalogView.childFolders.length > 0;
    const scanState: LocalMediaScanState = hasVisibleContent ?
      LocalMediaScanState.READY : LocalMediaScanState.EMPTY;
    const stableItems: LocalMediaAsset[] = LibraryFeatureController.sameItems(
      this.state.localItems, items) ? this.state.localItems : items;
    const stableFolders: LocalMediaFolder[] = LibraryFeatureController.sameFolders(
      this.state.localFolders, catalogView.folders) ? this.state.localFolders : catalogView.folders;
    this.update(this.state.recentItems, stableItems, scanState, this.state.localFailure, scanFailure,
      stableFolders, catalogView.selectedDirectoryUri, folderFilter, browseMode, fileFilter,
      refreshing, snapshotGeneration, lastSyncedAt);
  }

  private async cachedSnapshotNeedsRefresh(requestId: number): Promise<boolean> {
    if (this.cachedFingerprint.length === 0 || this.state.lastSyncedAt <= 0 ||
      Date.now() - this.state.lastSyncedAt >= LibraryFeatureController.FULL_RECONCILE_INTERVAL_MS) {
      return true;
    }
    try {
      const currentFingerprint: string = await this.mediaLibrary.probeFingerprint();
      if (!this.isCurrent(requestId) || currentFingerprint.length === 0) {
        return true;
      }
      return currentFingerprint !== this.cachedFingerprint;
    } catch (_error) {
      // A failed probe must never make an old cache look current.
      return true;
    }
  }

  private directoryItems(directoryUri: string): LocalMediaAsset[] | null {
    const index: number = this.cachedDirectoryUris.indexOf(directoryUri);
    return index < 0 ? null : this.cachedDirectoryItems[index];
  }

  private cacheDirectory(directoryUri: string, items: LocalMediaAsset[]): void {
    const index: number = this.cachedDirectoryUris.indexOf(directoryUri);
    if (index >= 0) {
      this.cachedDirectoryItems[index] = items;
      return;
    }
    this.cachedDirectoryUris.push(directoryUri);
    this.cachedDirectoryItems.push(items);
  }

  private clearDirectoryCache(): void {
    this.cachedDirectoryUris = [];
    this.cachedDirectoryItems = [];
  }

  private update(recentItems: RecentMediaItem[], localItems: LocalMediaAsset[],
    scanState: LocalMediaScanState, localFailure: AppFailure | null,
    scanFailure: AppFailure | null, localFolders: LocalMediaFolder[] = this.state.localFolders,
    selectedFolderUri: string = this.state.selectedFolderUri,
    folderFilter: LocalMediaFolderFilter = this.state.folderFilter,
    browseMode: LocalBrowseMode = this.state.browseMode,
    fileFilter: LocalFileFilter = this.state.fileFilter,
    refreshing: boolean = this.state.refreshing,
    snapshotGeneration: number = this.state.snapshotGeneration,
    lastSyncedAt: number = this.state.lastSyncedAt,
    playbackProgress: LocalMediaPlaybackProgress[] = this.state.playbackProgress): void {
    this.state = new LibraryFeatureState(recentItems, localItems, scanState, localFailure, scanFailure,
      localFolders, selectedFolderUri, folderFilter, browseMode, fileFilter, refreshing,
      snapshotGeneration, lastSyncedAt, playbackProgress);
    this.observer(this.state);
  }

  private isCurrent(requestId: number): boolean {
    return this.active && requestId === this.requestId;
  }

  private static uniqueItems(items: LocalMediaAsset[]): LocalMediaAsset[] {
    const result: LocalMediaAsset[] = [];
    const uris: string[] = [];
    for (const item of items) {
      if (!uris.includes(item.uri)) {
        uris.push(item.uri);
        result.push(item);
      }
    }
    return result;
  }

  private static sameFilter(left: LocalFileFilter, right: LocalFileFilter): boolean {
    return left.videoExtensions.join('|') === right.videoExtensions.join('|') &&
      left.imageExtensions.join('|') === right.imageExtensions.join('|') &&
      left.subtitleExtensions.join('|') === right.subtitleExtensions.join('|') &&
      left.audioExtensions.join('|') === right.audioExtensions.join('|');
  }

  private static sameItems(left: LocalMediaAsset[], right: LocalMediaAsset[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      const first: LocalMediaAsset = left[index];
      const second: LocalMediaAsset = right[index];
      if (first.uri !== second.uri || first.displayName !== second.displayName ||
        first.durationMs !== second.durationMs || first.width !== second.width ||
        first.height !== second.height || first.sizeBytes !== second.sizeBytes ||
        first.modifiedAt !== second.modifiedAt || first.category !== second.category ||
        first.parentUri !== second.parentUri || first.origin !== second.origin ||
        first.availability !== second.availability || first.sourceUri !== second.sourceUri) {
        return false;
      }
    }
    return true;
  }

  private static sameFolders(left: LocalMediaFolder[], right: LocalMediaFolder[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      const first: LocalMediaFolder = left[index];
      const second: LocalMediaFolder = right[index];
      if (first.uri !== second.uri || first.displayName !== second.displayName ||
        first.totalCount !== second.totalCount || first.videoCount !== second.videoCount ||
        first.imageCount !== second.imageCount || first.subtitleCount !== second.subtitleCount ||
        first.coverUri !== second.coverUri || first.parentUri !== second.parentUri ||
        first.totalSizeBytes !== second.totalSizeBytes || first.virtual !== second.virtual ||
        first.folderCount !== second.folderCount) {
        return false;
      }
    }
    return true;
  }

  private static sameProgress(left: LocalMediaPlaybackProgress[],
    right: LocalMediaPlaybackProgress[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      const first: LocalMediaPlaybackProgress = left[index];
      const second: LocalMediaPlaybackProgress = right[index];
      if (first.uri !== second.uri || first.positionMs !== second.positionMs ||
        first.durationMs !== second.durationMs || first.updatedAt !== second.updatedAt) {
        return false;
      }
    }
    return true;
  }

  private async loadManualItems(requestId: number): Promise<void> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (repository === null) {
      return;
    }
    try {
      const items: LocalMediaAsset[] = await repository.load();
      const folders: LocalMediaFolder[] = await repository.loadFolders();
      if (this.isCurrent(requestId)) {
        this.manualItems = items;
        this.manualFolders = folders;
      }
    } catch (_error) {
      if (this.isCurrent(requestId)) {
        this.manualItems = [];
        this.manualFolders = [];
      }
    }
  }

  private verifyManualItems(): void {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (repository === null || this.manualItems.length === 0) {
      return;
    }
    const requestId: number = ++this.manualRequestId;
    repository.verify().then((items: LocalMediaAsset[]): void => {
      if (!this.active || requestId !== this.manualRequestId ||
        LibraryFeatureController.sameItems(this.manualItems, items)) {
        return;
      }
      this.manualItems = items;
      this.projectLocal(this.state.selectedFolderUri, this.state.folderFilter,
        this.state.browseMode, this.state.fileFilter, this.state.refreshing);
    }).catch(() => {});
  }

  private isVirtualFolder(uri: string): boolean {
    for (const folder of this.manualFolders) {
      if (folder.uri === uri && folder.isVirtual()) {
        return true;
      }
    }
    return false;
  }

  private async reloadManualProjection(requestId: number): Promise<void> {
    const repository: ManualMediaRepository | null = this.manualRepository;
    if (repository !== null) {
      try {
        this.manualItems = await repository.verify();
        this.manualFolders = await repository.loadFolders();
      } catch (_error) {
      }
    }
    if (!this.isCurrent(requestId)) {
      return;
    }
    const selectedUri: string = this.isVirtualFolder(this.state.selectedFolderUri) ?
      this.state.selectedFolderUri : '';
    this.projectLocal(selectedUri, this.state.folderFilter, this.state.browseMode,
      this.state.fileFilter, false);
  }
}
