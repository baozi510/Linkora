import { AppSection } from '../models/AppRoute';
import { AppColors, AppLayout, AppRadius } from '../ui/AppTheme';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct AppSideBar {
  @Param activeSection: AppSection = AppSection.LIBRARY;
  @Param networkStorageEnabled: boolean = false;
  @Event onChange: (section: AppSection) => void = () => {};
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';

  @Builder
  private navigationItem(section: AppSection, label: ResourceStr, icon: AppIconName) {
    Button() {
      Row({ space: 12 }) {
        AppIcon({
          name: icon,
          iconSize: 21,
          color: this.activeSection === section ? AppColors.accent(this.accentColor) : AppColors.ICON_SECONDARY
        })
        Text(label)
          .fontSize(14)
          .fontWeight(this.activeSection === section ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.activeSection === section ? AppColors.TEXT_PRIMARY : AppColors.TEXT_SECONDARY)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 14, right: 14 })
    }
    .type(ButtonType.Normal)
    .width('100%')
    .height(46)
    .backgroundColor(this.activeSection === section ? AppColors.SURFACE_RAISED : Color.Transparent)
    .borderRadius(AppRadius.SMALL)
    .stateEffect(true)
    .onClick(() => {
      this.onChange(section);
    })
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Stack() {
          Text('L')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.accentForeground(this.accentColor))
        }
        .width(34)
        .height(34)
        .backgroundColor(AppColors.accent(this.accentColor))
        .borderRadius(AppRadius.CONTROL)

        Text('Linkora')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      .height(64)
      .padding({ left: 10, right: 10 })

      Column({ space: 6 }) {
        this.navigationItem(AppSection.LIBRARY, $r('app.string.nav_local'), AppIconName.FOLDER)
        this.navigationItem(AppSection.STREAM, $r('app.string.nav_stream'), AppIconName.LINK)
        this.navigationItem(AppSection.NETWORK, $r('app.string.nav_network'), AppIconName.LANGUAGE)
        this.navigationItem(AppSection.SETTINGS, $r('app.string.nav_settings'), AppIconName.SETTINGS)
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 12 })

      Blank()

      Text('本地优先 · 不上传媒体资料')
        .fontSize(10)
        .fontColor(AppColors.TEXT_MUTED)
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 18 })
    }
    .width(AppLayout.SIDE_BAR_WIDTH)
    .height('100%')
    .backgroundColor(AppColors.NAVIGATION_BACKGROUND)
  }
}
