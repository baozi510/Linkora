import { PlayerGestureMode, PlayerGestureState } from 'linkora_core';
import { PlayerColors, PlayerRadius } from '../ui/AppTheme';

@ComponentV2
export struct PlayerGestureFeedback {
  @Param state: PlayerGestureState = new PlayerGestureState();

  private formatTime(milliseconds: number): string {
    const totalSeconds: number = Math.max(0, Math.floor(milliseconds / 1000));
    const hours: number = Math.floor(totalSeconds / 3600);
    const minutes: number = Math.floor((totalSeconds % 3600) / 60);
    const seconds: number = totalSeconds % 60;
    const minuteText: string = hours > 0 && minutes < 10 ? `0${minutes}` : `${minutes}`;
    const secondText: string = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return hours > 0 ? `${hours}:${minuteText}:${secondText}` : `${minuteText}:${secondText}`;
  }

  private title(): ResourceStr {
    if (this.state.mode === PlayerGestureMode.BRIGHTNESS) {
      return $r('app.string.player_gesture_brightness');
    }
    if (this.state.mode === PlayerGestureMode.VOLUME) {
      return $r('app.string.player_gesture_volume');
    }
    if (this.state.mode === PlayerGestureMode.FAST_PLAYBACK) {
      return $r('app.string.player_gesture_fast_playback');
    }
    return $r('app.string.player_gesture_seek');
  }

  build() {
    if (this.state.visible) {
      Column({ space: 10 }) {
        Text(this.title())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(PlayerColors.TEXT_PRIMARY)

        if (this.state.mode === PlayerGestureMode.SEEK) {
          Text(`${this.formatTime(this.state.position)} / ${this.formatTime(this.state.duration)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Progress({
            value: this.state.position,
            total: Math.max(1, this.state.duration),
            type: ProgressType.Linear
          })
            .width(180)
            .height(4)
            .color(PlayerColors.PRIMARY_SOFT)
            .backgroundColor(PlayerColors.TRACK)
        } else if (this.state.mode === PlayerGestureMode.BRIGHTNESS ||
          this.state.mode === PlayerGestureMode.VOLUME) {
          Text(`${Math.round(this.state.value * 100)}%`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Progress({ value: this.state.value * 100, total: 100, type: ProgressType.Linear })
            .width(140)
            .height(4)
            .color(PlayerColors.PRIMARY_SOFT)
            .backgroundColor(PlayerColors.TRACK)
        }
      }
      .padding({ left: 22, right: 22, top: 16, bottom: 16 })
      .constraintSize({ minWidth: 180 })
      .backgroundColor('#D9161920')
      .borderRadius(PlayerRadius.CARD)
      .backdropBlur(18)
      .hitTestBehavior(HitTestMode.None)
    }
  }
}
