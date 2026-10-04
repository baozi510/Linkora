import { describe, expect, it } from '@ohos/hypium';
import { MediaSource, PlaybackEngine, PlaybackSnapshot, PlaybackStatus } from 'linkora_core';
import {
  PlaybackPort,
  PlaybackPortError,
  PlaybackPortFactory,
  PlaybackPortObserver,
  PortBufferingEvent,
  PortPlaybackState
} from 'linkora_core';

class FakePlaybackPort implements PlaybackPort {
  readonly observer: PlaybackPortObserver;
  configuredSurface: string = '';
  seekPosition: number = -1;
  playbackRate: number = 1;
  volume: number = 1;
  released: boolean = false;
  surfaceWidth: number = 0;
  surfaceHeight: number = 0;
  sizeCalls: number = 0;

  constructor(observer: PlaybackPortObserver) {
    this.observer = observer;
  }

  configure(_source: MediaSource, surfaceId: string): void {
    this.configuredSurface = surfaceId;
    this.observer.onStateChange(PortPlaybackState.INITIALIZED);
  }

  setSurfaceSize(width: number, height: number): void {
    this.surfaceWidth = width;
    this.surfaceHeight = height;
    ++this.sizeCalls;
  }

  getDuration(): number {
    return 120000;
  }

  async prepare(): Promise<void> {
    this.observer.onDurationChange(120000);
    this.observer.onVideoSizeChange(1920, 1080);
    this.observer.onStateChange(PortPlaybackState.PREPARED);
  }

  async play(): Promise<void> {
    this.observer.onStateChange(PortPlaybackState.PLAYING);
  }

  async pause(): Promise<void> {
    this.observer.onStateChange(PortPlaybackState.PAUSED);
  }

  seek(position: number): void {
    this.seekPosition = position;
    this.observer.onPositionChange(position);
  }

  setPlaybackRate(rate: number): void {
    this.playbackRate = rate;
  }

  setVolume(volume: number): void {
    this.volume = volume;
  }

  async release(): Promise<void> {
    this.released = true;
    this.observer.onStateChange(PortPlaybackState.RELEASED);
  }

  emitBuffering(event: PortBufferingEvent, value: number): void {
    this.observer.onBufferingChange(event, value);
  }

  emitError(code: number, detail: string = ''): void {
    this.observer.onError(new PlaybackPortError(code, detail));
  }
}

class FailingPreparePort extends FakePlaybackPort {
  async prepare(): Promise<void> {
    throw new PlaybackPortError(5400106, 'video/av1 unsupported decoder type');
  }
}

function latest(snapshots: PlaybackSnapshot[]): PlaybackSnapshot {
  return snapshots[snapshots.length - 1];
}

export default function playbackEngineTest(): void {
  describe('PlaybackEngine', () => {
    for (const paused of [true, false]) {
      for (const endBeforeSeekDone of [true, false]) {
        it(`restoresSeekIntentPaused${paused}EndFirst${endBeforeSeekDone}`, 0, async () => {
          const snapshots: PlaybackSnapshot[] = [];
          const ports: FakePlaybackPort[] = [];
          const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
            async (observer: PlaybackPortObserver) => {
              const port = new FakePlaybackPort(observer);
              ports.push(port);
              return port;
            });
          await engine.open(MediaSource.fromLocalDocument('file://seek.mp4'), 'surface');
          if (paused) await engine.togglePlayback();
          engine.seek(60000);
          ports[0].emitBuffering(PortBufferingEvent.START, 0);
          // Slider input can issue another seek before the first one completes.
          engine.seek(108000);
          if (endBeforeSeekDone) ports[0].emitBuffering(PortBufferingEvent.END, 0);
          ports[0].observer.onSeekComplete(108000);
          if (!endBeforeSeekDone) {
            expect(latest(snapshots).status).assertEqual(PlaybackStatus.BUFFERING);
            ports[0].emitBuffering(PortBufferingEvent.END, 0);
          }
          expect(latest(snapshots).status).assertEqual(paused ? PlaybackStatus.PAUSED : PlaybackStatus.PLAYING);
          expect(latest(snapshots).position).assertEqual(108000);
          await engine.release();
        });
      }
    }

    it('deliversSizeStoredBeforeOpenToNewBackend', 0, async () => {
      const ports: FakePlaybackPort[] = [];
      const engine = new PlaybackEngine(() => {}, async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      });
      engine.setSurfaceSize(640, 360);
      await engine.open(MediaSource.fromLocalDocument('file://video.mp4'), 'surface');
      expect(ports[0].surfaceWidth).assertEqual(640);
      expect(ports[0].surfaceHeight).assertEqual(360);
      expect(ports[0].sizeCalls).assertEqual(1);
      await engine.release();
    });

    it('forwardsSizeChangesToActiveBackend', 0, async () => {
      const ports: FakePlaybackPort[] = [];
      const engine = new PlaybackEngine(() => {}, async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      });
      await engine.open(MediaSource.fromLocalDocument('file://video.mp4'), 'surface');
      engine.setSurfaceSize(1280, 720);
      expect(ports[0].surfaceWidth).assertEqual(1280);
      expect(ports[0].surfaceHeight).assertEqual(720);
      expect(ports[0].sizeCalls).assertEqual(1);
      await engine.release();
    });

    it('roundsSizeAndDoesNotForwardNonPositiveDimensions', 0, async () => {
      const ports: FakePlaybackPort[] = [];
      const engine = new PlaybackEngine(() => {}, async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      });
      engine.setSurfaceSize(-10, 360);
      await engine.open(MediaSource.fromLocalDocument('file://video.mp4'), 'surface');
      expect(ports[0].sizeCalls).assertEqual(0);
      engine.setSurfaceSize(640, 0);
      expect(ports[0].sizeCalls).assertEqual(0);
      engine.setSurfaceSize(640.6, 359.4);
      expect(ports[0].surfaceWidth).assertEqual(641);
      expect(ports[0].surfaceHeight).assertEqual(359);
      await engine.release();
    });

    it('opensAndAutoplaysThroughPort', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);

      await engine.open(MediaSource.fromLocalDocument('file://media/video.mp4'), 'surface-1');

      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
      expect(latest(snapshots).duration).assertEqual(120000);
      expect(latest(snapshots).videoWidth).assertEqual(1920);
      expect(ports[0].configuredSurface).assertEqual('surface-1');
    });

    it('pausesSeeksAndClampsVolume', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);
      await engine.open(MediaSource.fromLocalDocument('file://media/video.mp4'), 'surface-2');

      await engine.togglePlayback();
      engine.seek(180000);
      engine.setPlaybackRate(1.5);
      engine.setVolume(-1);

      const port: FakePlaybackPort = ports[0];
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.SEEKING);
      port.observer.onSeekComplete(port.seekPosition);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PAUSED);
      expect(port.seekPosition).assertEqual(120000);
      expect(port.playbackRate).assertEqual(1.5);
      expect(port.volume).assertEqual(0);
    });

    it('seeksToSavedPositionBeforeAutoplay', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);

      await engine.open(MediaSource.fromLocalDocument('file://media/video.mp4'), 'surface-resume', 33000);

      expect(ports[0].seekPosition).assertEqual(33000);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
    });

    it('restoresStateAfterBuffering', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);
      await engine.open(MediaSource.fromLocalDocument('file://media/video.mp4'), 'surface-3');

      const port: FakePlaybackPort = ports[0];
      port.emitBuffering(PortBufferingEvent.START, 0);
      port.emitBuffering(PortBufferingEvent.START, 0);
      port.emitBuffering(PortBufferingEvent.PERCENT, 44);
      port.emitBuffering(PortBufferingEvent.CACHED_DURATION, 90000);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.BUFFERING);
      expect(latest(snapshots).bufferedPercent).assertEqual(44);
      port.emitBuffering(PortBufferingEvent.END, 0);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
    });

    it('restartsCompletedMediaFromBeginning', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);
      await engine.open(MediaSource.fromLocalDocument('file://media/video.mp4'), 'surface-replay');
      ports[0].observer.onStateChange(PortPlaybackState.COMPLETED);

      await engine.togglePlayback();

      expect(ports[0].seekPosition).assertEqual(0);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
    });

    it('pausesWhenAudioIsInterrupted', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);
      await engine.open(MediaSource.fromLocalDocument('file://media/video.mp4'), 'surface-interrupt');

      ports[0].observer.onInterruptionPause();

      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PAUSED);
    });

    it('ignoresEventsFromReleasedSession', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);
      await engine.open(MediaSource.fromLocalDocument('file://media/first.mp4'), 'surface-4');
      await engine.open(MediaSource.fromLocalDocument('file://media/second.mp4'), 'surface-4');

      ports[0].emitError(5400106);

      expect(ports[0].released).assertTrue();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
    });

    it('mapsPlatformErrorAndReleasesPort', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FakePlaybackPort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);
      await engine.open(MediaSource.fromLocalDocument('file://media/video.mp4'), 'surface-5');
      const port: FakePlaybackPort = ports[0];

      port.emitError(5400106);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.ERROR);
      expect(latest(snapshots).failure!.message).assertEqual('视频或音频编码超出当前设备的系统解码能力。');
      expect(latest(snapshots).failure!.diagnosticCode).assertEqual('LNK-PLAY-001/5400106');
      expect(port.released).assertTrue();

      await engine.release();
      expect(port.released).assertTrue();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.RELEASED);
    });

    it('preservesSpecificPrepareFailure', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FailingPreparePort[] = [];
      const factory: PlaybackPortFactory = async (observer: PlaybackPortObserver) => {
        const port = new FailingPreparePort(observer);
        ports.push(port);
        return port;
      };
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot), factory);

      await engine.open(MediaSource.fromLocalDocument('file://media/av1.mp4'), 'surface-error');

      expect(latest(snapshots).status).assertEqual(PlaybackStatus.ERROR);
      expect(latest(snapshots).failure!.code).assertEqual('LNK-PLAY-001');
      expect(latest(snapshots).failure!.diagnosticCode).assertEqual('LNK-PLAY-001/5400106');
      expect(ports[0].released).assertTrue();
    });
  });
}
