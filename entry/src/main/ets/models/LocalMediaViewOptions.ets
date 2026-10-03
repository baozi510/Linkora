import { LocalBrowseMode } from 'linkora_core';

export enum LocalMediaSortField {
  NAME = 'name',
  ITEM_COUNT = 'item_count',
  MODIFIED = 'modified',
  PLAYBACK_TIME = 'playback_time',
  STATUS = 'status',
  SIZE = 'size',
  DURATION = 'duration',
  RESOLUTION = 'resolution',
  PATH = 'path',
  FRAME_RATE = 'frame_rate',
  TYPE = 'type'
}

export class LocalMediaSortOptions {
  static supports(mode: LocalBrowseMode, field: LocalMediaSortField): boolean {
    if (mode === LocalBrowseMode.DIRECTORY) {
      return field === LocalMediaSortField.NAME || field === LocalMediaSortField.ITEM_COUNT;
    }
    return field === LocalMediaSortField.NAME || field === LocalMediaSortField.MODIFIED ||
      field === LocalMediaSortField.SIZE || field === LocalMediaSortField.TYPE;
  }

  static normalize(mode: LocalBrowseMode, field: LocalMediaSortField): LocalMediaSortField {
    return LocalMediaSortOptions.supports(mode, field) ? field : LocalMediaSortField.NAME;
  }
}

export enum LocalMediaTypeFilter {
  ALL = 'all',
  VIDEO = 'video',
  IMAGE = 'image',
  AUDIO = 'audio',
  SUBTITLE = 'subtitle'
}

export enum LocalMediaSourceFilter {
  ALL = 'all',
  MEDIA_LIBRARY = 'media_library',
  MANUAL = 'manual'
}

export enum LocalMediaAvailabilityFilter {
  ALL = 'all',
  AVAILABLE = 'available',
  UNAVAILABLE = 'unavailable'
}

export const LOCAL_VIEW_SETTINGS_SCHEMA_VERSION: number = 1;

// UI-specific local media preferences live outside the media-library domain model.
// New fields must have defaults so older preference stores remain forward-compatible.
export class LocalViewSettings {
  browseMode: LocalBrowseMode = LocalBrowseMode.DIRECTORY;
  gridView: boolean = false;
  sortField: LocalMediaSortField = LocalMediaSortField.NAME;
  sortAscending: boolean = true;
  typeFilter: LocalMediaTypeFilter = LocalMediaTypeFilter.ALL;
  sourceFilter: LocalMediaSourceFilter = LocalMediaSourceFilter.ALL;
  availabilityFilter: LocalMediaAvailabilityFilter = LocalMediaAvailabilityFilter.ALL;
  showItemCount: boolean = true;
  showSize: boolean = true;
  showResolution: boolean = true;
  showFileExtension: boolean = false;
  showDuration: boolean = true;
  showModifiedDate: boolean = false;
  showHiddenItems: boolean = false;
  showThumbnails: boolean = true;
}
