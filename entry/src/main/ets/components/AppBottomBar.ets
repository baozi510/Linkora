import { AppSection } from '../models/AppRoute';
import { AppColors, AppIconSize, AppLayout } from '../ui/AppTheme';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct AppBottomBar {
  @Param activeSection: AppSection = AppSection.LIBRARY;
  @Param networkStorageEnabled: boolean = false;
  @Event onChange: (section: AppSection) => void = () => {};
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';

  @Builder
  private tab(section: AppSection, label: ResourceStr, icon: AppIconName) {
    Column({ space: 2 }) {
      AppIcon({
        name: icon,
        iconSize: AppIconSize.BOTTOM_BAR,
        color: this.activeSection === section ? AppColors.accent(this.accentColor) : AppColors.ICON_SECONDARY
      })
      Text(label)
        .fontSize(11)
        .fontWeight(this.activeSection === section ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.activeSection === section ? AppColors.accent(this.accentColor) : AppColors.TEXT_SECONDARY)
    }
    .height('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onChange(section);
    })
  }

  build() {
    Row() {
      this.tab(AppSection.LIBRARY, $r('app.string.nav_local'), AppIconName.FOLDER)
      this.tab(AppSection.STREAM, $r('app.string.nav_stream'), AppIconName.LINK)
      this.tab(AppSection.NETWORK, $r('app.string.nav_network'), AppIconName.LANGUAGE)
      this.tab(AppSection.SETTINGS, $r('app.string.nav_settings'), AppIconName.SETTINGS)
    }
    .width('100%')
    .height(AppLayout.BOTTOM_BAR_HEIGHT)
    .padding({ left: 8, right: 8 })
    .backgroundColor(AppColors.NAVIGATION_BACKGROUND)
  }
}
