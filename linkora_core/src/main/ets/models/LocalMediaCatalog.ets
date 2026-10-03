import { LocalBrowseMode } from './LocalFileFilter';
import { LocalMediaAsset } from './LocalMediaAsset';
import { LocalMediaFolder, LocalMediaScanOptions } from './LocalMediaFolder';
import { MediaSource } from './MediaSource';

export class LocalMediaCatalogView {
  readonly items: LocalMediaAsset[];
  readonly folders: LocalMediaFolder[];
  readonly childFolders: LocalMediaFolder[];
  readonly selectedDirectoryUri: string;
  /** Compatibility name retained while the media-library adapter still uses albums. */
  readonly selectedAlbumUri: string;

  constructor(items: LocalMediaAsset[], folders: LocalMediaFolder[], selectedDirectoryUri: string,
    childFolders: LocalMediaFolder[] = folders) {
    this.items = items;
    this.folders = folders;
    this.childFolders = childFolders;
    this.selectedDirectoryUri = selectedDirectoryUri;
    this.selectedAlbumUri = selectedDirectoryUri;
  }
}

export class LocalMediaCatalog {
  static createLibraryView(sourceItems: LocalMediaAsset[], options: LocalMediaScanOptions,
    sourceFolders: LocalMediaFolder[]): LocalMediaCatalogView {
    if (options.browseMode === LocalBrowseMode.VIDEO) {
      return LocalMediaCatalog.createView(sourceItems, options, sourceFolders);
    }
    const libraryUri: string = LocalMediaFolder.MEDIA_LIBRARY_URI;
    const libraryFolders: LocalMediaFolder[] = sourceFolders.filter((folder: LocalMediaFolder) =>
      !folder.isVirtual() && folder.parentUri.length === 0);
    const looseItems: LocalMediaAsset[] = sourceItems.filter((item: LocalMediaAsset) =>
      !item.isManuallyAdded() && item.parentUri.length === 0);
    const libraryRoot = new LocalMediaFolder(libraryUri, '本地媒体',
      libraryFolders.reduce((count: number, folder: LocalMediaFolder) => count + folder.totalCount, looseItems.length),
      libraryFolders.reduce((count: number, folder: LocalMediaFolder) => count + folder.videoCount,
        looseItems.filter((item: LocalMediaAsset) => item.isVideo()).length),
      libraryFolders.reduce((count: number, folder: LocalMediaFolder) => count + folder.imageCount,
        looseItems.filter((item: LocalMediaAsset) => item.isImage()).length), '',
      libraryFolders.reduce((count: number, folder: LocalMediaFolder) => count + folder.subtitleCount,
        looseItems.filter((item: LocalMediaAsset) => item.isSubtitle()).length), '',
      libraryFolders.reduce((size: number, folder: LocalMediaFolder) => size + folder.totalSizeBytes,
        looseItems.reduce((size: number, item: LocalMediaAsset) => size + item.sizeBytes, 0)),
      false, libraryFolders.length);
    const folders: LocalMediaFolder[] = sourceFolders.map((folder: LocalMediaFolder): LocalMediaFolder => {
      if (folder.isVirtual() || folder.parentUri.length > 0) {
        return folder;
      }
      return new LocalMediaFolder(folder.uri, folder.displayName, folder.totalCount, folder.videoCount,
        folder.imageCount, folder.coverUri, folder.subtitleCount, libraryUri, folder.totalSizeBytes,
        false, folder.folderCount);
    });
    folders.push(libraryRoot);
    const view: LocalMediaCatalogView = LocalMediaCatalog.createView(sourceItems.filter(
      (item: LocalMediaAsset) => item.isManuallyAdded() || item.parentUri.length > 0), options, folders);
    const items: LocalMediaAsset[] = view.selectedDirectoryUri === libraryUri ?
      looseItems.filter((item: LocalMediaAsset) => options.acceptsFile(item.displayName)) : view.items;
    return new LocalMediaCatalogView(items, view.folders, view.selectedDirectoryUri, view.childFolders);
  }

  static newManualSources(sources: MediaSource[], items: LocalMediaAsset[],
    parentUri: string): MediaSource[] {
    const locators: Set<string> = new Set<string>();
    for (const item of items) {
      if (item.isManuallyAdded() && item.parentUri === parentUri) {
        locators.add(item.contentUri());
      }
    }
    return sources.filter((source: MediaSource): boolean => {
      if (source.locator.length === 0 || locators.has(source.locator)) {
        return false;
      }
      locators.add(source.locator);
      return true;
    });
  }

  static createView(sourceItems: LocalMediaAsset[], options: LocalMediaScanOptions,
    sourceAlbums: LocalMediaFolder[] = []): LocalMediaCatalogView {
    const candidates: LocalMediaAsset[] = options.browseMode === LocalBrowseMode.VIDEO ?
      LocalMediaCatalog.uniqueItems(sourceItems) : sourceItems;
    const accepted: LocalMediaAsset[] = candidates.filter((item: LocalMediaAsset) =>
      options.acceptsFile(item.displayName));
    if (options.browseMode === LocalBrowseMode.VIDEO) {
      return new LocalMediaCatalogView(accepted.filter((item: LocalMediaAsset) => item.isVideo()), [], '');
    }

    const selectedDirectoryUri: string = options.selectedFolderUri.length === 0 ||
      sourceAlbums.some((directory: LocalMediaFolder) => directory.uri === options.selectedFolderUri) ?
      options.selectedFolderUri : '';
    const directories: LocalMediaFolder[] = sourceAlbums.filter((directory: LocalMediaFolder) =>
      directory.matches(options.folderFilter));
    directories.sort((left: LocalMediaFolder, right: LocalMediaFolder) => {
      const leftName: string = left.displayName.toLowerCase();
      const rightName: string = right.displayName.toLowerCase();
      if (leftName === rightName) {
        return left.uri < right.uri ? -1 : 1;
      }
      return leftName < rightName ? -1 : 1;
    });
    const childDirectories: LocalMediaFolder[] = directories.filter((directory: LocalMediaFolder) =>
      directory.parentUri === selectedDirectoryUri);
    const items: LocalMediaAsset[] = accepted.filter((item: LocalMediaAsset) =>
      item.parentUri === selectedDirectoryUri);
    return new LocalMediaCatalogView(items, directories, selectedDirectoryUri, childDirectories);
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

}
