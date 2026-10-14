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

class FailingReleasePort extends FakePlaybackPort {
  async release(): Promise<void> {
    throw new PlaybackPortError(5400104, 'native release failed');
  }
}

class DurationAfterPlayPort extends FakePlaybackPort {
  getDuration(): number {
    return 0;
  }

  async prepare(): Promise<void> {
    this.observer.onStateChange(PortPlaybackState.PREPARED);
  }

  async play(): Promise<void> {
    this.observer.onDurationChange(120000);
    await super.play();
  }
}

// The old session's asynchronous operation can complete after the next open.
class DeferredPausePort extends FakePlaybackPort {
  private rejectPause: ((error: PlaybackPortError) => void) | null = null;
  private pendingPause: Promise<void> | null = null;

  // Return the actual deferred promise: no extra async Promise adoption job.
  pause(): Promise<void> {
    this.pendingPause = new Promise<void>((_resolve: () => void,
      reject: (error: PlaybackPortError) => void) => {
      this.rejectPause = reject;
    });
    return this.pendingPause;
  }

  failPendingPause(): Promise<void> {
    const pending: Promise<void> | null = this.pendingPause;
    const reject: ((error: PlaybackPortError) => void) | null = this.rejectPause;
    this.rejectPause = null;
    reject?.(new PlaybackPortError(5400104, 'previous session pause cancelled'));
    // Engine's rejection handler is already attached to this same promise.
    // Await our later subscriber so the engine handler executes first.
    return pending === null ? Promise.resolve() :
      pending.catch((_error: PlaybackPortError) => {});
  }
}

class DeferredReleasePort extends FakePlaybackPort {
  private finish: (() => void) | null = null;
  private signalReleaseStarted: (() => void) | null = null;
  readonly releaseStarted: Promise<void>;

  constructor(observer: PlaybackPortObserver) {
    super(observer);
    this.releaseStarted = new Promise<void>((resolve: () => void) => {
      this.signalReleaseStarted = resolve;
    });
  }

  async release(): Promise<void> {
    this.released = true;
    this.signalReleaseStarted?.();
    this.signalReleaseStarted = null;
    await new Promise<void>((resolve: () => void) => {
      this.finish = resolve;
    });
    this.observer.onStateChange(PortPlaybackState.RELEASED);
  }

  finishRelease(): void {
    const finish: (() => void) | null = this.finish;
    this.finish = null;
    finish?.();
  }
}

class DeferredReleaseFailingPreparePort extends DeferredReleasePort {
  async prepare(): Promise<void> {
    throw new PlaybackPortError(5400106, 'old session prepare failed');
  }
}

function latest(snapshots: PlaybackSnapshot[]): PlaybackSnapshot {
  return snapshots[snapshots.length - 1];
}

export default function playbackEngineTest(): void {
  describe('PlaybackEngine', () => {
    it('doesNotReportReleasedWhenNativeReleaseFails', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver) => new FailingReleasePort(observer));
      await engine.open(MediaSource.fromLocalDocument('file://release.mp4'), 'surface');
      let rejected: boolean = false;
      try { await engine.release(); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.ERROR);
      expect(latest(snapshots).failure!.diagnosticCode).assertEqual('LNK-PLAY-003/5400104');
      rejected = false;
      try { await engine.release(); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.ERROR);
    });

    it('doesNotOpenReplacementWhenPreviousNativeReleaseFails', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      let factoryCalls: number = 0;
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver) => {
          factoryCalls++;
          return new FailingReleasePort(observer);
        });
      await engine.open(MediaSource.fromLocalDocument('file://first.mp4'), 'surface');
      await engine.open(MediaSource.fromLocalDocument('file://second.mp4'), 'surface');
      expect(factoryCalls).assertEqual(1);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.ERROR);
    });
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

    it('resumesPreparedMediaBeforeDelayedDurationMetadata', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      let port: DurationAfterPlayPort | null = null;
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver): Promise<PlaybackPort> => {
          port = new DurationAfterPlayPort(observer);
          return port;
        });

      await engine.open(MediaSource.fromLocalDocument('file://media/video.mkv'), 'surface-resume', 33000);

      expect(port!.seekPosition).assertEqual(33000);
      expect(latest(snapshots).position).assertEqual(33000);
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

    it('ignoresLateTogglePauseFailureFromReplacedPort', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver) => {
          const port: FakePlaybackPort = ports.length === 0 ?
            new DeferredPausePort(observer) : new FakePlaybackPort(observer);
          ports.push(port);
          return port;
        });
      await engine.open(MediaSource.fromLocalDocument('file://first.mp4'), 'surface');
      const stalePause: Promise<void> = engine.togglePlayback();
      await engine.open(MediaSource.fromLocalDocument('file://second.mp4'), 'surface');
      await (ports[0] as DeferredPausePort).failPendingPause();
      await stalePause;

      expect(ports[0].released).assertTrue();
      expect(ports[1].released).assertFalse();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
      await engine.release();
    });

    it('ignoresLateInterruptionPauseFailureFromReplacedPort', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver) => {
          const port: FakePlaybackPort = ports.length === 0 ?
            new DeferredPausePort(observer) : new FakePlaybackPort(observer);
          ports.push(port);
          return port;
        });
      await engine.open(MediaSource.fromLocalDocument('file://first.mp4'), 'surface');
      ports[0].observer.onInterruptionPause();
      await engine.open(MediaSource.fromLocalDocument('file://second.mp4'), 'surface');
      await (ports[0] as DeferredPausePort).failPendingPause();

      expect(ports[1].released).assertFalse();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
      await engine.release();
    });

    it('doesNotStartStaleOpenAfterConcurrentRelease', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver) => {
          const port: FakePlaybackPort = ports.length === 0 ?
            new DeferredReleasePort(observer) : new FakePlaybackPort(observer);
          ports.push(port);
          return port;
        });
      await engine.open(MediaSource.fromLocalDocument('file://first.mp4'), 'surface');
      const staleOpen: Promise<void> =
        engine.open(MediaSource.fromLocalDocument('file://second.mp4'), 'surface');
      await engine.release();
      (ports[0] as DeferredReleasePort).finishRelease();
      await staleOpen;

      expect(ports.length).assertEqual(1);
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.RELEASED);
    });

    it('doesNotLetLateReleaseOverwriteNewPlayback', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver) => {
          const port: FakePlaybackPort = ports.length === 0 ?
            new DeferredReleasePort(observer) : new FakePlaybackPort(observer);
          ports.push(port);
          return port;
        });
      await engine.open(MediaSource.fromLocalDocument('file://first.mp4'), 'surface');
      const staleRelease: Promise<void> = engine.release();
      await engine.open(MediaSource.fromLocalDocument('file://second.mp4'), 'surface');
      (ports[0] as DeferredReleasePort).finishRelease();
      await staleRelease;

      expect(ports.length).assertEqual(2);
      expect(ports[1].released).assertFalse();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
      await engine.release();
    });

    it('ignoresLateFailedOpenAfterDisposalWhenNewSessionIsPlaying', 0, async () => {
      const snapshots: PlaybackSnapshot[] = [];
      const ports: FakePlaybackPort[] = [];
      let firstPortReady: ((port: DeferredReleaseFailingPreparePort) => void) | null = null;
      const firstPortCreated: Promise<DeferredReleaseFailingPreparePort> =
        new Promise<DeferredReleaseFailingPreparePort>(
          (resolve: (port: DeferredReleaseFailingPreparePort) => void) => {
            firstPortReady = resolve;
          });
      const engine = new PlaybackEngine((snapshot: PlaybackSnapshot) => snapshots.push(snapshot),
        async (observer: PlaybackPortObserver) => {
          if (ports.length === 0) {
            const port = new DeferredReleaseFailingPreparePort(observer);
            ports.push(port);
            firstPortReady?.(port);
            return port;
          }
          const port = new FakePlaybackPort(observer);
          ports.push(port);
          return port;
        });

      const failedOpen: Promise<void> =
        engine.open(MediaSource.fromLocalDocument('file://old-failure.mp4'), 'surface');
      const oldPort: DeferredReleaseFailingPreparePort = await firstPortCreated;
      // The rejected prepare has entered open() catch and its disposal is pending.
      await oldPort.releaseStarted;
      await engine.open(MediaSource.fromLocalDocument('file://new-healthy.mp4'), 'surface');
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);

      oldPort.finishRelease();
      await failedOpen;

      expect(ports.length).assertEqual(2);
      expect(oldPort.released).assertTrue();
      expect(ports[1].released).assertFalse();
      expect(latest(snapshots).status).assertEqual(PlaybackStatus.PLAYING);
      expect(latest(snapshots).failure === null).assertTrue();
      await engine.release();
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
