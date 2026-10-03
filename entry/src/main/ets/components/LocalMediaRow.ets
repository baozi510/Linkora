import { image } from '@kit.ImageKit';
import { LocalMediaAsset, MediaSource } from 'linkora_core';
import { AppColors, AppTypography, MediaLayout } from '../ui/AppTheme';
import { AppActionListItem } from './AppActionListItem';
import { FileMediaPreview } from './FileMediaPreview';
import { MetadataChip } from './MetadataChip';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct LocalMediaRow {
  @Param item: LocalMediaAsset = new LocalMediaAsset('', '', 0, 0, 0, 0, 0);
  @Param progressRatio: number = 0;
  @Param showSize: boolean = true;
  @Param showResolution: boolean = true;
  @Param showFileExtension: boolean = true;
  @Param showDuration: boolean = true;
  @Param showModifiedDate: boolean = false;
  @Param showThumbnails: boolean = true;
  @Param hidden: boolean = false;
  @Param selectionMode: boolean = false;
  @Param selected: boolean = false;
  @Param accentColor: string = 'system';
  @Event onPlay: (source: MediaSource) => void = () => {};
  @Event onOpenMenu: () => void = () => {};
  @Event onToggleSelection: () => void = () => {};
  @Event loadThumbnail: (uri: string) => Promise<image.PixelMap | null> = async () => null;

  private displayNameLabel(): string {
    if (this.showFileExtension) {
      return this.item.displayName;
    }
    const dot: number = this.item.displayName.lastIndexOf('.');
    if (dot <= 0 || dot === this.item.displayName.length - 1) {
      return this.item.displayName;
    }
    return this.item.displayName.substring(0, dot);
  }

  private modifiedDateLabel(): string {
    if (this.item.modifiedAt <= 0) {
      return '日期未知';
    }
    const date: Date = new Date(this.item.modifiedAt);
    const month: number = date.getMonth() + 1;
    const day: number = date.getDate();
    const monthText: string = month < 10 ? `0${month}` : `${month}`;
    const dayText: string = day < 10 ? `0${day}` : `${day}`;
    return `${date.getFullYear()}/${monthText}/${dayText}`;
  }

  @Builder
  private rowContent() {
    Row({ space: 10 }) {
      FileMediaPreview({
        uri: this.item.contentUri(), category: this.item.category,
        thumbnailEnabled: this.item.isAvailable() && this.showThumbnails && !this.item.isSubtitle(),
        durationLabel: this.item.isVideo() && this.showDuration ? this.item.durationLabel() : '',
        progressRatio: this.progressRatio, accentColor: this.accentColor,
        load: this.loadThumbnail
      })

      Column({ space: 5 }) {
        Row({ space: 5 }) {
          if (this.hidden) {
            AppIcon({ name: AppIconName.VISIBILITY_OFF, iconSize: 16, color: AppColors.ICON_SECONDARY })
          }
          Text(this.displayNameLabel())
            .fontSize(AppTypography.BODY)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        Row({ space: 5 }) {
          if (!this.item.isAvailable()) {
            MetadataChip({ label: '文件不可用' })
          } else if (this.showSize) {
            MetadataChip({ label: this.item.sizeLabel() })
          }
          if (this.showResolution && this.item.isVideo() && this.item.isAvailable()) {
            MetadataChip({ label: this.item.resolutionLabel() })
          } else if (this.item.isSubtitle()) {
            MetadataChip({ label: '字幕' })
          }
          if (this.showModifiedDate) {
            MetadataChip({ label: this.modifiedDateLabel() })
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
  }

  build() {
    AppActionListItem({
      itemHeight: MediaLayout.LIST_MEDIA_ITEM_HEIGHT,
      contentOpacity: !this.item.isAvailable() ? 0.58 : (this.hidden ? 0.72 : 1),
      selectionEnabled: true,
      selectionMode: this.selectionMode,
      selected: this.selected,
      showTrailingAction: false,
      accentColor: this.accentColor,
      accessibilityLabel: this.selectionMode ?
        `${this.selected ? '已选择' : '未选择'} ${this.item.displayName}` :
        `打开 ${this.item.displayName}${this.hidden ? '，已隐藏' : ''}`,
      menuAccessibilityLabel: this.hidden ? '已隐藏文件菜单' : '文件菜单',
      onOpen: () => {
        if (this.item.isVideo() && this.item.isAvailable()) {
          this.onPlay(this.item.toMediaSource());
        }
      },
      onOpenMenu: () => {
        this.onOpenMenu();
      },
      onToggleSelection: () => {
        this.onToggleSelection();
      },
      onLongPress: () => {
        if (this.selectionMode) {
          this.onToggleSelection();
        } else {
          this.onOpenMenu();
        }
      }
    }) {
      this.rowContent()
    }
  }
}
