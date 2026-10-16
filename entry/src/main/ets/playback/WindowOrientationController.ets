import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export enum PlayerScreenDirection {
  FOLLOW_SYSTEM = 'follow_system',
  LANDSCAPE = 'landscape',
  PORTRAIT = 'portrait'
}

/** Owns the playback window policy, never video pixels or player state. */
export class WindowOrientationController {
  private static previousRestore: Promise<void> = Promise.resolve();
  private readonly ready: Promise<window.Window>;
  private original: window.Orientation | null = null;
  private tail: Promise<void> = Promise.resolve();
  private closed: boolean = false;
  private immersive: boolean = false;
  private restoring: Promise<void> | null = null;

  constructor(context: common.UIAbilityContext) {
    // Main-window ownership passes to the next page only after the old page settles restoration.
    this.ready = WindowOrientationController.previousRestore.catch(() => {}).then(() =>
      window.getLastWindow(context)).then((appWindow: window.Window) => {
      this.original = appWindow.getPreferredOrientation();
      return appWindow;
    });
    this.ready.catch(() => {});
  }

  set(direction: PlayerScreenDirection): Promise<PlayerScreenDirection> {
    const operation: Promise<PlayerScreenDirection> = this.tail.then(async () => {
      if (this.closed) throw new Error('Playback window owner closed');
      if (direction !== PlayerScreenDirection.FOLLOW_SYSTEM && direction !== PlayerScreenDirection.LANDSCAPE &&
        direction !== PlayerScreenDirection.PORTRAIT) throw new Error('Invalid screen direction');
      const appWindow: window.Window = await this.ready;
      if (this.closed) throw new Error('Playback window owner closed');
      if (!this.immersive) {
        await appWindow.setWindowSystemBarEnable([]);
        this.immersive = true;
        if (this.closed) throw new Error('Playback window owner closed');
      }
      const policy: window.Orientation = direction === PlayerScreenDirection.FOLLOW_SYSTEM ?
        window.Orientation.AUTO_ROTATION_RESTRICTED : (direction === PlayerScreenDirection.LANDSCAPE ?
          window.Orientation.LANDSCAPE : window.Orientation.PORTRAIT);
      await appWindow.setPreferredOrientation(policy);
      if (this.closed) throw new Error('Playback window owner closed');
      if (appWindow.getPreferredOrientation() !== policy) throw new Error('Screen direction policy not applied');
      return direction;
    });
    this.tail = operation.then(() => {}, () => {});
    return operation;
  }

  restore(): Promise<void> {
    if (this.restoring !== null) return this.restoring;
    this.closed = true;
    // Drain a pending native change before restoring, so it cannot rotate a departed page later.
    this.restoring = this.tail.then(async () => {
      const appWindow: window.Window = await this.ready;
      try {
        if (this.original !== null) {
          await appWindow.setPreferredOrientation(this.original);
          if (appWindow.getPreferredOrientation() !== this.original) throw new Error('Original screen direction not restored');
        }
      } finally {
        // The surrounding app always shows its normal status/navigation bars.
        await appWindow.setWindowSystemBarEnable(['status', 'navigation']);
      }
    });
    WindowOrientationController.previousRestore = this.restoring;
    return this.restoring;
  }
}
