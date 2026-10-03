import { AppColors, AppRadius, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct MetadataChip {
  @Param label: string = '';
  @Param highlighted: boolean = false;
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';

  build() {
    Text(this.label)
      .fontSize(AppTypography.META)
      .fontColor(this.highlighted ? AppColors.accent(this.accentColor) : AppColors.TEXT_SECONDARY)
      .height(18)
      .padding({ left: 6, right: 6 })
      .backgroundColor(this.highlighted ? AppColors.SURFACE_RAISED : AppColors.CHIP_BACKGROUND)
      .borderRadius(AppRadius.SMALL)
      .maxLines(1)
  }
}
