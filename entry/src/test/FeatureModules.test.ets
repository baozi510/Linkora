import { describe, expect, it } from '@ohos/hypium';
import {
  AppAccentColor,
  AppSettings,
  AppThemeMode,
  DiscoveryMethod,
  LibraryFeatureController,
  LibraryFeatureState,
  LocalBrowseMode,
  LocalFileCategory,
  LocalFileFilter,
  LocalMediaAsset,
  LocalMediaCatalog,
  LocalMediaAvailability,
  LocalMediaFolder,
  LocalMediaFolderFilter,
  LocalMediaOrigin,
  LocalMediaPlaybackProgress,
  LocalMediaProgressRepository,
  LocalFilePickerGateway,
  LocalMediaPermissionResult,
  LocalMediaPickResult,
  LocalMediaScanResult,
  LocalMediaScanOptions,
  LocalMediaScanState,
  ManualMediaRepository,
  MediaLibraryGateway,
  MediaSource,
  NetworkLinkController,
  NetworkProbePort,
  NetworkProbeResult,
  PlaybackBookmark,
  PlaybackBookmarkRepository,
  PlaybackEngine,
  PlaybackObserver,
  PlaybackPort,
  PlaybackPortObserver,
  PlaybackStatus,
  PlayerFeatureController,
  PortPlaybackState,
  RecentMediaItem,
  RecentMediaRepository,
  RemoteConnectionOptions,
  RemoteEntry,
  RemoteProtocol,
  RemoteReadSession,
  SourceConnection,
  SourcePlugin,
  SourcePluginRegistry,
  SettingsFeatureController,
  SettingsRepository
} from 'linkora_core';

class FakeLocalMediaGateway implements MediaLibraryGateway, LocalFilePickerGateway {
  authorized: boolean = true;
  permission: LocalMediaPermissionResult = new LocalMediaPermissionResult(true);
  cachedResult: LocalMediaScanResult | null = null;
  cachedAlbumResult: LocalMediaScanResult | null = null;
  scanResult: LocalMediaScanResult = new LocalMediaScanResult([]);
  albumScanResult: LocalMediaScanResult = new LocalMediaScanResult([]);
  pickResult: LocalMediaPickResult = new LocalMediaPickResult([]);
  lastScanOptions: LocalMediaScanOptions | null = null;
  scanCalls: number = 0;
  albumScanCalls: number = 0;
  albumScanDelayMs: number = 0;
  cachedAlbumCalls: number = 0;
  probeCalls: number = 0;
  fingerprintResult: string = '';
  changeObserver: (() => void) | null = null;

  async isAuthorized(): Promise<boolean> {
    return this.authorized;
  }

  async requestAuthorization(): Promise<LocalMediaPermissionResult> {
    return this.permission;
  }

  async loadCached(): Promise<LocalMediaScanResult | null> {
    return this.cachedResult;
  }

  async loadCachedDirectory(albumUri: string): Promise<LocalMediaScanResult | null> {
    ++this.cachedAlbumCalls;
    if (this.cachedAlbumResult === null) {
      return null;
    }
    return new LocalMediaScanResult(this.cachedAlbumResult.items, [], albumUri,
      this.cachedAlbumResult.errorCode, this.cachedAlbumResult.snapshotComplete,
      this.cachedAlbumResult.generation, this.cachedAlbumResult.completedAt,
      this.cachedAlbumResult.fingerprint, this.cachedAlbumResult.cachePersisted);
  }

  async probeFingerprint(): Promise<string> {
    ++this.probeCalls;
    return this.fingerprintResult;
  }

  observeChanges(observer: () => void): void {
    this.changeObserver = observer;
  }

  stopObservingChanges(): void {
    this.changeObserver = null;
  }

  async scan(options: LocalMediaScanOptions = new LocalMediaScanOptions()): Promise<LocalMediaScanResult> {
    ++this.scanCalls;
    this.lastScanOptions = options;
    return this.scanResult;
  }

  async scanDirectory(albumUri: string,
    _options: LocalMediaScanOptions = new LocalMediaScanOptions()): Promise<LocalMediaScanResult> {
    ++this.albumScanCalls;
    if (this.albumScanDelayMs > 0) {
      await waitFor(this.albumScanDelayMs);
    }
    return new LocalMediaScanResult(this.albumScanResult.items, [], albumUri,
      this.albumScanResult.errorCode, this.albumScanResult.snapshotComplete,
      this.albumScanResult.generation, this.albumScanResult.completedAt,
      this.albumScanResult.fingerprint, this.albumScanResult.cachePersisted);
  }

  async pick(_fileFilter?: LocalFileFilter,
    _categories?: LocalFileCategory[]): Promise<LocalMediaPickResult> {
    return this.pickResult;
  }
}

class FakeRecentMediaRepository implements RecentMediaRepository {
  items: RecentMediaItem[] = [];

  async load(): Promise<RecentMediaItem[]> {
    return this.items;
  }

  async record(source: MediaSource): Promise<RecentMediaItem[]> {
    this.items = [new RecentMediaItem(source, 10)];
    return this.items;
  }
}

class FakeManualMediaRepository implements ManualMediaRepository {
  items: LocalMediaAsset[] = [];
  folders: LocalMediaFolder[] = [];
  aliasSequence: number = 0;
  folderSequence: number = 0;
  addCalls: number = 0;
  verifyCalls: number = 0;
  removeCalls: number = 0;
  removeUnavailableCalls: number = 0;

  async load(): Promise<LocalMediaAsset[]> {
    return this.items;
  }

  async loadFolders(): Promise<LocalMediaFolder[]> {
    return this.folders.map((folder: LocalMediaFolder): LocalMediaFolder => {
      const children: number = this.folders.filter((child: LocalMediaFolder): boolean =>
        child.parentUri === folder.uri).length;
      const items: LocalMediaAsset[] = this.items.filter((item: LocalMediaAsset): boolean =>
        item.parentUri === folder.uri);
      const videos: number = items.filter((item: LocalMediaAsset): boolean => item.isVideo()).length;
      return new LocalMediaFolder(folder.uri, folder.displayName, items.length, videos,
        items.length - videos, folder.coverUri, 0, folder.parentUri, 0, true, children);
    });
  }

  async add(sources: MediaSource[], parentUri: string = ''): Promise<LocalMediaAsset[]> {
    ++this.addCalls;
    for (const source of LocalMediaCatalog.newManualSources(sources, this.items, parentUri)) {
      ++this.aliasSequence;
      this.items.push(new LocalMediaAsset(`linkora://item/${this.aliasSequence}`, source.displayName,
        0, 0, 0, 10, 1, LocalFileCategory.VIDEO, parentUri,
        LocalMediaOrigin.DOCUMENT_PICKER, LocalMediaAvailability.AVAILABLE, source.locator));
    }
    return this.items;
  }

  async reauthorize(uri: string, source: MediaSource): Promise<LocalMediaAsset[]> {
    this.items = this.items.map((item: LocalMediaAsset): LocalMediaAsset => item.uri === uri ?
      new LocalMediaAsset(item.uri, source.displayName, 0, 0, 0, 10, 1, item.category,
        item.parentUri, LocalMediaOrigin.DOCUMENT_PICKER, LocalMediaAvailability.AVAILABLE,
        source.locator) : item);
    return this.items;
  }

  async createFolder(parentUri: string, name: string): Promise<LocalMediaFolder[]> {
    const safeName: string = name.trim();
    if (safeName.length === 0 || (parentUri.length > 0 && !this.hasFolder(parentUri)) ||
      this.hasSibling(parentUri, safeName, '')) {
      throw new Error('Unable to create virtual folder');
    }
    ++this.folderSequence;
    this.folders.push(new LocalMediaFolder(`linkora://folder/${this.folderSequence}`, safeName,
      0, 0, 0, '', 0, parentUri, 0, true));
    return this.folders;
  }

  async renameFolder(uri: string, name: string): Promise<LocalMediaFolder[]> {
    const safeName: string = name.trim();
    const updated: LocalMediaFolder[] = [];
    for (const folder of this.folders) {
      if (folder.uri === uri) {
        if (safeName.length === 0 || this.hasSibling(folder.parentUri, safeName, uri)) {
          throw new Error('Unable to rename virtual folder');
        }
        updated.push(new LocalMediaFolder(folder.uri, safeName, folder.totalCount,
          folder.videoCount, folder.imageCount, folder.coverUri, folder.subtitleCount,
          folder.parentUri, folder.totalSizeBytes, true));
      } else {
        updated.push(folder);
      }
    }
    this.folders = updated;
    return this.folders;
  }

  async removeFolder(uri: string): Promise<void> {
    const removed: string[] = [uri];
    let changed: boolean = true;
    while (changed) {
      changed = false;
      for (const folder of this.folders) {
        if (removed.includes(folder.parentUri) && !removed.includes(folder.uri)) {
          removed.push(folder.uri);
          changed = true;
        }
      }
    }
    this.items = this.items.filter((item: LocalMediaAsset) => !removed.includes(item.parentUri));
    this.folders = this.folders.filter((folder: LocalMediaFolder) => !removed.includes(folder.uri));
  }

  async verify(): Promise<LocalMediaAsset[]> {
    ++this.verifyCalls;
    return this.items;
  }

  async remove(uri: string): Promise<LocalMediaAsset[]> {
    ++this.removeCalls;
    this.items = this.items.filter((item: LocalMediaAsset) => item.uri !== uri);
    return this.items;
  }

  async removeUnavailable(): Promise<LocalMediaAsset[]> {
    ++this.removeUnavailableCalls;
    this.items = this.items.filter((item: LocalMediaAsset) => item.isAvailable());
    return this.items;
  }

  private hasFolder(uri: string): boolean {
    return this.folders.some((folder: LocalMediaFolder): boolean => folder.uri === uri);
  }

  private hasSibling(parentUri: string, name: string, excludedUri: string): boolean {
    return this.folders.some((folder: LocalMediaFolder): boolean =>
      folder.uri !== excludedUri && folder.parentUri === parentUri && folder.displayName === name);
  }
}

class FakeLocalMediaProgressRepository implements LocalMediaProgressRepository {
  items: LocalMediaPlaybackProgress[] = [];
  loadCalls: number = 0;

  async loadFor(_items: LocalMediaAsset[]): Promise<LocalMediaPlaybackProgress[]> {
    ++this.loadCalls;
    return this.items;
  }
}

class FakeSettingsRepository implements SettingsRepository {
  settings: AppSettings = new AppSettings();
  saveCalls: number = 0;

  async load(): Promise<AppSettings> {
    return this.settings;
  }

  async save(settings: AppSettings): Promise<void> {
    this.settings = settings;
    ++this.saveCalls;
  }
}

class FakeNetworkProbe implements NetworkProbePort {
  calls: number = 0;

  async inspect(_url: string): Promise<NetworkProbeResult> {
    ++this.calls;
    return new NetworkProbeResult(200, true, null);
  }

  cancel(): void {
  }
}

class FakePlaybackPort implements PlaybackPort {
  readonly observer: PlaybackPortObserver;
  seekPosition: number = -1;

  constructor(observer: PlaybackPortObserver) {
    this.observer = observer;
  }

  configure(_source: MediaSource, _surfaceId: string): void {
    this.observer.onStateChange(PortPlaybackState.INITIALIZED);
  }

  getDuration(): number {
    return 120000;
  }

  async prepare(): Promise<void> {
    this.observer.onDurationChange(120000);
    this.observer.onStateChange(PortPlaybackState.PREPARED);
  }

  async play(): Promise<void> {
    this.observer.onStateChange(PortPlaybackState.PLAYING);
  }

  async pause(): Promise<void> {
    this.observer.onStateChange(PortPlaybackState.PAUSED);
  }

  seek(position: number): void {
    this.seekPosition = position;
    this.observer.onPositionChange(position);
  }

  setPlaybackRate(_rate: number): void {
  }

  setVolume(_volume: number): void {
  }

  async release(): Promise<void> {
    this.observer.onStateChange(PortPlaybackState.RELEASED);
  }
}

class FakeBookmarkRepository implements PlaybackBookmarkRepository {
  bookmark: PlaybackBookmark | null = new PlaybackBookmark(33000, 120000, 1);
  saved: PlaybackBookmark | null = null;

  async load(_source: MediaSource): Promise<PlaybackBookmark | null> {
    return this.bookmark;
  }

  async save(_source: MediaSource, bookmark: PlaybackBookmark): Promise<void> {
    this.saved = bookmark;
  }

  async clear(_source: MediaSource): Promise<void> {
    this.bookmark = null;
  }
}

class EmptyReadSession implements RemoteReadSession {
  size(): number {
    return 0;
  }

  async read(_offset: number, _length: number): Promise<ArrayBuffer> {
    return new ArrayBuffer(0);
  }

  cancel(): void {
  }

  async close(): Promise<void> {
  }
}

class EmptySourceConnection implements SourceConnection {
  async list(_path: string): Promise<RemoteEntry[]> {
    return [];
  }

  async stat(_path: string): Promise<RemoteEntry | null> {
    return null;
  }

  async openReader(_path: string): Promise<RemoteReadSession> {
    return new EmptyReadSession();
  }

  async close(): Promise<void> {
  }
}

class FakeWebDavPlugin implements SourcePlugin {
  protocol(): RemoteProtocol {
    return RemoteProtocol.WEBDAV;
  }

  async connect(_options: RemoteConnectionOptions): Promise<SourceConnection> {
    return new EmptySourceConnection();
  }
}

async function settle(): Promise<void> {
  await new Promise<void>((resolve: () => void) => setTimeout(resolve, 0));
}

async function waitFor(milliseconds: number): Promise<void> {
  await new Promise<void>((resolve: () => void) => setTimeout(resolve, milliseconds));
}

export default function featureModulesTest(): void {
  describe('FeatureModules', () => {
    it('keepsImportedFilesAtRootAndScannedAlbumsInsideLocalMedia', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      const album = new LocalMediaFolder('album://camera', 'Camera', 1, 1, 0);
      gateway.scanResult = new LocalMediaScanResult([], [album]);
      gateway.albumScanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://camera.mp4', 'camera.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, album.uri)
      ]);
      gateway.pickResult = new LocalMediaPickResult([
        MediaSource.fromLocalDocument('file://imported.mp4')
      ]);
      const manual = new FakeManualMediaRepository();
      const custom = (await manual.createFolder('', 'Custom'))[0];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);
      await controller.initialize();
      await controller.pickLocal('');

      const root = controller.currentState();
      const rootFolders = root.localFolders.filter((folder: LocalMediaFolder) => folder.parentUri === '');
      expect(rootFolders.length).assertEqual(2);
      expect(rootFolders.some((folder: LocalMediaFolder) => folder.displayName === '本地媒体')).assertTrue();
      expect(rootFolders.some((folder: LocalMediaFolder) => folder.uri === custom.uri)).assertTrue();
      expect(root.localItems[0].contentUri()).assertEqual('file://imported.mp4');

      await controller.selectFolder('linkora://media-library');
      expect(controller.currentState().selectedFolderUri).assertEqual('linkora://media-library');
      expect(controller.currentState().localItems.length).assertEqual(0);
      expect(controller.currentState().localFolders.some((folder: LocalMediaFolder) =>
        folder.uri === album.uri && folder.parentUri === 'linkora://media-library')).assertTrue();
      expect(gateway.albumScanCalls).assertEqual(0);
      expect(controller.canManageVirtualEntries()).assertFalse();

      await controller.selectFolder(album.uri);
      expect(controller.currentState().localItems[0].contentUri()).assertEqual('file://camera.mp4');
      await controller.selectFolder('linkora://media-library');
      await controller.scanLocal();
      expect(gateway.albumScanCalls).assertEqual(1);
      await controller.selectFolder('');
      expect(controller.currentState().localItems[0].contentUri()).assertEqual('file://imported.mp4');
    });

    it('keepsTheFixedLocalMediaEntryWhenEmptyOrAuthorizationFails', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      gateway.permission = new LocalMediaPermissionResult(false, 201);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});
      await controller.initialize();
      expect(controller.currentState().localFolders.length).assertEqual(1);
      expect(controller.currentState().localFolders[0].isMediaLibraryRoot()).assertTrue();
      expect(controller.currentState().localFolders[0].isVirtual()).assertFalse();
      await controller.setFolderFilter(LocalMediaFolderFilter.NON_EMPTY);
      expect(controller.currentState().localFolders.length).assertEqual(1);
      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.EMPTY);
      await controller.scanLocal();
      expect(controller.currentState().selectedFolderUri).assertEqual(LocalMediaFolder.MEDIA_LIBRARY_URI);
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.PERMISSION_DENIED);
      await controller.selectFolder('');
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.READY);
      expect(controller.currentState().localFolders.length).assertEqual(1);

      gateway.permission = new LocalMediaPermissionResult(true);
      gateway.scanResult = new LocalMediaScanResult([], [], '', 13900020);
      await controller.scanLocal();
      expect(controller.currentState().localFolders.length).assertEqual(1);
      expect(controller.currentState().scanFailure).not().assertNull();
    });

    it('loadsLibraryStateWithoutArkUI', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://video.mp4', 'video.mp4', 1000, 1920, 1080, 10, 1)
      ]);
      const recent = new FakeRecentMediaRepository();
      recent.items = [new RecentMediaItem(MediaSource.fromLocalDocument('file://recent.mp4'), 1)];
      const controller = new LibraryFeatureController(gateway, gateway, recent, () => {});

      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      await controller.initialize();

      expect(controller.currentState().recentItems.length).assertEqual(1);
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.READY);
    });

    it('publishesCachedLibraryBeforeBackgroundRefresh', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.cachedResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://cached.mp4', 'cached.mp4', 1000, 1920, 1080, 10, 1)
      ]);
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://fresh.mp4', 'fresh.mp4', 1000, 1920, 1080, 10, 2)
      ]);
      const observed: LibraryFeatureState[] = [];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), (state: LibraryFeatureState) => {
          observed.push(state);
        });

      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      await controller.initialize();

      let cacheWasVisible: boolean = false;
      let refreshedWithoutClearing: boolean = false;
      for (const state of observed) {
        if (state.localItems.length > 0 && state.localItems[0].displayName === 'cached.mp4') {
          cacheWasVisible = true;
          if (state.refreshing) {
            refreshedWithoutClearing = true;
          }
        }
      }
      expect(cacheWasVisible).assertTrue();
      expect(refreshedWithoutClearing).assertTrue();
      expect(controller.currentState().localItems[0].displayName).assertEqual('fresh.mp4');
      expect(controller.currentState().refreshing).assertFalse();
    });

    it('keepsRecentCacheWhenColdStartFingerprintMatches', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.cachedResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://cached.mp4', 'cached.mp4', 1000, 1920, 1080, 10, 1)
      ], [], '', 0, true, 7, Date.now(), 'fingerprint-a');
      gateway.fingerprintResult = 'fingerprint-a';
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://unneeded.mp4', 'unneeded.mp4', 1000, 1920, 1080, 10, 2)
      ]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      await controller.initialize();
      expect(gateway.probeCalls).assertEqual(1);
      expect(gateway.scanCalls).assertEqual(0);
      expect(controller.currentState().localItems[0].displayName).assertEqual('cached.mp4');
    });

    it('refreshesCacheWhenColdStartFingerprintChanges', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.cachedResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://cached.mp4', 'cached.mp4', 1000, 1920, 1080, 10, 1)
      ], [], '', 0, true, 7, Date.now(), 'fingerprint-a');
      gateway.fingerprintResult = 'fingerprint-b';
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://fresh.mp4', 'fresh.mp4', 1000, 1920, 1080, 10, 2)
      ], [], '', 0, true, 8, Date.now(), 'fingerprint-b');
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      await controller.initialize();
      expect(gateway.scanCalls).assertEqual(1);
      expect(controller.currentState().localItems[0].displayName).assertEqual('fresh.mp4');
    });

    it('surfacesIndexPersistenceFailureWithoutDiscardingFreshItems', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://fresh.mp4', 'fresh.mp4', 1000, 1920, 1080, 10, 2)
      ], [], '', 0, true, 0, 0, 'fingerprint-a', false);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      await controller.initialize();
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().scanFailure).not().assertNull();
      expect(controller.currentState().scanFailure!.title).assertEqual('媒体索引未保存');
    });

    it('keepsCachedLibraryWhenBackgroundRefreshFails', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.cachedResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://cached.mp4', 'cached.mp4', 1000, 1920, 1080, 10, 1)
      ]);
      gateway.scanResult = new LocalMediaScanResult([], [], '', 13900020);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      await controller.initialize();
      expect(controller.currentState().localItems[0].displayName).assertEqual('cached.mp4');
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.READY);
      expect(controller.currentState().scanFailure).not().assertNull();
      expect(controller.currentState().refreshing).assertFalse();
    });

    it('tracksCompletedSnapshotMetadata', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.cachedResult = new LocalMediaScanResult([], [], '', 0, true, 7, 1000);
      gateway.scanResult = new LocalMediaScanResult([], [], '', 0, true, 8, 2000);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();

      expect(controller.currentState().snapshotGeneration).assertEqual(8);
      expect(controller.currentState().lastSyncedAt).assertEqual(2000);
    });

    it('keepsStableListReferencesWhenSnapshotIsUnchanged', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://stable.mp4', 'stable.mp4', 1000, 1920, 1080, 10, 1)
      ], [new LocalMediaFolder('album://stable', 'Stable', 1, 1, 0)]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      const items: LocalMediaAsset[] = controller.currentState().localItems;
      const folders: LocalMediaFolder[] = controller.currentState().localFolders;
      await controller.scanLocal();

      expect(controller.currentState().localItems === items).assertTrue();
      expect(controller.currentState().localFolders === folders).assertTrue();
    });

    it('endsRefreshWhenLeavingTheCurrentFolder', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      const folder: LocalMediaFolder = new LocalMediaFolder('album://camera', 'Camera', 1, 1, 0);
      gateway.scanResult = new LocalMediaScanResult([], [folder]);
      gateway.albumScanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://camera.mp4', 'camera.mp4', 1000, 1920, 1080, 10, 1,
          LocalFileCategory.VIDEO, folder.uri)
      ]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      await controller.selectFolder(folder.uri);
      gateway.albumScanDelayMs = 20;
      const refresh: Promise<void> = controller.scanLocal();
      await controller.selectFolder('');

      expect(controller.currentState().selectedFolderUri).assertEqual('');
      expect(controller.currentState().refreshing).assertFalse();
      await refresh;
    });

    it('showsPersistentAlbumCacheBeforeAlbumRefresh', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      const folder: LocalMediaFolder = new LocalMediaFolder('album://camera', 'Camera', 1, 1, 0);
      gateway.scanResult = new LocalMediaScanResult([], [folder]);
      gateway.cachedAlbumResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://cached-album.mp4', 'cached-album.mp4',
          1000, 1920, 1080, 10, 1, LocalFileCategory.VIDEO, folder.uri)
      ]);
      gateway.albumScanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://fresh-album.mp4', 'fresh-album.mp4',
          1000, 1920, 1080, 10, 2, LocalFileCategory.VIDEO, folder.uri)
      ]);
      const observed: LibraryFeatureState[] = [];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), (state: LibraryFeatureState) => observed.push(state));

      await controller.initialize();
      await controller.selectFolder(folder.uri);

      let cacheWasVisible: boolean = false;
      for (const state of observed) {
        if (state.selectedFolderUri === folder.uri && state.refreshing &&
          state.localItems.length === 1 && state.localItems[0].displayName === 'cached-album.mp4') {
          cacheWasVisible = true;
        }
      }
      expect(cacheWasVisible).assertTrue();
      expect(gateway.cachedAlbumCalls).assertEqual(1);
      expect(gateway.albumScanCalls).assertEqual(1);
      expect(controller.currentState().localItems[0].displayName).assertEqual('fresh-album.mp4');
    });

    it('keepsDeniedLibraryPermissionOutOfTheErrorState', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      gateway.permission = new LocalMediaPermissionResult(false, 201);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.scanLocal();

      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.PERMISSION_DENIED);
      expect(controller.currentState().scanFailure).assertNull();
    });

    it('persistsPickedFilesAndProjectsThemAtAlbumRoot', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([]);
      gateway.pickResult = new LocalMediaPickResult([
        MediaSource.fromLocalDocument('file://picked-a.mp4'),
        MediaSource.fromLocalDocument('file://picked-b.mkv')
      ]);
      const manual = new FakeManualMediaRepository();
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();
      const added: number = await controller.pickLocal();

      expect(added).assertEqual(2);
      expect(manual.addCalls).assertEqual(1);
      expect(controller.currentState().localItems.length).assertEqual(2);
      expect(controller.currentState().localItems[0].isManuallyAdded()).assertTrue();
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.READY);
    });

    it('countsRepeatedSelectionsOnlyOncePerImport', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      const manual = new FakeManualMediaRepository();
      const source = MediaSource.fromLocalDocument('file://shared.mp4');
      gateway.pickResult = new LocalMediaPickResult([source, source]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);
      await controller.initialize();

      expect(await controller.pickLocal()).assertEqual(1);
      expect(controller.currentState().localItems.length).assertEqual(1);
    });

    it('reportsSkippedDuplicatesButAllowsTheSameFileInAnotherFolder', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      gateway.pickResult = new LocalMediaPickResult([
        MediaSource.fromLocalDocument('file://shared.mp4')
      ]);
      const manual = new FakeManualMediaRepository();
      const folder = (await manual.createFolder('', 'Custom'))[0];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);
      await controller.initialize();
      expect(await controller.pickLocal()).assertEqual(1);
      let skippedCount: number = 0;
      expect(await controller.pickLocal('', (added: number, skipped: number) => {
        expect(added).assertEqual(0);
        skippedCount = skipped;
      })).assertEqual(0);
      expect(skippedCount).assertEqual(1);
      expect(await controller.pickLocal(folder.uri)).assertEqual(1);
      expect(manual.items.length).assertEqual(2);
      expect(manual.items[0].uri === manual.items[1].uri).assertFalse();

      gateway.pickResult = new LocalMediaPickResult([]);
      let completed: boolean = false;
      expect(await controller.pickLocal(folder.uri, () => {
        completed = true;
      })).assertEqual(0);
      expect(completed).assertFalse();
    });

    it('nestsAndRecursivelyRemovesVirtualFoldersWithoutRemovingOtherAliases', 0, async () => {
      const manual = new FakeManualMediaRepository();
      const source = MediaSource.fromLocalDocument('file://shared.mp4');
      const parent = (await manual.createFolder('', 'Parent'))[0];
      const child = (await manual.createFolder(parent.uri, 'Child'))[1];

      await manual.add([source], '');
      await manual.add([source], child.uri);
      await manual.removeFolder(parent.uri);

      expect((await manual.loadFolders()).length).assertEqual(0);
      const items = await manual.load();
      expect(items.length).assertEqual(1);
      expect(items[0].parentUri).assertEqual('');
      expect(items[0].sourceUri).assertEqual('file://shared.mp4');
    });

    it('projectsVirtualFoldersWithoutScanningTheSystemLibrary', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      const manual = new FakeManualMediaRepository();
      const folder = (await manual.createFolder('', 'Watch later'))[0];
      await manual.add([MediaSource.fromLocalDocument('file://episode.mp4')], folder.uri);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();
      expect(controller.currentState().localFolders.length).assertEqual(2);
      await controller.selectFolder(folder.uri);

      expect(controller.currentState().selectedFolderUri).assertEqual(folder.uri);
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(gateway.albumScanCalls).assertEqual(0);
    });

    it('importsIntoVirtualFoldersButNotSystemFolders', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      gateway.pickResult = new LocalMediaPickResult([
        MediaSource.fromLocalDocument('file://episode.mp4')
      ]);
      const manual = new FakeManualMediaRepository();
      const virtualFolder = (await manual.createFolder('', 'Virtual'))[0];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();
      expect(controller.canManageVirtualEntries('')).assertTrue();
      await controller.selectFolder(virtualFolder.uri);
      expect(controller.canManageVirtualEntries()).assertTrue();
      expect(await controller.pickLocal()).assertEqual(1);
      expect((await manual.load())[0].parentUri).assertEqual(virtualFolder.uri);

      const systemFolder = new LocalMediaFolder('album://system', 'System', 1, 1, 0);
      gateway.scanResult = new LocalMediaScanResult([], [systemFolder]);
      gateway.authorized = true;
      await controller.selectFolder('');
      await controller.scanLocal();
      await controller.selectFolder(systemFolder.uri);
      expect(controller.canManageVirtualEntries()).assertFalse();
      expect(await controller.pickLocal()).assertEqual(0);
    });

    it('refreshesVirtualFoldersWithoutMediaLibraryPermission', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      gateway.permission = new LocalMediaPermissionResult(false, 201);
      const manual = new FakeManualMediaRepository();
      const folder = (await manual.createFolder('', 'Offline'))[0];
      await manual.add([MediaSource.fromLocalDocument('file://offline.mp4')], folder.uri);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();
      await controller.selectFolder(folder.uri);
      await controller.scanLocal();

      expect(controller.currentState().selectedFolderUri).assertEqual(folder.uri);
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.READY);
    });

    it('refreshesVirtualFolderCountsAfterRemovingAnAlias', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      const manual = new FakeManualMediaRepository();
      const folder = (await manual.createFolder('', 'Two items'))[0];
      await manual.add([MediaSource.fromLocalDocument('file://one.mp4')], folder.uri);
      await manual.add([MediaSource.fromLocalDocument('file://two.mp4')], folder.uri);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();
      expect(controller.currentState().localFolders[0].totalCount).assertEqual(2);
      await controller.removeManual((await manual.load())[0].uri);

      expect(controller.currentState().localFolders[0].totalCount).assertEqual(1);
    });

    it('deduplicatesManualFilesOnlyInVideoMode', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://same.mp4', 'same.mp4', 1000, 1920, 1080, 10, 1)
      ]);
      const manual = new FakeManualMediaRepository();
      manual.items = [new LocalMediaAsset('file://same.mp4', 'same.mp4', 0, 0, 0, 10, 1,
        LocalFileCategory.VIDEO, '', LocalMediaOrigin.DOCUMENT_PICKER)];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().localItems[0].isManuallyAdded()).assertTrue();
      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().localItems[0].isManuallyAdded()).assertFalse();
      await controller.setBrowseMode(LocalBrowseMode.VIDEO);
      expect(controller.currentState().localItems.length).assertEqual(1);
    });

    it('keepsUnavailableManualFilesVisibleButNotPlayable', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      const manual = new FakeManualMediaRepository();
      manual.items = [new LocalMediaAsset('file://missing.mp4', 'missing.mp4', 0, 0, 0, 0, 1,
        LocalFileCategory.VIDEO, '', LocalMediaOrigin.DOCUMENT_PICKER,
        LocalMediaAvailability.UNAVAILABLE)];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();

      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().localItems[0].isAvailable()).assertFalse();
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.READY);
    });

    it('removesUnavailableManualFilesAsOneRepositoryOperation', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.authorized = false;
      const manual = new FakeManualMediaRepository();
      manual.items = [
        new LocalMediaAsset('file://available.mp4', 'available.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, '', LocalMediaOrigin.DOCUMENT_PICKER),
        new LocalMediaAsset('file://missing.mp4', 'missing.mp4', 0, 0, 0, 0, 1,
          LocalFileCategory.VIDEO, '', LocalMediaOrigin.DOCUMENT_PICKER,
          LocalMediaAvailability.UNAVAILABLE)
      ];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, manual);

      await controller.initialize();
      await controller.removeUnavailableManual();

      expect(manual.removeUnavailableCalls).assertEqual(1);
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().localItems[0].displayName).assertEqual('available.mp4');
    });

    it('loadsPlaybackProgressWithoutChangingMediaAssets', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://movie.mp4', 'movie.mp4', 120000, 1920, 1080, 10, 1)
      ]);
      const progress = new FakeLocalMediaProgressRepository();
      progress.items = [new LocalMediaPlaybackProgress('file://movie.mp4', 30000, 120000, 10)];
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {}, null, progress);

      await controller.initialize();

      expect(progress.loadCalls).assertEqual(1);
      expect(controller.currentState().playbackProgress.length).assertEqual(1);
      expect(controller.currentState().playbackProgress[0].ratio()).assertEqual(0.25);
    });

    it('ownsFolderFilteringAndSelectionOutsideArkUI', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://video.mp4', 'video.mp4', 1000, 1920, 1080, 10, 1)
      ], [
        new LocalMediaFolder('album://camera', 'Camera', 4, 2, 2),
        new LocalMediaFolder('album://empty', 'Empty', 0, 0, 0)
      ]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      await controller.setFolderFilter(LocalMediaFolderFilter.ALL);
      await controller.selectFolder('album://empty');
      await controller.selectFolder('');
      await controller.selectFolder('album://empty');

      expect(controller.currentState().folderFilter).assertEqual(LocalMediaFolderFilter.ALL);
      expect(controller.currentState().selectedFolderUri).assertEqual('album://empty');
      expect(controller.currentState().localFolders.length).assertEqual(3);
      expect(gateway.scanCalls).assertEqual(1);
      expect(gateway.albumScanCalls).assertEqual(1);
    });

    it('refreshesOnlyTheSelectedAlbumWhileInsideAnAlbum', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([], [
        new LocalMediaFolder('album://camera', 'Camera', 1, 1, 0)
      ]);
      gateway.albumScanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://first.mp4', 'first.mp4', 1000, 1920, 1080, 10, 1,
          LocalFileCategory.VIDEO, 'album://camera')
      ]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      await controller.selectFolder('album://camera');
      gateway.albumScanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://second.mp4', 'second.mp4', 2000, 1920, 1080, 10, 1,
          LocalFileCategory.VIDEO, 'album://camera')
      ]);
      await controller.scanLocal();

      expect(gateway.scanCalls).assertEqual(1);
      expect(gateway.albumScanCalls).assertEqual(2);
      expect(controller.currentState().selectedFolderUri).assertEqual('album://camera');
      expect(controller.currentState().localItems.length).assertEqual(1);
      expect(controller.currentState().localItems[0].displayName).assertEqual('second.mp4');
    });

    it('ownsBrowseModeAndFileFilterOutsideArkUI', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://video.mp4', 'video.mp4', 1000, 1920, 1080, 10, 1),
        new LocalMediaAsset('file://video.mp4', 'video.mp4', 1000, 1920, 1080, 10, 1)
      ], [new LocalMediaFolder('album://camera', 'Camera', 1, 1, 0)]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      await controller.setBrowseMode(LocalBrowseMode.VIDEO);
      await controller.setFileFilter(new LocalFileFilter(['mkv'], ['srt']));

      expect(controller.currentState().browseMode).assertEqual(LocalBrowseMode.VIDEO);
      expect(controller.currentState().selectedFolderUri).assertEqual('');
      expect(controller.currentState().localItems.length).assertEqual(0);
      expect(gateway.scanCalls).assertEqual(1);
    });

    it('keepsAlbumOnlyRootViewsReady', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([], [
        new LocalMediaFolder('album://travel', 'Travel', 10, 10, 0)
      ]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      gateway.albumScanResult = new LocalMediaScanResult([]);
      await controller.selectFolder('album://travel');

      expect(controller.currentState().selectedFolderUri).assertEqual('album://travel');
      expect(controller.currentState().localFolders.length).assertEqual(2);
      expect(controller.currentState().scanState).assertEqual(LocalMediaScanState.EMPTY);
    });

    it('coalescesMediaLibraryChangeNotifications', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://video.mp4', 'video.mp4', 1000, 1920, 1080, 10, 1)
      ]);
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      gateway.changeObserver!();
      gateway.changeObserver!();
      await waitFor(350);
      await settle();

      expect(gateway.scanCalls).assertEqual(2);
      controller.dispose();
    });

    it('skipsTrailingMediaChangeWhenCompletedFingerprintAlreadyMatches', 0, async () => {
      const gateway = new FakeLocalMediaGateway();
      gateway.scanResult = new LocalMediaScanResult([
        new LocalMediaAsset('file://video.mp4', 'video.mp4', 1000, 1920, 1080, 10, 1)
      ], [], '', 0, true, 1, Date.now(), 'fingerprint-a');
      gateway.fingerprintResult = 'fingerprint-a';
      const controller = new LibraryFeatureController(gateway, gateway,
        new FakeRecentMediaRepository(), () => {});

      await controller.initialize();
      gateway.changeObserver!();
      await waitFor(350);
      await settle();

      expect(gateway.probeCalls).assertEqual(1);
      expect(gateway.scanCalls).assertEqual(1);
      await controller.selectFolder(LocalMediaFolder.MEDIA_LIBRARY_URI);
      gateway.changeObserver!();
      await waitFor(350);
      await settle();
      expect(gateway.probeCalls).assertEqual(2);
      expect(gateway.scanCalls).assertEqual(1);
      controller.dispose();
    });

    it('validatesNetworkLinksThroughInjectedProbe', 0, async () => {
      const probe = new FakeNetworkProbe();
      const controller = new NetworkLinkController(probe, () => {});
      controller.setInput('https://media.example.com/movie.mp4');

      await controller.check();

      expect(probe.calls).assertEqual(1);
      expect(controller.currentState().probe!.statusCode).assertEqual(200);
      expect(controller.currentSource()!.displayName).assertEqual('movie.mp4');
    });

    it('ownsPlaybackResumeAndBackgroundPolicyOutsideUI', 0, async () => {
      let port: FakePlaybackPort | null = null;
      const bookmarkRepository = new FakeBookmarkRepository();
      const source: MediaSource = MediaSource.fromLocalDocument('file://movie.mp4');
      const controller = new PlayerFeatureController(
        source,
        (observer: PlaybackObserver) => new PlaybackEngine(observer,
          async (portObserver: PlaybackPortObserver): Promise<PlaybackPort> => {
            port = new FakePlaybackPort(portObserver);
            return port;
          }),
        bookmarkRepository,
        new AppSettings(),
        () => {}
      );

      controller.attachSurface('surface');
      await settle();
      expect(port!.seekPosition).assertEqual(33000);
      expect(controller.currentState().playback.status).assertEqual(PlaybackStatus.PLAYING);

      controller.handleBackground();
      await settle();
      expect(controller.currentState().playback.status).assertEqual(PlaybackStatus.PAUSED);
      controller.stop();
    });

    it('persistsSettingsThroughInjectedRepository', 0, async () => {
      const repository = new FakeSettingsRepository();
      repository.settings = new AppSettings(false, true, false);
      const controller = new SettingsFeatureController(repository, () => {});

      await controller.initialize();
      expect(controller.currentState().settings.rememberPlaybackPosition).assertFalse();

      controller.setAllowCellularPlayback(true);
      await settle();
      expect(repository.saveCalls).assertEqual(1);
      expect(repository.settings.allowCellularPlayback).assertTrue();
      controller.setLocalMediaFolderFilter(LocalMediaFolderFilter.ALL);
      await settle();
      expect(repository.settings.localMediaFolderFilter).assertEqual(LocalMediaFolderFilter.ALL);
      controller.setThemeMode(AppThemeMode.LIGHT);
      await settle();
      expect(repository.settings.themeMode).assertEqual(AppThemeMode.LIGHT);
      controller.setAccentColor(AppAccentColor.PURPLE);
      await settle();
      expect(repository.settings.accentColor).assertEqual(AppAccentColor.PURPLE);
      controller.setAccentColor(AppAccentColor.SYSTEM);
      await settle();
      expect(repository.settings.accentColor).assertEqual(AppAccentColor.SYSTEM);
      controller.setLocalVideoExtensions(['mkv', '.MP4']);
      controller.setLocalSubtitleExtensions(['SRT', '.ass']);
      await settle();
      expect(repository.settings.localVideoExtensions[0]).assertEqual('.mkv');
      expect(repository.settings.localSubtitleExtensions[0]).assertEqual('.srt');
      controller.dispose();
    });

    it('honorsDisabledResumeAndKeepScreenSettings', 0, async () => {
      let port: FakePlaybackPort | null = null;
      const bookmarks = new FakeBookmarkRepository();
      const controller = new PlayerFeatureController(
        MediaSource.fromLocalDocument('file://privacy.mp4'),
        (observer: PlaybackObserver) => new PlaybackEngine(observer,
          async (portObserver: PlaybackPortObserver): Promise<PlaybackPort> => {
            port = new FakePlaybackPort(portObserver);
            return port;
          }),
        bookmarks,
        new AppSettings(false, false, false),
        () => {}
      );

      controller.attachSurface('surface');
      await settle();
      expect(port!.seekPosition).assertEqual(-1);
      expect(controller.currentState().keepScreenOn).assertFalse();
      controller.stop();
    });

    it('registersSourceAdaptersByProtocol', 0, () => {
      const registry = new SourcePluginRegistry();
      const plugin = new FakeWebDavPlugin();

      registry.register(plugin);

      expect(registry.resolve(RemoteProtocol.WEBDAV)).assertEqual(plugin);
      expect(registry.resolve(RemoteProtocol.SMB)).assertNull();
      expect(registry.registeredProtocols()[0]).assertEqual(RemoteProtocol.WEBDAV);
      expect(DiscoveryMethod.MDNS_DNS_SD).assertEqual('mdns_dns_sd');
    });
  });
}
