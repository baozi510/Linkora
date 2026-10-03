import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { AppThemeMode } from 'linkora_core';

export class AppThemeController {
  private static currentMode: AppThemeMode = AppThemeMode.SYSTEM;

  static apply(context: common.UIAbilityContext, mode: AppThemeMode): void {
    const effectiveMode: AppThemeMode = AppThemeController.supportsManualMode() ? mode : AppThemeMode.SYSTEM;
    AppThemeController.currentMode = effectiveMode;
    try {
      if (AppThemeController.supportsManualMode()) {
        context.setColorMode(AppThemeController.platformMode(effectiveMode));
      }
    } catch (_error) {
      // API 12-17 continues to follow the system resource qualifier.
    }
    AppThemeController.updateSystemBars(context, effectiveMode).catch(() => {});
  }

  static supportsManualMode(): boolean {
    return deviceInfo.distributionOSApiVersion >= 18;
  }

  static refreshSystemBars(context: common.UIAbilityContext): void {
    AppThemeController.updateSystemBars(context, AppThemeController.currentMode).catch(() => {});
  }

  private static platformMode(mode: AppThemeMode): ConfigurationConstant.ColorMode {
    if (mode === AppThemeMode.LIGHT) {
      return ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    }
    if (mode === AppThemeMode.DARK) {
      return ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    return ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  }

  private static async updateSystemBars(context: common.UIAbilityContext, mode: AppThemeMode): Promise<void> {
    try {
      const dark: boolean = AppThemeController.isDark(context, mode);
      const content: string = await AppThemeController.resourceColor(context,
        $r('sys.color.font_primary'), dark, dark ? '#F4F5F7' : '#171A21');
      const appWindow: window.Window = await window.getLastWindow(context);
      await appWindow.setWindowLayoutFullScreen(true);
      await appWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: content,
        navigationBarContentColor: content
      });
    } catch (_error) {
    }
  }

  private static async resourceColor(context: common.UIAbilityContext, resource: Resource,
    dark: boolean, fallback: string): Promise<string> {
    try {
      const configuration: resourceManager.Configuration = context.resourceManager.getConfigurationSync();
      configuration.colorMode = dark ? resourceManager.ColorMode.DARK : resourceManager.ColorMode.LIGHT;
      const themedResourceManager: resourceManager.ResourceManager =
        context.resourceManager.getOverrideResourceManager(configuration);
      const value: number = await themedResourceManager.getColor(resource.id);
      return `#${(value >>> 0).toString(16).padStart(8, '0').toUpperCase()}`;
    } catch (_error) {
      return fallback;
    }
  }

  private static isDark(context: common.UIAbilityContext, mode: AppThemeMode): boolean {
    if (mode === AppThemeMode.DARK) {
      return true;
    }
    if (mode === AppThemeMode.LIGHT) {
      return false;
    }
    try {
      return context.resourceManager.getConfigurationSync().colorMode === resourceManager.ColorMode.DARK;
    } catch (_error) {
      return true;
    }
  }
}
