import { common, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppLifecycleEvents } from '../services/AppLifecycleEvents';
import { AppThemeController } from '../ui/AppThemeController';
import { AppSettingsStore } from '../services/AppSettingsStore';
import { LinkoraDatabase } from '../services/LinkoraDatabase';
import { ProxyBuildProfile } from 'linkora_proxy';
import { NetworkProxySmokeTest } from '../services/NetworkProxySmokeTest';
import { MediaProbeBuildProfile } from 'linkora_media_probe';
import { NetworkMediaProbeSmokeTest } from '../services/NetworkMediaProbeSmokeTest';
import { RuntimeDiagnostics } from 'entry/RuntimeDiagnostics';
import { AnalysisBenchmarkRunner } from '../benchmark/AnalysisBenchmarkRunner';

export default class EntryAbility extends UIAbility {
  private mediaProbeSmokeConfig: string = '';
  private proxySmokeConfig: string = '';
  private analysisBenchmarkConfig: string = '';
  onCreate(want: Want): void {
    RuntimeDiagnostics.configure(want);
    if (MediaProbeBuildProfile.DEBUG && typeof want.parameters?.linkoraMediaProbeSmokeConfig === 'string') {
      this.mediaProbeSmokeConfig = want.parameters.linkoraMediaProbeSmokeConfig as string;
    }
    if (ProxyBuildProfile.DEBUG && typeof want.parameters?.linkoraProxySmokeConfig === 'string') {
      this.proxySmokeConfig = want.parameters.linkoraProxySmokeConfig as string;
    }
    if (MediaProbeBuildProfile.DEBUG && typeof want.parameters?.linkoraAnalysisBenchmarkConfig === 'string') {
      this.analysisBenchmarkConfig = want.parameters.linkoraAnalysisBenchmarkConfig as string;
    }
  }
  private registerIconFonts(windowStage: window.WindowStage): void {
    try {
      const iconFont = windowStage.getMainWindowSync().getUIContext().getFont();
      iconFont.registerFont({
        familyName: 'Linkora Material Symbols Outlined',
        familySrc: $rawfile('font/linkora_material_symbols_outlined.ttf')
      });
      iconFont.registerFont({
        familyName: 'Linkora Material Symbols Filled',
        familySrc: $rawfile('font/linkora_material_symbols_filled.ttf')
      });
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`Failed to register icon fonts. code=${businessError.code}, message=${businessError.message}`);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const context: common.UIAbilityContext = this.context as common.UIAbilityContext;
    new AppSettingsStore(context).load().then((settings) => {
      AppThemeController.apply(context, settings.themeMode);
      return windowStage.loadContent('pages/Index');
    }).then(() => {
      this.registerIconFonts(windowStage);
      RuntimeDiagnostics.run(context).catch(() => {});
      if (this.mediaProbeSmokeConfig.length > 0) {
        NetworkMediaProbeSmokeTest.run(context, this.mediaProbeSmokeConfig).catch(() => {});
      }
      if (this.proxySmokeConfig.length > 0) {
        NetworkProxySmokeTest.run(context, this.proxySmokeConfig).catch(() => {});
      }
      if (this.analysisBenchmarkConfig.length > 0) {
        AnalysisBenchmarkRunner.run(context, this.analysisBenchmarkConfig).catch(() => {});
      }
      LinkoraDatabase.shared(context).initialize().catch((error: BusinessError) => {
        console.error(`Failed to initialize the local database. code=${error.code}, message=${error.message}`);
      });
    }).catch((error: BusinessError) => {
      console.error(`Failed to initialize the main page. code=${error.code}, message=${error.message}`);
    });
  }

  onConfigurationUpdate(_configuration: Configuration): void {
    AppThemeController.refreshSystemBars(this.context as common.UIAbilityContext);
  }

  onBackground(): void {
    this.context.eventHub.emit(AppLifecycleEvents.BACKGROUND);
  }
}
