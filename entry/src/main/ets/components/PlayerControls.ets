import { PlaybackSnapshot, PlaybackStatus, PortTrack, PortTrackKind, VideoDisplayMode, PlaybackPlaylist,
  PlaybackLoopMode } from 'linkora_core';
import { AppTypography, PlayerColors, PlayerRadius } from '../ui/AppTheme';

@ComponentV2
export struct PlayerControls {
  @Param snapshot: PlaybackSnapshot = new PlaybackSnapshot(
    PlaybackStatus.IDLE, 0, 0, 0, 0, 0, null, false
  );
  @Param sliderPosition: number = 0;
  @Param playbackRate: number = 1;
  @Param volume: number = 1;
  @Param playlist: PlaybackPlaylist | null = null;
  @Event onPrevious: () => void = () => {};
  @Event onNext: () => void = () => {};
  @Event onSelectPlaylistItem: (index: number) => void = () => {};

  @Event onSeekChange: (value: number, mode: SliderChangeMode) => void = () => {};
  @Event onTogglePlayback: () => void = () => {};
  @Event onChangePlaybackRate: () => void = () => {};
  @Event onChangeVolume: (value: number) => void = () => {};
  @Event onStopPlayback: () => void = () => {};
  @Event onChangeLoopMode: () => void = () => {};
  @Event onSelectAudioTrack: (id: string) => void = () => {};
  @Event onChangeDisplayMode: () => void = () => {};

  private displayModeText(): ResourceStr {
    if (this.snapshot.displayMode === VideoDisplayMode.FIT) return $r('app.string.player_display_fit');
    if (this.snapshot.displayMode === VideoDisplayMode.CROP) return $r('app.string.player_display_crop');
    if (this.snapshot.displayMode === VideoDisplayMode.STRETCH) return $r('app.string.player_display_stretch');
    return $r('app.string.player_display_mode');
  }

  private loopModeText(): Resource {
    if (this.snapshot.loopMode === PlaybackLoopMode.SINGLE) return $r('app.string.player_loop_single');
    if (this.snapshot.loopMode === PlaybackLoopMode.LIST) return $r('app.string.player_loop_list');
    return $r('app.string.player_loop_sequence');
  }

  private audioTracks(): PortTrack[] {
    return this.snapshot.tracks.filter((track: PortTrack) => track.kind === PortTrackKind.AUDIO);
  }

  private audioOptions(): SelectOption[] {
    return this.audioTracks().map((track: PortTrack): SelectOption => ({
      value: track.title || track.language || `${track.id} ${track.codec}`
    }));
  }

  private playlistOptions(): SelectOption[] {
    return this.playlist === null ? [] : this.playlist.items.map((item): SelectOption => ({
      value: item.source.displayName
    }));
  }

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

        Button(this.displayModeText())
          .type(ButtonType.Normal)
          .height(38)
          .fontSize(13)
          .fontColor(PlayerColors.TEXT_CONTROL)
          .backgroundColor(PlayerColors.CONTROL_SURFACE)
          .borderRadius(PlayerRadius.CONTROL)
          .enabled(this.canControl())
          .onClick(() => this.onChangeDisplayMode())

        Blank()
        Button(this.isPlaying() ? '❚❚' : '▶')
          .type(ButtonType.Circle)
          .width(58)
          .height(58)
          .fontSize(this.isPlaying() ? 19 : 23)
          .fontColor('#FFFFFF')
          .backgroundColor(PlayerColors.PRIMARY)
          .enabled(this.canControl() || this.snapshot.status === PlaybackStatus.STOPPED)
          .onClick(() => {
            this.onTogglePlayback();
          })
        Blank()

      }
      .width('100%')

      Row({ space: 10 }) {
        Button($r('app.string.player_stop'))
          .enabled(this.canControl())
          .onClick(() => this.onStopPlayback())
        Button(this.loopModeText())
          .enabled(this.canControl())
          .accessibilityText(this.loopModeText())
          .onClick(() => this.onChangeLoopMode())
        if (this.audioTracks().length > 0) {
          Select(this.audioOptions())
            .selected(this.audioTracks().findIndex((track: PortTrack) => track.selected))
            .accessibilityText($r('app.string.player_audio_track'))
            .layoutWeight(1)
            .enabled(this.canControl())
            .onSelect((index: number) => {
              const track: PortTrack | undefined = this.audioTracks()[index];
              if (track !== undefined) this.onSelectAudioTrack(track.id);
            })
        }
      }
      .width('100%')

      if (this.playlist !== null && this.snapshot.playlistIndex >= 0) {
        Row({ space: 10 }) {
          Button('上一项')
            .enabled(this.canControl() && this.snapshot.playlistIndex > 0)
            .onClick(() => this.onPrevious())
          Select(this.playlistOptions())
            .selected(this.snapshot.playlistIndex)
            .value(this.playlist.items[this.snapshot.playlistIndex].source.displayName)
            .fontColor(PlayerColors.TEXT_CONTROL)
            .backgroundColor(PlayerColors.CONTROL_SURFACE)
            .optionFontColor(PlayerColors.TEXT_CONTROL)
            .optionBgColor(PlayerColors.CONTROL_SURFACE)
            .accessibilityText('播放列表')
            .layoutWeight(1)
            .enabled(this.canControl())
            .onSelect((index: number) => this.onSelectPlaylistItem(index))
          Button('下一项')
            .enabled(this.canControl() && this.snapshot.playlistIndex < this.playlist.items.length - 1)
            .onClick(() => this.onNext())
        }
        .width('100%')
      }

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
          .enabled(this.canControl())
          .onChange((value: number) => {
            this.onChangeVolume(value);
          })
      }
      .width('100%')
    }
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .width('100%')
  }
}
