import { AppColors, AppRadius, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct MediaSourceCard {
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Param title: ResourceStr = '';
  @Param description: ResourceStr = '';
  @Param symbol: Resource = $r('sys.symbol.folder');
  @Event onOpen: () => void = () => {};

  build() {
    Column({ space: 14 }) {
      Row() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        SymbolGlyph($r('sys.symbol.chevron_forward'))
          .fontSize(16)
          .fontColor([AppColors.TEXT_SECONDARY])
      }
      .width('100%')

      Row({ space: 10 }) {
        SymbolGlyph(this.symbol)
          .fontSize(27)
          .fontColor([AppColors.accent(this.accentColor)])
        Text(this.description)
          .fontSize(AppTypography.CAPTION)
          .lineHeight(17)
          .fontColor(AppColors.TEXT_SECONDARY)
          .layoutWeight(1)
      }
      .width('100%')
    }
    .padding(15)
    .height(100)
    .layoutWeight(1)
    .backgroundColor(AppColors.SURFACE_RAISED)
    .borderRadius(AppRadius.CARD)
    .onClick(() => {
      this.onOpen();
    })
  }
}
