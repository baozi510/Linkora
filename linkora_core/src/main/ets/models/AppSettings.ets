import { LocalMediaFolderFilter } from './LocalMediaFolder';
import { DEFAULT_SUBTITLE_EXTENSIONS, DEFAULT_VIDEO_EXTENSIONS, LocalFileFilter } from './LocalFileFilter';
import { PlayerBackendPreference } from '../playback/PlaybackBackend';

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
  readonly playerBackendPreference: PlayerBackendPreference;

  constructor(rememberPlaybackPosition: boolean = true,
    keepScreenOnDuringPlayback: boolean = true, allowCellularPlayback: boolean = false,
    localMediaFolderFilter: LocalMediaFolderFilter = LocalMediaFolderFilter.VIDEO_ONLY,
    themeMode: AppThemeMode = AppThemeMode.SYSTEM,
    accentColor: AppAccentColor = AppAccentColor.SYSTEM,
    localVideoExtensions: string[] = DEFAULT_VIDEO_EXTENSIONS,
    localSubtitleExtensions: string[] = DEFAULT_SUBTITLE_EXTENSIONS,
    experimentalNetworkStorage: boolean = false,
    playerBackendPreference: PlayerBackendPreference = PlayerBackendPreference.AUTO) {
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
    this.playerBackendPreference = playerBackendPreference;
  }

  withRememberPlaybackPosition(enabled: boolean): AppSettings {
    return this.copy({ rememberPlaybackPosition: enabled });
  }

  withKeepScreenOnDuringPlayback(enabled: boolean): AppSettings {
    return this.copy({ keepScreenOnDuringPlayback: enabled });
  }

  withAllowCellularPlayback(enabled: boolean): AppSettings {
    return this.copy({ allowCellularPlayback: enabled });
  }

  withLocalMediaFolderFilter(filter: LocalMediaFolderFilter): AppSettings {
    return this.copy({ localMediaFolderFilter: filter });
  }

  withThemeMode(mode: AppThemeMode): AppSettings {
    return this.copy({ themeMode: mode });
  }

  withAccentColor(accentColor: AppAccentColor): AppSettings {
    return this.copy({ accentColor });
  }

  withLocalVideoExtensions(extensions: string[]): AppSettings {
    return this.copy({ localVideoExtensions: extensions });
  }

  withLocalSubtitleExtensions(extensions: string[]): AppSettings {
    return this.copy({ localSubtitleExtensions: extensions });
  }

  withLocalFileExtensions(videoExtensions: string[], subtitleExtensions: string[]): AppSettings {
    return this.copy({ localVideoExtensions: videoExtensions, localSubtitleExtensions: subtitleExtensions });
  }

  withExperimentalNetworkStorage(enabled: boolean): AppSettings {
    return this.copy({ experimentalNetworkStorage: enabled });
  }

  withPlayerBackendPreference(preference: PlayerBackendPreference): AppSettings {
    return this.copy({ playerBackendPreference: preference });
  }

  private copy(change: {
    rememberPlaybackPosition?: boolean;
    keepScreenOnDuringPlayback?: boolean;
    allowCellularPlayback?: boolean;
    localMediaFolderFilter?: LocalMediaFolderFilter;
    themeMode?: AppThemeMode;
    accentColor?: AppAccentColor;
    localVideoExtensions?: string[];
    localSubtitleExtensions?: string[];
    experimentalNetworkStorage?: boolean;
    playerBackendPreference?: PlayerBackendPreference;
  }): AppSettings {
    return new AppSettings(
      change.rememberPlaybackPosition ?? this.rememberPlaybackPosition,
      change.keepScreenOnDuringPlayback ?? this.keepScreenOnDuringPlayback,
      change.allowCellularPlayback ?? this.allowCellularPlayback,
      change.localMediaFolderFilter ?? this.localMediaFolderFilter,
      change.themeMode ?? this.themeMode,
      change.accentColor ?? this.accentColor,
      change.localVideoExtensions ?? this.localVideoExtensions,
      change.localSubtitleExtensions ?? this.localSubtitleExtensions,
      change.experimentalNetworkStorage ?? this.experimentalNetworkStorage,
      change.playerBackendPreference ?? this.playerBackendPreference
    );
  }
}
