import { MediaSource } from './MediaSource';
import { LocalFileCategory } from './LocalFileFilter';
import { FileSizeFormatter } from './FileSizeFormatter';

export enum LocalMediaOrigin {
  MEDIA_LIBRARY = 'media_library',
  DOCUMENT_PICKER = 'document_picker'
}

export enum LocalMediaAvailability {
  AVAILABLE = 'available',
  UNAVAILABLE = 'unavailable'
}

export class LocalMediaAsset {
  readonly uri: string;
  readonly displayName: string;
  readonly durationMs: number;
  readonly width: number;
  readonly height: number;
  readonly sizeBytes: number;
  readonly modifiedAt: number;
  readonly category: LocalFileCategory;
  /** URI of the directory that directly contains this entry. */
  readonly parentUri: string;
  /** Compatibility name for media-library backed directory membership. */
  readonly albumUri: string;
  readonly origin: LocalMediaOrigin;
  readonly availability: LocalMediaAvailability;
  /** Real media locator used for I/O when uri is a virtual entry identity. */
  readonly sourceUri: string;

  constructor(uri: string, displayName: string, durationMs: number, width: number, height: number,
    sizeBytes: number, modifiedAt: number, category: LocalFileCategory = LocalFileCategory.VIDEO,
    albumUri: string = '', origin: LocalMediaOrigin = LocalMediaOrigin.MEDIA_LIBRARY,
    availability: LocalMediaAvailability = LocalMediaAvailability.AVAILABLE,
    sourceUri: string = uri) {
    this.uri = uri;
    this.displayName = displayName;
    this.durationMs = Math.max(0, durationMs);
    this.width = Math.max(0, width);
    this.height = Math.max(0, height);
    this.sizeBytes = Math.max(0, sizeBytes);
    const safeModifiedAt: number = Math.max(0, modifiedAt);
    this.modifiedAt = safeModifiedAt > 0 && safeModifiedAt < 1000000000000 ?
      safeModifiedAt * 1000 : safeModifiedAt;
    this.category = category;
    this.parentUri = albumUri;
    this.albumUri = albumUri;
    this.origin = origin;
    this.availability = availability;
    this.sourceUri = sourceUri;
  }

  isVideo(): boolean {
    return this.category === LocalFileCategory.VIDEO;
  }

  isImage(): boolean {
    return this.category === LocalFileCategory.IMAGE;
  }

  isSubtitle(): boolean {
    return this.category === LocalFileCategory.SUBTITLE;
  }

  isAvailable(): boolean {
    return this.availability === LocalMediaAvailability.AVAILABLE;
  }

  isManuallyAdded(): boolean {
    return this.origin === LocalMediaOrigin.DOCUMENT_PICKER;
  }

  toMediaSource(): MediaSource {
    return this.isManuallyAdded() ? MediaSource.fromLocalDocument(this.sourceUri, this.displayName, this.category) :
      MediaSource.fromLocalLibrary(this.uri, this.displayName, this.category);
  }

  contentUri(): string {
    return this.isManuallyAdded() ? this.sourceUri : this.uri;
  }

  durationLabel(): string {
    const totalSeconds: number = Math.floor(this.durationMs / 1000);
    const hours: number = Math.floor(totalSeconds / 3600);
    const minutes: number = Math.floor((totalSeconds % 3600) / 60);
    const seconds: number = totalSeconds % 60;
    const paddedSeconds: string = seconds < 10 ? `0${seconds}` : `${seconds}`;
    if (hours > 0) {
      const paddedMinutes: string = minutes < 10 ? `0${minutes}` : `${minutes}`;
      return `${hours}:${paddedMinutes}:${paddedSeconds}`;
    }
    return `${minutes}:${paddedSeconds}`;
  }

  resolutionLabel(): string {
    if (this.width <= 0 || this.height <= 0) {
      return '清晰度未知';
    }
    const shortEdge: number = Math.min(this.width, this.height);
    if (shortEdge >= 4320) {
      return '8K';
    }
    if (shortEdge >= 2160) {
      return '4K';
    }
    if (shortEdge >= 1440) {
      return '2K';
    }
    if (shortEdge >= 1080) {
      return '1080P';
    }
    if (shortEdge >= 720) {
      return '720P';
    }
    if (shortEdge >= 480) {
      return '480P';
    }
    if (shortEdge >= 360) {
      return '360P';
    }
    return `${shortEdge}P`;
  }

  sizeLabel(): string {
    return FileSizeFormatter.format(this.sizeBytes);
  }
}
