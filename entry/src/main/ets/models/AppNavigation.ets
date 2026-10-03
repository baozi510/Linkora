import { MediaSource } from 'linkora_core';

export enum AppDestination {
  SETTINGS_DETAIL = 'settings_detail',
  NETWORK_DIRECTORY = 'network_directory',
  PLAYER = 'player',
  HIDDEN_ITEMS = 'hidden_items',
  SYSTEM_COMPONENTS = 'system_components'
}

export enum SettingsDetail {
  HOME = 'home',
  PLAYER = 'player',
  NETWORK = 'network',
  LOCAL_MEDIA = 'local_media',
  APPEARANCE = 'appearance'
}

export class SettingsDetailDestinationParams {
  readonly detail: SettingsDetail;

  constructor(detail: SettingsDetail) {
    this.detail = detail;
  }
}

export class NetworkDirectoryDestinationParams {
  readonly serverId: number;

  constructor(serverId: number) {
    this.serverId = serverId;
  }
}

export class PlayerDestinationParams {
  readonly source: MediaSource;

  constructor(source: MediaSource) {
    this.source = source;
  }
}

export class AppNavigationParams {
  static settingsDetail(param: Object): SettingsDetailDestinationParams | null {
    return param instanceof SettingsDetailDestinationParams && param.detail !== SettingsDetail.HOME ? param : null;
  }

  static networkDirectory(param: Object): NetworkDirectoryDestinationParams | null {
    return param instanceof NetworkDirectoryDestinationParams && param.serverId > 0 ? param : null;
  }

  static player(param: Object): PlayerDestinationParams | null {
    return param instanceof PlayerDestinationParams ? param : null;
  }
}
