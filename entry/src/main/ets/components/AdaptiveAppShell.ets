import { AppSection } from '../models/AppRoute';
import { AppColors, AppLayout } from '../ui/AppTheme';
import { AppBottomBar } from './AppBottomBar';
import { AppSideBar } from './AppSideBar';

@ComponentV2
export struct AdaptiveAppShell {
  @Param activeSection: AppSection = AppSection.LIBRARY;
  @Param navigationHidden: boolean = false;
  @Param networkStorageEnabled: boolean = false;
  @Event onSectionChange: (section: AppSection) => void = () => {};
  @BuilderParam content: () => void = this.emptyContent;

  @Local private windowWidth: number = 0;

  @Builder
  private emptyContent() {
  }

  private expanded(): boolean {
    return this.windowWidth >= AppLayout.EXPANDED_BREAKPOINT;
  }

  build() {
    Row() {
      if (this.expanded() && !this.navigationHidden) {
        AppSideBar({
          activeSection: this.activeSection,
          networkStorageEnabled: this.networkStorageEnabled,
          onChange: (section: AppSection) => {
            this.onSectionChange(section);
          }
        })
      }

      Column() {
        Column() {
          Column() {
            this.content()
          }
          .width('100%')
          .height('100%')
          .constraintSize({ maxWidth: AppLayout.CONTENT_MAX_WIDTH })
        }
        .width('100%')
        .height(0)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        if (!this.expanded() && !this.navigationHidden) {
          AppBottomBar({
            activeSection: this.activeSection,
            networkStorageEnabled: this.networkStorageEnabled,
            onChange: (section: AppSection) => {
              this.onSectionChange(section);
            }
          })
        }
      }
      .height('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const width: number = Number(newValue.width);
      if (width > 0 && width !== this.windowWidth) {
        this.windowWidth = width;
      }
    })
  }
}
