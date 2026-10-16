import { PlayerColors } from '../ui/AppTheme';

@ComponentV2
export struct PlayerTopBar {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Event onBack: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Button('‹')
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .fontSize(28)
        .fontColor(PlayerColors.TEXT_PRIMARY)
        .backgroundColor('#191D24')
        .onClick(() => {
          this.onBack();
        })

      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PlayerColors.TEXT_PRIMARY)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor('#818895')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
    }
    .padding({ left: 18, right: 18, top: 20, bottom: 16 })
    .width('100%')
  }
}
