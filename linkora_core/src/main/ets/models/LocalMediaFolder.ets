import { LocalBrowseMode, LocalFileCategory, LocalFileFilter } from './LocalFileFilter';
import { FileSizeFormatter } from './FileSizeFormatter';

export enum LocalMediaFolderFilter {
  ALL = 'all',
  NON_EMPTY = 'non_empty',
  VIDEO_ONLY = 'video_only'
}

export class LocalMediaScanOptions {
  readonly folderFilter: LocalMediaFolderFilter;
  readonly selectedFolderUri: string;
  /** Maximum number of PhotoAccessHelper rows fetched per query; not a result cap. */
  readonly maxResults: number;
  readonly browseMode: LocalBrowseMode;
  readonly fileFilter: LocalFileFilter;

  constructor(folderFilter: LocalMediaFolderFilter = LocalMediaFolderFilter.VIDEO_ONLY,
    selectedFolderUri: string = '', maxResults: number = 500,
    browseMode: LocalBrowseMode = LocalBrowseMode.DIRECTORY,
    fileFilter: LocalFileFilter = new LocalFileFilter()) {
    this.folderFilter = folderFilter;
    this.selectedFolderUri = selectedFolderUri;
    this.maxResults = Math.max(1, Math.min(2000, Math.floor(maxResults)));
    this.browseMode = browseMode;
    this.fileFilter = fileFilter;
  }

  acceptsFile(fileName: string): boolean {
    const category: LocalFileCategory = this.fileFilter.categoryOf(fileName);
    if (this.browseMode === LocalBrowseMode.VIDEO) {
      return category === LocalFileCategory.VIDEO;
    }
    return category !== LocalFileCategory.UNSUPPORTED;
  }
}

export class LocalMediaFolder {
  static readonly MEDIA_LIBRARY_URI: string = 'linkora://media-library';
  readonly uri: string;
  readonly displayName: string;
  readonly totalCount: number;
  readonly videoCount: number;
  readonly imageCount: number;
  readonly subtitleCount: number;
  readonly coverUri: string;
  /** URI of the parent directory. An empty value identifies a root child. */
  readonly parentUri: string;
  readonly totalSizeBytes: number;
  readonly virtual: boolean;
  readonly folderCount: number;

  constructor(uri: string, displayName: string, totalCount: number, videoCount: number,
    imageCount: number, coverUri: string = '', subtitleCount: number = 0,
    parentUri: string = '', totalSizeBytes: number = 0, virtual: boolean = false,
    folderCount: number = 0) {
    this.uri = uri;
    this.displayName = displayName.trim().length > 0 ? displayName.trim() : '未命名目录';
    this.totalCount = Math.max(0, totalCount);
    this.videoCount = Math.max(0, videoCount);
    this.imageCount = Math.max(0, imageCount);
    this.subtitleCount = Math.max(0, subtitleCount);
    this.coverUri = coverUri;
    this.parentUri = parentUri;
    this.totalSizeBytes = Math.max(0, totalSizeBytes);
    this.virtual = virtual;
    this.folderCount = Math.max(0, folderCount);
  }

  isEmpty(): boolean {
    return this.totalCount === 0;
  }

  containsVideo(): boolean {
    return this.videoCount > 0;
  }

  isVirtual(): boolean {
    return this.virtual;
  }

  isMediaLibraryRoot(): boolean {
    return this.uri === LocalMediaFolder.MEDIA_LIBRARY_URI;
  }

  matches(filter: LocalMediaFolderFilter): boolean {
    if (this.virtual || this.isMediaLibraryRoot()) {
      return true;
    }
    if (filter === LocalMediaFolderFilter.VIDEO_ONLY) {
      return this.containsVideo();
    }
    if (filter === LocalMediaFolderFilter.NON_EMPTY) {
      return !this.isEmpty();
    }
    return true;
  }

  detailLabel(): string {
    if (this.virtual) {
      const virtualParts: string[] = [];
      if (this.folderCount > 0) {
        virtualParts.push(`${this.folderCount} 个文件夹`);
      }
      if (this.totalCount > 0) {
        virtualParts.push(`${this.totalCount} 个文件`);
      }
      return virtualParts.length > 0 ? virtualParts.join(' · ') : '空目录';
    }
    if (this.isEmpty()) {
      return '空目录';
    }
    const parts: string[] = [];
    if (this.videoCount > 0) {
      parts.push(`${this.videoCount} 个视频`);
    }
    if (this.imageCount > 0) {
      parts.push(`${this.imageCount} 张图片`);
    }
    if (this.subtitleCount > 0) {
      parts.push(`${this.subtitleCount} 个字幕`);
    }
    return parts.length > 0 ? parts.join(' · ') : `${this.totalCount} 项`;
  }

  sizeLabel(): string {
    return FileSizeFormatter.format(this.totalSizeBytes);
  }
}
