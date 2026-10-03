import { AppColors, AppSpacing } from '../ui/AppTheme';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct AppActionListItem {
  @Param itemHeight: number = 58;
  @Param contentOpacity: number = 1;
  @Param selectionEnabled: boolean = false;
  @Param selectionMode: boolean = false;
  @Param selected: boolean = false;
  @Param accentColor: string = 'system';
  @Param trailingIcon: AppIconName = AppIconName.MORE_VERT;
  @Param trailingIconSize: number = 20;
  @Param trailingLoading: boolean = false;
  @Param trailingOpensItem: boolean = false;
  @Param showTrailingAction: boolean = true;
  @Param accessibilityLabel: string = '打开列表项';
  @Param menuAccessibilityLabel: string = '打开菜单';
  @Event onOpen: () => void = () => {};
  @Event onOpenMenu: () => void = () => {};
  @Event onToggleSelection: () => void = () => {};
  @Event onLongPress: () => void = () => {};
  @BuilderParam content: () => void = this.emptyContent;

  @Local private pressed: boolean = false;
  private lastLongPressAt: number = 0;

  @Builder
  private emptyContent() {
  }

  private updatePressed(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.pressed = true;
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.pressed = false;
    }
  }

  build() {
    Row() {
      Button() {
        Row() {
          this.content()
        }
        .width('100%')
        .constraintSize({ minHeight: this.itemHeight })
        .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: 8, top: 5, bottom: 5 })
      }
      .type(ButtonType.Normal)
      .constraintSize({ minHeight: this.itemHeight })
      .layoutWeight(1)
      .padding(0)
      .stateEffect(false)
      .backgroundColor(Color.Transparent)
      .accessibilityText(this.accessibilityLabel)
      .onClick(() => {
        if (Date.now() - this.lastLongPressAt < 800) {
          return;
        }
        if (this.selectionMode) {
          this.onToggleSelection();
        } else {
          this.onOpen();
        }
      })
      .gesture(
        LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
          .onAction(() => {
            this.lastLongPressAt = Date.now();
            this.pressed = false;
            if (this.selectionEnabled) {
              this.onLongPress();
            } else {
              this.onOpenMenu();
            }
          })
      )

      if (this.selectionMode || this.showTrailingAction) {
        Button() {
          if (!this.selectionMode && this.trailingLoading) {
            LoadingProgress()
              .width(19)
              .height(19)
              .color(AppColors.accent(this.accentColor))
          } else {
            AppIcon({
              name: this.selectionMode ?
                (this.selected ? AppIconName.CHECK_CIRCLE : AppIconName.RADIO_UNCHECKED) : this.trailingIcon,
              iconSize: this.selectionMode ? 20 : this.trailingIconSize,
              color: this.selectionMode && this.selected ?
                AppColors.accent(this.accentColor) : AppColors.ICON_SECONDARY
            })
          }
        }
        .type(ButtonType.Normal)
        .width(44)
        .height(this.itemHeight)
        .padding(0)
        .stateEffect(false)
        .backgroundColor(Color.Transparent)
        .accessibilityText(this.selectionMode ?
          (this.selected ? '取消选择' : '选择') : this.menuAccessibilityLabel)
        .onClick(() => {
          if (this.selectionMode) {
            this.onToggleSelection();
          } else if (this.trailingOpensItem) {
            this.onOpen();
          } else {
            this.onOpenMenu();
          }
        })
      }
    }
    .width('100%')
    .constraintSize({ minHeight: this.itemHeight })
    .opacity(this.contentOpacity)
    .backgroundColor(this.selected ? AppColors.SELECTED_BACKGROUND :
      (this.pressed ? AppColors.PRESSED_BACKGROUND : Color.Transparent))
    .onTouch((event: TouchEvent) => {
      this.updatePressed(event);
    })
  }
}
