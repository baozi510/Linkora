import { AppFailure, RecoveryAction } from 'linkora_core';
import { PlayerColors, PlayerRadius } from '../ui/AppTheme';

@ComponentV2
export struct PlayerFailureOverlay {
  @Param failure: AppFailure | null = null;
  @Event onRetry: () => void = () => {};
  @Event onEditSource: () => void = () => {};
  @Event onOpenSettings: () => void = () => {};

  private performAction(): void {
    if (this.failure === null) {
      return;
    }
    if (this.failure.action === RecoveryAction.RETRY) {
      this.onRetry();
    } else if (this.failure.action === RecoveryAction.EDIT_SOURCE) {
      this.onEditSource();
    } else if (this.failure.action === RecoveryAction.OPEN_SETTINGS) {
      this.onOpenSettings();
    }
  }

  build() {
    Column({ space: 14 }) {
      Text(this.failure === null ? $r('app.string.player_unavailable') : this.failure!.title)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
      Text(this.failure === null ? $r('app.string.player_generic_error') : this.failure!.message)
        .fontSize(13)
        .fontColor('#AEB3BD')
        .textAlign(TextAlign.Center)
      if (this.failure !== null) {
        Text(this.failure!.diagnosticCode)
          .fontSize(10)
          .fontColor(PlayerColors.TEXT_DISABLED)
      }
      if (this.failure !== null && this.failure!.hasAction()) {
        Button(this.failure!.actionLabel)
          .type(ButtonType.Normal)
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(PlayerColors.PRIMARY)
          .borderRadius(PlayerRadius.ACTION)
          .onClick(() => {
            this.performAction();
          })
      }
    }
    .padding(20)
  }
}
