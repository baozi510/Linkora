import { common } from '@kit.AbilityKit';
import { AppSettings, LibraryFeatureController, LibraryFeatureObserver, MediaSource, NetworkLinkController,
  NetworkLinkObserver, PlaybackEngine, PlaybackEngineFactory, PlaybackObserver,
  PlayerFeatureController, PlayerFeatureObserver, SettingsFeatureController,
  SettingsFeatureObserver, SourcePluginRegistry, PlayerBrightnessPort } from 'linkora_core';
import { HarmonyLocalFilePickerGateway } from '../adapters/HarmonyLocalFilePickerGateway';
import { HarmonyMediaLibraryGateway } from '../adapters/HarmonyMediaLibraryGateway';
import { HarmonyNetworkProbe } from '../adapters/HarmonyNetworkProbe';
import { HarmonyNetworkAccessPolicy } from '../adapters/HarmonyNetworkAccessPolicy';
import { SystemPlaybackPort } from '../playback/SystemPlaybackPort';
import { PlaybackBookmarkStore } from '../services/PlaybackBookmarkStore';
import { RecentMediaStore } from '../services/RecentMediaStore';
import { AppSettingsStore } from '../services/AppSettingsStore';
import { LocalMediaThumbnailLoader } from '../services/LocalMediaThumbnailLoader';
import { ManualMediaStore } from '../services/ManualMediaStore';
import { WindowBrightnessController } from '../playback/WindowBrightnessController';
import { NetworkFileProxy } from 'linkora_proxy';
import { NetworkMediaProbe } from 'linkora_media_probe';
import { NetworkMediaLoader } from '../services/NetworkMediaLoader';
import { NetworkDirectoryEntry } from '../models/NetworkDirectoryState';
import { CachedNetworkMedia } from '../services/NetworkMediaCache';
import { NetworkServerEntry } from '../services/NetworkServerStore';

// Production integration switch. Disabling extraction does not disable linkora_proxy.
const NETWORK_MEDIA_ENABLED: boolean = true;

export class LinkoraFeatures {
  static createNetworkMediaLoader(context: common.UIAbilityContext, server: NetworkServerEntry,
    onMetadata: (entry: NetworkDirectoryEntry, info: CachedNetworkMedia) => void): NetworkMediaLoader | null {
    return NETWORK_MEDIA_ENABLED ? new NetworkMediaLoader(context, server, onMetadata) : null;
  }
  static createNetworkMediaProbe(): NetworkMediaProbe { return new NetworkMediaProbe(); }
  static createNetworkFileProxy(): NetworkFileProxy { return new NetworkFileProxy(); }
  static createLibrary(context: common.UIAbilityContext,
    observer: LibraryFeatureObserver): LibraryFeatureController {
    const playbackStore: PlaybackBookmarkStore = new PlaybackBookmarkStore(context);
    return new LibraryFeatureController(
      new HarmonyMediaLibraryGateway(context),
      new HarmonyLocalFilePickerGateway(context),
      new RecentMediaStore(context),
      observer,
      new ManualMediaStore(context),
      playbackStore
    );
  }

  static createNetwork(settings: AppSettings, observer: NetworkLinkObserver): NetworkLinkController {
    return new NetworkLinkController(new HarmonyNetworkProbe(), observer,
      new HarmonyNetworkAccessPolicy(settings));
  }

  static createPlayer(context: common.UIAbilityContext, source: MediaSource,
    settings: AppSettings, observer: PlayerFeatureObserver): PlayerFeatureController {
    const engineFactory: PlaybackEngineFactory = (playbackObserver: PlaybackObserver) =>
      new PlaybackEngine(playbackObserver, (portObserver) => SystemPlaybackPort.create(portObserver));
    return new PlayerFeatureController(
      source,
      engineFactory,
      new PlaybackBookmarkStore(context),
      settings,
      observer,
      new HarmonyNetworkAccessPolicy(settings)
    );
  }

  static createSettings(context: common.UIAbilityContext,
    observer: SettingsFeatureObserver): SettingsFeatureController {
    return new SettingsFeatureController(new AppSettingsStore(context), observer);
  }

  static createLocalMediaThumbnailLoader(context: common.UIAbilityContext): LocalMediaThumbnailLoader {
    return new LocalMediaThumbnailLoader(context);
  }

  static createPlayerBrightness(context: common.UIAbilityContext): PlayerBrightnessPort {
    return new WindowBrightnessController(context);
  }

  static createSourceRegistry(): SourcePluginRegistry {
    return new SourcePluginRegistry();
  }
}
