import { image } from '@kit.ImageKit';
import { LocalMediaAsset, LocalMediaFolder, LocalMediaPlaybackProgress, MediaSource } from 'linkora_core';
import { AppColors, AppRadius, AppSpacing, AppTypography, MediaLayout } from '../ui/AppTheme';
import { AppActionListItem } from './AppActionListItem';
import { AppIcon, AppIconName } from './AppIcon';
import { FolderPreview } from './FolderPreview';
import { AppSheetHeader } from './AppSheetHeader';
import { AppSheetSurface } from './AppSheetSurface';
import { LocalMediaRow } from './LocalMediaRow';
import { FileMediaPreview } from './FileMediaPreview';
import { MetadataChip } from './MetadataChip';
import { LocalMediaAvailabilityFilter, LocalMediaSortField, LocalMediaSourceFilter,
  LocalMediaTypeFilter } from '../models/LocalMediaViewOptions';
import { HiddenLocalItem, HiddenLocalItemType } from '../services/HiddenLocalItemStore';
import { LocalMediaOrdering } from '../models/LocalMediaOrdering';
import { fileBrowserGridColumnsTemplate } from './FileBrowserGridLayout';

enum LocalBrowserEntryKind {
  DIRECTORY = 'directory',
  MEDIA = 'media'
}

export class LocalBrowserEntry {
  readonly kind: LocalBrowserEntryKind;
  readonly directory: LocalMediaFolder | null;
  readonly media: LocalMediaAsset | null;
  readonly key: string;

  private constructor(kind: LocalBrowserEntryKind, key: string,
    directory: LocalMediaFolder | null = null, media: LocalMediaAsset | null = null) {
    this.kind = kind;
    this.key = key;
    this.directory = directory;
    this.media = media;
  }

  static fromDirectory(directory: LocalMediaFolder): LocalBrowserEntry {
    const key: string = `directory:${LocalBrowserEntry.stringPart(directory.uri)}:` +
      `${LocalBrowserEntry.stringPart(directory.displayName)}:${directory.totalCount}:` +
      `${directory.videoCount}:${directory.imageCount}:${directory.subtitleCount}:` +
      `${LocalBrowserEntry.stringPart(directory.coverUri)}:${LocalBrowserEntry.stringPart(directory.parentUri)}:` +
      `${directory.totalSizeBytes}:${directory.virtual}:${directory.folderCount}`;
    return new LocalBrowserEntry(LocalBrowserEntryKind.DIRECTORY, key, directory);
  }

  static fromMedia(media: LocalMediaAsset): LocalBrowserEntry {
    const key: string = `media:${media.origin}:${LocalBrowserEntry.stringPart(media.uri)}:` +
      `${LocalBrowserEntry.stringPart(media.displayName)}:${media.durationMs}:${media.width}:` +
      `${media.height}:${media.sizeBytes}:${media.modifiedAt}:${media.category}:` +
      `${LocalBrowserEntry.stringPart(media.parentUri)}:${media.availability}:` +
      `${LocalBrowserEntry.stringPart(media.sourceUri)}`;
    return new LocalBrowserEntry(LocalBrowserEntryKind.MEDIA, key, null, media);
  }

  private static stringPart(value: string): string {
    return `${value.length}:${value}`;
  }

}

@ComponentV2
export struct LocalMediaBrowser {
  @Param scroller: Scroller = new Scroller();
  @Param folders: LocalMediaFolder[] = [];
  @Param items: LocalMediaAsset[] = [];
  @Param playbackProgress: LocalMediaPlaybackProgress[] = [];
  @Param showFolders: boolean = true;
  @Param currentDirectoryUri: string = '';
  @Param gridView: boolean = false;
  @Param contentWidth: number = 0;
  @Param searchText: string = '';
  @Param accentColor: string = 'system';
  @Param sortField: LocalMediaSortField = LocalMediaSortField.MODIFIED;
  @Param sortAscending: boolean = false;
  @Param typeFilter: LocalMediaTypeFilter = LocalMediaTypeFilter.ALL;
  @Param sourceFilter: LocalMediaSourceFilter = LocalMediaSourceFilter.ALL;
  @Param availabilityFilter: LocalMediaAvailabilityFilter = LocalMediaAvailabilityFilter.ALL;
  @Param showSize: boolean = true;
  @Param showItemCount: boolean = true;
  @Param showResolution: boolean = true;
  @Param showFileExtension: boolean = true;
  @Param showDuration: boolean = true;
  @Param showModifiedDate: boolean = false;
  @Param showThumbnails: boolean = true;
  @Param hiddenItems: HiddenLocalItem[] = [];
  @Param selectionMode: boolean = false;
  @Param selectedEntryKeys: string[] = [];
  @Event onFolderChange: (folderUri: string) => void = () => {};
  @Event onScrollIndexChange: (index: number) => void = () => {};
  @Event onPlay: (source: MediaSource) => void = () => {};
  @Event onAddFavorite: (source: MediaSource) => void = () => {};
  @Event onAddToPlaylist: (source: MediaSource) => void = () => {};
  @Event onHideFolder: (folder: LocalMediaFolder) => void = () => {};
  @Event onRenameVirtualFolder: (folder: LocalMediaFolder) => void = () => {};
  @Event onRemoveVirtualFolder: (uri: string) => void = () => {};
  @Event onHideMedia: (item: LocalMediaAsset) => void = () => {};
  @Event onRestoreHidden: (item: HiddenLocalItem) => void = () => {};
  @Event onToggleSelection: (key: string) => void = () => {};
  @Event onRemoveManual: (uri: string) => void = () => {};
  @Event onReauthorizeManual: (uri: string) => void = () => {};
  @Event onCleanUnavailable: () => void = () => {};
  @Event loadThumbnail: (uri: string) => Promise<image.PixelMap | null> = async () => null;

  @Local private menuVisible: boolean = false;
  @Local private menuItem: LocalMediaAsset | null = null;
  @Local private menuFolder: LocalMediaFolder | null = null;
  private lastLongPressAt: number = 0;
  private lastLongPressKey: string = '';

  private folderSelectionKey(folder: LocalMediaFolder): string {
    return `folder:${folder.uri}`;
  }

  private mediaSelectionKey(item: LocalMediaAsset): string {
    return `file:${item.uri}`;
  }

  private isSelected(key: string): boolean {
    return this.selectedEntryKeys.indexOf(key) >= 0;
  }

  private isHighlighted(key: string): boolean {
    if (this.isSelected(key)) return true;
    if (!this.menuVisible) return false;
    return (this.menuFolder !== null && key === this.folderSelectionKey(this.menuFolder)) ||
      (this.menuItem !== null && key === this.mediaSelectionKey(this.menuItem));
  }

  private suppressClickAfterLongPress(key: string): boolean {
    return this.lastLongPressKey === key && Date.now() - this.lastLongPressAt < 800;
  }

  private recordLongPress(key: string): void {
    this.lastLongPressAt = Date.now();
    this.lastLongPressKey = key;
  }

  private handleFolderLongPress(folder: LocalMediaFolder): void {
    if (folder.isMediaLibraryRoot()) {
      this.openFolderMenu(folder);
      return;
    }
    const key: string = this.folderSelectionKey(folder);
    this.recordLongPress(key);
    if (this.selectionMode) {
      this.onToggleSelection(key);
    } else {
      this.openFolderMenu(folder);
    }
  }

  private handleMediaLongPress(item: LocalMediaAsset): void {
    const key: string = this.mediaSelectionKey(item);
    this.recordLongPress(key);
    if (this.selectionMode) {
      this.onToggleSelection(key);
    } else {
      this.openMediaMenu(item);
    }
  }

  private hiddenRecord(itemType: HiddenLocalItemType, locator: string): HiddenLocalItem | null {
    for (const item of this.hiddenItems) {
      if (item.itemType === itemType && item.locator === locator) {
        return item;
      }
    }
    return null;
  }

  private isFolderHidden(folder: LocalMediaFolder): boolean {
    return this.hiddenRecord(HiddenLocalItemType.FOLDER, folder.uri) !== null;
  }

  private isMediaHidden(item: LocalMediaAsset): boolean {
    return this.hiddenRecord(HiddenLocalItemType.FILE, item.uri) !== null;
  }

  private folderDetailLabel(folder: LocalMediaFolder): string {
    return this.isFolderHidden(folder) ? `${folder.detailLabel()} · 已隐藏` : folder.detailLabel();
  }

  private entryAccessibilityLabel(entry: LocalBrowserEntry): string {
    if (entry.directory !== null) {
      return `${entry.directory.displayName}, ${this.folderDetailLabel(entry.directory)}`;
    }
    if (entry.media !== null) {
      return `${entry.media.displayName}${this.isMediaHidden(entry.media) ? '，已隐藏' : ''}`;
    }
    return '';
  }

  private displayNameLabel(item: LocalMediaAsset): string {
    if (this.showFileExtension) {
      return item.displayName;
    }
    const dot: number = item.displayName.lastIndexOf('.');
    if (dot <= 0 || dot === item.displayName.length - 1) {
      return item.displayName;
    }
    return item.displayName.substring(0, dot);
  }

  private progressRatio(item: LocalMediaAsset): number {
    for (const progress of this.playbackProgress) {
      if (progress.uri === item.uri) {
        return progress.ratio();
      }
    }
    return 0;
  }

  private openMediaMenu(item: LocalMediaAsset): void {
    this.menuItem = item;
    this.menuFolder = null;
    this.menuVisible = true;
  }

  private openFolderMenu(folder: LocalMediaFolder): void {
    this.menuFolder = folder;
    this.menuItem = null;
    this.menuVisible = true;
  }

  private closeMediaMenu(): void {
    this.menuVisible = false;
    this.menuItem = null;
    this.menuFolder = null;
  }

  private confirmRemoveManual(item: LocalMediaAsset): void {
    const uri: string = item.uri;
    const displayName: string = item.displayName;
    this.closeMediaMenu();
    this.getUIContext().showAlertDialog({
      title: '确认移除',
      message: `确定要将“${displayName}”从列表中移除吗？原文件不会被删除。`,
      cornerRadius: AppRadius.SHEET,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '移除',
        action: () => {
          this.onRemoveManual(uri);
        }
      }
    });
  }

  private confirmCleanUnavailable(): void {
    this.closeMediaMenu();
    this.getUIContext().showAlertDialog({
      title: '确认清理',
      message: '确定要清理全部失效的手动添加记录吗？',
      cornerRadius: AppRadius.SHEET,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清理',
        action: () => {
          this.onCleanUnavailable();
        }
      }
    });
  }

  private confirmRemoveVirtualFolder(folder: LocalMediaFolder): void {
    const uri: string = folder.uri;
    const displayName: string = folder.displayName;
    this.closeMediaMenu();
    this.getUIContext().showAlertDialog({
      title: '删除文件夹',
      message: `确定删除“${displayName}”及其中的子文件夹吗？原文件不会被删除。`,
      cornerRadius: AppRadius.SHEET,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.onRemoveVirtualFolder(uri);
        }
      }
    });
  }

  @Builder
  private mediaMenuAction(icon: AppIconName, label: string, action: () => void,
    destructive: boolean = false) {
    Button() {
      Row({ space: 12 }) {
        AppIcon({
          name: icon,
          iconSize: 20,
          color: destructive ? AppColors.DESTRUCTIVE_ACTION : AppColors.ICON_PRIMARY
        })
        Text(label)
          .fontSize(AppTypography.BODY)
          .fontColor(destructive ? AppColors.DESTRUCTIVE_ACTION : AppColors.TEXT_PRIMARY)
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
      action();
      this.closeMediaMenu();
    })
  }

  @Builder
  private mediaMenuContent() {
    AppSheetSurface() {
      Column({ space: 2 }) {
        if (this.menuFolder !== null) {
          AppSheetHeader({ title: this.menuFolder.displayName })
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })

          Divider()
            .color(AppColors.DIVIDER)
            .margin({ left: 14, right: 14 })

          this.mediaMenuAction(AppIconName.FOLDER_OPEN, '打开', () => {
            if (this.menuFolder !== null) {
              this.onFolderChange(this.menuFolder.uri);
            }
          })
          if (this.menuFolder.isVirtual()) {
            this.mediaMenuAction(AppIconName.EDIT, '重命名', () => {
              if (this.menuFolder !== null) {
                this.onRenameVirtualFolder(this.menuFolder);
              }
            })
            this.mediaMenuAction(AppIconName.DELETE, '删除文件夹', () => {
              if (this.menuFolder !== null) {
                this.confirmRemoveVirtualFolder(this.menuFolder);
              }
            }, true)
          } else if (!this.menuFolder.isMediaLibraryRoot() &&
            this.hiddenRecord(HiddenLocalItemType.FOLDER, this.menuFolder.uri) !== null) {
            this.mediaMenuAction(AppIconName.VISIBILITY, '恢复显示', () => {
              if (this.menuFolder !== null) {
                const hidden: HiddenLocalItem | null =
                  this.hiddenRecord(HiddenLocalItemType.FOLDER, this.menuFolder.uri);
                if (hidden !== null) {
                  this.onRestoreHidden(hidden);
                }
              }
            })
          } else if (!this.menuFolder.isMediaLibraryRoot()) {
            this.mediaMenuAction(AppIconName.VISIBILITY_OFF, '隐藏此文件夹', () => {
              if (this.menuFolder !== null) {
                this.onHideFolder(this.menuFolder);
              }
            })
          }
        } else if (this.menuItem !== null) {
          AppSheetHeader({ title: this.menuItem.displayName })
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })

          Divider()
            .color(AppColors.DIVIDER)
            .margin({ left: 14, right: 14 })

          if (this.menuItem.isVideo() && this.menuItem.isAvailable()) {
            this.mediaMenuAction(AppIconName.PLAY_ARROW, '打开播放', () => {
              this.onPlay(this.menuItem?.toMediaSource() ?? MediaSource.empty());
            })
          }
          if (this.hiddenRecord(HiddenLocalItemType.FILE, this.menuItem.uri) !== null) {
            this.mediaMenuAction(AppIconName.VISIBILITY, '恢复显示', () => {
              if (this.menuItem !== null) {
                const hidden: HiddenLocalItem | null =
                  this.hiddenRecord(HiddenLocalItemType.FILE, this.menuItem.uri);
                if (hidden !== null) {
                  this.onRestoreHidden(hidden);
                }
              }
            })
          }
          if (this.menuItem.isAvailable()) {
            this.mediaMenuAction(AppIconName.FAVORITE, '添加至收藏', () => {
              if (this.menuItem !== null) {
                this.onAddFavorite(this.menuItem.toMediaSource());
              }
            })
            this.mediaMenuAction(AppIconName.PLAYLIST_ADD, '添加至播放列表', () => {
              if (this.menuItem !== null) {
                this.onAddToPlaylist(this.menuItem.toMediaSource());
              }
            })
          }
          if (this.menuItem.isManuallyAdded() && !this.menuItem.isAvailable()) {
            this.mediaMenuAction(AppIconName.LOCK, '重新选择并授权', () => {
              if (this.menuItem !== null) {
                this.onReauthorizeManual(this.menuItem.uri);
              }
            })
          }
          if (this.menuItem.isManuallyAdded()) {
            this.mediaMenuAction(AppIconName.DELETE, '从列表移除', () => {
              if (this.menuItem !== null) {
                this.confirmRemoveManual(this.menuItem);
              }
            }, true)
          } else if (this.hiddenRecord(HiddenLocalItemType.FILE, this.menuItem.uri) === null) {
            this.mediaMenuAction(AppIconName.VISIBILITY_OFF, '隐藏此文件', () => {
              if (this.menuItem !== null) {
                this.onHideMedia(this.menuItem);
              }
            })
          }
          if (this.menuItem.isManuallyAdded() && !this.menuItem.isAvailable()) {
            this.mediaMenuAction(AppIconName.DELETE, '清理全部失效记录', () => {
              this.confirmCleanUnavailable();
            }, true)
          }
        }
      }
      .width('100%')
      .padding({ top: 4, bottom: 8 })
    }
  }

  private visibleFolders(): LocalMediaFolder[] {
    return LocalMediaOrdering.folders(this.folders, this.showFolders, this.currentDirectoryUri,
      this.searchText, this.sortField, this.sortAscending);
  }

  private visibleItems(): LocalMediaAsset[] {
    return LocalMediaOrdering.items(this.items, this.playbackProgress, this.searchText,
      this.sortField, this.sortAscending, this.typeFilter, this.sourceFilter,
      this.availabilityFilter);
  }

  private visibleEntries(): LocalBrowserEntry[] {
    const entries: LocalBrowserEntry[] = [];
    const folders: LocalMediaFolder[] = this.visibleFolders();
    const items: LocalMediaAsset[] = this.visibleItems();
    for (const directory of folders) {
      entries.push(LocalBrowserEntry.fromDirectory(directory));
    }
    for (const media of items) {
      entries.push(LocalBrowserEntry.fromMedia(media));
    }
    return entries;
  }

  @Builder
  private folderRowContent(folder: LocalMediaFolder) {
    Row({ space: 10 }) {
      FolderPreview({ virtualFolder: folder.isVirtual(), accentColor: this.accentColor })
      Column({ space: 5 }) {
        Row({ space: 5 }) {
          if (this.isFolderHidden(folder)) {
            AppIcon({ name: AppIconName.VISIBILITY_OFF, iconSize: 16, color: AppColors.ICON_SECONDARY })
          }
          Text(folder.displayName)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        if (this.showItemCount) {
          Row({ space: 5 }) {
            MetadataChip({ label: this.folderDetailLabel(folder) })
            if (this.showSize && (folder.videoCount === 0 || folder.totalSizeBytes > 0)) {
              MetadataChip({ label: folder.sizeLabel() })
            }
          }
        } else if (this.showSize && (folder.videoCount === 0 || folder.totalSizeBytes > 0)) {
          Row({ space: 5 }) {
            MetadataChip({ label: folder.sizeLabel() })
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  private folderListItem(folder: LocalMediaFolder) {
    AppActionListItem({
      itemHeight: MediaLayout.LIST_MEDIA_ITEM_HEIGHT,
      contentOpacity: this.isFolderHidden(folder) ? 0.72 : 1,
      selectionEnabled: !folder.isMediaLibraryRoot(),
      selectionMode: this.selectionMode && !folder.isMediaLibraryRoot(),
      selected: this.isHighlighted(this.folderSelectionKey(folder)),
      showTrailingAction: false,
      accentColor: this.accentColor,
      accessibilityLabel: this.selectionMode && !folder.isMediaLibraryRoot() ?
        `${this.isSelected(this.folderSelectionKey(folder)) ? '已选择' : '未选择'} ${folder.displayName}` :
        `打开 ${folder.displayName}${this.isFolderHidden(folder) ? '，已隐藏' : ''}`,
      menuAccessibilityLabel: this.isFolderHidden(folder) ? '已隐藏文件夹菜单' : '文件夹菜单',
      onOpen: () => {
        this.onFolderChange(folder.uri);
      },
      onOpenMenu: () => {
        this.openFolderMenu(folder);
      },
      onToggleSelection: () => {
        this.onToggleSelection(this.folderSelectionKey(folder));
      },
      onLongPress: () => {
        this.handleFolderLongPress(folder);
      }
    }) {
      this.folderRowContent(folder)
    }
  }

  @Builder
  private folderGridItem(folder: LocalMediaFolder) {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.Center }) {
        FolderPreview({ gridView: true, virtualFolder: folder.isVirtual(), accentColor: this.accentColor })
        if (this.selectionMode && !folder.isMediaLibraryRoot()) {
          Button() {
            AppIcon({
              name: this.isSelected(this.folderSelectionKey(folder)) ?
                AppIconName.CHECK_CIRCLE : AppIconName.RADIO_UNCHECKED,
              iconSize: 18,
              color: this.isSelected(this.folderSelectionKey(folder)) ?
                AppColors.accent(this.accentColor) : AppColors.ICON_SECONDARY
            })
          }
          .type(ButtonType.Normal)
          .width(28)
          .height(28)
          .padding(0)
          .margin({ left: 4, top: 4 })
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(AppRadius.FULL)
          .align(Alignment.TopStart)
          .accessibilityText(this.isSelected(this.folderSelectionKey(folder)) ? '取消选择' : '选择')
          .onClick(() => {
            this.onToggleSelection(this.folderSelectionKey(folder));
          })
        }
      }
      .width('100%')
      Row({ space: 4 }) {
        if (this.isFolderHidden(folder)) {
          AppIcon({ name: AppIconName.VISIBILITY_OFF, iconSize: 16, color: AppColors.ICON_SECONDARY })
        }
        Text(folder.displayName)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('auto')
    .padding(4)
    .backgroundColor(this.isHighlighted(this.folderSelectionKey(folder)) ?
      AppColors.SELECTED_BACKGROUND : Color.Transparent)
    .borderRadius(AppRadius.CARD)
    .onClick(() => {
      if (this.suppressClickAfterLongPress(this.folderSelectionKey(folder))) {
        return;
      }
      if (this.selectionMode && !folder.isMediaLibraryRoot()) {
        this.onToggleSelection(this.folderSelectionKey(folder));
      } else {
        this.onFolderChange(folder.uri);
      }
    })
    .priorityGesture(
      LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
        .onAction(() => {
          this.handleFolderLongPress(folder);
        })
    )
    .opacity(this.isFolderHidden(folder) ? 0.72 : 1)
  }

  @Builder
  private mediaGridItem(item: LocalMediaAsset) {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        FileMediaPreview({
          uri: item.contentUri(), category: item.category,
          thumbnailEnabled: item.isAvailable() && this.showThumbnails && !item.isSubtitle(),
          gridView: true,
          progressRatio: this.progressRatio(item), accentColor: this.accentColor,
          load: this.loadThumbnail
        })
        if (this.selectionMode) {
          Button() {
            AppIcon({
              name: this.isSelected(this.mediaSelectionKey(item)) ?
                AppIconName.CHECK_CIRCLE : AppIconName.RADIO_UNCHECKED,
              iconSize: 18,
              color: this.isSelected(this.mediaSelectionKey(item)) ?
                AppColors.accent(this.accentColor) : AppColors.ICON_SECONDARY
            })
          }
          .type(ButtonType.Normal)
          .width(28)
          .height(28)
          .padding(0)
          .margin({ left: 4, top: 4 })
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(AppRadius.FULL)
          .accessibilityText(this.isSelected(this.mediaSelectionKey(item)) ? '取消选择' : '选择')
          .onClick(() => {
            this.onToggleSelection(this.mediaSelectionKey(item));
          })
        }
      }
        .width('100%')

      Row({ space: 4 }) {
        if (this.isMediaHidden(item)) {
          AppIcon({ name: AppIconName.VISIBILITY_OFF, iconSize: 16, color: AppColors.ICON_SECONDARY })
        }
        Text(this.displayNameLabel(item))
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('auto')
    .padding(4)
    .backgroundColor(this.isHighlighted(this.mediaSelectionKey(item)) ?
      AppColors.SELECTED_BACKGROUND : Color.Transparent)
    .borderRadius(AppRadius.CARD)
    .onClick(() => {
      if (this.suppressClickAfterLongPress(this.mediaSelectionKey(item))) {
        return;
      }
      if (this.selectionMode) {
        this.onToggleSelection(this.mediaSelectionKey(item));
      } else if (item.isVideo() && item.isAvailable()) {
        this.onPlay(item.toMediaSource());
      }
    })
    .priorityGesture(
      LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
        .onAction(() => {
          this.handleMediaLongPress(item);
        })
    )
    .opacity(!item.isAvailable() ? 0.58 : (this.isMediaHidden(item) ? 0.72 : 1))
  }

  build() {
    Grid(this.scroller) {
      Repeat<LocalBrowserEntry>(this.visibleEntries())
        .virtualScroll({ reusable: false })
        .each((repeatItem: RepeatItem<LocalBrowserEntry>) => {
          GridItem() {
            if (repeatItem.item.kind === LocalBrowserEntryKind.DIRECTORY &&
              repeatItem.item.directory !== null) {
              if (this.gridView) {
                this.folderGridItem(repeatItem.item.directory)
              } else {
                this.folderListItem(repeatItem.item.directory)
              }
            } else if (repeatItem.item.media !== null) {
              if (this.gridView) {
                this.mediaGridItem(repeatItem.item.media)
              } else {
                LocalMediaRow({
                  item: repeatItem.item.media,
                  progressRatio: this.progressRatio(repeatItem.item.media),
                  showSize: this.showSize,
                  showResolution: this.showResolution,
                  showFileExtension: this.showFileExtension,
                  showDuration: this.showDuration,
                  showModifiedDate: this.showModifiedDate,
                  showThumbnails: this.showThumbnails,
                  hidden: this.isMediaHidden(repeatItem.item.media),
                  selectionMode: this.selectionMode,
                  selected: this.isHighlighted(this.mediaSelectionKey(repeatItem.item.media)),
                  accentColor: this.accentColor,
                  loadThumbnail: this.loadThumbnail,
                  onPlay: this.onPlay,
                  onOpenMenu: () => {
                    this.openMediaMenu(repeatItem.item.media as LocalMediaAsset);
                  },
                  onToggleSelection: () => {
                    this.onToggleSelection(this.mediaSelectionKey(repeatItem.item.media as LocalMediaAsset));
                  },
                })
              }
            }
          }
          .accessibilityGroup(true)
          .accessibilityText(this.entryAccessibilityLabel(repeatItem.item))
        })
        .key((entry: LocalBrowserEntry) => `${this.currentDirectoryUri}|${entry.key}`)
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
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.None)
    .onScrollIndex((first: number, _last: number) => {
      this.onScrollIndexChange(first);
    })
    .bindSheet(this.menuVisible!!, this.mediaMenuContent(), {
      height: SheetSize.FIT_CONTENT,
      radius: { topLeft: AppRadius.SHEET, topRight: AppRadius.SHEET },
      effectEdge: 0,
      showClose: false
    })
  }
}
