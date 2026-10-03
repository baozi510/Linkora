import { common } from '@kit.AbilityKit';
import { dataSharePredicates } from '@kit.ArkData';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { LocalFileCategory, LocalMediaAsset,
  LocalMediaFolder, LocalMediaScanOptions, LocalMediaScanResult } from 'linkora_core';

interface AlbumPathInfo {
  readonly lpath?: string;
}

class AlbumQueryResult {
  readonly albums: photoAccessHelper.Album[];
  readonly errorCode: number;

  constructor(albums: photoAccessHelper.Album[], errorCode: number = 0) {
    this.albums = albums;
    this.errorCode = errorCode;
  }
}

class AlbumMediaStats {
  readonly videoCount: number;
  readonly imageCount: number;
  readonly totalSizeBytes: number;

  constructor(videoCount: number = 0, imageCount: number = 0, totalSizeBytes: number = 0) {
    this.videoCount = Math.max(0, videoCount);
    this.imageCount = Math.max(0, imageCount);
    this.totalSizeBytes = Math.max(0, totalSizeBytes);
  }
}

class AssetQueryResult {
  readonly assets: photoAccessHelper.PhotoAsset[];
  readonly expectedCount: number;

  constructor(assets: photoAccessHelper.PhotoAsset[], expectedCount: number) {
    this.assets = assets;
    this.expectedCount = Math.max(0, expectedCount);
  }

  complete(): boolean {
    return this.assets.length === this.expectedCount;
  }
}

const OWNER_ALBUM_ID_KEY: string = 'owner_album_id';
const SOURCE_ALBUM_TYPE: photoAccessHelper.AlbumType = 2048 as photoAccessHelper.AlbumType;
const SOURCE_ALBUM_SUBTYPE: photoAccessHelper.AlbumSubtype = 2049 as photoAccessHelper.AlbumSubtype;
const UNRESOLVED_ALBUM_URI: string = 'linkora://unresolved-album';

export class LocalMediaScanner {
  static async scan(context: common.UIAbilityContext,
    scanOptions: LocalMediaScanOptions = new LocalMediaScanOptions()): Promise<LocalMediaScanResult> {
    try {
      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const albumQuery: AlbumQueryResult = await LocalMediaScanner.queryAlbums(helper);
      if (albumQuery.errorCode !== 0) {
        return new LocalMediaScanResult([], [], '', albumQuery.errorCode);
      }
      const albums: photoAccessHelper.Album[] = albumQuery.albums;
      const browsableAlbums: photoAccessHelper.Album[] = albums.filter((album: photoAccessHelper.Album) =>
        LocalMediaScanner.isBrowsableAlbum(album));
      // The persisted source is always a complete media-library snapshot. Browse mode is
      // deliberately applied later as a projection so a video refresh cannot evict images.
      const assetQuery: AssetQueryResult = await LocalMediaScanner.queryAssets(helper,
        deviceInfo.distributionOSApiVersion >= 22, scanOptions.maxResults);
      const scanFingerprint: string = LocalMediaScanner.buildFingerprint(
        albums, assetQuery.expectedCount, assetQuery.assets.length > 0 ? assetQuery.assets[0] : null);
      const folders: LocalMediaFolder[] = await LocalMediaScanner.mapFolders(
        browsableAlbums, scanOptions.maxResults);
      const items: LocalMediaAsset[] = assetQuery.assets.map((asset: photoAccessHelper.PhotoAsset) =>
        LocalMediaScanner.map(asset, deviceInfo.distributionOSApiVersion >= 22 ?
          LocalMediaScanner.resolveAlbumUri(asset, albums) : UNRESOLVED_ALBUM_URI));
      const endingFingerprint: string = await LocalMediaScanner.probeFingerprintWithHelper(helper);
      const snapshotComplete: boolean = assetQuery.complete() && scanFingerprint === endingFingerprint;
      return new LocalMediaScanResult(items, folders, '', 0, snapshotComplete,
        0, 0, snapshotComplete ? endingFingerprint : '');
    } catch (error) {
      return new LocalMediaScanResult([], [], '', (error as BusinessError).code);
    }
  }

  static async fingerprint(context: common.UIAbilityContext): Promise<string> {
    try {
      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      return await LocalMediaScanner.probeFingerprintWithHelper(helper);
    } catch (_error) {
      return '';
    }
  }

  static async scanAlbum(context: common.UIAbilityContext, albumUri: string,
    scanOptions: LocalMediaScanOptions = new LocalMediaScanOptions()): Promise<LocalMediaScanResult> {
    try {
      if (albumUri.length === 0) {
        return new LocalMediaScanResult([]);
      }
      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const albumQuery: AlbumQueryResult = await LocalMediaScanner.queryAlbums(helper);
      if (albumQuery.errorCode !== 0) {
        return new LocalMediaScanResult([], [], albumUri, albumQuery.errorCode);
      }
      const albums: photoAccessHelper.Album[] = albumQuery.albums;
      const album: photoAccessHelper.Album | undefined = albums.find((candidate: photoAccessHelper.Album) =>
        candidate.albumUri === albumUri && LocalMediaScanner.isBrowsableAlbum(candidate));
      if (album === undefined) {
        return new LocalMediaScanResult([], [], '', 13900020);
      }
      const assetQuery: AssetQueryResult = await LocalMediaScanner.queryAlbumAssets(
        album, scanOptions.maxResults);
      const assets: photoAccessHelper.PhotoAsset[] = assetQuery.assets;
      const scanFingerprint: string = LocalMediaScanner.buildAlbumFingerprint(
        albumUri, assetQuery.expectedCount, assets.length > 0 ? assets[0] : null);
      const items: LocalMediaAsset[] = assets.map((asset: photoAccessHelper.PhotoAsset) =>
        LocalMediaScanner.map(asset, albumUri));
      const expectedCount: number = assetQuery.expectedCount;
      const endingFingerprint: string = await LocalMediaScanner.probeAlbumFingerprint(album);
      const snapshotComplete: boolean = assetQuery.complete() && expectedCount === assets.length &&
        scanFingerprint === endingFingerprint;
      return new LocalMediaScanResult(items, [], albumUri, 0, snapshotComplete);
    } catch (error) {
      return new LocalMediaScanResult([], [], albumUri, (error as BusinessError).code);
    }
  }

  private static async queryAlbums(helper: photoAccessHelper.PhotoAccessHelper):
    Promise<AlbumQueryResult> {
    let userResult: photoAccessHelper.FetchResult<photoAccessHelper.Album> | null = null;
    let sourceResult: photoAccessHelper.FetchResult<photoAccessHelper.Album> | null = null;
    try {
      userResult = await helper.getAlbums(photoAccessHelper.AlbumType.USER,
        photoAccessHelper.AlbumSubtype.USER_GENERIC);
      const userAlbums: photoAccessHelper.Album[] = await userResult.getAllObjects();
      let sourceAlbums: photoAccessHelper.Album[] = [];
      if (deviceInfo.distributionOSApiVersion >= 23) {
        try {
          sourceResult = await helper.getAlbums(SOURCE_ALBUM_TYPE, SOURCE_ALBUM_SUBTYPE);
          sourceAlbums = await sourceResult.getAllObjects();
        } catch (_sourceAlbumError) {
          LocalMediaScanner.close(sourceResult);
          sourceResult = null;
        }
      }
      return new AlbumQueryResult(LocalMediaScanner.uniqueAlbums(userAlbums.concat(sourceAlbums)));
    } catch (error) {
      return new AlbumQueryResult([], (error as BusinessError).code);
    } finally {
      LocalMediaScanner.close(userResult);
      LocalMediaScanner.close(sourceResult);
    }
  }

  private static mediaFetchOptions(includeOwnerAlbum: boolean = false,
    limit: number = 0, offset: number = 0): photoAccessHelper.FetchOptions {
    const predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE, photoAccessHelper.PhotoType.VIDEO);
    predicates.orderByDesc(photoAccessHelper.PhotoKeys.DATE_MODIFIED);
    if (limit > 0) {
      predicates.limit(limit, Math.max(0, offset));
    }
    const fetchColumns: string[] = [
      photoAccessHelper.PhotoKeys.PHOTO_TYPE,
      photoAccessHelper.PhotoKeys.SIZE,
      photoAccessHelper.PhotoKeys.DURATION,
      photoAccessHelper.PhotoKeys.WIDTH,
      photoAccessHelper.PhotoKeys.HEIGHT,
      photoAccessHelper.PhotoKeys.DATE_MODIFIED
    ];
    if (includeOwnerAlbum) {
      fetchColumns.push(OWNER_ALBUM_ID_KEY);
    }
    return {
      fetchColumns: fetchColumns,
      predicates: predicates
    };
  }

  private static async mapFolders(albums: photoAccessHelper.Album[], batchSize: number):
    Promise<LocalMediaFolder[]> {
    const folders: LocalMediaFolder[] = [];
    // Two albums at a time avoids a long serial walk without opening an unbounded
    // number of PhotoAccessHelper result sets on large libraries.
    for (let index: number = 0; index < albums.length; index += 2) {
      const chunk: photoAccessHelper.Album[] = albums.slice(index, index + 2);
      const stats: AlbumMediaStats[] = await Promise.all(chunk.map(
        (album: photoAccessHelper.Album): Promise<AlbumMediaStats> =>
          LocalMediaScanner.resolveMediaStats(album, batchSize)));
      for (let chunkIndex: number = 0; chunkIndex < chunk.length; chunkIndex++) {
        const album: photoAccessHelper.Album = chunk[chunkIndex];
        const mediaStats: AlbumMediaStats = stats[chunkIndex];
        folders.push(new LocalMediaFolder(
          album.albumUri,
          album.albumName,
          typeof album.videoCount === 'number' ? album.videoCount : mediaStats.videoCount,
          typeof album.videoCount === 'number' ? album.videoCount : mediaStats.videoCount,
          0,
          album.coverUri,
          0,
          '',
          mediaStats.totalSizeBytes
        ));
      }
    }
    return folders.sort((left: LocalMediaFolder, right: LocalMediaFolder) => {
      const leftName: string = left.displayName.toLowerCase();
      const rightName: string = right.displayName.toLowerCase();
      if (leftName === rightName) {
        return left.uri < right.uri ? -1 : 1;
      }
      return leftName < rightName ? -1 : 1;
    });
  }

  private static async resolveMediaStats(album: photoAccessHelper.Album,
    batchSize: number): Promise<AlbumMediaStats> {
    try {
      const query: AssetQueryResult = await LocalMediaScanner.queryAlbumAssets(album, batchSize);
      const assets: photoAccessHelper.PhotoAsset[] = query.assets;
      let videoCount: number = 0;
      let totalSizeBytes: number = 0;
      for (const asset of assets) {
        if (asset.photoType === photoAccessHelper.PhotoType.VIDEO) {
          ++videoCount;
        }
        totalSizeBytes += LocalMediaScanner.number(asset, photoAccessHelper.PhotoKeys.SIZE);
      }
      return new AlbumMediaStats(
        typeof album.videoCount === 'number' ? album.videoCount : videoCount,
        0,
        totalSizeBytes);
    } catch (error) {
      const failure: BusinessError = error as BusinessError;
      console.warn(`Album media size calculation failed. code=${failure.code}, ` +
        `message=${failure.message}`);
      return new AlbumMediaStats(
        typeof album.videoCount === 'number' ? album.videoCount : 0,
        0);
    }
  }

  private static async queryAssets(helper: photoAccessHelper.PhotoAccessHelper,
    includeOwnerAlbum: boolean, batchSize: number): Promise<AssetQueryResult> {
    let countResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
    try {
      countResult = await helper.getAssets(LocalMediaScanner.mediaFetchOptions(includeOwnerAlbum));
      const expectedCount: number = countResult.getCount();
      LocalMediaScanner.close(countResult);
      countResult = null;
      const assets: photoAccessHelper.PhotoAsset[] = [];
      for (let offset: number = 0; offset < expectedCount; offset += batchSize) {
        let page: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
        try {
          page = await helper.getAssets(LocalMediaScanner.mediaFetchOptions(
            includeOwnerAlbum, Math.min(batchSize, expectedCount - offset), offset));
          LocalMediaScanner.appendUnique(assets, await page.getAllObjects());
        } finally {
          LocalMediaScanner.close(page);
        }
      }
      return new AssetQueryResult(assets, expectedCount);
    } finally {
      LocalMediaScanner.close(countResult);
    }
  }

  private static async queryAlbumAssets(album: photoAccessHelper.Album,
    batchSize: number): Promise<AssetQueryResult> {
    let countResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
    try {
      countResult = await album.getAssets(LocalMediaScanner.mediaFetchOptions());
      const expectedCount: number = countResult.getCount();
      LocalMediaScanner.close(countResult);
      countResult = null;
      const assets: photoAccessHelper.PhotoAsset[] = [];
      for (let offset: number = 0; offset < expectedCount; offset += batchSize) {
        let page: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
        try {
          page = await album.getAssets(LocalMediaScanner.mediaFetchOptions(
            false, Math.min(batchSize, expectedCount - offset), offset));
          LocalMediaScanner.appendUnique(assets, await page.getAllObjects());
        } finally {
          LocalMediaScanner.close(page);
        }
      }
      return new AssetQueryResult(assets, expectedCount);
    } finally {
      LocalMediaScanner.close(countResult);
    }
  }

  private static appendUnique(target: photoAccessHelper.PhotoAsset[],
    values: photoAccessHelper.PhotoAsset[]): void {
    const uris: string[] = target.map((item: photoAccessHelper.PhotoAsset): string => item.uri);
    for (const value of values) {
      if (!uris.includes(value.uri)) {
        uris.push(value.uri);
        target.push(value);
      }
    }
  }

  private static async probeFingerprintWithHelper(helper: photoAccessHelper.PhotoAccessHelper): Promise<string> {
    let result: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
    const albumQuery: AlbumQueryResult = await LocalMediaScanner.queryAlbums(helper);
    if (albumQuery.errorCode !== 0) {
      return '';
    }
    try {
      result = await helper.getAssets(LocalMediaScanner.mediaFetchOptions());
      const count: number = result.getCount();
      const latest: photoAccessHelper.PhotoAsset | null = count > 0 ? await result.getFirstObject() : null;
      return LocalMediaScanner.buildFingerprint(albumQuery.albums, count, latest);
    } finally {
      LocalMediaScanner.close(result);
    }
  }

  private static async probeAlbumFingerprint(album: photoAccessHelper.Album): Promise<string> {
    let result: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
    try {
      result = await album.getAssets(LocalMediaScanner.mediaFetchOptions());
      const count: number = result.getCount();
      const latest: photoAccessHelper.PhotoAsset | null = count > 0 ? await result.getFirstObject() : null;
      return LocalMediaScanner.buildAlbumFingerprint(album.albumUri, count, latest);
    } finally {
      LocalMediaScanner.close(result);
    }
  }

  private static buildFingerprint(albums: photoAccessHelper.Album[], count: number,
    latest: photoAccessHelper.PhotoAsset | null): string {
    const albumParts: string[] = albums.map((album: photoAccessHelper.Album): string =>
      `${album.albumUri}:${album.count}:${album.videoCount ?? -1}:${album.imageCount ?? -1}:` +
      `${album.coverUri ?? ''}`);
    albumParts.sort();
    const latestPart: string = latest === null ? '' :
      `${latest.uri}:${LocalMediaScanner.number(latest, photoAccessHelper.PhotoKeys.SIZE)}:` +
      `${LocalMediaScanner.timestampMs(latest, photoAccessHelper.PhotoKeys.DATE_MODIFIED)}`;
    return `v1|${Math.max(0, count)}|${latestPart}|${albumParts.join('|')}`;
  }

  private static buildAlbumFingerprint(albumUri: string, count: number,
    latest: photoAccessHelper.PhotoAsset | null): string {
    const latestPart: string = latest === null ? '' :
      `${latest.uri}:${LocalMediaScanner.number(latest, photoAccessHelper.PhotoKeys.SIZE)}:` +
      `${LocalMediaScanner.timestampMs(latest, photoAccessHelper.PhotoKeys.DATE_MODIFIED)}`;
    return `album-v1|${albumUri}|${Math.max(0, count)}|${latestPart}`;
  }

  private static close<T>(result: photoAccessHelper.FetchResult<T> | null): void {
    if (result === null) {
      return;
    }
    try {
      result.close();
    } catch (_error) {
    }
  }

  private static map(asset: photoAccessHelper.PhotoAsset, albumUri: string = ''): LocalMediaAsset {
    const category: LocalFileCategory = asset.photoType === photoAccessHelper.PhotoType.IMAGE ?
      LocalFileCategory.IMAGE : LocalFileCategory.VIDEO;
    return new LocalMediaAsset(
      asset.uri,
      asset.displayName,
      LocalMediaScanner.number(asset, photoAccessHelper.PhotoKeys.DURATION),
      LocalMediaScanner.number(asset, photoAccessHelper.PhotoKeys.WIDTH),
      LocalMediaScanner.number(asset, photoAccessHelper.PhotoKeys.HEIGHT),
      LocalMediaScanner.number(asset, photoAccessHelper.PhotoKeys.SIZE),
      LocalMediaScanner.timestampMs(asset, photoAccessHelper.PhotoKeys.DATE_MODIFIED),
      category,
      albumUri
    );
  }

  private static resolveAlbumUri(asset: photoAccessHelper.PhotoAsset,
    albums: photoAccessHelper.Album[]): string {
    const ownerAlbumId: string = LocalMediaScanner.text(asset, OWNER_ALBUM_ID_KEY);
    if (ownerAlbumId === '0') {
      return '';
    }
    for (const album of albums) {
      if (LocalMediaScanner.albumId(album.albumUri) === ownerAlbumId) {
        return LocalMediaScanner.isRootAlbum(album) ? '' : album.albumUri;
      }
    }
    return UNRESOLVED_ALBUM_URI;
  }

  private static uniqueAlbums(albums: photoAccessHelper.Album[]): photoAccessHelper.Album[] {
    const result: photoAccessHelper.Album[] = [];
    const uris: string[] = [];
    for (const album of albums) {
      if (!uris.includes(album.albumUri)) {
        uris.push(album.albumUri);
        result.push(album);
      }
    }
    return result;
  }

  private static isRootAlbum(album: photoAccessHelper.Album): boolean {
    const pathInfo: AlbumPathInfo = album as AlbumPathInfo;
    const lpath: string = (pathInfo.lpath ?? '').trim().split('\\').join('/');
    return lpath === '/Pictures' || lpath === 'Pictures';
  }

  private static isBrowsableAlbum(album: photoAccessHelper.Album): boolean {
    const name: string = album.albumName.trim();
    return name.length > 0 && !name.startsWith('.') && !LocalMediaScanner.isRootAlbum(album);
  }

  private static albumId(albumUri: string): string {
    const query: number = albumUri.indexOf('?');
    const cleanUri: string = query < 0 ? albumUri : albumUri.substring(0, query);
    const slash: number = cleanUri.lastIndexOf('/');
    return slash < 0 ? cleanUri : cleanUri.substring(slash + 1);
  }

  private static text(asset: photoAccessHelper.PhotoAsset, key: string): string {
    try {
      const value: photoAccessHelper.MemberType = asset.get(key);
      return `${value}`;
    } catch (_error) {
      return '';
    }
  }

  private static number(asset: photoAccessHelper.PhotoAsset, key: string): number {
    try {
      const value: photoAccessHelper.MemberType = asset.get(key);
      return typeof value === 'number' ? value : 0;
    } catch (_error) {
      return 0;
    }
  }

  private static timestampMs(asset: photoAccessHelper.PhotoAsset, key: string): number {
    const value: number = LocalMediaScanner.number(asset, key);
    if (value <= 0) {
      return 0;
    }
    // PhotoAccessHelper returns DATE_MODIFIED in seconds; Date expects milliseconds.
    return value < 1000000000000 ? value * 1000 : value;
  }
}
