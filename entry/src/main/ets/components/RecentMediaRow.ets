import { MediaSource, RecentMediaItem } from 'linkora_core';
import { AppColors, AppSpacing, AppTypography } from '../ui/AppTheme';
import { image } from '@kit.ImageKit';
import { RecentMediaThumbnail } from './RecentMediaThumbnail';

@ComponentV2
export struct RecentMediaRow {
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Param item: RecentMediaItem = new RecentMediaItem(MediaSource.empty(), 0);
  @Param expanded: boolean = false;
  @Event onPlay: (source: MediaSource) => void = () => {};
  @Event loadLocalThumbnail: (uri: string) => Promise<image.PixelMap | null> = async () => null;

  build() {
    Row({ space: this.expanded ? 13 : 12 }) {
      RecentMediaThumbnail({
        source: this.item.source,
        expanded: this.expanded,
        loadLocal: this.loadLocalThumbnail
      })
      Column({ space: this.expanded ? 6 : 5 }) {
        Text(this.item.source.displayName)
          .fontSize(this.expanded ? 15 : AppTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`${this.item.source.originLabel} · ${this.item.source.format}`)
          .fontSize(AppTypography.META)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      SymbolGlyph(this.expanded ? $r('sys.symbol.play_fill') : $r('sys.symbol.more'))
        .fontSize(this.expanded ? 20 : 19)
        .fontColor([this.expanded ? AppColors.accent(this.accentColor) : AppColors.TEXT_SECONDARY])
    }
    .width('100%')
    .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
      top: this.expanded ? 10 : 8, bottom: this.expanded ? 10 : 8 })
    .onClick(() => {
      this.onPlay(this.item.source);
    })
  }
}
