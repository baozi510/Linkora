import { AppColors, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct AppSheetHeader {
  @Param title: string = '';

  build() {
    Row() {
      Text(this.title)
        .fontSize(AppTypography.SHEET_TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
  }
}
