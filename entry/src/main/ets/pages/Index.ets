import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppAccentColor, AppFailure, AppSettings, AppThemeMode, LibraryFeatureController,
  LibraryFeatureState, LocalBrowseMode, LocalFileFilter, LocalMediaAsset,
  LocalMediaFolder, LocalMediaFolderFilter, LocalMediaPlaybackProgress, LocalMediaScanState,
  MediaSource, RecentMediaItem,
  SettingsFeatureController, SettingsFeatureState } from 'linkora_core';
import { AdaptiveAppShell } from '../components/AdaptiveAppShell';
import { AppSection } from '../models/AppRoute';
import { AppDestination, AppNavigationParams, NetworkDirectoryDestinationParams, PlayerDestinationParams,
  SettingsDetail, SettingsDetailDestinationParams } from '../models/AppNavigation';
import { DirectoryHistory } from '../models/DirectoryHistory';
import { LocalFolderPageData } from '../models/LocalFolderPageData';
import { LinkoraFeatures } from '../foundation/LinkoraFeatures';
import { HistoryPage } from './HistoryPage';
import { HiddenLocalItemsPage } from './HiddenLocalItemsPage';
import { LibraryPage } from './LibraryPage';
import { NetworkPage } from './NetworkPage';
import { StreamPage } from './StreamPage';
import { NetworkBrowserPage } from './NetworkBrowserPage';
import { PlayerPage } from './PlayerPage';
import { SettingsPage } from './SettingsPage';
import { SystemComponentDemoPage } from './SystemComponentDemoPage';
import { image } from '@kit.ImageKit';
import { LocalMediaThumbnailLoader } from '../services/LocalMediaThumbnailLoader';
import { HiddenLocalItem, HiddenLocalItemStore } from '../services/HiddenLocalItemStore';
import { AppThemeController } from '../ui/AppThemeController';

@Entry
@ComponentV2
struct Index {
  @Local private activeSection: AppSection = AppSection.LIBRARY;
  @Local private recentItems: RecentMediaItem[] = [];
  @Local private localFolders: LocalMediaFolder[] = [];
  @Local private localFolderPageData: LocalFolderPageData = new LocalFolderPageData();
  @Local private localFolderUri: string = '';
  @Local private networkBrowserPath: string = '';
  @Local private playbackProgress: LocalMediaPlaybackProgress[] = [];
  @Local private folderFilter: LocalMediaFolderFilter = LocalMediaFolderFilter.VIDEO_ONLY;
  @Local private browseMode: LocalBrowseMode = LocalBrowseMode.DIRECTORY;
  @Local private localScanState: LocalMediaScanState = LocalMediaScanState.IDLE;
  @Local private localFailure: AppFailure | null = null;
  @Local private localImportActive: boolean = false;
  private localReauthorizationUri: string = '';
  @Local private hiddenLocalItems: HiddenLocalItem[] = [];
  @Local private localViewSettingsRevision: number = 0;
  @Local private localSelectionMode: boolean = false;
  @Local private selectedLocalEntryKeys: string[] = [];
  @Local private settings: AppSettings = new AppSettings();
  @Local private settingsSaving: boolean = false;
  @Local private safeAreaTop: number = 0;
  @Local private safeAreaBottom: number = 0;
  @Provider('linkoraAccentColor') private accentColor: string = AppAccentColor.SYSTEM;

  private navigationStack: NavPathStack = new NavPathStack();
  private localFolderHistory: DirectoryHistory = new DirectoryHistory();
  private networkDirectoryHistory: DirectoryHistory = new DirectoryHistory();
  private libraryController: LibraryFeatureController | null = null;
  private settingsController: SettingsFeatureController | null = null;
  private thumbnailLoader: LocalMediaThumbnailLoader | null = null;
  private hiddenLocalItemStore: HiddenLocalItemStore | null = null;
  private appWindow: window.Window | null = null;
  private avoidAreaObserver: (options: window.AvoidAreaOptions) => void = (_options: window.AvoidAreaOptions): void => {
    this.refreshSafeAreaInsets();
  };

  aboutToAppear(): void {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.libraryController = LinkoraFeatures.createLibrary(context, (state: LibraryFeatureState) => {
      this.applyLibraryState(state);
    });
    this.hiddenLocalItemStore = new HiddenLocalItemStore(context);
    this.hiddenLocalItemStore.load().then((items: HiddenLocalItem[]) => {
      this.hiddenLocalItems = items;
      this.libraryController?.initialize().catch(() => {});
    }).catch(() => {
      this.libraryController?.initialize().catch(() => {});
    });
    this.thumbnailLoader = LinkoraFeatures.createLocalMediaThumbnailLoader(context);
    this.settingsController = LinkoraFeatures.createSettings(context, (state: SettingsFeatureState) => {
      this.settings = state.settings;
      this.settingsSaving = state.saving;
      this.accentColor = state.settings.accentColor;
      AppThemeController.apply(context, state.settings.themeMode);
      this.libraryController?.setFolderFilter(state.settings.localMediaFolderFilter).catch(() => {});
      this.libraryController?.setFileFilter(new LocalFileFilter(state.settings.localVideoExtensions,
        state.settings.localSubtitleExtensions)).catch(() => {});
    });
    this.settingsController.initialize().catch(() => {});
    window.getLastWindow(context).then((appWindow: window.Window) => {
      this.appWindow = appWindow;
      appWindow.on('avoidAreaChange', this.avoidAreaObserver);
      this.refreshSafeAreaInsets();
    }).catch(() => {});
  }

  private refreshSafeAreaInsets(): void {
    const appWindow: window.Window | null = this.appWindow;
    if (appWindow === null) {
      return;
    }
    try {
      const systemArea: window.AvoidArea = appWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const navigationArea: window.AvoidArea =
        appWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const top: number = this.getUIContext().px2vp(systemArea.visible ? systemArea.topRect.height : 0);
      const bottom: number = this.getUIContext().px2vp(Math.max(
        systemArea.visible ? systemArea.bottomRect.height : 0,
        navigationArea.visible ? navigationArea.bottomRect.height : 0));
      this.safeAreaTop = top;
      this.safeAreaBottom = bottom;
    } catch (_error) {
      this.safeAreaTop = 0;
      this.safeAreaBottom = 0;
    }
  }

  aboutToDisappear(): void {
    this.appWindow?.off('avoidAreaChange', this.avoidAreaObserver);
    this.appWindow = null;
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.libraryController?.dispose();
    this.libraryController = null;
    this.settingsController?.dispose();
    this.settingsController = null;
    this.thumbnailLoader = null;
    this.hiddenLocalItemStore = null;
  }

  onBackPress(): boolean {
    if (this.localSelectionMode) {
      this.localSelectionMode = false;
      this.selectedLocalEntryKeys = [];
      return true;
    }
    if (this.activeSection === AppSection.LIBRARY && this.backLocalFolder()) {
      return true;
    }
    return false;
  }

  private applyLibraryState(state: LibraryFeatureState): void {
    const permissionJustDenied: boolean = state.scanState === LocalMediaScanState.PERMISSION_DENIED &&
      this.localScanState !== LocalMediaScanState.PERMISSION_DENIED;
    this.recentItems = state.recentItems;
    this.localFolders = state.localFolders;
    this.localFolderPageData = new LocalFolderPageData(state.selectedFolderUri, state.localItems,
      state.scanState, state.scanFailure, state.refreshing);
    this.playbackProgress = state.playbackProgress;
    this.folderFilter = state.folderFilter;
    this.browseMode = state.browseMode;
    this.localScanState = state.scanState;
    this.localFailure = state.localFailure;
    if (permissionJustDenied) {
      this.getUIContext().getPromptAction().showToast({
        message: '未授予媒体访问权限，重新扫描时可前往系统设置授权'
      });
    }
  }

  private openSource(source: MediaSource): void {
    this.navigationStack.pushPath(new NavPathInfo(AppDestination.PLAYER, new PlayerDestinationParams(source)));
    this.libraryController?.recordOpened(source).catch(() => {});
  }

  private openLocalFolder(folderUri: string): void {
    this.localFolderHistory.enter(this.localFolderUri);
    this.localFolderUri = folderUri;
    this.libraryController?.selectFolder(folderUri).catch(() => {});
  }

  private backLocalFolder(): boolean {
    const folderUri: string | null = this.localFolderHistory.back();
    if (folderUri === null) {
      return false;
    }
    this.localFolderUri = folderUri;
    this.libraryController?.selectFolder(folderUri).catch(() => {});
    return true;
  }

  private openNetworkDirectory(path: string): void {
    this.networkDirectoryHistory.enter(this.networkBrowserPath);
    this.networkBrowserPath = path;
  }

  private backNetworkDirectory(): boolean {
    const path: string | null = this.networkDirectoryHistory.back();
    if (path === null) {
      return false;
    }
    this.networkBrowserPath = path;
    return true;
  }

  private closeNetworkDirectory(): void {
    if (!this.backNetworkDirectory()) {
      this.navigationStack.pop();
    }
  }

  private openSettingsDetail(detail: SettingsDetail): void {
    this.navigationStack.pushPath(new NavPathInfo(AppDestination.SETTINGS_DETAIL,
      new SettingsDetailDestinationParams(detail)));
  }

  private async selectLocalMedia(): Promise<void> {
    const controller: LibraryFeatureController | null = this.libraryController;
    if (controller === null || this.localImportActive) {
      return;
    }
    this.localReauthorizationUri = '';
    this.localImportActive = true;
    try {
      await controller.pickLocal(this.localFolderUri, (added: number, skipped: number) => {
        if (this.libraryController !== controller) {
          return;
        }
        const message: string = added === 0 ? '所选文件已在当前文件夹中' :
          `已添加 ${added} 项${skipped > 0 ? `，跳过 ${skipped} 个重复项` : ''}`;
        this.getUIContext().getPromptAction().showToast({ message });
      });
    } catch (_error) {
      if (this.libraryController === controller) {
        this.getUIContext().getPromptAction().showToast({ message: '添加失败，请稍后重试' });
      }
    } finally {
      this.localImportActive = false;
    }
  }

  private scanLocalMedia(): void {
    this.libraryController?.scanLocal().catch(() => {});
  }

  private async reauthorizeLocalMedia(uri: string): Promise<void> {
    const controller: LibraryFeatureController | null = this.libraryController;
    if (controller === null || this.localImportActive) {
      return;
    }
    this.localReauthorizationUri = uri;
    this.localImportActive = true;
    try {
      if (await controller.reauthorizeManual(uri) && this.libraryController === controller) {
        this.localReauthorizationUri = '';
        this.getUIContext().getPromptAction().showToast({ message: '已恢复文件访问' });
      } else if (this.libraryController === controller && controller.currentState().localFailure !== null) {
        this.getUIContext().getPromptAction().showToast({
          message: '恢复失败，文件可能不可读取或已在当前文件夹中'
        });
      } else {
        this.localReauthorizationUri = '';
      }
    } finally {
      this.localImportActive = false;
    }
  }

  private async hideLocalItem(item: HiddenLocalItem): Promise<void> {
    const store: HiddenLocalItemStore | null = this.hiddenLocalItemStore;
    if (store === null) {
      return;
    }
    try {
      this.hiddenLocalItems = await store.hide(item);
      this.getUIContext().getPromptAction().showToast({
        message: `已隐藏“${item.displayName}”，可在已隐藏项目中恢复`
      });
    } catch (_error) {
      this.getUIContext().getPromptAction().showToast({ message: '隐藏失败，请稍后重试' });
    }
  }

  private async hideLocalItems(items: HiddenLocalItem[]): Promise<void> {
    const store: HiddenLocalItemStore | null = this.hiddenLocalItemStore;
    if (store === null || items.length === 0) {
      return;
    }
    try {
      this.hiddenLocalItems = await store.hideMany(items);
      this.getUIContext().getPromptAction().showToast({
        message: `已隐藏 ${items.length} 项，可在已隐藏项目中恢复`
      });
    } catch (_error) {
      this.getUIContext().getPromptAction().showToast({ message: '隐藏失败，请稍后重试' });
    }
  }

  private async restoreHiddenLocalItem(item: HiddenLocalItem): Promise<void> {
    const store: HiddenLocalItemStore | null = this.hiddenLocalItemStore;
    if (store === null) {
      return;
    }
    try {
      this.hiddenLocalItems = await store.restore(item.itemType, item.locator);
      this.getUIContext().getPromptAction().showToast({ message: `已恢复显示“${item.displayName}”` });
    } catch (_error) {
      this.getUIContext().getPromptAction().showToast({ message: '恢复失败，请稍后重试' });
    }
  }

  private async restoreHiddenLocalItems(items: HiddenLocalItem[]): Promise<void> {
    const store: HiddenLocalItemStore | null = this.hiddenLocalItemStore;
    if (store === null || items.length === 0) {
      return;
    }
    try {
      this.hiddenLocalItems = await store.restoreMany(items);
      this.getUIContext().getPromptAction().showToast({ message: `已恢复显示 ${items.length} 项` });
    } catch (_error) {
      this.getUIContext().getPromptAction().showToast({ message: '恢复失败，请稍后重试' });
    }
  }

  private async restoreAllHiddenLocalItems(): Promise<void> {
    const store: HiddenLocalItemStore | null = this.hiddenLocalItemStore;
    if (store === null) {
      return;
    }
    try {
      this.hiddenLocalItems = await store.restoreAll();
      this.getUIContext().getPromptAction().showToast({ message: '已恢复全部隐藏项目' });
    } catch (_error) {
      this.getUIContext().getPromptAction().showToast({ message: '恢复失败，请稍后重试' });
    }
  }

  @Builder
  private settingsPage(detail: SettingsDetail) {
    SettingsPage({
      detail: detail,
      settings: this.settings,
      saving: this.settingsSaving,
      manualThemeSupported: AppThemeController.supportsManualMode(),
      hiddenItemCount: this.hiddenLocalItems.length,
      onRememberPositionChange: (enabled: boolean) => {
        this.settingsController?.setRememberPlaybackPosition(enabled);
      },
      onKeepScreenOnChange: (enabled: boolean) => {
        this.settingsController?.setKeepScreenOnDuringPlayback(enabled);
      },
      onCellularPlaybackChange: (enabled: boolean) => {
        this.settingsController?.setAllowCellularPlayback(enabled);
      },
      onExperimentalNetworkStorageChange: (enabled: boolean) => {
        this.settingsController?.setExperimentalNetworkStorage(enabled);
      },
      onThemeModeChange: (mode: AppThemeMode) => {
        this.settingsController?.setThemeMode(mode);
      },
      onAccentColorChange: (accentColor: AppAccentColor) => {
        this.settingsController?.setAccentColor(accentColor);
      },
      onLocalFileExtensionsChange: (videoExtensions: string[], subtitleExtensions: string[]) => {
        this.settingsController?.setLocalFileExtensions(videoExtensions, subtitleExtensions);
      },
      onOpenSystemComponents: () => {
        this.navigationStack.pushPath(new NavPathInfo(AppDestination.SYSTEM_COMPONENTS, null));
      },
      onLocalViewSettingsChange: () => {
        ++this.localViewSettingsRevision;
      },
      onManageHiddenItems: () => {
        this.navigationStack.pushPath(new NavPathInfo(AppDestination.HIDDEN_ITEMS, null));
      },
      onOpenDetail: (nextDetail: SettingsDetail) => {
        this.openSettingsDetail(nextDetail);
      },
      onBack: () => {
        this.navigationStack.pop();
      }
    })
  }

  @Builder
  private libraryPage() {
    LibraryPage({
      localFolders: this.localFolders,
      projection: this.localFolderPageData,
      hiddenItems: this.hiddenLocalItems,
      selectionMode: this.localSelectionMode,
      selectedEntryKeys: this.selectedLocalEntryKeys,
      playbackProgress: this.playbackProgress,
      selectedFolderUri: this.localFolderUri,
      folderFilter: this.folderFilter,
      browseMode: this.browseMode,
      localFailure: this.localFailure,
      importing: this.localImportActive,
      localViewSettingsRevision: this.localViewSettingsRevision,
      onSelectLocal: () => {
        this.selectLocalMedia().catch(() => {});
      },
      onReauthorizeManual: (uri: string) => {
        this.reauthorizeLocalMedia(uri).catch(() => {});
      },
      onRetryLocal: () => {
        if (this.localReauthorizationUri.length > 0) {
          this.reauthorizeLocalMedia(this.localReauthorizationUri).catch(() => {});
        } else {
          this.selectLocalMedia().catch(() => {});
        }
      },
      onScanLocal: () => {
        this.scanLocalMedia();
      },
      onFolderFilterChange: (filter: LocalMediaFolderFilter) => {
        this.libraryController?.setFolderFilter(filter).catch(() => {});
        this.settingsController?.setLocalMediaFolderFilter(filter);
      },
      onActivateFolder: (activeFolderUri: string) => {
        this.libraryController?.selectFolder(activeFolderUri).catch(() => {});
      },
      onOpenFolder: (nextFolderUri: string) => {
        this.openLocalFolder(nextFolderUri);
      },
      onBack: () => {
        this.backLocalFolder();
      },
      onBrowseModeChange: (mode: LocalBrowseMode) => {
        this.localFolderUri = this.localFolderHistory.reset();
        this.libraryController?.setBrowseMode(mode).catch(() => {});
      },
      onOpenNetwork: () => {
        this.activeSection = AppSection.NETWORK;
      },
      onPlay: (source: MediaSource) => {
        this.openSource(source);
      },
      onHideFolder: (folder: LocalMediaFolder) => {
        this.hideLocalItem(HiddenLocalItem.fromFolder(folder)).catch(() => {});
      },
      onHideMedia: (item: LocalMediaAsset) => {
        this.hideLocalItem(HiddenLocalItem.fromFile(item)).catch(() => {});
      },
      onRestoreHidden: (item: HiddenLocalItem) => {
        this.restoreHiddenLocalItem(item).catch(() => {});
      },
      onHideMany: (items: HiddenLocalItem[]) => {
        this.hideLocalItems(items).catch(() => {});
      },
      onRestoreManyHidden: (items: HiddenLocalItem[]) => {
        this.restoreHiddenLocalItems(items).catch(() => {});
      },
      onSelectionModeChange: (enabled: boolean) => {
        this.localSelectionMode = enabled;
        if (!enabled) {
          this.selectedLocalEntryKeys = [];
        }
      },
      onSelectedEntryKeysChange: (keys: string[]) => {
        this.selectedLocalEntryKeys = keys;
      },
      onRemoveManual: (uri: string) => {
        this.libraryController?.removeManual(uri).catch(() => {});
      },
      onCleanUnavailable: () => {
        this.libraryController?.removeUnavailableManual().catch(() => {});
      },
      onCreateVirtualFolder: (parentUri: string, name: string) => {
        return this.libraryController?.createVirtualFolder(name, parentUri) ?? Promise.resolve(false);
      },
      onRenameVirtualFolder: (uri: string, name: string) => {
        return this.libraryController?.renameVirtualFolder(uri, name) ?? Promise.resolve(false);
      },
      onRemoveVirtualFolder: (uri: string) => {
        this.libraryController?.removeVirtualFolder(uri).catch(() => {});
      },
      loadLocalThumbnail: (uri: string): Promise<image.PixelMap | null> => {
        return this.thumbnailLoader?.load(uri) ?? Promise.resolve(null);
      }
    })
  }

  @Builder
  private currentSection() {
    if (this.activeSection === AppSection.LIBRARY) {
      this.libraryPage()
    } else if (this.activeSection === AppSection.STREAM) {
      StreamPage({
        settings: this.settings,
        onOpenSource: (source: MediaSource) => {
          this.openSource(source);
        },
        onOpenHistory: () => {
          this.activeSection = AppSection.HISTORY;
        }
      })
    } else if (this.activeSection === AppSection.NETWORK) {
      NetworkPage({
        settings: this.settings,
        onOpenServer: (serverId: number) => {
          this.networkBrowserPath = '';
          this.networkDirectoryHistory.reset();
          this.navigationStack.pushPath(new NavPathInfo(AppDestination.NETWORK_DIRECTORY,
            new NetworkDirectoryDestinationParams(serverId)));
        },
        onOpenSettings: () => {
          this.activeSection = AppSection.SETTINGS;
        }
      })
    } else if (this.activeSection === AppSection.HISTORY) {
      HistoryPage({
        recentItems: this.recentItems,
        loadLocalThumbnail: (uri: string): Promise<image.PixelMap | null> => {
          return this.thumbnailLoader?.load(uri) ?? Promise.resolve(null);
        },
        onPlay: (source: MediaSource) => {
          this.openSource(source);
        }
      })
    } else {
      this.settingsPage(SettingsDetail.HOME)
    }
  }

  @Builder
  private destinationBuilder(name: string, param: Object) {
    if (name === AppDestination.NETWORK_DIRECTORY &&
      AppNavigationParams.networkDirectory(param) !== null) {
      NavDestination() {
        NetworkBrowserPage({
          serverId: (AppNavigationParams.networkDirectory(param) as NetworkDirectoryDestinationParams).serverId,
          path: this.networkBrowserPath,
          onOpenDirectory: (path: string) => {
            this.openNetworkDirectory(path);
          },
          onBack: () => {
            this.closeNetworkDirectory();
          },
          onOpenSource: (source: MediaSource) => {
            this.openSource(source);
          }
        })
      }
      .hideTitleBar(true)
      .onBackPressed((): boolean => this.backNetworkDirectory())
    } else if (name === AppDestination.PLAYER && AppNavigationParams.player(param) !== null) {
      NavDestination() {
        PlayerPage({
          source: (AppNavigationParams.player(param) as PlayerDestinationParams).source,
          settings: this.settings,
          onBack: () => {
            this.navigationStack.pop();
          },
          onOpenSettings: () => {
            this.navigationStack.clear();
            this.activeSection = AppSection.SETTINGS;
          }
        })
      }
      .hideTitleBar(true)
      .onHidden(() => {
        this.libraryController?.refreshPlaybackProgress().catch(() => {});
      })
    } else if (name === AppDestination.SETTINGS_DETAIL && AppNavigationParams.settingsDetail(param) !== null) {
      NavDestination() {
        this.settingsPage((AppNavigationParams.settingsDetail(param) as SettingsDetailDestinationParams).detail)
      }
      .hideTitleBar(true)
    } else if (name === AppDestination.HIDDEN_ITEMS) {
      NavDestination() {
        HiddenLocalItemsPage({
          hiddenItems: this.hiddenLocalItems,
          onBack: () => {
            this.navigationStack.pop();
          },
          onRestore: (item: HiddenLocalItem) => {
            this.restoreHiddenLocalItem(item).catch(() => {});
          },
          onRestoreAll: () => {
            this.restoreAllHiddenLocalItems().catch(() => {});
          }
        })
      }
      .hideTitleBar(true)
    } else if (name === AppDestination.SYSTEM_COMPONENTS) {
      NavDestination() {
        SystemComponentDemoPage({
          onBack: () => {
            this.navigationStack.pop();
          }
        })
      }
      .hideTitleBar(true)
    } else {
      NavDestination() {
        Column({ space: 12 }) {
          Text('页面无法打开')
          Button('返回')
            .onClick(() => {
              this.navigationStack.pop();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .hideTitleBar(true)
    }
  }

  build() {
    Navigation(this.navigationStack) {
      AdaptiveAppShell({
        activeSection: this.activeSection,
        navigationHidden: this.localSelectionMode,
        networkStorageEnabled: this.settings.experimentalNetworkStorage,
        onSectionChange: (section: AppSection) => {
          this.activeSection = section;
          this.localSelectionMode = false;
          this.selectedLocalEntryKeys = [];
        }
      }) {
        this.currentSection()
      }
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.destinationBuilder)
    .width('100%')
    .height('100%')
    .padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom })
  }
}
