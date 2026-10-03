import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { PlayerBrightnessPort } from 'linkora_core';

export class WindowBrightnessController implements PlayerBrightnessPort {
  private context: common.UIAbilityContext;
  private appWindow: window.Window | null = null;
  private originalBrightness: number = -1;
  private brightness: number = 0.5;
  private initialized: boolean = false;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }
    try {
      const appWindow: window.Window = await window.getLastWindow(this.context);
      const original: number = appWindow.getWindowProperties().brightness;
      this.appWindow = appWindow;
      this.originalBrightness = original;
      this.brightness = original >= 0 ? original : 0.5;
      this.initialized = true;
    } catch (_error) {
    }
  }

  currentValue(): number {
    return this.brightness;
  }

  set(value: number): void {
    this.brightness = Math.max(0.05, Math.min(value, 1));
    const appWindow: window.Window | null = this.appWindow;
    if (appWindow === null) {
      this.initialize().then(() => {
        this.appWindow?.setWindowBrightness(this.brightness).catch(() => {});
      }).catch(() => {});
      return;
    }
    appWindow.setWindowBrightness(this.brightness).catch(() => {});
  }

  restore(): void {
    const appWindow: window.Window | null = this.appWindow;
    const brightness: number = this.originalBrightness;
    this.appWindow = null;
    this.initialized = false;
    this.originalBrightness = -1;
    this.brightness = 0.5;
    if (appWindow !== null) {
      appWindow.setWindowBrightness(brightness).catch(() => {});
    }
  }
}
