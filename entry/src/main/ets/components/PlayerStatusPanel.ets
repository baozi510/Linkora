import { PlaybackSnapshot, PlaybackStatus } from 'linkora_core';
import { PlayerColors, PlayerRadius } from '../ui/AppTheme';

@ComponentV2
export struct PlayerStatusPanel {
  @Param snapshot: PlaybackSnapshot = new PlaybackSnapshot(
    PlaybackStatus.IDLE, 0, 0, 0, 0, 0, null, false
  );

  private statusText(): ResourceStr {
    if (this.snapshot.status === PlaybackStatus.ERROR) {
      return $r('app.string.status_failed');
    }
    if (this.snapshot.status === PlaybackStatus.BUFFERING) {
      return $r('app.string.status_buffering');
    }
    if (this.snapshot.status === PlaybackStatus.PLAYING) {
      return $r('app.string.status_playing');
    }
    if (this.snapshot.status === PlaybackStatus.PAUSED) {
      return $r('app.string.status_paused');
    }
    if (this.snapshot.status === PlaybackStatus.READY) {
      return $r('app.string.status_ready');
    }
    if (this.snapshot.status === PlaybackStatus.COMPLETED) {
      return $r('app.string.status_completed');
    }
    if (this.snapshot.status === PlaybackStatus.RELEASED) {
      return $r('app.string.status_closed');
    }
    if (this.snapshot.status === PlaybackStatus.IDLE) {
      return $r('app.string.status_idle');
    }
    return $r('app.string.status_connecting');
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        Text($r('app.string.player_connection_status'))
          .fontSize(13)
          .fontColor(PlayerColors.TEXT_SECONDARY)
        Blank()
        Text(this.statusText())
          .fontSize(13)
          .fontColor(this.snapshot.status === PlaybackStatus.ERROR ? '#FF9F96' : PlayerColors.TEXT_STATUS)
      }
      .width('100%')

      if (this.snapshot.videoWidth > 0 && this.snapshot.videoHeight > 0) {
        Row() {
          Text($r('app.string.player_video_size'))
            .fontSize(13)
            .fontColor(PlayerColors.TEXT_SECONDARY)
          Blank()
          Text(`${this.snapshot.videoWidth} × ${this.snapshot.videoHeight}`)
            .fontSize(13)
            .fontColor(PlayerColors.TEXT_STATUS)
        }
        .width('100%')
      }
    }
    .padding(18)
    .margin({ left: 20, right: 20, top: 6 })
    .backgroundColor(PlayerColors.SURFACE_RAISED)
    .borderRadius(PlayerRadius.PANEL)
    .width('calc(100% - 40vp)')
  }
}
