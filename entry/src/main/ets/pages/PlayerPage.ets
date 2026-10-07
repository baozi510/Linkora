import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppSettings, MediaSource, PlaybackSnapshot, PlaybackStatus, PlayerFeatureController,
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

@ComponentV2
export struct PlayerPage {
  @Param source: MediaSource = MediaSource.empty();
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
  @Local private fullScreen: boolean = false;
  @Local private controlsVisible: boolean = true;
  @Local private gestureState: PlayerGestureState = new PlayerGestureState();
  @Local private surfaceWidth: number = 1;
  @Local private surfaceHeight: number = 1;

  private surfaceController: XComponentController = new XComponentController();
  private controller: PlayerFeatureController | null = null;
  private gestureController: PlayerGestureController | null = null;
  private brightnessController: PlayerBrightnessPort | null = null;
  private active: boolean = false;
  private abilityContext: common.UIAbilityContext | null = null;
  private backgroundObserver: () => void = () => {
    this.handleAppBackground();
  };
  private keepScreenOn: boolean = false;
  private rateBeforeLongPress: number = 1;

  aboutToAppear(): void {
    this.active = true;
    if (this.previewMode) {
      this.snapshot = new PlaybackSnapshot(
        PlaybackStatus.PAUSED, 96000, 454000, 63, 1920, 1080, null, true
      );
      this.sliderPosition = this.snapshot.position;
      return;
    }
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.abilityContext = context;
    this.brightnessController = LinkoraFeatures.createPlayerBrightness(context);
    this.brightnessController.initialize().catch(() => {});
    context.eventHub.on(AppLifecycleEvents.BACKGROUND, this.backgroundObserver);
    this.controller = LinkoraFeatures.createPlayer(context, this.source, this.settings,
      (state: PlayerFeatureState) => {
      if (this.active) {
        this.applyFeatureState(state);
      }
    });
    this.gestureController = new PlayerGestureController(new PlayerGestureCallbacks(
      () => {
        if (this.fullScreen) {
          this.controlsVisible = !this.controlsVisible;
        }
      },
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
    if (this.fullScreen) {
      this.restoreWindowMode();
    }
    this.controller?.stop();
    this.controller = null;
  }

  private applyFeatureState(state: PlayerFeatureState): void {
    this.snapshot = state.playback;
    this.sliderPosition = state.sliderPosition;
    this.isSeeking = state.seeking;
    this.playbackRate = state.playbackRate;
    this.volume = state.volume;
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

  private toggleFullScreen(): void {
    this.setWindowMode(!this.fullScreen).catch(() => {});
  }

  private async setWindowMode(fullScreen: boolean): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      const appWindow: window.Window = await window.getLastWindow(context);
      await appWindow.setWindowSystemBarEnable(fullScreen ? [] : ['status', 'navigation']);
      await appWindow.setPreferredOrientation(fullScreen ?
        window.Orientation.AUTO_ROTATION_LANDSCAPE : window.Orientation.UNSPECIFIED);
      if (this.active) {
        this.fullScreen = fullScreen;
      }
    } catch (_error) {
    }
  }

  private restoreWindowMode(): void {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    window.getLastWindow(context).then((appWindow: window.Window) => {
      appWindow.setWindowSystemBarEnable(['status', 'navigation']).catch(() => {});
      appWindow.setPreferredOrientation(window.Orientation.UNSPECIFIED).catch(() => {});
    }).catch(() => {});
  }

  private close(): void {
    if (this.fullScreen) {
      this.setWindowMode(false).then(() => {
        this.onBack();
      }).catch(() => {
        this.onBack();
      });
      return;
    }
    this.onBack();
  }

  private isLoading(): boolean {
    return this.snapshot.status === PlaybackStatus.PREPARING ||
      this.snapshot.status === PlaybackStatus.READY ||
      this.snapshot.status === PlaybackStatus.BUFFERING;
  }

  private sourceLabel(): string {
    return this.source.originLabel.length > 0 ? this.source.originLabel : this.source.displayName;
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
            this.onBack();
          },
          onOpenSettings: () => {
            this.onOpenSettings();
          }
        })
      }

      PlayerGestureFeedback({ state: this.gestureState })

      if (this.fullScreen && this.controlsVisible) {
        PlayerTopBar({
          title: this.source.displayName,
          showSubtitle: false,
          overlayMode: true,
          onBack: () => {
            this.close();
          }
        })
        .align(Alignment.Top)

        Column() {
          PlayerControls({
            snapshot: this.snapshot,
            sliderPosition: this.sliderPosition,
            playbackRate: this.playbackRate,
            volume: this.volume,
            fullScreen: this.fullScreen,
            onSeekChange: (value: number, mode: SliderChangeMode) => {
              this.changePosition(value, mode);
            },
            onTogglePlayback: () => {
              this.togglePlayback();
            },
            onChangePlaybackRate: () => {
              this.nextPlaybackRate();
            },
            onChangeVolume: (value: number) => {
              this.changeVolume(value);
            },
            onToggleFullScreen: () => {
              this.toggleFullScreen();
            }
          })
        }
        .width('100%')
        .align(Alignment.Bottom)
      }
    }
    .width('100%')
    .height('100%')
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

  build() {
    Column() {
      if (this.fullScreen) {
        // Fullscreen must be constrained by the actual viewport, not by a
        // width-derived 16:9 height that can exceed short/wide displays.
        // MPV/System own aspect fitting inside this viewport-sized surface.
        this.videoSurface()
      } else {
        PlayerTopBar({
          title: $r('app.string.player_now_playing'),
          subtitle: this.sourceLabel(),
          onBack: () => {
            this.close();
          }
        })

        Stack() {
          this.videoSurface()
        }
        .width('100%')
        .aspectRatio(16 / 9)

        PlayerControls({
          snapshot: this.snapshot,
          sliderPosition: this.sliderPosition,
          playbackRate: this.playbackRate,
          volume: this.volume,
          fullScreen: this.fullScreen,
          onSeekChange: (value: number, mode: SliderChangeMode) => {
            this.changePosition(value, mode);
          },
          onTogglePlayback: () => {
            this.togglePlayback();
          },
          onChangePlaybackRate: () => {
            this.nextPlaybackRate();
          },
          onChangeVolume: (value: number) => {
            this.changeVolume(value);
          },
          onToggleFullScreen: () => {
            this.toggleFullScreen();
          }
        })

        PlayerStatusPanel({ snapshot: this.snapshot })
        Blank()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PlayerColors.BACKGROUND)
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
