import { AppColors, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct AppSectionHeader {
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Param title: ResourceStr = '';
  @Param accessory: ResourceStr = '';

  build() {
    Row() {
      Text(this.title)
        .fontSize(AppTypography.SECTION_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      if (this.accessory.toString().length > 0) {
        Text(this.accessory)
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.accent(this.accentColor))
      }
    }
    .width('100%')
  }
}
