@ComponentV2
export struct AppSheetSurface {
  @Param fillHeight: boolean = false;
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  private emptyContent() {
  }

  build() {
    if (this.fillHeight) {
      Column() {
        this.content()
      }
      .width('100%')
      .height('100%')
    } else {
      Column() {
        this.content()
      }
      .width('100%')
    }
  }
}
