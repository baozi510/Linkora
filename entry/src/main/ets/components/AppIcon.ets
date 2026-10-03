import { AppColors } from '../ui/AppTheme';
import {
  APP_ICON_FONT_FILLED,
  APP_ICON_FONT_OUTLINED,
  AppIconName,
  appIconGlyph,
  appIconUsesFilledFont
} from './generated/MaterialIconRegistry';

export { AppIconName } from './generated/MaterialIconRegistry';

@ComponentV2
export struct AppIcon {
  @Param name: AppIconName = AppIconName.SEARCH;
  @Param iconSize: number = 24;
  @Param color: ResourceColor = AppColors.ICON_PRIMARY;

  build() {
    Text(appIconGlyph(this.name))
      .width(this.iconSize)
      .height(this.iconSize)
      .fontFamily(appIconUsesFilledFont(this.name) ? APP_ICON_FONT_FILLED : APP_ICON_FONT_OUTLINED)
      .fontSize(`${this.iconSize}vp`)
      .lineHeight(`${this.iconSize}vp`)
      .fontColor(this.color)
      .textAlign(TextAlign.Center)
      .maxLines(1)
  }
}
