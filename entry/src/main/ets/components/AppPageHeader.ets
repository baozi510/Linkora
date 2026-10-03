import { AppColors, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct AppPageHeader {
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Param symbol: Resource = $r('sys.symbol.folder');
  @Param actionSymbol: Resource = $r('sys.symbol.magnifyingglass');
  @Param actionEnabled: boolean = false;
  @Event onAction: () => void = () => {};

  build() {
    Row() {
      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(AppTypography.PAGE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(this.subtitle)
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)

      if (this.actionEnabled) {
        Button() {
          SymbolGlyph(this.actionSymbol)
            .fontSize(22)
            .fontColor([AppColors.TEXT_PRIMARY])
        }
        .type(ButtonType.Circle)
        .width(42)
        .height(42)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.onAction();
        })
      } else {
        SymbolGlyph(this.symbol)
          .fontSize(25)
          .fontColor([AppColors.accent(this.accentColor)])
      }
    }
    .width('100%')
  }
}
