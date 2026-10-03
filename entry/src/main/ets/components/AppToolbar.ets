import { AppColors, AppIconSize, AppLayout, AppSpacing, AppTypography } from '../ui/AppTheme';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct AppToolbar {
  @Param title: ResourceStr = '';
  @Param path: string = '';
  @Param showBack: boolean = false;
  @Event onBack: () => void = () => {};
  @BuilderParam actions: () => void = this.emptyActions;

  @Builder
  private emptyActions() {
  }

  build() {
    Row({ space: 6 }) {
      if (this.showBack) {
        Button() {
          AppIcon({ name: AppIconName.ARROW_BACK, iconSize: AppIconSize.TOP_BAR,
            color: AppColors.ICON_PRIMARY })
        }
        .type(ButtonType.Normal)
        .width(AppLayout.TOP_BAR_LEADING_SIZE)
        .height(AppLayout.TOP_BAR_LEADING_SIZE)
        .padding(0)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.onBack();
        })
      }

      Column({ space: 1 }) {
        Text(this.title)
          .width('100%')
          .fontSize(AppTypography.PAGE_TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.path.length > 0) {
          Text(this.path)
            .fontSize(AppTypography.META)
            .fontColor(AppColors.TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width(0)
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 2 }) {
        this.actions()
      }
    }
    .width('100%')
    .height(AppLayout.TOP_BAR_HEIGHT)
    .padding({ left: this.showBack ? 0 : AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL })
    .backgroundColor(AppColors.NAVIGATION_BACKGROUND)
  }
}
