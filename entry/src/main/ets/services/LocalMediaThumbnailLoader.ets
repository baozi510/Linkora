import { common } from '@kit.AbilityKit';
import { dataSharePredicates } from '@kit.ArkData';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

const THUMBNAIL_WIDTH: number = 224;
const THUMBNAIL_HEIGHT: number = 132;
const CACHE_CAPACITY: number = 24;
const FAILURE_CACHE_MS: number = 30 * 1000;

class ThumbnailPixels {
  readonly uri: string;
  readonly pixels: ArrayBuffer;
  readonly info: image.ImageInfo;

  constructor(uri: string, pixels: ArrayBuffer, info: image.ImageInfo) {
    this.uri = uri;
    this.pixels = pixels;
    this.info = info;
  }

  createPixelMap(): Promise<image.PixelMap> {
    const options: image.InitializationOptions = {
      size: this.info.size,
      srcPixelFormat: this.info.pixelFormat,
      pixelFormat: this.info.pixelFormat,
      alphaType: this.info.alphaType,
      editable: false
    };
    return image.createPixelMap(this.pixels, options);
  }
}

export class LocalMediaThumbnailLoader {
  private context: common.UIAbilityContext;
  private cache: ThumbnailPixels[] = [];
  private loadingUris: string[] = [];
  private loadingTasks: Promise<ThumbnailPixels | null>[] = [];
  private failedUris: string[] = [];
  private failedAt: number[] = [];

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async load(uri: string): Promise<image.PixelMap | null> {
    if (uri.length === 0) {
      return null;
    }
    const cached: ThumbnailPixels | null = this.cached(uri);
    if (cached !== null) {
      return cached.createPixelMap();
    }
    if (this.recentlyFailed(uri)) {
      return null;
    }
    const loadingIndex: number = this.loadingUris.indexOf(uri);
    if (loadingIndex >= 0) {
      const shared: ThumbnailPixels | null = await this.loadingTasks[loadingIndex];
      return shared === null ? null : shared.createPixelMap();
    }
    const task: Promise<ThumbnailPixels | null> = this.fetch(uri);
    this.loadingUris.push(uri);
    this.loadingTasks.push(task);
    try {
      const loaded: ThumbnailPixels | null = await task;
      if (loaded === null) {
        this.rememberFailure(uri);
        return null;
      }
      this.remember(loaded);
      return loaded.createPixelMap();
    } finally {
      const index: number = this.loadingUris.indexOf(uri);
      if (index >= 0) {
        this.loadingUris.splice(index, 1);
        this.loadingTasks.splice(index, 1);
      }
    }
  }

  private async fetch(uri: string): Promise<ThumbnailPixels | null> {
    let result: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
    let thumbnail: image.PixelMap | null = null;
    try {
      const helper: photoAccessHelper.PhotoAccessHelper =
        photoAccessHelper.getPhotoAccessHelper(this.context);
      const predicates: dataSharePredicates.DataSharePredicates =
        new dataSharePredicates.DataSharePredicates();
      predicates.equalTo(photoAccessHelper.PhotoKeys.URI, uri);
      const options: photoAccessHelper.FetchOptions = {
        fetchColumns: [],
        predicates: predicates
      };
      result = await helper.getAssets(options);
      if (result.getCount() === 0) {
        return null;
      }
      const asset: photoAccessHelper.PhotoAsset = await result.getFirstObject();
      const size: image.Size = { width: THUMBNAIL_WIDTH, height: THUMBNAIL_HEIGHT };
      thumbnail = await asset.getThumbnail(size);
      const info: image.ImageInfo = await thumbnail.getImageInfo();
      const pixels: ArrayBuffer = new ArrayBuffer(thumbnail.getPixelBytesNumber());
      await thumbnail.readPixelsToBuffer(pixels);
      return new ThumbnailPixels(uri, pixels, info);
    } catch (_error) {
      return null;
    } finally {
      if (thumbnail !== null) {
        try {
          await thumbnail.release();
        } catch (_releaseError) {
        }
      }
      if (result !== null) {
        try {
          result.close();
        } catch (_error) {
        }
      }
    }
  }

  private cached(uri: string): ThumbnailPixels | null {
    const index: number = this.cache.findIndex(
      (entry: ThumbnailPixels): boolean => entry.uri === uri);
    if (index < 0) {
      return null;
    }
    const entry: ThumbnailPixels = this.cache[index];
    this.cache.splice(index, 1);
    this.cache.push(entry);
    return entry;
  }

  private remember(entry: ThumbnailPixels): void {
    const existing: number = this.cache.findIndex(
      (candidate: ThumbnailPixels): boolean => candidate.uri === entry.uri);
    if (existing >= 0) {
      this.cache.splice(existing, 1);
    }
    this.cache.push(entry);
    if (this.cache.length > CACHE_CAPACITY) {
      this.cache.splice(0, this.cache.length - CACHE_CAPACITY);
    }
    const failedIndex: number = this.failedUris.indexOf(entry.uri);
    if (failedIndex >= 0) {
      this.failedUris.splice(failedIndex, 1);
      this.failedAt.splice(failedIndex, 1);
    }
  }

  private recentlyFailed(uri: string): boolean {
    const index: number = this.failedUris.indexOf(uri);
    if (index < 0) {
      return false;
    }
    if (Date.now() - this.failedAt[index] < FAILURE_CACHE_MS) {
      return true;
    }
    this.failedUris.splice(index, 1);
    this.failedAt.splice(index, 1);
    return false;
  }

  private rememberFailure(uri: string): void {
    const index: number = this.failedUris.indexOf(uri);
    if (index >= 0) {
      this.failedAt[index] = Date.now();
      return;
    }
    this.failedUris.push(uri);
    this.failedAt.push(Date.now());
    if (this.failedUris.length > CACHE_CAPACITY) {
      this.failedUris.shift();
      this.failedAt.shift();
    }
  }
}
