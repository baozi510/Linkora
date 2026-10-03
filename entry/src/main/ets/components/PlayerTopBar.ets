import { PlayerColors } from '../ui/AppTheme';

@ComponentV2
export struct PlayerTopBar {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Param showSubtitle: boolean = true;
  @Param overlayMode: boolean = false;
  @Event onBack: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Button('‹')
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .fontSize(28)
        .fontColor(PlayerColors.TEXT_PRIMARY)
        .backgroundColor(this.overlayMode ? '#80191D24' : '#191D24')
        .onClick(() => {
          this.onBack();
        })

      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(this.overlayMode ? 14 : 16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PlayerColors.TEXT_PRIMARY)
        if (this.showSubtitle) {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor(this.overlayMode ? '#FFFFFF' : '#818895')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
    }
    .padding({ left: 18, right: 18, top: this.overlayMode ? 14 : 20, bottom: this.overlayMode ? 14 : 16 })
    .width('100%')
  }
}
