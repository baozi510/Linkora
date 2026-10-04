import { common } from '@kit.AbilityKit';
import { ComponentContent } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { FileSizeFormatter, LocalFileCategory, LocalFileFilter, LocalMediaAsset, MediaFormatDetector,
  MediaSource } from 'linkora_core';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind,
  NetworkDirectoryLoadGuard } from '../models/NetworkDirectoryState';
import { NetworkDirectoryService } from '../services/NetworkDirectoryService';
import { NetworkDirectorySummary, NetworkDirectorySummaryCache } from
  '../services/NetworkDirectorySummaryCache';
import { NetworkServerEntry } from '../services/NetworkServerStore';
import { AppColors, AppRadius, AppSpacing, AppTypography, MediaLayout } from '../ui/AppTheme';
import { AppActionListItem } from './AppActionListItem';
import { AppIcon, AppIconName } from './AppIcon';
import { AppSheetHeader } from './AppSheetHeader';
import { AppSheetSurface } from './AppSheetSurface';
import { FileMediaPreview } from './FileMediaPreview';
import { FolderPreview } from './FolderPreview';
import { MetadataChip } from './MetadataChip';
import { NetworkBrowserToolbar } from './NetworkBrowserToolbar';
import { networkDirectoryPathDetail } from './NetworkDirectoryLabels';
import { fileBrowserGridColumnsTemplate } from './FileBrowserGridLayout';
import { LinkoraFeatures } from '../foundation/LinkoraFeatures';
import { NetworkMediaLoader } from '../services/NetworkMediaLoader';
import { CachedNetworkMedia } from '../services/NetworkMediaCache';
import { AppLifecycleEvents } from '../services/AppLifecycleEvents';
import { NetworkMediaSourceFactory } from '../services/NetworkMediaSourceFactory';

class NetworkRefreshIndicatorParams {
  accentColor: string;

  constructor(accentColor: string) {
    this.accentColor = accentColor;
  }
}

@Builder
function networkRefreshIndicator(params: NetworkRefreshIndicatorParams) {
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
  .zIndex(3)
}

class NetworkRefreshModifier implements AttributeModifier<RefreshAttribute> {
  applyNormalAttribute(instance: RefreshAttribute): void {
    if (deviceInfo.sdkApiVersion >= 23) {
      instance.pullUpToCancelRefresh(false);
    }
  }
}

@ComponentV2
struct NetworkDirectoryList {
  @Param scroller: Scroller = new Scroller();
  @Param entries: NetworkDirectoryEntry[] = [];
  @Param currentPath: string = '';
  @Param preparingPath: string = '';
  @Param gridView: boolean = false;
  @Param contentWidth: number = 0;
  @Param accentColor: string = 'system';
  @Param mediaEnabled: boolean = false;
  @Param previewGeneration: number = 0;
  @Event loadThumbnail: (entry: NetworkDirectoryEntry, consumerId: string) => Promise<image.PixelMap | null> = async () => null;
  @Event cancelThumbnail: (path: string, consumerId: string) => void = () => {};
  @Event onOpen: (entry: NetworkDirectoryEntry) => void = () => {};
  @Event onScrollIndexChange: (index: number) => void = () => {};
  @Local private menuVisible: boolean = false;
  @Local private menuEntry: NetworkDirectoryEntry | null = null;
  private lastLongPressAt: number = 0;
  private lastLongPressPath: string = '';

  private detailLabels(entry: NetworkDirectoryEntry): string[] {
    if (entry.kind === NetworkDirectoryEntryKind.DIRECTORY) {
      return entry.modifiedAt > 0 ? [this.dateLabel(entry.modifiedAt)] : [];
    }
    const size: string = FileSizeFormatter.format(entry.size);
    const labels: string[] = [size];
    if (entry.mediaPreviewReady && entry.width > 0 && entry.height > 0) labels.push(this.mediaAsset(entry).resolutionLabel());
    if (entry.modifiedAt <= 0) {
      return labels;
    }
    return [...labels, this.dateLabel(entry.modifiedAt)];
  }

  private dateLabel(timestamp: number): string {
    const date = new Date(timestamp);
    return [date.getFullYear().toString(), (date.getMonth() + 1).toString().padStart(2, '0'),
      date.getDate().toString().padStart(2, '0')].join('/');
  }

  private mediaAsset(entry: NetworkDirectoryEntry): LocalMediaAsset {
    return new LocalMediaAsset(entry.path, entry.displayName, entry.durationMs, entry.width,
      entry.height, entry.size, entry.modifiedAt);
  }

  private previewKey(entry: NetworkDirectoryEntry): string {
    return JSON.stringify([entry.path, entry.size, entry.modifiedAt, this.previewGeneration]);
  }

  private isDirectory(entry: NetworkDirectoryEntry): boolean {
    return entry.kind === NetworkDirectoryEntryKind.DIRECTORY;
  }

  private isHighlighted(entry: NetworkDirectoryEntry): boolean {
    return this.menuVisible && this.menuEntry?.path === entry.path;
  }

  private openMenu(entry: NetworkDirectoryEntry): void {
    this.menuEntry = entry;
    this.menuVisible = true;
  }

  private recordLongPress(entry: NetworkDirectoryEntry): void {
    this.lastLongPressAt = Date.now();
    this.lastLongPressPath = entry.path;
    this.openMenu(entry);
  }

  private suppressClickAfterLongPress(entry: NetworkDirectoryEntry): boolean {
    return this.lastLongPressPath === entry.path && Date.now() - this.lastLongPressAt < 800;
  }

  private openMenuEntry(): void {
    const entry: NetworkDirectoryEntry | null = this.menuEntry;
    this.menuVisible = false;
    if (entry !== null) {
      this.onOpen(entry);
    }
  }

  private menuTitle(): string {
    return this.menuEntry?.displayName ?? '';
  }

  private menuIsDirectory(): boolean {
    return this.menuEntry?.kind === NetworkDirectoryEntryKind.DIRECTORY;
  }

  @Builder
  private menuContent() {
    AppSheetSurface() {
      Column({ space: 2 }) {
        AppSheetHeader({ title: this.menuTitle() })
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })

        Divider()
          .color(AppColors.DIVIDER)
          .margin({ left: 14, right: 14 })

        Button() {
          Row({ space: 12 }) {
            AppIcon({
              name: this.menuIsDirectory() ? AppIconName.FOLDER_OPEN : AppIconName.PLAY_ARROW,
              iconSize: 20,
              color: AppColors.ICON_PRIMARY
            })
            Text(this.menuIsDirectory() ? '打开' : '打开播放')
              .fontSize(AppTypography.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .height('100%')
        }
        .type(ButtonType.Normal)
        .width('100%')
        .height(40)
        .padding({ left: 14, right: 14 })
        .backgroundColor(Color.Transparent)
        .borderRadius(AppRadius.SMALL)
        .onClick(() => {
          this.openMenuEntry();
        })
      }
      .width('100%')
      .padding({ top: 4, bottom: 8 })
    }
  }

  @Builder
  private metadataChips(repeatItem: RepeatItem<NetworkDirectoryEntry>) {
    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap,
      justifyContent: FlexAlign.Start }) {
      ForEach(this.preparingPath === repeatItem.item.path ? ['正在准备播放…'] : this.detailLabels(repeatItem.item),
        (label: string, index: number) => {
          MetadataChip({ label: label, highlighted: this.preparingPath === repeatItem.item.path })
            .margin({ left: index > 0 ? 5 : 0, bottom: 2 })
        }, (label: string): string => label)
    }
    .width('100%')
  }

  @Builder
  private listEntry(repeatItem: RepeatItem<NetworkDirectoryEntry>) {
    AppActionListItem({
      itemHeight: MediaLayout.LIST_MEDIA_ITEM_HEIGHT,
      selected: this.isHighlighted(repeatItem.item),
      accentColor: this.accentColor,
      showTrailingAction: false,
      accessibilityLabel: `打开 ${repeatItem.item.displayName}`,
      menuAccessibilityLabel: `${repeatItem.item.displayName} 菜单`,
      onOpen: () => {
        this.onOpen(repeatItem.item);
      },
      onOpenMenu: () => {
        this.openMenu(repeatItem.item);
      }
    }) {
      Row({ space: 10 }) {
        if (this.isDirectory(repeatItem.item)) {
          FolderPreview({ accentColor: this.accentColor })
        } else {
          FileMediaPreview({ fileName: repeatItem.item.displayName, accentColor: this.accentColor,
            uri: this.previewKey(repeatItem.item), thumbnailEnabled: this.mediaEnabled, visibleOnly: true,
            durationLabel: repeatItem.item.mediaPreviewReady && repeatItem.item.durationMs > 0 ? this.mediaAsset(repeatItem.item).durationLabel() : '',
            onReadyChanged: (ready: boolean) => {
              repeatItem.item.mediaPreviewReady = ready;
            },
            load: (_uri: string, consumerId: string) => this.loadThumbnail(repeatItem.item, consumerId),
            cancelLoad: (_uri: string, consumerId: string) => this.cancelThumbnail(repeatItem.item.path, consumerId) })
        }

        Column({ space: 5 }) {
          Text(repeatItem.item.displayName)
            .width('100%')
            .fontSize(AppTypography.BODY)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          this.metadataChips(repeatItem)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
  }

  @Builder
  private gridEntry(repeatItem: RepeatItem<NetworkDirectoryEntry>) {
    Column({ space: 6 }) {
      if (this.isDirectory(repeatItem.item)) {
        FolderPreview({ gridView: true, accentColor: this.accentColor })
      } else {
        Stack() {
          FileMediaPreview({ fileName: repeatItem.item.displayName, gridView: true,
            accentColor: this.accentColor, uri: this.previewKey(repeatItem.item),
            thumbnailEnabled: this.mediaEnabled, visibleOnly: true,
            load: (_uri: string, consumerId: string) => this.loadThumbnail(repeatItem.item, consumerId),
            cancelLoad: (_uri: string, consumerId: string) => this.cancelThumbnail(repeatItem.item.path, consumerId) })
          if (this.preparingPath === repeatItem.item.path) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(AppColors.accent(this.accentColor))
          }
        }
        .width('100%')
      }

      Text(repeatItem.item.displayName)
        .width('100%')
        .fontSize(AppTypography.BODY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding(4)
    .backgroundColor(this.isHighlighted(repeatItem.item) ? AppColors.SELECTED_BACKGROUND : Color.Transparent)
    .borderRadius(AppRadius.CARD)
    .onClick(() => {
      if (!this.suppressClickAfterLongPress(repeatItem.item)) {
        this.onOpen(repeatItem.item);
      }
    })
    .priorityGesture(
      LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
        .onAction(() => {
          this.recordLongPress(repeatItem.item);
        })
    )
    .accessibilityText(`打开 ${repeatItem.item.displayName}，长按打开菜单`)
  }

  build() {
    Grid(this.scroller) {
      Repeat<NetworkDirectoryEntry>(this.entries)
        .virtualScroll()
        .each((repeatItem: RepeatItem<NetworkDirectoryEntry>) => {
          GridItem() {
            if (this.gridView) {
              this.gridEntry(repeatItem)
            } else {
              this.listEntry(repeatItem)
            }
          }
        })
        .key((entry: NetworkDirectoryEntry) => `${this.currentPath}|${entry.path}`)
    }
    .columnsTemplate(this.gridView ? fileBrowserGridColumnsTemplate(this.contentWidth) : '1fr')
    .columnsGap(this.gridView ? MediaLayout.GRID_COLUMN_GAP : 0)
    .rowsGap(this.gridView ? MediaLayout.GRID_ROW_GAP : MediaLayout.LIST_ITEM_VERTICAL_GAP)
    .cachedCount(MediaLayout.VIRTUAL_SCROLL_CACHED_ROWS)
    .width('100%')
    .height('100%')
    .padding({ left: this.gridView ? AppSpacing.PAGE_HORIZONTAL : 0,
      right: this.gridView ? AppSpacing.PAGE_HORIZONTAL : 0,
      top: MediaLayout.BROWSER_TOP_INSET, bottom: AppSpacing.PAGE_BOTTOM })
    .edgeEffect(EdgeEffect.None)
    .scrollBar(BarState.Auto)
    .onScrollIndex((first: number, _last: number) => {
      this.onScrollIndexChange(first);
    })
    .bindSheet(this.menuVisible!!, this.menuContent(), {
      height: SheetSize.FIT_CONTENT,
      radius: { topLeft: AppRadius.SHEET, topRight: AppRadius.SHEET },
      effectEdge: 0,
      showClose: false
    })
  }
}

@ComponentV2
export struct NetworkDirectoryBrowser {
  private static readonly AUTO_REFRESH_INDICATOR_DELAY_MS: number = 150;

  @Require @Param server: NetworkServerEntry;
  @Param gridView: boolean = false;
  @Param path: string = '';
  @Event onOpenDirectory: (path: string) => void = () => {};
  @Event onBack: () => void = () => {};
  @Event onOpenSource: (source: MediaSource) => void = () => {};
  @Event onGridViewChange: (gridView: boolean) => void = () => {};

  @Local private currentPath: string = '';
  @Local private renderedPath: string = '';
  @Local private entries: NetworkDirectoryEntry[] = [];
  @Local private loading: boolean = true;
  @Local private failure: string = '';
  @Local private preparingPath: string = '';
  @Local private currentDirectoryInfo: string = '';
  @Local private contentWidth: number = 0;
  @Local private manualRefreshActive: boolean = false;
  @Local private automaticRefreshIndicatorVisible: boolean = false;
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  private service: NetworkDirectoryService | null = null;
  private mediaLoader: NetworkMediaLoader | null = null;
  @Local private previewGeneration: number = 0;
  private abilityContext: common.UIAbilityContext | null = null;
  private backgroundObserver: () => void = () => { this.mediaLoader?.reset(this.entries, false); };
  private scroller: Scroller = new Scroller();
  private scrollPositions: Map<string, number> = new Map<string, number>();
  private currentScrollIndex: number = 0;
  private fileFilter: LocalFileFilter = new LocalFileFilter();
  private loadGuard: NetworkDirectoryLoadGuard = new NetworkDirectoryLoadGuard();
  private automaticRefreshIndicatorTimer: number = -1;
  private refreshIndicatorParams: NetworkRefreshIndicatorParams = new NetworkRefreshIndicatorParams('system');
  private refreshingContent: ComponentContent<NetworkRefreshIndicatorParams> | undefined = undefined;
  private refreshModifier: NetworkRefreshModifier = new NetworkRefreshModifier();

  aboutToAppear(): void {
    this.refreshIndicatorParams.accentColor = this.accentColor;
    this.refreshingContent = new ComponentContent<NetworkRefreshIndicatorParams>(
      this.getUIContext(), wrapBuilder(networkRefreshIndicator), this.refreshIndicatorParams);
    this.service = new NetworkDirectoryService(this.server);
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.abilityContext = context;
    context.eventHub.on(AppLifecycleEvents.BACKGROUND, this.backgroundObserver);
    this.mediaLoader = LinkoraFeatures.createNetworkMediaLoader(context, this.server,
      (entry: NetworkDirectoryEntry, info: CachedNetworkMedia) => {
        const current = this.entries.find((item: NetworkDirectoryEntry): boolean =>
          item.path === entry.path && item.size === entry.size && item.modifiedAt === entry.modifiedAt);
        if (current !== undefined) {
          current.durationMs = info.durationMs; current.width = info.width; current.height = info.height;
        }
      });
    this.currentPath = this.service.directoryPath(this.path.length > 0 ? this.path : this.service.initialPath());
    this.renderedPath = this.currentPath;
    this.loadDirectory(false);
  }

  aboutToDisappear(): void {
    this.abilityContext?.eventHub.off(AppLifecycleEvents.BACKGROUND, this.backgroundObserver);
    this.mediaLoader?.close();
    this.loadGuard.cancel();
    this.service?.cancel();
    this.clearAutomaticRefreshIndicator();
    this.manualRefreshActive = false;
  }

  @Monitor('accentColor')
  private onAccentColorChanged(): void {
    this.refreshIndicatorParams.accentColor = this.accentColor;
    this.refreshingContent?.update(this.refreshIndicatorParams);
  }

  @Monitor('path')
  private onPathChanged(): void {
    if (this.service === null) {
      return;
    }
    const nextPath: string = this.service.directoryPath(
      this.path.length > 0 ? this.path : this.service.initialPath());
    if (nextPath === this.currentPath && this.entries.length > 0) {
      return;
    }
    this.currentPath = nextPath;
    this.currentDirectoryInfo = '';
    this.manualRefreshActive = false;
    this.loadDirectory(false);
  }

  private async loadDirectory(forceRefresh: boolean): Promise<void> {
    if (this.service === null) {
      return;
    }
    const service: NetworkDirectoryService = this.service;
    const path: string = this.currentPath;
    const generation: number = this.loadGuard.next();
    this.mediaLoader?.reset([], false);
    this.loading = true;
    this.failure = '';
    this.updateAutomaticRefreshIndicator();
    try {
      const entries: NetworkDirectoryEntry[] = await service.list(path, forceRefresh);
      if (!this.loadGuard.isCurrent(generation)) {
        return;
      }
      let fileCount: number = 0;
      let totalSize: number = 0;
      let directoryCount: number = 0;
      for (const entry of entries) {
        if (entry.kind === NetworkDirectoryEntryKind.DIRECTORY) {
          ++directoryCount;
        } else if (entry.kind === NetworkDirectoryEntryKind.FILE) {
          ++fileCount;
          totalSize += entry.size;
        }
      }
      const summary: NetworkDirectorySummary =
        new NetworkDirectorySummary(path, fileCount, totalSize, directoryCount);
      NetworkDirectorySummaryCache.put(this.server, summary);
      this.entries = entries;
      this.mediaLoader?.reset(entries, forceRefresh);
      ++this.previewGeneration;
      this.renderedPath = path;
      this.currentDirectoryInfo = networkDirectoryPathDetail(summary);
      this.restoreScrollPosition(path);
    } catch (error) {
      if (!this.loadGuard.isCurrent(generation)) {
        return;
      }
      this.entries = [];
      this.renderedPath = path;
      this.currentDirectoryInfo = '';
      this.failure = error instanceof Error ? error.message : '无法读取远程目录。';
    } finally {
      if (this.loadGuard.isCurrent(generation)) {
        this.loading = false;
        this.manualRefreshActive = false;
        this.updateAutomaticRefreshIndicator();
      }
    }
  }

  private updateAutomaticRefreshIndicator(): void {
    if (!this.loading || this.manualRefreshActive) {
      this.clearAutomaticRefreshIndicator();
      return;
    }
    if (this.automaticRefreshIndicatorVisible || this.automaticRefreshIndicatorTimer >= 0) {
      return;
    }
    this.automaticRefreshIndicatorTimer = setTimeout((): void => {
      this.automaticRefreshIndicatorTimer = -1;
      if (this.loading && !this.manualRefreshActive) {
        this.automaticRefreshIndicatorVisible = true;
      }
    }, NetworkDirectoryBrowser.AUTO_REFRESH_INDICATOR_DELAY_MS);
  }

  private clearAutomaticRefreshIndicator(): void {
    if (this.automaticRefreshIndicatorTimer >= 0) {
      clearTimeout(this.automaticRefreshIndicatorTimer);
      this.automaticRefreshIndicatorTimer = -1;
    }
    this.automaticRefreshIndicatorVisible = false;
  }

  private scrollPositionKey(path: string): string {
    return `${path}|${this.gridView ? 'grid' : 'list'}`;
  }

  private rememberScrollPosition(): void {
    this.scrollPositions.set(this.scrollPositionKey(this.currentPath), this.currentScrollIndex);
  }

  private restoreScrollPosition(path: string): void {
    const index: number = this.scrollPositions.get(this.scrollPositionKey(path)) ?? 0;
    this.currentScrollIndex = index;
    setTimeout((): void => {
      this.scroller.scrollToIndex(index, false);
    }, 0);
  }

  private async openEntry(entry: NetworkDirectoryEntry): Promise<void> {
    if (entry.kind === NetworkDirectoryEntryKind.DIRECTORY) {
      this.rememberScrollPosition();
      this.onOpenDirectory(this.service?.directoryPath(entry.path) ?? entry.path);
      return;
    }
    if (this.service === null) {
      return;
    }
    const category: LocalFileCategory = this.fileFilter.categoryOf(entry.displayName);
    if (category !== LocalFileCategory.VIDEO && category !== LocalFileCategory.AUDIO) {
      this.showToast('当前文件类型暂不支持直接打开');
      return;
    }

    this.mediaLoader?.reset(this.entries, false);
    this.onOpenSource(NetworkMediaSourceFactory.fromEntry(this.server, entry));
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (_error) {
    }
  }

  @Builder
  private directoryContent() {
    if (this.failure.length > 0 && !this.loading) {
      Column({ space: 12 }) {
        AppIcon({ name: AppIconName.WARNING, iconSize: 34, color: AppColors.ERROR_TEXT })
        Text(this.failure)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
        Button('重新加载')
          .type(ButtonType.Normal)
          .height(38)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.accent(this.accentColor))
          .backgroundColor(AppColors.SURFACE_RAISED)
          .onClick(() => {
            this.loadDirectory(true);
          })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 32, right: 32 })
      .justifyContent(FlexAlign.Center)
    } else if (this.entries.length === 0 && !this.loading) {
      Column({ space: 10 }) {
        AppIcon({ name: AppIconName.FOLDER_OPEN, iconSize: 42, color: AppColors.ICON_TERTIARY })
        Text('这个文件夹是空的')
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      ForEach([this.renderedPath], (renderedPath: string) => {
        NetworkDirectoryList({
          scroller: this.scroller,
          entries: this.entries,
          currentPath: renderedPath,
          preparingPath: this.preparingPath,
          mediaEnabled: this.mediaLoader !== null, previewGeneration: this.previewGeneration,
          loadThumbnail: (entry: NetworkDirectoryEntry, consumerId: string): Promise<image.PixelMap | null> =>
            this.mediaLoader?.load(entry, consumerId) ?? Promise.resolve(null),
          cancelThumbnail: (path: string, consumerId: string) => this.mediaLoader?.cancel(path, consumerId),
          gridView: this.gridView,
          contentWidth: this.contentWidth,
          accentColor: this.accentColor,
          onOpen: (entry: NetworkDirectoryEntry) => {
            this.openEntry(entry);
          },
          onScrollIndexChange: (index: number) => {
            this.currentScrollIndex = index;
          }
        })
      }, (renderedPath: string): string => renderedPath)
    }
  }

  build() {
    Column() {
      NetworkBrowserToolbar({
        title: this.server.titleLabel(),
        path: this.currentDirectoryInfo.length > 0 ?
          `${this.service?.displayPath(this.currentPath) ?? ''} · ${this.currentDirectoryInfo}` :
          (this.service?.displayPath(this.currentPath) ?? ''),
        gridView: this.gridView,
        onBack: this.onBack,
        onGridViewChange: this.onGridViewChange
      })

      Refresh({ refreshing: this.manualRefreshActive && this.loading,
        refreshingContent: this.refreshingContent }) {
        Stack() {
          this.directoryContent()
          if (this.automaticRefreshIndicatorVisible) {
            Column() {
              networkRefreshIndicator(this.refreshIndicatorParams)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .hitTestBehavior(HitTestMode.Block)
            .zIndex(3)
          }
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }
      .attributeModifier(this.refreshModifier)
      .pullToRefresh(!this.loading)
      .refreshOffset(96)
      .onRefreshing(() => {
        if (!this.loading) {
          this.manualRefreshActive = true;
          this.updateAutomaticRefreshIndicator();
          this.loadDirectory(true);
        }
      })
      .width('100%')
      .height(0)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const width: number = Number(newValue.width);
      if (width > 0 && width !== this.contentWidth) {
        this.contentWidth = width;
      }
    })
  }
}
