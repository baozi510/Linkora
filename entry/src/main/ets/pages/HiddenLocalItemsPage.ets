import { AppIcon, AppIconName } from '../components/AppIcon';
import { AppToolbar } from '../components/AppToolbar';
import { HiddenLocalItem, HiddenLocalItemType } from '../services/HiddenLocalItemStore';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct HiddenLocalItemsPage {
  @Param hiddenItems: HiddenLocalItem[] = [];
  @Event onBack: () => void = () => {};
  @Event onRestore: (item: HiddenLocalItem) => void = () => {};
  @Event onRestoreAll: () => void = () => {};
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';

  @Builder
  private toolbarActions() {
    if (this.hiddenItems.length > 0) {
      Button('全部恢复')
        .type(ButtonType.Normal)
        .height(34)
        .padding({ left: 10, right: 10 })
        .fontSize(AppTypography.CAPTION)
        .fontColor(AppColors.accent(this.accentColor))
        .backgroundColor(Color.Transparent)
        .borderRadius(AppRadius.CONTROL)
        .accessibilityText(`恢复全部 ${this.hiddenItems.length} 个隐藏项目`)
        .onClick(() => {
          this.onRestoreAll();
        })
    }
  }

  @Builder
  private restoreButton(item: HiddenLocalItem) {
    Button() {
      Row({ space: 5 }) {
        AppIcon({
          name: AppIconName.VISIBILITY,
          iconSize: 18,
          color: AppColors.accent(this.accentColor)
        })
        Text('恢复')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.accent(this.accentColor))
      }
    }
    .type(ButtonType.Normal)
    .height(36)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.Transparent)
    .borderRadius(AppRadius.CONTROL)
    .accessibilityText(`恢复显示 ${item.displayName}`)
    .onClick(() => {
      this.onRestore(item);
    })
  }

  @Builder
  private hiddenItemRow(item: HiddenLocalItem, showDivider: boolean) {
    Column() {
      Row({ space: 12 }) {
        AppIcon({
          name: item.itemType === HiddenLocalItemType.FOLDER ? AppIconName.FOLDER : AppIconName.MOVIE,
          iconSize: 24,
          color: AppColors.ICON_SECONDARY
        })
        Column({ space: 4 }) {
          Text(item.displayName)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(item.typeLabel())
            .fontSize(AppTypography.META)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        this.restoreButton(item)
      }
      .width('100%')
      .height(64)
      .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: 8 })

      if (showDivider) {
        Divider()
          .color(AppColors.DIVIDER)
          .margin({ left: 52, right: AppSpacing.PAGE_HORIZONTAL })
      }
    }
    .width('100%')
  }

  @Builder
  private emptyState() {
    Column({ space: 10 }) {
      AppIcon({
        name: AppIconName.VISIBILITY_OFF,
        iconSize: 42,
        color: AppColors.ICON_TERTIARY
      })
      Text('没有隐藏项目')
        .fontSize(AppTypography.SECTION_TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text('隐藏的文件和文件夹会显示在这里')
        .fontSize(AppTypography.CAPTION)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .height(0)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      AppToolbar({
        title: '已隐藏项目',
        path: this.hiddenItems.length > 0 ? `共 ${this.hiddenItems.length} 项` : '',
        showBack: true,
        onBack: () => {
          this.onBack();
        }
      }) {
        this.toolbarActions()
      }

      if (this.hiddenItems.length === 0) {
        this.emptyState()
      } else {
        List() {
          ForEach(this.hiddenItems, (item: HiddenLocalItem, index: number) => {
            ListItem() {
              this.hiddenItemRow(item, index < this.hiddenItems.length - 1)
            }
          }, (item: HiddenLocalItem) => `${item.itemType}:${item.locator}`)
        }
        .width('100%')
        .height(0)
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.None)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
