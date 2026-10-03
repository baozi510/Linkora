import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AppAccentColor, AppSettings, AppThemeMode, DEFAULT_SUBTITLE_EXTENSIONS,
  DEFAULT_VIDEO_EXTENSIONS, LocalMediaFolderFilter, SettingsRepository } from 'linkora_core';

const STORE_NAME: string = 'app_settings';
const KEY_SCHEMA_VERSION: string = 'schema_version';
const KEY_REMEMBER_POSITION: string = 'remember_playback_position';
const KEY_KEEP_SCREEN_ON: string = 'keep_screen_on_during_playback';
const KEY_ALLOW_CELLULAR: string = 'allow_cellular_playback';
const KEY_LOCAL_FOLDER_FILTER: string = 'local_media_folder_filter';
const KEY_THEME_MODE: string = 'theme_mode';
const KEY_ACCENT_COLOR: string = 'accent_color';
const KEY_LOCAL_VIDEO_EXTENSIONS: string = 'local_video_extensions';
const KEY_LOCAL_SUBTITLE_EXTENSIONS: string = 'local_subtitle_extensions';
const KEY_EXPERIMENTAL_NETWORK_STORAGE: string = 'experimental_network_storage';
const SCHEMA_VERSION: number = 7;

export class AppSettingsStore implements SettingsRepository {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async load(): Promise<AppSettings> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(this.context, STORE_NAME);
      const remember: preferences.ValueType = await store.get(KEY_REMEMBER_POSITION, true);
      const keepScreenOn: preferences.ValueType = await store.get(KEY_KEEP_SCREEN_ON, true);
      const allowCellular: preferences.ValueType = await store.get(KEY_ALLOW_CELLULAR, false);
      const folderFilter: preferences.ValueType = await store.get(KEY_LOCAL_FOLDER_FILTER,
        LocalMediaFolderFilter.VIDEO_ONLY);
      const themeMode: preferences.ValueType = await store.get(KEY_THEME_MODE, AppThemeMode.SYSTEM);
      const accentColor: preferences.ValueType = await store.get(KEY_ACCENT_COLOR, AppAccentColor.SYSTEM);
      const videoExtensions: preferences.ValueType = await store.get(KEY_LOCAL_VIDEO_EXTENSIONS,
        DEFAULT_VIDEO_EXTENSIONS.join(','));
      const subtitleExtensions: preferences.ValueType = await store.get(KEY_LOCAL_SUBTITLE_EXTENSIONS,
        DEFAULT_SUBTITLE_EXTENSIONS.join(','));
      const experimentalNetworkStorage: preferences.ValueType =
        await store.get(KEY_EXPERIMENTAL_NETWORK_STORAGE, false);
      return new AppSettings(
        typeof remember === 'boolean' ? remember : true,
        typeof keepScreenOn === 'boolean' ? keepScreenOn : true,
        typeof allowCellular === 'boolean' ? allowCellular : false,
        AppSettingsStore.folderFilter(folderFilter),
        AppSettingsStore.themeMode(themeMode),
        AppSettingsStore.accentColor(accentColor),
        AppSettingsStore.extensions(videoExtensions, DEFAULT_VIDEO_EXTENSIONS),
        AppSettingsStore.extensions(subtitleExtensions, DEFAULT_SUBTITLE_EXTENSIONS),
        typeof experimentalNetworkStorage === 'boolean' ? experimentalNetworkStorage : false
      );
    } catch (_error) {
      return new AppSettings();
    }
  }

  async save(settings: AppSettings): Promise<void> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(this.context, STORE_NAME);
      await store.put(KEY_SCHEMA_VERSION, SCHEMA_VERSION);
      await store.put(KEY_REMEMBER_POSITION, settings.rememberPlaybackPosition);
      await store.put(KEY_KEEP_SCREEN_ON, settings.keepScreenOnDuringPlayback);
      await store.put(KEY_ALLOW_CELLULAR, settings.allowCellularPlayback);
      await store.put(KEY_LOCAL_FOLDER_FILTER, settings.localMediaFolderFilter);
      await store.put(KEY_THEME_MODE, settings.themeMode);
      await store.put(KEY_ACCENT_COLOR, settings.accentColor);
      await store.put(KEY_LOCAL_VIDEO_EXTENSIONS, settings.localVideoExtensions.join(','));
      await store.put(KEY_LOCAL_SUBTITLE_EXTENSIONS, settings.localSubtitleExtensions.join(','));
      await store.put(KEY_EXPERIMENTAL_NETWORK_STORAGE, settings.experimentalNetworkStorage);
      await store.flush();
    } catch (_error) {
      throw new Error('Unable to persist application settings');
    }
  }

  private static folderFilter(value: preferences.ValueType): LocalMediaFolderFilter {
    if (value === LocalMediaFolderFilter.ALL || value === LocalMediaFolderFilter.NON_EMPTY) {
      return value;
    }
    return LocalMediaFolderFilter.VIDEO_ONLY;
  }

  private static themeMode(value: preferences.ValueType): AppThemeMode {
    if (value === AppThemeMode.LIGHT || value === AppThemeMode.DARK) {
      return value;
    }
    return AppThemeMode.SYSTEM;
  }

  private static accentColor(value: preferences.ValueType): AppAccentColor {
    if (value === AppAccentColor.SYSTEM || value === AppAccentColor.PURPLE || value === AppAccentColor.GREEN ||
      value === AppAccentColor.ORANGE || value === AppAccentColor.PINK) {
      return value;
    }
    return AppAccentColor.BLUE;
  }

  private static extensions(value: preferences.ValueType, fallback: string[]): string[] {
    if (typeof value !== 'string' || value.trim().length === 0) {
      return fallback;
    }
    return value.split(',');
  }
}
