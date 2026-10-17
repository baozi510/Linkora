import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppSettings, MediaSource, PlaybackPlaylist, PlaybackSnapshot, PlaybackStatus, PlayerFeatureController,
  PlayerBrightnessPort, PlayerFeatureState, PlayerGestureCallbacks, PlayerGestureController,
  PlayerGestureState } from 'linkora_core';
import { PlayerControls } from '../components/PlayerControls';
import { PlayerFailureOverlay } from '../components/PlayerFailureOverlay';
import { PlayerGestureFeedback } from '../components/PlayerGestureFeedback';
import { PlayerStatusPanel } from '../components/PlayerStatusPanel';
import { PlayerTopBar } from '../components/PlayerTopBar';
import { LinkoraFeatures } from '../foundation/LinkoraFeatures';
import { AppLifecycleEvents } from '../services/AppLifecycleEvents';
import { PlayerColors } from '../ui/AppTheme';
import { PlayerScreenDirection, WindowOrientationController } from '../playback/WindowOrientationController';

@ComponentV2
export struct PlayerPage {
  @Param source: MediaSource = MediaSource.empty();
  @Param playlist: PlaybackPlaylist | null = null;
  @Param settings: AppSettings = new AppSettings();
  @Param previewMode: boolean = false;
  @Event onBack: () => void = () => {};
  @Event onOpenSettings: () => void = () => {};

  @Local private snapshot: PlaybackSnapshot = new PlaybackSnapshot(
    PlaybackStatus.IDLE, 0, 0, 0, 0, 0, null, false
  );
  @Local private sliderPosition: number = 0;
  @Local private isSeeking: boolean = false;
  @Local private playbackRate: number = 1;
  @Local private volume: number = 1;
  @Local private audioDelay: number | null = null;
  @Local private audioDelayError: boolean = false;
  @Local private audioBusy: boolean = false;
  @Local private audioError: boolean = false;
  @Local private screenDirection: PlayerScreenDirection | null = null;
  @Local private directionBusy: boolean = false;
  @Local private directionFailed: boolean = false;
  @Local private controlsVisible: boolean = true;
  @Local private gestureState: PlayerGestureState = new PlayerGestureState();
  @Local private surfaceWidth: number = 1;
  @Local private surfaceHeight: number = 1;
  @Local private viewportHeight: number = 800;

  private surfaceController: XComponentController = new XComponentController();
  private controller: PlayerFeatureController | null = null;
  private gestureController: PlayerGestureController | null = null;
  private brightnessController: PlayerBrightnessPort | null = null;
  private orientationController: WindowOrientationController | null = null;
  private active: boolean = false;
  private closing: boolean = false;
  private abilityContext: common.UIAbilityContext | null = null;
  private backgroundObserver: () => void = () => {
    this.handleAppBackground();
  };
  private keepScreenOn: boolean = false;
  private rateBeforeLongPress: number = 1;

  aboutToAppear(): void {
    this.active = true;
    this.closing = false;
    this.controlsVisible = true;
    if (this.previewMode) {
      this.snapshot = new PlaybackSnapshot(
        PlaybackStatus.PAUSED, 96000, 454000, 63, 1920, 1080, null, true
      );
      this.sliderPosition = this.snapshot.position;
      return;
    }
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.abilityContext = context;
    this.orientationController = new WindowOrientationController(context);
    this.changeScreenDirection(PlayerScreenDirection.FOLLOW_SYSTEM);
    this.brightnessController = LinkoraFeatures.createPlayerBrightness(context);
    this.brightnessController.initialize().catch(() => {});
    context.eventHub.on(AppLifecycleEvents.BACKGROUND, this.backgroundObserver);
    this.controller = LinkoraFeatures.createPlayer(context, this.source, this.settings,
      (state: PlayerFeatureState) => {
      if (this.active) {
        this.applyFeatureState(state);
      }
    }, this.playlist);
    this.gestureController = new PlayerGestureController(new PlayerGestureCallbacks(
      () => { this.controlsVisible = !this.controlsVisible; },
      () => {
        this.controller?.togglePlayback();
      },
      (position: number, begin: boolean) => {
        if (begin) {
          this.controller?.beginSeek(position);
        } else {
          this.controller?.moveSeek(position);
        }
      },
      (position: number) => {
        this.controller?.commitSeek(position);
      },
      () => {
        this.controller?.cancelSeek();
      },
      (offset: number) => {
        this.controller?.seekBy(offset);
      },
      (value: number) => {
        this.controller?.setVolume(value);
      },
      (value: number) => {
        this.brightnessController?.set(value);
      },
      (enabled: boolean) => {
        if (enabled) {
          this.rateBeforeLongPress = this.playbackRate;
          this.controller?.setPlaybackRate(2);
        } else {
          this.controller?.setPlaybackRate(this.rateBeforeLongPress);
        }
      }
    ), (state: PlayerGestureState) => {
      if (this.active) {
        this.gestureState = state;
      }
    });
  }

  aboutToDisappear(): void {
    this.active = false;
    this.setKeepScreenOn(false);
    this.gestureController?.cancelPan();
    this.gestureController?.endLongPress();
    this.gestureController = null;
    this.brightnessController?.restore();
    this.brightnessController = null;
    const context: common.UIAbilityContext | null = this.abilityContext;
    this.abilityContext = null;
    if (context !== null) {
      context.eventHub.off(AppLifecycleEvents.BACKGROUND, this.backgroundObserver);
    }
    this.orientationController?.restore().catch((error: Object) => {
      console.error(`[PlayerWindow] Restore failed: ${String(error)}`);
    });
    this.orientationController = null;
    this.controller?.stop();
    this.controller = null;
  }

  private applyFeatureState(state: PlayerFeatureState): void {
    this.snapshot = state.playback;
    this.sliderPosition = state.sliderPosition;
    this.isSeeking = state.seeking;
    this.playbackRate = state.playbackRate;
    this.volume = state.volume;
    this.audioDelay = state.audioDelay;
    this.audioDelayError = state.audioDelayError;
    this.audioBusy = state.audioBusy;
    this.audioError = state.audioError;
    this.setKeepScreenOn(state.keepScreenOn);
  }

  private surfaceReady(): void {
    if (this.previewMode) {
      return;
    }
    const surfaceId: string = this.surfaceController.getXComponentSurfaceId();
    if (surfaceId.length === 0) {
      return;
    }
    const uiContext = this.getUIContext();
    this.controller?.setSurfaceSize(
      uiContext.vp2px(this.surfaceWidth),
      uiContext.vp2px(this.surfaceHeight)
    );
    this.controller?.attachSurface(surfaceId);
  }

  private surfaceDestroyed(): void {
    this.controller?.detachSurface();
  }

  private handleAppBackground(): void {
    this.setKeepScreenOn(false);
    this.gestureController?.cancelPan();
    this.gestureController?.endLongPress();
    this.controller?.handleBackground();
  }

  private fingerX(event: GestureEvent): number {
    return event.fingerList.length > 0 ? event.fingerList[0].localX : this.surfaceWidth / 2;
  }

  private beginPan(event: GestureEvent): void {
    const startX: number = this.fingerX(event) - event.offsetX;
    this.gestureController?.beginPan(startX, this.surfaceWidth, this.surfaceHeight,
      this.snapshot.position, this.snapshot.duration, this.volume,
      this.brightnessController?.currentValue() ?? 0.5);
    this.gestureController?.updatePan(event.offsetX, event.offsetY);
  }

  private canBeginLongPress(): boolean {
    return this.snapshot.status === PlaybackStatus.PLAYING ||
      this.snapshot.status === PlaybackStatus.BUFFERING;
  }

  private setKeepScreenOn(enabled: boolean): void {
    if (this.keepScreenOn === enabled) {
      return;
    }
    this.keepScreenOn = enabled;
    const context: common.UIAbilityContext | null = this.abilityContext;
    if (context === null) {
      return;
    }
    window.getLastWindow(context).then((appWindow: window.Window) => {
      appWindow.setWindowKeepScreenOn(enabled).catch(() => {});
    }).catch(() => {});
  }

  private togglePlayback(): void {
    this.controller?.togglePlayback();
  }

  private changePosition(value: number, mode: SliderChangeMode): void {
    this.sliderPosition = value;
    if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
      if (mode === SliderChangeMode.Begin) {
        this.controller?.beginSeek(value);
      } else {
        this.controller?.moveSeek(value);
      }
      return;
    }
    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
      this.controller?.commitSeek(value);
    }
  }

  private nextPlaybackRate(): void {
    this.controller?.cyclePlaybackRate();
  }

  private changeVolume(value: number): void {
    this.controller?.setVolume(value);
  }

  private changeScreenDirection(direction: PlayerScreenDirection): void {
    const owner: WindowOrientationController | null = this.orientationController;
    if (owner === null || this.directionBusy) return;
    this.directionBusy = true;
    this.directionFailed = false;
    owner.set(direction).then((confirmed: PlayerScreenDirection) => {
      if (this.active && this.orientationController === owner) this.screenDirection = confirmed;
    }).catch(() => {
      if (this.active && this.orientationController === owner) this.directionFailed = true;
    }).finally(() => {
      if (this.active && this.orientationController === owner) this.directionBusy = false;
    });
  }

  private close(): void {
    if (this.closing || !this.active) return;
    this.closing = true;
    const owner: WindowOrientationController | null = this.orientationController;
    this.orientationController = null;
    this.directionBusy = true;
    (owner?.restore() ?? Promise.resolve()).catch((error: Object) => {
      console.error(`[PlayerWindow] Restore failed: ${String(error)}`);
    }).then(() => { if (this.active) this.onBack(); });
  }

  private isLoading(): boolean {
    return this.snapshot.status === PlaybackStatus.PREPARING ||
      this.snapshot.status === PlaybackStatus.READY ||
      this.snapshot.status === PlaybackStatus.BUFFERING;
  }

  private sourceLabel(): string {
    const source: MediaSource = this.currentSource();
    const label: string = source.originLabel.length > 0 ? source.originLabel : source.displayName;
    if (this.playlist === null) return label;
    const index: number = this.snapshot.playlistIndex >= 0 ? this.snapshot.playlistIndex : this.playlist.startIndex;
    return `${label} · ${index + 1}/${this.playlist.items.length}` +
      (this.snapshot.playlistIndex < 0 ? ' · 已整理' : '') +
      (this.playlist.complete ? '' : ' · 清单未确认完整');
  }

  private currentSource(): MediaSource {
    return this.playlist !== null && this.snapshot.playlistIndex >= 0 ?
      this.playlist.items[this.snapshot.playlistIndex].source : this.source;
  }

  @Builder
  private videoSurface() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.previewMode) {
        Column({ space: 8 }) {
          Text('LINKORA PLAYER')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#9A86FF')
            .letterSpacing(2)
          Text('视频画面将在设备运行时显示')
            .fontSize(12)
            .fontColor('#747C8A')
        }
      } else {
        XComponent({
          id: 'linkora-player-surface',
          type: XComponentType.SURFACE,
          controller: this.surfaceController
        })
          .width('100%')
          .height('100%')
          .onLoad(() => {
            this.surfaceReady();
          })
          .onDestroy(() => {
            this.surfaceDestroyed();
          })
      }

      if (this.isLoading() && !this.snapshot.firstFrameRendered) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(34)
            .height(34)
            .color('#A997FF')
          Text(this.snapshot.status === PlaybackStatus.BUFFERING ?
            `正在缓冲 ${this.snapshot.bufferedPercent}%` : '正在打开媒体')
            .fontSize(13)
            .fontColor('#C7CAD1')
        }
      }

      if (this.snapshot.status === PlaybackStatus.ERROR) {
        PlayerFailureOverlay({
          failure: this.snapshot.failure,
          onRetry: () => {
            this.controller?.retry();
          },
          onEditSource: () => {
            this.close();
          },
          onOpenSettings: () => {
            this.onOpenSettings();
          }
        })
      }

      PlayerGestureFeedback({ state: this.gestureState })


    }
    .width('100%')
    .height('100%')
    .id('player-video-viewport')
    .backgroundColor('#000000')
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      // ArkUI Area dimensions are vp; mpv-ohos ohos-surface-size expects
      // physical pixels. Passing vp directly renders only a density-scaled
      // sub-rectangle of the XComponent surface on real devices.
      this.surfaceWidth = Number(newArea.width);
      this.surfaceHeight = Number(newArea.height);
      const uiContext = this.getUIContext();
      this.controller?.setSurfaceSize(
        uiContext.vp2px(this.surfaceWidth),
        uiContext.vp2px(this.surfaceHeight)
      );
    })
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 2, fingers: 1 })
          .onAction((event: GestureEvent) => {
            this.gestureController?.doubleTap(this.fingerX(event), this.surfaceWidth);
          }),
        LongPressGesture({ fingers: 1, repeat: false, duration: 450 })
          .onAction(() => {
            if (this.canBeginLongPress()) {
              this.gestureController?.beginLongPress();
            }
          })
          .onActionEnd(() => {
            this.gestureController?.endLongPress();
          })
          .onActionCancel(() => {
            this.gestureController?.endLongPress();
          }),
        PanGesture({ fingers: 1, direction: PanDirection.All, distance: 12 })
          .onActionStart((event: GestureEvent) => {
            this.beginPan(event);
          })
          .onActionUpdate((event: GestureEvent) => {
            this.gestureController?.updatePan(event.offsetX, event.offsetY);
          })
          .onActionEnd(() => {
            this.gestureController?.endPan();
          })
          .onActionCancel(() => {
            this.gestureController?.cancelPan();
          }),
        TapGesture({ count: 1, fingers: 1 })
          .onAction(() => {
            this.gestureController?.singleTap();
          })
      )
    )
  }

  @Builder
  private playbackOverlay() {
    Column() {
      Column() {
        PlayerTopBar({
          title: $r('app.string.player_now_playing'),
          subtitle: this.sourceLabel(),
          onBack: () => this.close()
        })
        Row({ space: 12 }) {
          Text(this.screenDirection === null ? $r('app.string.player_screen_direction') :
            (this.screenDirection === PlayerScreenDirection.LOCK_CURRENT ?
              $r('app.string.player_direction_locked') : $r('app.string.player_direction_system')))
            .fontSize(13)
            .fontColor(PlayerColors.TEXT_SECONDARY)
          Button(this.screenDirection === PlayerScreenDirection.LOCK_CURRENT ?
            $r('app.string.player_direction_unlock') : $r('app.string.player_direction_lock'))
            .type(ButtonType.Normal)
            .height(40)
            .fontSize(13)
            .fontColor(PlayerColors.TEXT_CONTROL)
            .backgroundColor(PlayerColors.CONTROL_SURFACE)
            .enabled(!this.directionBusy && !this.previewMode)
            .onClick(() => {
              this.changeScreenDirection(this.screenDirection === PlayerScreenDirection.LOCK_CURRENT ?
                PlayerScreenDirection.FOLLOW_SYSTEM : PlayerScreenDirection.LOCK_CURRENT);
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 8 })
        if (this.directionFailed) {
          Text($r('app.string.player_direction_failed'))
            .fontSize(12)
            .fontColor('#FFB4AB')
        }
      }
      .width('100%')
      .backgroundColor('#990B0D12')
      Blank()
        .hitTestBehavior(HitTestMode.None)
      Scroll() {
        Column() {
          PlayerControls({
            snapshot: this.snapshot,
            sliderPosition: this.sliderPosition,
            playbackRate: this.playbackRate,
            volume: this.volume,
            audioDelay: this.audioDelay,
            audioDelayError: this.audioDelayError,
            audioBusy: this.audioBusy,
            audioError: this.audioError,
            playlist: this.playlist,
            onPrevious: () => this.controller?.previousPlaylistItem(),
            onNext: () => this.controller?.nextPlaylistItem(),
            onSelectPlaylistItem: (index: number) => this.controller?.selectPlaylistItem(index),
            onSeekChange: (value: number, mode: SliderChangeMode) => this.changePosition(value, mode),
            onTogglePlayback: () => this.togglePlayback(),
            onChangeDisplayMode: () => this.controller?.cycleDisplayMode(),
            onStopPlayback: () => this.controller?.stopPlayback(),
            onChangeLoopMode: () => this.controller?.cycleLoopMode(),
            onSelectAudioTrack: (id: string) => this.controller?.selectAudioTrack(id),
            onSetAudioDelay: (milliseconds: number) => this.controller?.setAudioDelay(milliseconds),
            onChangePlaybackRate: () => this.nextPlaybackRate(),
            onChangeVolume: (value: number) => this.changeVolume(value)
          })
          PlayerStatusPanel({ snapshot: this.snapshot })
        }
        .width('100%')
      }
      .width('100%')
      .height(Math.min(330, this.viewportHeight * 0.5))
      .backgroundColor('#990B0D12')
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  build() {
    Stack() {
      this.videoSurface()
      if (this.controlsVisible && this.snapshot.status !== PlaybackStatus.ERROR) {
        this.playbackOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      this.viewportHeight = Number(newArea.height);
    })
  }

}

@Preview
@ComponentV2
struct PlayerPagePreview {
  build() {
    PlayerPage({
      source: MediaSource.fromLocalDocument('file://media/sample-video.mp4'),
      previewMode: true
    })
  }
}
