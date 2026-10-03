export { AppFailure, FailureCode, FailureDomain, RecoveryAction } from './src/main/ets/errors/AppFailure';
export { FailureCatalog } from './src/main/ets/errors/FailureCatalog';
export { LocalFilePickerGateway, LocalMediaPermissionResult, LocalMediaPickResult, LocalMediaScanResult,
  ManualMediaRepository, MediaLibraryGateway,
  LocalMediaProgressRepository, PlaybackBookmarkRepository, PlayerBrightnessPort, RecentMediaRepository,
  SettingsRepository } from './src/main/ets/contracts/FeaturePorts';
export { NetworkAccessPolicyPort, NetworkProbePort, NetworkProbeResult,
  ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult } from './src/main/ets/contracts/NetworkPorts';
export { LibraryFeatureController, LibraryFeatureObserver,
  LibraryFeatureState } from './src/main/ets/features/LibraryFeatureController';
export { NetworkLinkController, NetworkLinkObserver,
  NetworkLinkState } from './src/main/ets/features/NetworkLinkController';
export { PlaybackEngineFactory, PlayerFeatureController, PlayerFeatureObserver,
  PlayerFeatureState } from './src/main/ets/features/PlayerFeatureController';
export { PlayerGestureCallbacks, PlayerGestureConfig, PlayerGestureController, PlayerGestureMode,
  PlayerGestureObserver, PlayerGestureState, PlayerTapZone } from './src/main/ets/features/PlayerGestureController';
export { SettingsFeatureController, SettingsFeatureObserver,
  SettingsFeatureState } from './src/main/ets/features/SettingsFeatureController';
export { AppAccentColor, AppSettings, AppThemeMode } from './src/main/ets/models/AppSettings';
export { LinkIssue, LinkParseResult, MediaFormat, MediaLink, MediaProtocol } from './src/main/ets/models/MediaLink';
export { LocalMediaAsset, LocalMediaAvailability,
  LocalMediaOrigin } from './src/main/ets/models/LocalMediaAsset';
export { FileSizeFormatter } from './src/main/ets/models/FileSizeFormatter';
export { LocalMediaCatalog, LocalMediaCatalogView } from './src/main/ets/models/LocalMediaCatalog';
export { DEFAULT_AUDIO_EXTENSIONS, DEFAULT_IMAGE_EXTENSIONS, DEFAULT_SUBTITLE_EXTENSIONS,
  DEFAULT_VIDEO_EXTENSIONS, LocalBrowseMode,
  LocalFileCategory, LocalFileFilter } from './src/main/ets/models/LocalFileFilter';
export { LocalMediaFolder, LocalMediaFolderFilter,
  LocalMediaScanOptions } from './src/main/ets/models/LocalMediaFolder';
export { LocalMediaScanState } from './src/main/ets/models/LocalMediaScanState';
export { LocalMediaPlaybackProgress } from './src/main/ets/models/LocalMediaPlaybackProgress';
export { MediaSource, MediaSourceKind } from './src/main/ets/models/MediaSource';
export { PlaybackBookmark } from './src/main/ets/models/PlaybackBookmark';
export { RecentMediaItem } from './src/main/ets/models/RecentMediaItem';
export { AdapterRuntime, DiscoveryMethod, NETWORK_PROTOCOL_CAPABILITIES, ProtocolCapability,
  RemoteProtocol, SourceFamily } from './src/main/ets/models/RemoteSource';
export { PlaybackEngine } from './src/main/ets/playback/PlaybackEngine';
export { PlaybackObserver, PlaybackSnapshot, PlaybackStatus } from './src/main/ets/playback/PlaybackModels';
export { PlaybackPort, PlaybackPortError, PlaybackPortFactory, PlaybackPortObserver,
  PortBufferingEvent, PortPlaybackState } from './src/main/ets/playback/PlaybackPort';
export { MediaFormatDetector } from './src/main/ets/models/MediaFormatDetector';
export { NetworkLinkParser } from './src/main/ets/services/NetworkLinkParser';
export { DiscoveredService, DiscoveryObserver, DiscoveryPlugin, DiscoveryRequest,
  DiscoverySession } from './src/main/ets/sources/DiscoveryPlugin';
export { RemoteConnectionOptions, RemoteEntry, RemoteEntryKind, RemoteReadSession,
  SourceConnection, SourcePlugin, SourcePluginRegistry } from './src/main/ets/sources/SourcePlugin';

export const LINKORA_CORE_VERSION: string = '1.0.0';
