import { describe, expect, it } from '@ohos/hypium';
import { PlayerGestureCallbacks, PlayerGestureController, PlayerGestureMode,
  PlayerGestureState } from 'linkora_core';

export default function playerGestureControllerTest(): void {
  describe('PlayerGestureController', () => {
    it('previewsAndCommitsHorizontalSeek', 0, () => {
      let previewPosition: number = -1;
      let committedPosition: number = -1;
      let began: boolean = false;
      const controller = new PlayerGestureController(new PlayerGestureCallbacks(
        () => {}, () => {},
        (position: number, begin: boolean) => {
          previewPosition = position;
          began = begin;
        },
        (position: number) => {
          committedPosition = position;
        }
      ), () => {});

      controller.beginPan(100, 200, 100, 30000, 240000, 0.5, 0.5);
      controller.updatePan(50, 4);
      controller.endPan();

      expect(began).assertTrue();
      expect(previewPosition).assertEqual(90000);
      expect(committedPosition).assertEqual(90000);
      expect(controller.currentState().mode).assertEqual(PlayerGestureMode.IDLE);
    });

    it('routesVerticalPanByScreenSide', 0, () => {
      let brightness: number = 0;
      let volume: number = 1;
      let state: PlayerGestureState = new PlayerGestureState();
      const controller = new PlayerGestureController(new PlayerGestureCallbacks(
        () => {}, () => {}, () => {}, () => {}, () => {}, () => {},
        (value: number) => {
          volume = value;
        },
        (value: number) => {
          brightness = value;
        }
      ), (next: PlayerGestureState) => {
        state = next;
      });

      controller.beginPan(60, 300, 200, 0, 120000, 0.8, 0.4);
      controller.updatePan(2, -80);
      expect(state.mode).assertEqual(PlayerGestureMode.BRIGHTNESS);
      expect(brightness).assertEqual(0.8);
      controller.endPan();

      controller.beginPan(240, 300, 200, 0, 120000, 0.8, 0.4);
      controller.updatePan(2, 80);
      expect(state.mode).assertEqual(PlayerGestureMode.VOLUME);
      expect(volume).assertEqual(0.4);
    });

    it('protectsEdgesAndRoutesDoubleTap', 0, () => {
      let seekOffset: number = 0;
      let toggles: number = 0;
      let volumeChanges: number = 0;
      const controller = new PlayerGestureController(new PlayerGestureCallbacks(
        () => {},
        () => {
          ++toggles;
        },
        () => {}, () => {}, () => {},
        (offset: number) => {
          seekOffset += offset;
        },
        () => {
          ++volumeChanges;
        }
      ), () => {});

      controller.beginPan(8, 300, 200, 0, 120000, 1, 0.5);
      controller.updatePan(1, -100);
      expect(volumeChanges).assertEqual(0);
      controller.cancelPan();

      controller.doubleTap(20, 300);
      controller.doubleTap(150, 300);
      controller.doubleTap(280, 300);
      expect(seekOffset).assertEqual(0);
      expect(toggles).assertEqual(1);
    });

    it('restoresTemporaryPlaybackRate', 0, () => {
      let enabledCalls: number = 0;
      let disabledCalls: number = 0;
      const controller = new PlayerGestureController(new PlayerGestureCallbacks(
        () => {}, () => {}, () => {}, () => {}, () => {}, () => {}, () => {}, () => {},
        (enabled: boolean) => {
          if (enabled) {
            ++enabledCalls;
          } else {
            ++disabledCalls;
          }
        }
      ), () => {});

      controller.beginLongPress();
      expect(controller.currentState().mode).assertEqual(PlayerGestureMode.FAST_PLAYBACK);
      controller.endLongPress();
      expect(enabledCalls).assertEqual(1);
      expect(disabledCalls).assertEqual(1);
    });
  });
}
