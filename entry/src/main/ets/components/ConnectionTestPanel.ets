import { AppIcon, AppIconName } from './AppIcon';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct ConnectionTestPanel {
  @Param title: string = '测试连接';
  @Param target: string = '';
  @Param testing: boolean = false;
  @Param succeeded: boolean = false;
  @Param message: string = '';
  @Param canRetry: boolean = true;
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Event onRetry: () => void = () => {};
  @Event onClose: () => void = () => {};

  build() {
    Column({ space: 16 }) {
      Text(this.title)
        .fontSize(AppTypography.SHEET_TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
      if (this.target.length > 0) {
        Text(this.target)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      if (this.testing) {
        Row({ space: 10 }) {
          LoadingProgress()
            .width(22)
            .height(22)
            .color(AppColors.accent(this.accentColor))
          Text(this.message)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 12, bottom: 12 })
      } else {
        Row({ space: 10 }) {
          AppIcon({
            name: this.succeeded ? AppIconName.CHECK_CIRCLE : AppIconName.WARNING,
            iconSize: 24,
            color: this.succeeded ? AppColors.SUCCESS : AppColors.WARNING_TEXT
          })
          Text(this.message)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }
      Row({ space: 10 }) {
        if (this.canRetry && !this.testing) {
          Button('重试')
            .type(ButtonType.Normal)
            .height(40)
            .layoutWeight(1)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.accent(this.accentColor))
            .backgroundColor(Color.Transparent)
            .borderRadius(AppRadius.CONTROL)
            .onClick(() => {
              this.onRetry();
            })
        }
        Button('关闭')
          .type(ButtonType.Normal)
          .height(40)
          .layoutWeight(1)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(Color.Transparent)
          .borderRadius(AppRadius.CONTROL)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
    }
    .width('86%')
    .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
      top: 20, bottom: 20 })
    .backgroundColor(AppColors.SURFACE_RAISED)
    .borderRadius(AppRadius.SHEET)
  }
}
