import { AppColors, AppIconSize, AppLayout, AppRadius } from '../ui/AppTheme';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct AppIconButton {
  @Param icon: AppIconName = AppIconName.SEARCH;
  @Param selected: boolean = false;
  @Param controlEnabled: boolean = true;
  @Param label: string = '';
  @Event onPressed: () => void = () => {};

  build() {
    Button() {
      AppIcon({
        name: this.icon,
        iconSize: AppIconSize.TOP_BAR,
        color: AppColors.ICON_PRIMARY
      })
    }
    .type(ButtonType.Normal)
    .width(AppLayout.TOP_BAR_ACTION_SIZE)
    .height(AppLayout.TOP_BAR_ACTION_SIZE)
    .padding(0)
    .backgroundColor(Color.Transparent)
    .borderRadius(AppRadius.NONE)
    .enabled(this.controlEnabled)
    .opacity(this.controlEnabled ? 1 : 0.4)
    .accessibilityText(this.label)
    .onClick(() => {
      this.onPressed();
    })
  }
}
