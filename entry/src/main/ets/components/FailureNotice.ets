import { AppFailure, FailureCatalog } from 'linkora_core';
import { AppColors, AppRadius, AppTypography } from '../ui/AppTheme';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct FailureNotice {
  @Param failure: AppFailure = FailureCatalog.unknown();
  @Event onAction: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        AppIcon({ name: AppIconName.WARNING, iconSize: 20, color: AppColors.ERROR_TEXT })
        Column({ space: 4 }) {
          Text(this.failure.title)
            .fontSize(AppTypography.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.ERROR_TEXT)
            .width('100%')
          Text(this.failure.message)
            .fontSize(AppTypography.CAPTION)
            .lineHeight(18)
            .fontColor(AppColors.ERROR_MUTED)
            .width('100%')
        }
        .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Text(this.failure.diagnosticCode)
          .fontSize(10)
          .fontColor(AppColors.ERROR_MUTED)
        Blank()
        if (this.failure.hasAction()) {
          Button(this.failure.actionLabel)
            .type(ButtonType.Normal)
            .height(34)
            .fontSize(12)
            .fontColor(AppColors.ERROR_TEXT)
            .backgroundColor(AppColors.ERROR_BORDER)
            .borderRadius(AppRadius.SMALL)
            .onClick(() => {
              this.onAction();
            })
        }
      }
      .width('100%')
    }
    .padding(14)
    .width('100%')
    .backgroundColor(AppColors.ERROR_SURFACE)
    .borderRadius(AppRadius.CARD)
  }
}
