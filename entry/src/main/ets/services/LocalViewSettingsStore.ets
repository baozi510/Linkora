import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { LocalBrowseMode } from 'linkora_core';
import { LOCAL_VIEW_SETTINGS_SCHEMA_VERSION, LocalMediaAvailabilityFilter, LocalMediaSortField,
  LocalMediaSourceFilter, LocalMediaTypeFilter, LocalViewSettings } from '../models/LocalMediaViewOptions';

const STORE_NAME: string = 'local_view_settings';
const KEY_SCHEMA_VERSION: string = 'schema_version';
const KEY_BROWSE_MODE: string = 'browse_mode';
const KEY_GRID_VIEW: string = 'grid_view';
const KEY_SORT_FIELD: string = 'sort_field';
const KEY_SORT_ASCENDING: string = 'sort_ascending';
const KEY_TYPE_FILTER: string = 'type_filter';
const KEY_SOURCE_FILTER: string = 'source_filter';
const KEY_AVAILABILITY_FILTER: string = 'availability_filter';
const KEY_SHOW_ITEM_COUNT: string = 'show_item_count';
const KEY_SHOW_SIZE: string = 'show_size';
const KEY_SHOW_RESOLUTION: string = 'show_resolution';
const KEY_SHOW_FILE_EXTENSION: string = 'show_file_extension';
const KEY_SHOW_DURATION: string = 'show_duration';
const KEY_SHOW_MODIFIED_DATE: string = 'show_modified_date';
const KEY_SHOW_HIDDEN_ITEMS: string = 'show_hidden_items';
const KEY_SHOW_THUMBNAILS: string = 'show_thumbnails';

export class LocalViewSettingsStore {
  private static cachedSettings: LocalViewSettings | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  static peek(): LocalViewSettings | null {
    return LocalViewSettingsStore.cachedSettings === null ? null :
      LocalViewSettingsStore.copy(LocalViewSettingsStore.cachedSettings);
  }

  async load(): Promise<LocalViewSettings> {
    if (LocalViewSettingsStore.cachedSettings !== null) {
      return LocalViewSettingsStore.copy(LocalViewSettingsStore.cachedSettings);
    }
    const settings: LocalViewSettings = new LocalViewSettings();
    try {
      const store: preferences.Preferences = await preferences.getPreferences(this.context, STORE_NAME);
      settings.browseMode = LocalViewSettingsStore.browseMode(
        await store.get(KEY_BROWSE_MODE, settings.browseMode));
      settings.gridView = LocalViewSettingsStore.boolean(
        await store.get(KEY_GRID_VIEW, settings.gridView), settings.gridView);
      settings.sortField = LocalViewSettingsStore.sortField(
        await store.get(KEY_SORT_FIELD, settings.sortField));
      settings.sortAscending = LocalViewSettingsStore.boolean(
        await store.get(KEY_SORT_ASCENDING, settings.sortAscending), settings.sortAscending);
      settings.typeFilter = LocalViewSettingsStore.typeFilter(
        await store.get(KEY_TYPE_FILTER, settings.typeFilter));
      settings.sourceFilter = LocalViewSettingsStore.sourceFilter(
        await store.get(KEY_SOURCE_FILTER, settings.sourceFilter));
      settings.availabilityFilter = LocalViewSettingsStore.availabilityFilter(
        await store.get(KEY_AVAILABILITY_FILTER, settings.availabilityFilter));
      settings.showItemCount = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_ITEM_COUNT, settings.showItemCount), settings.showItemCount);
      settings.showSize = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_SIZE, settings.showSize), settings.showSize);
      settings.showResolution = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_RESOLUTION, settings.showResolution), settings.showResolution);
      settings.showFileExtension = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_FILE_EXTENSION, settings.showFileExtension), settings.showFileExtension);
      settings.showDuration = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_DURATION, settings.showDuration), settings.showDuration);
      settings.showModifiedDate = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_MODIFIED_DATE, settings.showModifiedDate), settings.showModifiedDate);
      settings.showHiddenItems = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_HIDDEN_ITEMS, settings.showHiddenItems), settings.showHiddenItems);
      settings.showThumbnails = LocalViewSettingsStore.boolean(
        await store.get(KEY_SHOW_THUMBNAILS, settings.showThumbnails), settings.showThumbnails);
    } catch (_error) {
      const fallback: LocalViewSettings = new LocalViewSettings();
      LocalViewSettingsStore.cachedSettings = LocalViewSettingsStore.copy(fallback);
      return fallback;
    }
    LocalViewSettingsStore.cachedSettings = LocalViewSettingsStore.copy(settings);
    return settings;
  }

  async save(settings: LocalViewSettings): Promise<void> {
    // Update the session snapshot before the asynchronous preferences write. A recreated
    // LibraryPage can then use the exact current layout on its first render.
    LocalViewSettingsStore.cachedSettings = LocalViewSettingsStore.copy(settings);
    try {
      const store: preferences.Preferences = await preferences.getPreferences(this.context, STORE_NAME);
      await store.put(KEY_SCHEMA_VERSION, LOCAL_VIEW_SETTINGS_SCHEMA_VERSION);
      await store.put(KEY_BROWSE_MODE, settings.browseMode);
      await store.put(KEY_GRID_VIEW, settings.gridView);
      await store.put(KEY_SORT_FIELD, settings.sortField);
      await store.put(KEY_SORT_ASCENDING, settings.sortAscending);
      await store.put(KEY_TYPE_FILTER, settings.typeFilter);
      await store.put(KEY_SOURCE_FILTER, settings.sourceFilter);
      await store.put(KEY_AVAILABILITY_FILTER, settings.availabilityFilter);
      await store.put(KEY_SHOW_ITEM_COUNT, settings.showItemCount);
      await store.put(KEY_SHOW_SIZE, settings.showSize);
      await store.put(KEY_SHOW_RESOLUTION, settings.showResolution);
      await store.put(KEY_SHOW_FILE_EXTENSION, settings.showFileExtension);
      await store.put(KEY_SHOW_DURATION, settings.showDuration);
      await store.put(KEY_SHOW_MODIFIED_DATE, settings.showModifiedDate);
      await store.put(KEY_SHOW_HIDDEN_ITEMS, settings.showHiddenItems);
      await store.put(KEY_SHOW_THUMBNAILS, settings.showThumbnails);
      await store.flush();
    } catch (_error) {
      throw new Error('Unable to persist local view settings');
    }
  }

  private static boolean(value: preferences.ValueType, fallback: boolean): boolean {
    return typeof value === 'boolean' ? value : fallback;
  }

  private static copy(source: LocalViewSettings): LocalViewSettings {
    const target: LocalViewSettings = new LocalViewSettings();
    target.browseMode = source.browseMode;
    target.gridView = source.gridView;
    target.sortField = source.sortField;
    target.sortAscending = source.sortAscending;
    target.typeFilter = source.typeFilter;
    target.sourceFilter = source.sourceFilter;
    target.availabilityFilter = source.availabilityFilter;
    target.showItemCount = source.showItemCount;
    target.showSize = source.showSize;
    target.showResolution = source.showResolution;
    target.showFileExtension = source.showFileExtension;
    target.showDuration = source.showDuration;
    target.showModifiedDate = source.showModifiedDate;
    target.showHiddenItems = source.showHiddenItems;
    target.showThumbnails = source.showThumbnails;
    return target;
  }

  private static browseMode(value: preferences.ValueType): LocalBrowseMode {
    return value === LocalBrowseMode.VIDEO ? LocalBrowseMode.VIDEO : LocalBrowseMode.DIRECTORY;
  }

  private static sortField(value: preferences.ValueType): LocalMediaSortField {
    if (value === LocalMediaSortField.ITEM_COUNT || value === LocalMediaSortField.MODIFIED ||
      value === LocalMediaSortField.PLAYBACK_TIME || value === LocalMediaSortField.STATUS ||
      value === LocalMediaSortField.SIZE || value === LocalMediaSortField.DURATION ||
      value === LocalMediaSortField.RESOLUTION || value === LocalMediaSortField.PATH ||
      value === LocalMediaSortField.FRAME_RATE || value === LocalMediaSortField.TYPE) {
      return value;
    }
    return LocalMediaSortField.NAME;
  }

  private static typeFilter(value: preferences.ValueType): LocalMediaTypeFilter {
    if (value === LocalMediaTypeFilter.VIDEO || value === LocalMediaTypeFilter.IMAGE ||
      value === LocalMediaTypeFilter.AUDIO || value === LocalMediaTypeFilter.SUBTITLE) {
      return value;
    }
    return LocalMediaTypeFilter.ALL;
  }

  private static sourceFilter(value: preferences.ValueType): LocalMediaSourceFilter {
    if (value === LocalMediaSourceFilter.MEDIA_LIBRARY || value === LocalMediaSourceFilter.MANUAL) {
      return value;
    }
    return LocalMediaSourceFilter.ALL;
  }

  private static availabilityFilter(value: preferences.ValueType): LocalMediaAvailabilityFilter {
    if (value === LocalMediaAvailabilityFilter.AVAILABLE ||
      value === LocalMediaAvailabilityFilter.UNAVAILABLE) {
      return value;
    }
    return LocalMediaAvailabilityFilter.ALL;
  }
}
