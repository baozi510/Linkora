import { image } from '@kit.ImageKit';
import { MediaSource, MediaSourceKind } from 'linkora_core';
import { AppColors, AppRadius } from '../ui/AppTheme';
import { FileMediaPreview } from './FileMediaPreview';

@ComponentV2
export struct RecentMediaThumbnail {
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Param source: MediaSource = MediaSource.empty();
  @Param expanded: boolean = false;
  @Event loadLocal: (uri: string) => Promise<image.PixelMap | null> = async () => null;

  build() {
    if (this.source.kind === MediaSourceKind.LOCAL_DOCUMENT &&
      this.source.originLabel === '本机媒体库') {
      FileMediaPreview({
        uri: this.source.locator,
        previewWidth: this.expanded ? 128 : 120,
        previewHeight: this.expanded ? 72 : 67.5,
        thumbnailEnabled: true,
        accentColor: this.accentColor,
        load: this.loadLocal
      })
    } else {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph(this.source.kind === MediaSourceKind.NETWORK_LINK ?
          $r('sys.symbol.link') : $r('sys.symbol.play_fill'))
          .fontSize(25)
          .fontColor([AppColors.accent(this.accentColor)])
      }
      .width(this.expanded ? 128 : 120)
      .height(this.expanded ? 72 : 67.5)
      .backgroundColor(AppColors.SURFACE_RAISED)
      .borderRadius(AppRadius.SMALL)
    }
  }
}
