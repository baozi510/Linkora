import { common } from '@kit.AbilityKit';
import { ComponentContent } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { AppFailure, LocalBrowseMode, LocalFileCategory, LocalMediaAsset, LocalMediaAvailability,
  LocalMediaFolder, LocalMediaFolderFilter, LocalMediaOrigin, LocalMediaPlaybackProgress,
  LocalMediaScanState, MediaSource } from 'linkora_core';
import { AppIcon, AppIconName } from '../components/AppIcon';
import { AppIconButton } from '../components/AppIconButton';
import { AppToolbar } from '../components/AppToolbar';
import { AppSheetHeader } from '../components/AppSheetHeader';
import { AppSheetSurface } from '../components/AppSheetSurface';
import { FailureNotice } from '../components/FailureNotice';
import { LocalMediaBrowser } from '../components/LocalMediaBrowser';
import { AppColors, AppIconSize, AppLayout, AppRadius, AppSpacing, AppTypography } from '../ui/AppTheme';
import { HiddenLocalItem, HiddenLocalItemType } from '../services/HiddenLocalItemStore';
import { LocalViewSettingsStore } from '../services/LocalViewSettingsStore';
import { LocalMediaAvailabilityFilter, LocalMediaSortField, LocalMediaSortOptions, LocalMediaSourceFilter,
  LocalMediaTypeFilter, LocalViewSettings } from '../models/LocalMediaViewOptions';
import { LocalFolderPageData } from '../models/LocalFolderPageData';

class LocalRefreshIndicatorParams {
  accentColor: string;

  constructor(accentColor: string) {
    this.accentColor = accentColor;
  }
}

@Builder
function localRefreshIndicator(params: LocalRefreshIndicatorParams) {
  Row() {
    Stack() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(AppColors.accent(params.accentColor))
    }
    .width(44)
    .height(44)
    .borderRadius(AppRadius.FULL)
    .backgroundColor(AppColors.SURFACE_RAISED)
  }
  .width('100%')
  .constraintSize({ minHeight: 44 })
  .justifyContent(FlexAlign.Center)
  .clip(true)
  .zIndex(1)
}

class LocalRefreshModifier implements AttributeModifier<RefreshAttribute> {
  applyNormalAttribute(instance: RefreshAttribute): void {
    if (deviceInfo.sdkApiVersion >= 23) {
      instance.pullUpToCancelRefresh(false);
    }
  }
}

@ComponentV2
export struct LibraryPage {
  private static readonly AUTO_REFRESH_INDICATOR_DELAY_MS: number = 150;

  @Param localFolders: LocalMediaFolder[] = [];
  @Param projection: LocalFolderPageData = new LocalFolderPageData();
  @Param hiddenItems: HiddenLocalItem[] = [];
  @Param selectionMode: boolean = false;
  @Param selectedEntryKeys: string[] = [];
  @Param playbackProgress: LocalMediaPlaybackProgress[] = [];
  @Param selectedFolderUri: string = '';
  @Param folderFilter: LocalMediaFolderFilter = LocalMediaFolderFilter.VIDEO_ONLY;
  @Param browseMode: LocalBrowseMode = LocalBrowseMode.DIRECTORY;
  @Param localFailure: AppFailure | null = null;
  @Param importing: boolean = false;
  @Param localViewSettingsRevision: number = 0;
  @Event onSelectLocal: () => void = () => {};
  @Event onReauthorizeManual: (uri: string) => void = () => {};
  @Event onRetryLocal: () => void = () => {};
  @Event onScanLocal: () => void = () => {};
  @Event onFolderFilterChange: (filter: LocalMediaFolderFilter) => void = () => {};
  @Event onActivateFolder: (folderUri: string) => void = () => {};
  @Event onOpenFolder: (folderUri: string) => void = () => {};
  @Event onBack: () => void = () => {};
  @Event onBrowseModeChange: (mode: LocalBrowseMode) => void = () => {};
  @Event onOpenNetwork: () => void = () => {};
  @Event onPlay: (source: MediaSource) => void = () => {};
  @Event onAddFavorite: (source: MediaSource) => void = () => {};
  @Event onAddToPlaylist: (source: MediaSource) => void = () => {};
  @Event onHideFolder: (folder: LocalMediaFolder) => void = () => {};
  @Event onHideMedia: (item: LocalMediaAsset) => void = () => {};
  @Event onRestoreHidden: (item: HiddenLocalItem) => void = () => {};
  @Event onHideMany: (items: HiddenLocalItem[]) => void = () => {};
  @Event onRestoreManyHidden: (items: HiddenLocalItem[]) => void = () => {};
  @Event onSelectionModeChange: (enabled: boolean) => void = () => {};
  @Event onSelectedEntryKeysChange: (keys: string[]) => void = () => {};
  @Event onRemoveManual: (uri: string) => void = () => {};
  @Event onCleanUnavailable: () => void = () => {};
  @Event onCreateVirtualFolder: (parentUri: string, name: string) => Promise<boolean> = async () => false;
  @Event onRenameVirtualFolder: (uri: string, name: string) => Promise<boolean> = async () => false;
  @Event onRemoveVirtualFolder: (uri: string) => void = () => {};
  @Event loadLocalThumbnail: (uri: string) => Promise<image.PixelMap | null> = async () => null;

  @Local private searchVisible: boolean = false;
  @Local private searchText: string = '';
  @Local private gridView: boolean = false;
  @Local private sortField: LocalMediaSortField = LocalMediaSortField.NAME;
  @Local private sortAscending: boolean = true;
  @Local private typeFilter: LocalMediaTypeFilter = LocalMediaTypeFilter.ALL;
  @Local private sourceFilter: LocalMediaSourceFilter = LocalMediaSourceFilter.ALL;
  @Local private availabilityFilter: LocalMediaAvailabilityFilter = LocalMediaAvailabilityFilter.ALL;
  @Local private showSize: boolean = true;
  @Local private showResolution: boolean = true;
  @Local private showFileExtension: boolean = false;
  @Local private showItemCount: boolean = true;
  @Local private showDuration: boolean = true;
  @Local private showModifiedDate: boolean = false;
  @Local private showHiddenItems: boolean = false;
  @Local private showThumbnails: boolean = true;
  @Local private viewSettingsReady: boolean = false;
  @Local private contentWidth: number = 0;
  @Local private pageData: LocalFolderPageData = new LocalFolderPageData();
  @Local private manualRefreshActive: boolean = false;
  @Local private automaticRefreshIndicatorVisible: boolean = false;
  @Local private folderEditorVisible: boolean = false;
  @Local private folderEditorUri: string = '';
  @Local private folderEditorName: string = '';
  @Local private folderEditorSaving: boolean = false;
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  private localViewSettingsStore: LocalViewSettingsStore | null = null;
  private refreshIndicatorParams: LocalRefreshIndicatorParams = new LocalRefreshIndicatorParams('system');
  private refreshingContent: ComponentContent<LocalRefreshIndicatorParams> | undefined = undefined;
  private refreshModifier: LocalRefreshModifier = new LocalRefreshModifier();
  private mediaScroller: Scroller = new Scroller();
  private scrollPositions: Map<string, number> = new Map<string, number>();
  private automaticRefreshIndicatorTimer: number = -1;

  aboutToAppear(): void {
    this.refreshIndicatorParams.accentColor = this.accentColor;
    this.refreshingContent = new ComponentContent<LocalRefreshIndicatorParams>(
      this.getUIContext(), wrapBuilder(localRefreshIndicator), this.refreshIndicatorParams);
    this.pageData = LocalFolderPageData.forRoute(this.selectedFolderUri,
      new LocalFolderPageData(this.selectedFolderUri, [], LocalMediaScanState.SCANNING), this.projection);
    this.updateAutomaticRefreshIndicator();
    this.onActivateFolder(this.selectedFolderUri);
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.localViewSettingsStore = new LocalViewSettingsStore(context);
    const cachedSettings: LocalViewSettings | null = LocalViewSettingsStore.peek();
    if (cachedSettings !== null) {
      this.applyLocalViewSettings(cachedSettings);
      this.viewSettingsReady = true;
      return;
    }
    this.viewSettingsReady = false;
    this.loadLocalViewSettings().catch(() => {});
  }

  @Monitor('projection')
  private onProjectionChanged(): void {
    this.pageData = LocalFolderPageData.forRoute(this.selectedFolderUri, this.pageData, this.projection);
    if (this.manualRefreshActive && !this.pageData.refreshing) {
      this.manualRefreshActive = false;
    }
    this.updateAutomaticRefreshIndicator();
    this.restoreScrollPosition();
  }

  @Monitor('accentColor')
  private onAccentColorChanged(): void {
    this.refreshIndicatorParams.accentColor = this.accentColor;
    this.refreshingContent?.update(this.refreshIndicatorParams);
  }

  @Monitor('selectedFolderUri')
  private onSelectedFolderChanged(): void {
    this.manualRefreshActive = false;
    this.pageData = LocalFolderPageData.forRoute(this.selectedFolderUri,
      new LocalFolderPageData(this.selectedFolderUri, [], LocalMediaScanState.SCANNING), this.projection);
    this.updateAutomaticRefreshIndicator();
    this.restoreScrollPosition();
  }

  @Monitor('localViewSettingsRevision')
  private onLocalViewSettingsRevisionChanged(): void {
    const settings: LocalViewSettings | null = LocalViewSettingsStore.peek();
    if (settings !== null) {
      this.applyLocalViewSettings(settings);
    }
  }

  private automaticRefreshActive(): boolean {
    return !this.manualRefreshActive &&
      (this.pageData.scanState === LocalMediaScanState.SCANNING || this.pageData.refreshing);
  }

  private updateAutomaticRefreshIndicator(): void {
    if (!this.automaticRefreshActive()) {
      if (this.automaticRefreshIndicatorTimer >= 0) {
        clearTimeout(this.automaticRefreshIndicatorTimer);
        this.automaticRefreshIndicatorTimer = -1;
      }
      this.automaticRefreshIndicatorVisible = false;
      return;
    }
    if (this.automaticRefreshIndicatorVisible || this.automaticRefreshIndicatorTimer >= 0) {
      return;
    }
    this.automaticRefreshIndicatorTimer = setTimeout((): void => {
      this.automaticRefreshIndicatorTimer = -1;
      if (this.automaticRefreshActive()) {
        this.automaticRefreshIndicatorVisible = true;
      }
    }, LibraryPage.AUTO_REFRESH_INDICATOR_DELAY_MS);
  }

  private scrollPositionKey(): string {
    return `${this.selectedFolderUri}|${this.gridView ? 'grid' : 'list'}`;
  }

  private rememberScrollPosition(index: number): void {
    this.scrollPositions.set(this.scrollPositionKey(), index);
  }

  private restoreScrollPosition(): void {
    const index: number = this.scrollPositions.get(this.scrollPositionKey()) ?? 0;
    setTimeout(() => {
      this.mediaScroller.scrollToIndex(index, false);
    }, 0);
  }

  aboutToDisappear(): void {
    if (this.automaticRefreshIndicatorTimer >= 0) {
      clearTimeout(this.automaticRefreshIndicatorTimer);
      this.automaticRefreshIndicatorTimer = -1;
    }
    this.refreshingContent?.dispose();
    this.refreshingContent = undefined;
    this.localViewSettingsStore = null;
  }

  private async loadLocalViewSettings(): Promise<void> {
    const store: LocalViewSettingsStore | null = this.localViewSettingsStore;
    if (store === null) {
      return;
    }
    try {
      const settings: LocalViewSettings = await store.load();
      if (this.localViewSettingsStore !== store) {
        return;
      }
      this.applyLocalViewSettings(settings);
    } finally {
      if (this.localViewSettingsStore === store) {
        this.viewSettingsReady = true;
      }
    }
  }

  private applyLocalViewSettings(settings: LocalViewSettings): void {
    this.gridView = settings.gridView;
    this.sortField = LocalMediaSortOptions.normalize(settings.browseMode, settings.sortField);
    this.sortAscending = settings.sortAscending;
    this.typeFilter = settings.typeFilter;
    this.sourceFilter = settings.sourceFilter;
    this.availabilityFilter = settings.availabilityFilter;
    this.showItemCount = settings.showItemCount;
    this.showSize = settings.showSize;
    this.showResolution = settings.showResolution;
    this.showFileExtension = settings.showFileExtension;
    this.showDuration = settings.showDuration;
    this.showModifiedDate = settings.showModifiedDate;
    this.showHiddenItems = settings.showHiddenItems;
    this.showThumbnails = settings.showThumbnails;
    if (settings.browseMode !== this.browseMode) {
      this.onBrowseModeChange(settings.browseMode);
    }
  }

  private captureLocalViewSettings(browseMode: LocalBrowseMode, gridView: boolean): LocalViewSettings {
    const settings: LocalViewSettings = new LocalViewSettings();
    settings.browseMode = browseMode;
    settings.gridView = gridView;
    settings.sortField = this.sortField;
    settings.sortAscending = this.sortAscending;
    settings.typeFilter = this.typeFilter;
    settings.sourceFilter = this.sourceFilter;
    settings.availabilityFilter = this.availabilityFilter;
    settings.showItemCount = this.showItemCount;
    settings.showSize = this.showSize;
    settings.showResolution = this.showResolution;
    settings.showFileExtension = this.showFileExtension;
    settings.showDuration = this.showDuration;
    settings.showModifiedDate = this.showModifiedDate;
    settings.showHiddenItems = this.showHiddenItems;
    settings.showThumbnails = this.showThumbnails;
    return settings;
  }

  private persistLocalViewSettings(browseMode: LocalBrowseMode, gridView: boolean): void {
    const store: LocalViewSettingsStore | null = this.localViewSettingsStore;
    if (store === null) {
      return;
    }
    const settings: LocalViewSettings = this.captureLocalViewSettings(browseMode, gridView);
    store.save(settings).catch(() => {
      console.warn('Unable to persist local view settings');
    });
  }

  private selectedFolder(): LocalMediaFolder | null {
    for (const folder of this.localFolders) {
      if (folder.uri === this.selectedFolderUri) {
        return folder;
      }
    }
    return null;
  }

  private pageTitle(): string {
    const folder: LocalMediaFolder | null = this.selectedFolder();
    if (folder !== null) {
      return folder.displayName;
    }
    return '本地';
  }

  private pagePath(): string {
    const folder: LocalMediaFolder | null = this.selectedFolder();
    return folder === null ? '' : `文件夹 / ${folder.displayName}`;
  }

  private canManageVirtualEntries(): boolean {
    const folder: LocalMediaFolder | null = this.selectedFolder();
    return this.selectedFolderUri.length === 0 || (folder !== null && folder.isVirtual());
  }

  private openFolderEditor(folder: LocalMediaFolder | null = null): void {
    this.folderEditorUri = folder?.uri ?? '';
    this.folderEditorName = folder?.displayName ?? '';
    this.folderEditorVisible = true;
  }

  private async submitFolderEditor(): Promise<void> {
    const name: string = this.folderEditorName.trim();
    if (name.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入文件夹名称' });
      return;
    }
    this.folderEditorSaving = true;
    const succeeded: boolean = this.folderEditorUri.length > 0 ?
      await this.onRenameVirtualFolder(this.folderEditorUri, name) :
      await this.onCreateVirtualFolder(this.selectedFolderUri, name);
    this.folderEditorSaving = false;
    if (!succeeded) {
      this.getUIContext().getPromptAction().showToast({
        message: '操作失败，请稍后重试，并检查同级文件夹是否重名'
      });
      return;
    }
    this.folderEditorVisible = false;
  }

  private folderSelectionKey(folder: LocalMediaFolder): string {
    return `folder:${folder.uri}`;
  }

  private mediaSelectionKey(item: LocalMediaAsset): string {
    return `file:${item.uri}`;
  }

  private selected(key: string): boolean {
    return this.selectedEntryKeys.indexOf(key) >= 0;
  }

  private toggleSelection(key: string): void {
    const keys: string[] = this.selectedEntryKeys.slice();
    const index: number = keys.indexOf(key);
    if (index >= 0) {
      keys.splice(index, 1);
    } else {
      keys.push(key);
    }
    this.onSelectedEntryKeysChange(keys);
  }

  private exitSelection(): void {
    this.onSelectedEntryKeysChange([]);
    this.onSelectionModeChange(false);
  }

  private matchesSelectionText(value: string): boolean {
    const query: string = this.searchText.trim().toLowerCase();
    return query.length === 0 || value.toLowerCase().includes(query);
  }

  private acceptsSelectionItem(item: LocalMediaAsset): boolean {
    if (!this.matchesSelectionText(item.displayName)) {
      return false;
    }
    if (this.typeFilter === LocalMediaTypeFilter.VIDEO && item.category !== LocalFileCategory.VIDEO) {
      return false;
    }
    if (this.typeFilter === LocalMediaTypeFilter.IMAGE && item.category !== LocalFileCategory.IMAGE) {
      return false;
    }
    if (this.typeFilter === LocalMediaTypeFilter.AUDIO && item.category !== LocalFileCategory.AUDIO) {
      return false;
    }
    if (this.typeFilter === LocalMediaTypeFilter.SUBTITLE && item.category !== LocalFileCategory.SUBTITLE) {
      return false;
    }
    if (this.sourceFilter === LocalMediaSourceFilter.MEDIA_LIBRARY &&
      item.origin !== LocalMediaOrigin.MEDIA_LIBRARY) {
      return false;
    }
    if (this.sourceFilter === LocalMediaSourceFilter.MANUAL &&
      item.origin !== LocalMediaOrigin.DOCUMENT_PICKER) {
      return false;
    }
    if (this.availabilityFilter === LocalMediaAvailabilityFilter.AVAILABLE &&
      item.availability !== LocalMediaAvailability.AVAILABLE) {
      return false;
    }
    if (this.availabilityFilter === LocalMediaAvailabilityFilter.UNAVAILABLE &&
      item.availability !== LocalMediaAvailability.UNAVAILABLE) {
      return false;
    }
    return true;
  }

  private visibleSelectionKeys(): string[] {
    const keys: string[] = [];
    if (this.browseMode === LocalBrowseMode.DIRECTORY) {
      for (const folder of this.displayedFolders()) {
        if (!folder.isMediaLibraryRoot() && folder.parentUri === this.selectedFolderUri &&
          this.matchesSelectionText(folder.displayName)) {
          keys.push(this.folderSelectionKey(folder));
        }
      }
    }
    for (const item of this.displayedItems()) {
      if (this.acceptsSelectionItem(item)) {
        keys.push(this.mediaSelectionKey(item));
      }
    }
    return keys;
  }

  private allVisibleSelected(): boolean {
    const visibleKeys: string[] = this.visibleSelectionKeys();
    if (visibleKeys.length === 0) {
      return false;
    }
    for (const key of visibleKeys) {
      if (!this.selected(key)) {
        return false;
      }
    }
    return true;
  }

  private toggleSelectAll(): void {
    const visibleKeys: string[] = this.visibleSelectionKeys();
    const keys: string[] = this.selectedEntryKeys.slice();
    const clearVisible: boolean = this.allVisibleSelected();
    for (const key of visibleKeys) {
      const index: number = keys.indexOf(key);
      if (clearVisible && index >= 0) {
        keys.splice(index, 1);
      } else if (!clearVisible && index < 0) {
        keys.push(key);
      }
    }
    this.onSelectedEntryKeysChange(keys);
  }

  private invertVisibleSelection(): void {
    const visibleKeys: string[] = this.visibleSelectionKeys();
    const keys: string[] = [];
    for (const key of this.selectedEntryKeys) {
      if (visibleKeys.indexOf(key) < 0) {
        keys.push(key);
      }
    }
    for (const key of visibleKeys) {
      if (!this.selected(key)) {
        keys.push(key);
      }
    }
    this.onSelectedEntryKeysChange(keys);
  }

  private selectedHiddenRecords(): HiddenLocalItem[] {
    const result: HiddenLocalItem[] = [];
    for (const item of this.hiddenItems) {
      const key: string = item.itemType === HiddenLocalItemType.FOLDER ?
        `folder:${item.locator}` : `file:${item.locator}`;
      if (this.selected(key)) {
        result.push(item);
      }
    }
    return result;
  }

  private selectedVisibleRecords(): HiddenLocalItem[] {
    const result: HiddenLocalItem[] = [];
    for (const folder of this.localFolders) {
      if (!folder.isMediaLibraryRoot() && this.selected(this.folderSelectionKey(folder)) &&
        !this.isHidden(HiddenLocalItemType.FOLDER, folder.uri)) {
        result.push(HiddenLocalItem.fromFolder(folder));
      }
    }
    for (const item of this.pageData.items) {
      if (this.selected(this.mediaSelectionKey(item)) &&
        !this.isHidden(HiddenLocalItemType.FILE, item.uri)) {
        result.push(HiddenLocalItem.fromFile(item));
      }
    }
    return result;
  }

  private hideSelected(): void {
    const items: HiddenLocalItem[] = this.selectedVisibleRecords();
    if (items.length > 0) {
      this.onHideMany(items);
      this.exitSelection();
    }
  }

  private restoreSelected(): void {
    const items: HiddenLocalItem[] = this.selectedHiddenRecords();
    if (items.length > 0) {
      this.onRestoreManyHidden(items);
      this.exitSelection();
    }
  }

  private pullRefreshActive(): boolean {
    return this.manualRefreshActive && this.pageData.refreshing &&
      this.pageData.scanState !== LocalMediaScanState.SCANNING;
  }

  private closeSearch(): void {
    this.searchVisible = false;
    this.searchText = '';
  }

  @Builder
  private toolbarActions() {
    AppIconButton({
      icon: AppIconName.SEARCH,
      selected: this.searchVisible,
      label: '搜索',
      onPressed: () => {
        this.searchVisible = true;
      }
    })
    AppIconButton({
      icon: this.browseMode === LocalBrowseMode.DIRECTORY ? AppIconName.MOVIE : AppIconName.FOLDER,
      selected: false,
      label: this.browseMode === LocalBrowseMode.DIRECTORY ? '切换到文件视图' : '切换到文件夹视图',
      onPressed: () => {
        this.selectBrowseMode(this.browseMode === LocalBrowseMode.DIRECTORY ?
          LocalBrowseMode.VIDEO : LocalBrowseMode.DIRECTORY);
      }
    })
    AppIconButton({
      icon: this.gridView ? AppIconName.VIEW_LIST : AppIconName.GRID_VIEW,
      selected: false,
      label: this.gridView ? '切换到列表布局' : '切换到网格布局',
      onPressed: () => {
        this.selectLayout(!this.gridView);
      }
    })
    Button() {
      AppIcon({
        name: AppIconName.SORT_BY_ALPHA,
        iconSize: AppIconSize.TOP_BAR,
        color: AppColors.ICON_PRIMARY
      })
    }
    .type(ButtonType.Normal)
    .width(AppLayout.TOP_BAR_ACTION_SIZE)
    .height(AppLayout.TOP_BAR_ACTION_SIZE)
    .padding(0)
    .backgroundColor(Color.Transparent)
    .borderRadius(AppRadius.NONE)
    .accessibilityText(`排序，当前按${this.sortFieldLabel()}，${this.directionLabel(this.sortAscending)}`)
    .bindMenu(this.sortOptionsMenu, { placement: Placement.BottomRight })
    AppIconButton({
      icon: AppIconName.CHECK_CIRCLE,
      selected: false,
      label: '多选',
      onPressed: () => {
        this.onSelectedEntryKeysChange([]);
        this.onSelectionModeChange(true);
      }
    })
    if (this.canManageVirtualEntries()) {
      Button() {
        AppIcon({
          name: AppIconName.MORE_VERT,
          iconSize: AppIconSize.TOP_BAR,
          color: AppColors.ICON_PRIMARY
        })
      }
      .type(ButtonType.Normal)
      .width(AppLayout.TOP_BAR_ACTION_SIZE)
      .height(AppLayout.TOP_BAR_ACTION_SIZE)
      .padding(0)
      .backgroundColor(Color.Transparent)
      .borderRadius(AppRadius.NONE)
      .accessibilityText('添加本地内容')
      .bindMenu(this.virtualEntryMenu, { placement: Placement.BottomRight })
    }
  }

  @Builder
  private virtualEntryMenu() {
    Menu() {
      MenuItem({ content: '添加视频' })
        .enabled(!this.importing)
        .onClick(() => {
          this.onSelectLocal();
        })
      MenuItem({ content: '新建文件夹' })
        .onClick(() => {
          this.openFolderEditor();
        })
    }
  }

  @Builder
  private folderEditorContent() {
    AppSheetSurface() {
      Column({ space: 16 }) {
        AppSheetHeader({ title: this.folderEditorUri.length > 0 ? '重命名文件夹' : '新建文件夹' })
        Text('仅用于应用内整理，不移动原文件')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
        TextInput({ text: this.folderEditorName, placeholder: '文件夹名称' })
          .height(44)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .backgroundColor(AppColors.SURFACE_RAISED)
          .borderRadius(AppRadius.CONTROL)
          .onChange((value: string) => {
            this.folderEditorName = value;
          })
        Row({ space: 10 }) {
          Button('取消')
            .type(ButtonType.Normal)
            .height(40)
            .layoutWeight(1)
            .fontColor(AppColors.TEXT_PRIMARY)
            .backgroundColor(AppColors.SURFACE_RAISED)
            .borderRadius(AppRadius.CONTROL)
            .onClick(() => {
              this.folderEditorVisible = false;
            })
          Button(this.folderEditorUri.length > 0 ? '保存' : '创建')
            .type(ButtonType.Normal)
            .height(40)
            .layoutWeight(1)
            .fontColor(AppColors.accentForeground(this.accentColor))
            .backgroundColor(AppColors.accent(this.accentColor))
            .borderRadius(AppRadius.CONTROL)
            .enabled(!this.folderEditorSaving)
            .opacity(this.folderEditorSaving ? 0.55 : 1)
            .onClick(() => {
              this.submitFolderEditor().catch(() => {
                this.folderEditorSaving = false;
              });
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
        top: 20, bottom: 28 })
    }
  }

  @Builder
  private selectionToolbarActions() {
    Button(this.allVisibleSelected() ? '取消全选' : '全选')
      .type(ButtonType.Normal)
      .height(AppLayout.TOP_BAR_ACTION_SIZE)
      .padding({ left: 8, right: 8 })
      .fontSize(AppTypography.BODY)
      .fontColor(AppColors.accent(this.accentColor))
      .backgroundColor(Color.Transparent)
      .enabled(this.visibleSelectionKeys().length > 0)
      .opacity(this.visibleSelectionKeys().length > 0 ? 1 : 0.4)
      .onClick(() => {
        this.toggleSelectAll();
      })
    Button('反选')
      .type(ButtonType.Normal)
      .height(AppLayout.TOP_BAR_ACTION_SIZE)
      .padding({ left: 8, right: 8 })
      .fontSize(AppTypography.BODY)
      .fontColor(AppColors.accent(this.accentColor))
      .backgroundColor(Color.Transparent)
      .enabled(this.visibleSelectionKeys().length > 0)
      .opacity(this.visibleSelectionKeys().length > 0 ? 1 : 0.4)
      .onClick(() => {
        this.invertVisibleSelection();
      })
  }

  @Builder
  private selectionBottomBar() {
    Row({ space: 28 }) {
      Button() {
        Column({ space: 2 }) {
          AppIcon({
            name: AppIconName.VISIBILITY_OFF,
            iconSize: AppIconSize.BOTTOM_BAR,
            color: AppColors.ICON_PRIMARY
          })
          Text('隐藏')
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
      }
      .type(ButtonType.Normal)
      .width(88)
      .height('100%')
      .padding(0)
      .backgroundColor(Color.Transparent)
      .enabled(this.selectedVisibleRecords().length > 0)
      .opacity(this.selectedVisibleRecords().length > 0 ? 1 : 0.4)
      .accessibilityText(`隐藏 ${this.selectedVisibleRecords().length} 项`)
      .onClick(() => {
        this.hideSelected();
      })

      if (this.selectedHiddenRecords().length > 0) {
        Button() {
          Column({ space: 2 }) {
            AppIcon({
              name: AppIconName.VISIBILITY,
              iconSize: AppIconSize.BOTTOM_BAR,
              color: AppColors.ICON_PRIMARY
            })
            Text('恢复显示')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_PRIMARY)
          }
        }
        .type(ButtonType.Normal)
        .width(88)
        .height('100%')
        .padding(0)
        .backgroundColor(Color.Transparent)
        .accessibilityText(`恢复显示 ${this.selectedHiddenRecords().length} 项`)
        .onClick(() => {
          this.restoreSelected();
        })
      }
    }
    .width('100%')
    .height(AppLayout.BOTTOM_BAR_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.NAVIGATION_BACKGROUND)
  }

  @Builder
  private searchToolbar() {
    Row({ space: 8 }) {
      Search({ placeholder: '搜索当前媒体库', value: this.searchText })
        .height(36)
        .layoutWeight(1)
        .fontColor(AppColors.TEXT_PRIMARY)
        .placeholderColor(AppColors.TEXT_MUTED)
        .backgroundColor(AppColors.SURFACE_INPUT)
        .borderRadius(AppRadius.CONTROL)
        .onChange((value: string) => {
          this.searchText = value;
        })
      Button('取消')
        .type(ButtonType.Normal)
        .height(36)
        .padding({ left: 8, right: 8 })
        .fontSize(AppTypography.BODY)
        .fontColor(AppColors.accent(this.accentColor))
        .backgroundColor(Color.Transparent)
        .borderRadius(AppRadius.CONTROL)
        .onClick(() => {
          this.closeSearch();
        })
    }
    .width('100%')
    .height(AppLayout.TOP_BAR_HEIGHT)
    .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL })
    .backgroundColor(AppColors.NAVIGATION_BACKGROUND)
  }

  private selectBrowseMode(mode: LocalBrowseMode): void {
    if (mode === this.browseMode) {
      return;
    }
    const field: LocalMediaSortField = LocalMediaSortOptions.normalize(mode, this.sortField);
    if (field !== this.sortField) {
      this.sortField = field;
      this.sortAscending = true;
    }
    this.onBrowseModeChange(mode);
    this.persistLocalViewSettings(mode, this.gridView);
  }

  private selectLayout(gridView: boolean): void {
    if (gridView === this.gridView) {
      return;
    }
    this.gridView = gridView;
    this.persistLocalViewSettings(this.browseMode, gridView);
  }

  private selectSortField(field: LocalMediaSortField): void {
    if (field === this.sortField) {
      return;
    }
    this.sortField = field;
    this.sortAscending = field === LocalMediaSortField.NAME || field === LocalMediaSortField.TYPE;
    this.persistLocalViewSettings(this.browseMode, this.gridView);
  }

  private selectSortDirection(ascending: boolean): void {
    if (ascending === this.sortAscending) {
      return;
    }
    this.sortAscending = ascending;
    this.persistLocalViewSettings(this.browseMode, this.gridView);
  }

  private sortFieldLabel(): string {
    if (this.sortField === LocalMediaSortField.ITEM_COUNT) {
      return '数量';
    }
    if (this.sortField === LocalMediaSortField.MODIFIED) {
      return '日期';
    }
    if (this.sortField === LocalMediaSortField.SIZE) {
      return '大小';
    }
    if (this.sortField === LocalMediaSortField.TYPE) {
      return '类型';
    }
    return '标题';
  }

  private directionLabel(ascending: boolean): string {
    if (this.sortField === LocalMediaSortField.ITEM_COUNT) {
      return ascending ? '少到多' : '多到少';
    }
    if (this.sortField === LocalMediaSortField.MODIFIED) {
      return ascending ? '旧到新' : '新到旧';
    }
    if (this.sortField === LocalMediaSortField.SIZE) {
      return ascending ? '小到大' : '大到小';
    }
    if (this.sortField === LocalMediaSortField.TYPE) {
      return ascending ? '升序' : '降序';
    }
    return ascending ? 'A 到 Z' : 'Z 到 A';
  }

  @Builder
  private sortMenuItem(field: LocalMediaSortField, label: string) {
    MenuItem({ content: label })
      .selected(this.sortField === field)
      .selectIcon(true)
      .onClick(() => {
        this.selectSortField(field);
      })
  }

  @Builder
  private sortOptionsMenu() {
    Menu() {
      this.sortMenuItem(LocalMediaSortField.NAME, '标题')
      if (this.browseMode === LocalBrowseMode.DIRECTORY) {
        this.sortMenuItem(LocalMediaSortField.ITEM_COUNT, '数量')
      } else {
        this.sortMenuItem(LocalMediaSortField.MODIFIED, '日期')
        this.sortMenuItem(LocalMediaSortField.SIZE, '大小')
        this.sortMenuItem(LocalMediaSortField.TYPE, '类型')
      }
      MenuItem({
        content: '顺序',
        labelInfo: this.directionLabel(this.sortAscending),
        builder: this.directionMenu
      })
    }
    .subMenuExpandingMode(SubMenuExpandingMode.STACK_EXPAND)
  }

  @Builder
  private directionMenu() {
    Menu() {
      MenuItem({ content: this.directionLabel(true) })
        .selected(this.sortAscending)
        .selectIcon(true)
        .onClick(() => {
          this.selectSortDirection(true);
        })
      MenuItem({ content: this.directionLabel(false) })
        .selected(!this.sortAscending)
        .selectIcon(true)
        .onClick(() => {
          this.selectSortDirection(false);
        })
    }
  }

  private isHidden(itemType: HiddenLocalItemType, locator: string): boolean {
    for (const item of this.hiddenItems) {
      if (item.itemType === itemType && item.locator === locator) {
        return true;
      }
    }
    return false;
  }

  private displayedFolders(): LocalMediaFolder[] {
    if (this.showHiddenItems) {
      return this.localFolders;
    }
    return this.localFolders.filter((folder: LocalMediaFolder) => {
      return folder.isMediaLibraryRoot() || !this.isHidden(HiddenLocalItemType.FOLDER, folder.uri);
    });
  }

  private displayedItems(): LocalMediaAsset[] {
    if (this.showHiddenItems) {
      return this.pageData.items;
    }
    return this.pageData.items.filter((item: LocalMediaAsset) => {
      const fileHidden: boolean = this.isHidden(HiddenLocalItemType.FILE, item.uri);
      const parentHidden: boolean = item.parentUri.length > 0 &&
        this.isHidden(HiddenLocalItemType.FOLDER, item.parentUri);
      return !fileHidden && !parentHidden;
    });
  }

  @Builder
  private libraryState() {
    if (this.pageData.scanFailure !== null) {
      FailureNotice({
        failure: this.pageData.scanFailure,
        onAction: () => {
          this.onScanLocal();
        }
      })
    } else if (this.pageData.scanState === LocalMediaScanState.IDLE ||
      this.pageData.scanState === LocalMediaScanState.PERMISSION_DENIED) {
      Column({ space: 12 }) {
        AppIcon({ name: AppIconName.FOLDER, iconSize: 38, color: AppColors.accent(this.accentColor) })
        Text('扫描设备中的视频')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('授权后读取系统媒体库，不修改也不上传文件。')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_MUTED)
        Button('开始扫描')
          .type(ButtonType.Normal)
          .height(40)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.accentForeground(this.accentColor))
          .backgroundColor(AppColors.accent(this.accentColor))
          .borderRadius(AppRadius.CONTROL)
          .onClick(() => {
            this.onScanLocal();
          })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height(260)
    } else {
      if (this.pageData.scanState === LocalMediaScanState.EMPTY) {
        Column({ space: 10 }) {
          Text(this.selectedFolderUri === LocalMediaFolder.MEDIA_LIBRARY_URI ? '暂无本地媒体' :
            (this.selectedFolderUri.length > 0 ? '这个文件夹中没有视频' : '没有发现视频'))
            .fontSize(15)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.selectedFolderUri === LocalMediaFolder.MEDIA_LIBRARY_URI ?
            '扫描系统媒体库，或调整文件夹筛选条件。' : '可以调整文件夹筛选条件，或添加视频。')
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_MUTED)
          if (this.selectedFolderUri === LocalMediaFolder.MEDIA_LIBRARY_URI) {
            Button('开始扫描')
              .type(ButtonType.Normal)
              .height(40)
              .fontSize(AppTypography.BODY)
              .fontColor(AppColors.accentForeground(this.accentColor))
              .backgroundColor(AppColors.accent(this.accentColor))
              .borderRadius(AppRadius.CONTROL)
              .onClick(() => {
                this.onScanLocal();
              })
          } else if (this.selectedFolderUri.length > 0) {
            Button('返回上级文件夹')
              .type(ButtonType.Normal)
              .height(38)
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_PRIMARY)
              .backgroundColor(AppColors.SURFACE_RAISED)
              .borderRadius(AppRadius.CONTROL)
              .onClick(() => {
                this.onBack();
              })
          } else {
            Button('选择视频文件')
              .type(ButtonType.Normal)
              .height(38)
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_PRIMARY)
              .backgroundColor(AppColors.SURFACE_RAISED)
              .borderRadius(AppRadius.CONTROL)
              .onClick(() => {
                this.onSelectLocal();
              })
          }
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(180)
      }
    }
  }

  build() {
    Column() {
      if (this.selectionMode) {
        AppToolbar({
          title: this.selectedEntryKeys.length > 0 ? `已选择 ${this.selectedEntryKeys.length} 项` : '选择项目',
          showBack: true,
          onBack: () => {
            this.exitSelection();
          }
        }) {
          this.selectionToolbarActions()
        }
      } else {
        Stack() {
          AppToolbar({
            title: this.pageTitle(),
            path: this.pagePath(),
            showBack: this.selectedFolderUri.length > 0,
            onBack: () => {
              this.onBack();
            }
          }) {
            this.toolbarActions()
          }
          if (this.searchVisible) {
            this.searchToolbar()
          }
        }
        .width('100%')
        .height(AppLayout.TOP_BAR_HEIGHT)
      }

      Column() {
        if (this.importing) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(20)
              .height(20)
            Text('正在处理文件…')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(12)
        }
        if (this.localFailure !== null) {
          FailureNotice({
            failure: this.localFailure,
            onAction: () => {
              this.onRetryLocal();
            }
          })
        }
        if (this.pageData.scanFailure !== null && this.pageData.scanState === LocalMediaScanState.READY) {
          FailureNotice({
            failure: this.pageData.scanFailure,
            onAction: () => {
              this.onScanLocal();
            }
          })
        }
        Refresh({ refreshing: this.pullRefreshActive(), refreshingContent: this.refreshingContent }) {
          Stack() {
            if ((this.browseMode === LocalBrowseMode.DIRECTORY &&
              this.displayedFolders().some((folder: LocalMediaFolder) =>
                folder.parentUri === this.selectedFolderUri)) ||
              this.pageData.scanState === LocalMediaScanState.READY ||
              this.pageData.scanState === LocalMediaScanState.SCANNING) {
              if (this.viewSettingsReady) {
                LocalMediaBrowser({
                scroller: this.mediaScroller,
                folders: this.displayedFolders(),
                items: this.displayedItems(),
                playbackProgress: this.playbackProgress,
                showFolders: this.browseMode === LocalBrowseMode.DIRECTORY,
                currentDirectoryUri: this.selectedFolderUri,
                showItemCount: this.showItemCount,
                gridView: this.gridView,
                contentWidth: this.contentWidth,
                searchText: this.searchText,
                accentColor: this.accentColor,
                sortField: this.sortField,
                sortAscending: this.sortAscending,
                typeFilter: this.typeFilter,
                sourceFilter: this.sourceFilter,
                availabilityFilter: this.availabilityFilter,
                showSize: this.showSize,
                showResolution: this.showResolution,
                showFileExtension: this.showFileExtension,
                showDuration: this.showDuration,
                showModifiedDate: this.showModifiedDate,
                showThumbnails: this.showThumbnails,
                hiddenItems: this.hiddenItems,
                selectionMode: this.selectionMode,
                selectedEntryKeys: this.selectedEntryKeys,
                onFolderChange: (folderUri: string) => {
                  this.onOpenFolder(folderUri);
                },
                onScrollIndexChange: (index: number) => {
                  this.rememberScrollPosition(index);
                },
                onPlay: this.onPlay,
                onAddFavorite: this.onAddFavorite,
                onAddToPlaylist: this.onAddToPlaylist,
                onHideFolder: this.onHideFolder,
                onRenameVirtualFolder: (folder: LocalMediaFolder) => {
                  this.openFolderEditor(folder);
                },
                onRemoveVirtualFolder: this.onRemoveVirtualFolder,
                onHideMedia: this.onHideMedia,
                onRestoreHidden: this.onRestoreHidden,
                onToggleSelection: (key: string) => {
                  this.toggleSelection(key);
                },
                onRemoveManual: this.onRemoveManual,
                onReauthorizeManual: this.onReauthorizeManual,
                onCleanUnavailable: this.onCleanUnavailable,
                loadThumbnail: this.loadLocalThumbnail
                })
                .height('100%')
              } else {
                Column()
                  .width('100%')
                  .height('100%')
              }
            } else {
              Scroll() {
                Column() {
                  this.libraryState()
                }
                .width('100%')
                .constraintSize({ minHeight: '100%' })
                .justifyContent(FlexAlign.Start)
                .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
                  bottom: AppSpacing.PAGE_BOTTOM })
              }
              .width('100%')
              .height('100%')
              .scrollBar(BarState.Off)
            }
            if (this.automaticRefreshIndicatorVisible) {
              Column() {
                localRefreshIndicator(this.refreshIndicatorParams)
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .hitTestBehavior(HitTestMode.Block)
              .zIndex(2)
            }
          }
          .width('100%')
          .height('100%')
          .position({ x: 0, y: 0 })
        }
        .attributeModifier(this.refreshModifier)
        .pullToRefresh(!this.selectionMode &&
          (this.pageData.scanState === LocalMediaScanState.READY ||
            this.pageData.scanState === LocalMediaScanState.EMPTY))
        .refreshOffset(96)
        .onRefreshing(() => {
          if (!this.pageData.refreshing &&
            (this.pageData.scanState === LocalMediaScanState.READY ||
              this.pageData.scanState === LocalMediaScanState.EMPTY)) {
            this.manualRefreshActive = true;
            this.updateAutomaticRefreshIndicator();
            this.onScanLocal();
          }
        })
        .width('100%')
        .height(0)
        .layoutWeight(1)
      }
      .width('100%')
      .height(0)
      .layoutWeight(1)

      if (this.selectionMode) {
        this.selectionBottomBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .bindSheet(this.folderEditorVisible!!, this.folderEditorContent(), {
      height: SheetSize.FIT_CONTENT,
      radius: { topLeft: AppRadius.SHEET, topRight: AppRadius.SHEET },
      effectEdge: 0,
      showClose: false
    })
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const width: number = Number(newValue.width);
      if (width > 0 && width !== this.contentWidth) {
        this.contentWidth = width;
      }
    })
  }
}
