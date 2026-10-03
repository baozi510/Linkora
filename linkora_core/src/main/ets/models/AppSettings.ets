import { LocalMediaFolderFilter } from './LocalMediaFolder';
import { DEFAULT_SUBTITLE_EXTENSIONS, DEFAULT_VIDEO_EXTENSIONS, LocalFileFilter } from './LocalFileFilter';

export enum AppThemeMode {
  SYSTEM = 'system',
  LIGHT = 'light',
  DARK = 'dark'
}

export enum AppAccentColor {
  SYSTEM = 'system',
  BLUE = 'blue',
  PURPLE = 'purple',
  GREEN = 'green',
  ORANGE = 'orange',
  PINK = 'pink'
}

export class AppSettings {
  readonly rememberPlaybackPosition: boolean;
  readonly keepScreenOnDuringPlayback: boolean;
  readonly allowCellularPlayback: boolean;
  readonly localMediaFolderFilter: LocalMediaFolderFilter;
  readonly themeMode: AppThemeMode;
  readonly accentColor: AppAccentColor;
  readonly localVideoExtensions: string[];
  readonly localSubtitleExtensions: string[];
  readonly experimentalNetworkStorage: boolean;

  constructor(rememberPlaybackPosition: boolean = true,
    keepScreenOnDuringPlayback: boolean = true, allowCellularPlayback: boolean = false,
    localMediaFolderFilter: LocalMediaFolderFilter = LocalMediaFolderFilter.VIDEO_ONLY,
    themeMode: AppThemeMode = AppThemeMode.SYSTEM,
    accentColor: AppAccentColor = AppAccentColor.SYSTEM,
    localVideoExtensions: string[] = DEFAULT_VIDEO_EXTENSIONS,
    localSubtitleExtensions: string[] = DEFAULT_SUBTITLE_EXTENSIONS,
    experimentalNetworkStorage: boolean = false) {
    this.rememberPlaybackPosition = rememberPlaybackPosition;
    this.keepScreenOnDuringPlayback = keepScreenOnDuringPlayback;
    this.allowCellularPlayback = allowCellularPlayback;
    this.localMediaFolderFilter = localMediaFolderFilter;
    this.themeMode = themeMode;
    this.accentColor = accentColor;
    const fileFilter: LocalFileFilter = new LocalFileFilter(localVideoExtensions, localSubtitleExtensions);
    this.localVideoExtensions = fileFilter.videoExtensions;
    this.localSubtitleExtensions = fileFilter.subtitleExtensions;
    this.experimentalNetworkStorage = experimentalNetworkStorage;
  }

  withRememberPlaybackPosition(enabled: boolean): AppSettings {
    return new AppSettings(enabled, this.keepScreenOnDuringPlayback, this.allowCellularPlayback,
      this.localMediaFolderFilter, this.themeMode, this.accentColor,
      this.localVideoExtensions, this.localSubtitleExtensions, this.experimentalNetworkStorage);
  }

  withKeepScreenOnDuringPlayback(enabled: boolean): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, enabled, this.allowCellularPlayback,
      this.localMediaFolderFilter, this.themeMode, this.accentColor,
      this.localVideoExtensions, this.localSubtitleExtensions, this.experimentalNetworkStorage);
  }

  withAllowCellularPlayback(enabled: boolean): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback, enabled,
      this.localMediaFolderFilter, this.themeMode, this.accentColor,
      this.localVideoExtensions, this.localSubtitleExtensions, this.experimentalNetworkStorage);
  }

  withLocalMediaFolderFilter(filter: LocalMediaFolderFilter): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback,
      this.allowCellularPlayback, filter, this.themeMode, this.accentColor,
      this.localVideoExtensions, this.localSubtitleExtensions, this.experimentalNetworkStorage);
  }

  withThemeMode(mode: AppThemeMode): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback,
      this.allowCellularPlayback, this.localMediaFolderFilter, mode, this.accentColor,
      this.localVideoExtensions, this.localSubtitleExtensions, this.experimentalNetworkStorage);
  }

  withAccentColor(accentColor: AppAccentColor): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback,
      this.allowCellularPlayback, this.localMediaFolderFilter, this.themeMode, accentColor,
      this.localVideoExtensions, this.localSubtitleExtensions, this.experimentalNetworkStorage);
  }

  withLocalVideoExtensions(extensions: string[]): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback,
      this.allowCellularPlayback, this.localMediaFolderFilter, this.themeMode, this.accentColor,
      extensions, this.localSubtitleExtensions, this.experimentalNetworkStorage);
  }

  withLocalSubtitleExtensions(extensions: string[]): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback,
      this.allowCellularPlayback, this.localMediaFolderFilter, this.themeMode, this.accentColor,
      this.localVideoExtensions, extensions, this.experimentalNetworkStorage);
  }

  withLocalFileExtensions(videoExtensions: string[], subtitleExtensions: string[]): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback,
      this.allowCellularPlayback, this.localMediaFolderFilter, this.themeMode, this.accentColor,
      videoExtensions, subtitleExtensions, this.experimentalNetworkStorage);
  }

  withExperimentalNetworkStorage(enabled: boolean): AppSettings {
    return new AppSettings(this.rememberPlaybackPosition, this.keepScreenOnDuringPlayback,
      this.allowCellularPlayback, this.localMediaFolderFilter, this.themeMode, this.accentColor,
      this.localVideoExtensions, this.localSubtitleExtensions, enabled);
  }
}
