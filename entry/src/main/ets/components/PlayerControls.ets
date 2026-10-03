import { PlaybackSnapshot, PlaybackStatus } from 'linkora_core';
import { AppTypography, PlayerColors, PlayerRadius } from '../ui/AppTheme';

@ComponentV2
export struct PlayerControls {
  @Param snapshot: PlaybackSnapshot = new PlaybackSnapshot(
    PlaybackStatus.IDLE, 0, 0, 0, 0, 0, null, false
  );
  @Param sliderPosition: number = 0;
  @Param playbackRate: number = 1;
  @Param volume: number = 1;
  @Param fullScreen: boolean = false;

  @Event onSeekChange: (value: number, mode: SliderChangeMode) => void = () => {};
  @Event onTogglePlayback: () => void = () => {};
  @Event onChangePlaybackRate: () => void = () => {};
  @Event onChangeVolume: (value: number) => void = () => {};
  @Event onToggleFullScreen: () => void = () => {};

  private isPlaying(): boolean {
    return this.snapshot.status === PlaybackStatus.PLAYING ||
      this.snapshot.status === PlaybackStatus.BUFFERING;
  }

  private canControl(): boolean {
    return this.snapshot.status === PlaybackStatus.PLAYING ||
      this.snapshot.status === PlaybackStatus.PAUSED ||
      this.snapshot.status === PlaybackStatus.BUFFERING ||
      this.snapshot.status === PlaybackStatus.COMPLETED ||
      this.snapshot.status === PlaybackStatus.READY;
  }

  private formatTime(milliseconds: number): string {
    const totalSeconds: number = Math.max(0, Math.floor(milliseconds / 1000));
    const hours: number = Math.floor(totalSeconds / 3600);
    const minutes: number = Math.floor((totalSeconds % 3600) / 60);
    const seconds: number = totalSeconds % 60;
    const minuteText: string = hours > 0 && minutes < 10 ? `0${minutes}` : `${minutes}`;
    const secondText: string = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return hours > 0 ? `${hours}:${minuteText}:${secondText}` : `${minuteText}:${secondText}`;
  }

  build() {
    Column({ space: 8 }) {
      Slider({
        value: this.sliderPosition,
        min: 0,
        max: Math.max(1, this.snapshot.duration),
        step: 1000,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .blockColor('#FFFFFF')
        .selectedColor(PlayerColors.PRIMARY_SOFT)
        .trackColor(PlayerColors.TRACK)
        .enabled(this.snapshot.duration > 0 && this.canControl())
        .onChange((value: number, mode: SliderChangeMode) => {
          this.onSeekChange(value, mode);
        })

      Row() {
        Text(this.formatTime(this.sliderPosition))
          .fontSize(AppTypography.CAPTION)
          .fontColor(PlayerColors.TEXT_SECONDARY)
        Blank()
        Text(this.formatTime(this.snapshot.duration))
          .fontSize(AppTypography.CAPTION)
          .fontColor(PlayerColors.TEXT_SECONDARY)
      }
      .width('100%')

      Row({ space: 16 }) {
        Button(`${this.playbackRate}×`)
          .type(ButtonType.Normal)
          .width(58)
          .height(38)
          .fontSize(13)
          .fontColor(PlayerColors.TEXT_CONTROL)
          .backgroundColor(PlayerColors.CONTROL_SURFACE)
          .borderRadius(PlayerRadius.CONTROL)
          .enabled(this.canControl())
          .onClick(() => {
            this.onChangePlaybackRate();
          })

        Blank()
        Button(this.isPlaying() ? '❚❚' : '▶')
          .type(ButtonType.Circle)
          .width(58)
          .height(58)
          .fontSize(this.isPlaying() ? 19 : 23)
          .fontColor('#FFFFFF')
          .backgroundColor(PlayerColors.PRIMARY)
          .enabled(this.canControl())
          .onClick(() => {
            this.onTogglePlayback();
          })
        Blank()

        Button(this.fullScreen ? $r('app.string.player_exit_fullscreen') : $r('app.string.player_fullscreen'))
          .type(ButtonType.Normal)
          .width(58)
          .height(38)
          .fontSize(13)
          .fontColor(PlayerColors.TEXT_CONTROL)
          .backgroundColor(PlayerColors.CONTROL_SURFACE)
          .borderRadius(PlayerRadius.CONTROL)
          .onClick(() => {
            this.onToggleFullScreen();
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        Text(this.volume === 0 ? $r('app.string.player_mute') : $r('app.string.player_volume'))
          .fontSize(AppTypography.CAPTION)
          .fontColor(PlayerColors.TEXT_SECONDARY)
          .width(34)
        Slider({
          value: this.volume,
          min: 0,
          max: 1,
          step: 0.05,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .blockColor('#FFFFFF')
          .selectedColor(PlayerColors.PRIMARY_SOFT)
          .trackColor(PlayerColors.TRACK)
          .onChange((value: number) => {
            this.onChangeVolume(value);
          })
      }
      .width('100%')
    }
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .width('100%')
    .backgroundColor(this.fullScreen ? '#B30B0D12' : PlayerColors.BACKGROUND)
  }
}
