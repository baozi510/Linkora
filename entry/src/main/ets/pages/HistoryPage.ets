import { AppPageHeader } from '../components/AppPageHeader';
import { RecentMediaRow } from '../components/RecentMediaRow';
import { MediaSource, RecentMediaItem } from 'linkora_core';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../ui/AppTheme';
import { image } from '@kit.ImageKit';

@ComponentV2
export struct HistoryPage {
  @Param recentItems: RecentMediaItem[] = [];
  @Event onPlay: (source: MediaSource) => void = () => {};
  @Event loadLocalThumbnail: (uri: string) => Promise<image.PixelMap | null> = async () => null;

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column() {
          AppPageHeader({
            title: $r('app.string.page_history_title'),
            subtitle: $r('app.string.page_history_subtitle'),
            symbol: $r('sys.symbol.clock')
          })
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL })

        if (this.recentItems.length === 0) {
          Column({ space: 12 }) {
            Image($r('app.media.recent_city'))
              .width('100%')
              .height(150)
              .objectFit(ImageFit.Cover)
              .borderRadius(AppRadius.CARD)
              .opacity(0.38)
            Text('暂无播放记录')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
            Text('从媒体库或网络资源打开视频后，会自动记录在这里。')
              .fontSize(AppTypography.CAPTION)
              .lineHeight(18)
              .textAlign(TextAlign.Center)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 28 })
          .width('100%')
        } else {
          Column() {
            ForEach(this.recentItems, (item: RecentMediaItem) => {
              RecentMediaRow({
                item: item,
                expanded: true,
                loadLocalThumbnail: this.loadLocalThumbnail,
                onPlay: (source: MediaSource) => {
                  this.onPlay(source);
                }
              })
            }, (item: RecentMediaItem) => item.source.locator)
          }
          .width('100%')
        }
      }
      .padding({ top: AppSpacing.PAGE_TOP, bottom: AppSpacing.PAGE_BOTTOM })
      .width('100%')
      .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.BACKGROUND)
  }
}
