import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppThemeController } from '../ui/AppThemeController';

export enum PlayerScreenDirection {
  FOLLOW_SYSTEM = 'follow_system',
  LOCK_CURRENT = 'lock_current'
}

/** Owns the playback window policy, never video pixels or player state. */
export class WindowOrientationController {
  private static previousRestore: Promise<void> = Promise.resolve();
  private readonly ready: Promise<window.Window>;
  private original: window.Orientation | null = null;
  private tail: Promise<void> = Promise.resolve();
  private closed: boolean = false;
  private immersive: boolean = false;
  private controlsVisible: boolean = true;
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
      if (direction !== PlayerScreenDirection.FOLLOW_SYSTEM && direction !== PlayerScreenDirection.LOCK_CURRENT)
        throw new Error('Invalid screen direction');
      const appWindow: window.Window = await this.ready;
      if (this.closed) throw new Error('Playback window owner closed');
      if (!this.immersive) {
        await AppThemeController.setPlaybackSystemBars(appWindow, true, this.controlsVisible);
        this.immersive = true;
        if (this.closed) throw new Error('Playback window owner closed');
      }
      let policy: window.Orientation = window.Orientation.AUTO_ROTATION_RESTRICTED;
      if (direction === PlayerScreenDirection.LOCK_CURRENT) {
        const rect: window.Rect = appWindow.getWindowProperties().windowRect;
        if (!(rect.width > 0 && rect.height > 0) || rect.width === rect.height)
          throw new Error('Playback window size cannot identify an axis');
        // Lock the axis while leaving 180-degree sensor rotation to the platform.
        policy = rect.width > rect.height ? window.Orientation.AUTO_ROTATION_LANDSCAPE :
          window.Orientation.AUTO_ROTATION_PORTRAIT;
      }
      await appWindow.setPreferredOrientation(policy);
      if (this.closed) throw new Error('Playback window owner closed');
      if (appWindow.getPreferredOrientation() !== policy) throw new Error('Screen direction policy not applied');
      return direction;
    });
    this.tail = operation.then(() => {}, () => {});
    return operation;
  }

  setControlsVisible(visible: boolean): Promise<void> {
    this.controlsVisible = visible;
    const operation: Promise<void> = this.tail.then(async () => {
      if (this.closed) throw new Error('Playback window owner closed');
      const appWindow: window.Window = await this.ready;
      if (this.closed) throw new Error('Playback window owner closed');
      await AppThemeController.setPlaybackSystemBars(appWindow, true, this.controlsVisible);
    });
    this.tail = operation.catch(() => {});
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
        // Leaving playback restores ordinary-page layout and visible system bars.
        await AppThemeController.setPlaybackSystemBars(appWindow, false);
      }
    });
    WindowOrientationController.previousRestore = this.restoring;
    return this.restoring;
  }
}
