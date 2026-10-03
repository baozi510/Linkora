import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { MediaLibraryGateway, LocalMediaPermissionResult, LocalMediaScanOptions,
  LocalMediaScanResult } from 'linkora_core';
import { LocalMediaPermission } from '../services/LocalMediaPermission';
import { LocalMediaScanner } from '../services/LocalMediaScanner';
import { LocalMediaIndexStore } from '../services/LocalMediaIndexStore';

export class HarmonyMediaLibraryGateway implements MediaLibraryGateway {
  private context: common.UIAbilityContext;
  private indexStore: LocalMediaIndexStore;
  private changeHelper: photoAccessHelper.PhotoAccessHelper | null = null;
  private changeCallback: ((data: photoAccessHelper.ChangeData) => void) | null = null;
  private rootScanEpoch: number = 0;
  private directoryScanEpoch: number = 0;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.indexStore = new LocalMediaIndexStore(context);
  }

  isAuthorized(): Promise<boolean> {
    return LocalMediaPermission.isGranted();
  }

  requestAuthorization(): Promise<LocalMediaPermissionResult> {
    return LocalMediaPermission.request(this.context);
  }

  loadCached(): Promise<LocalMediaScanResult | null> {
    return this.indexStore.loadCachedLibrary();
  }

  loadCachedDirectory(directoryUri: string): Promise<LocalMediaScanResult | null> {
    return this.indexStore.loadCachedDirectory(directoryUri);
  }

  probeFingerprint(): Promise<string> {
    return LocalMediaScanner.fingerprint(this.context);
  }

  observeChanges(observer: () => void): void {
    this.stopObservingChanges();
    try {
      const helper: photoAccessHelper.PhotoAccessHelper =
        photoAccessHelper.getPhotoAccessHelper(this.context);
      const callback: (data: photoAccessHelper.ChangeData) => void =
        (_data: photoAccessHelper.ChangeData): void => observer();
      this.changeHelper = helper;
      this.changeCallback = callback;
      helper.registerChange(photoAccessHelper.DefaultChangeUri.DEFAULT_PHOTO_URI, true, callback);
      helper.registerChange(photoAccessHelper.DefaultChangeUri.DEFAULT_ALBUM_URI, true, callback);
    } catch (_error) {
      this.stopObservingChanges();
    }
  }

  stopObservingChanges(): void {
    const helper: photoAccessHelper.PhotoAccessHelper | null = this.changeHelper;
    const callback: ((data: photoAccessHelper.ChangeData) => void) | null = this.changeCallback;
    this.changeHelper = null;
    this.changeCallback = null;
    if (helper === null || callback === null) {
      return;
    }
    try {
      helper.unRegisterChange(photoAccessHelper.DefaultChangeUri.DEFAULT_PHOTO_URI, callback);
    } catch (_photoError) {
    }
    try {
      helper.unRegisterChange(photoAccessHelper.DefaultChangeUri.DEFAULT_ALBUM_URI, callback);
    } catch (_albumError) {
    }
  }

  async scan(options: LocalMediaScanOptions = new LocalMediaScanOptions()): Promise<LocalMediaScanResult> {
    const epoch: number = ++this.rootScanEpoch;
    const result: LocalMediaScanResult = await LocalMediaScanner.scan(this.context, options);
    if (epoch !== this.rootScanEpoch) {
      return result;
    }
    return this.indexStore.replaceLibrary(result);
  }

  async scanDirectory(directoryUri: string,
    options: LocalMediaScanOptions = new LocalMediaScanOptions()): Promise<LocalMediaScanResult> {
    const epoch: number = ++this.directoryScanEpoch;
    const result: LocalMediaScanResult = await LocalMediaScanner.scanAlbum(this.context, directoryUri, options);
    if (epoch !== this.directoryScanEpoch) {
      return result;
    }
    return this.indexStore.replaceDirectory(result);
  }
}
