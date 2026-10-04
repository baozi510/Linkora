import { common, Want } from '@kit.AbilityKit';
import { FfmpegRuntimeSmoke } from './ets/diagnostics/FfmpegRuntimeSmoke';
import { AnalyzerIntegrationSmoke } from './ets/diagnostics/AnalyzerIntegrationSmoke';

export class RuntimeDiagnostics {
  private static endpoint: string = '';
  private static analysisEndpoint: string = '';
  static configure(want: Want): void {
    const analysis = want.parameters?.linkoraAnalyzerSmoke;
    if (typeof analysis === 'string' && /^http:\/\/10\.0\.2\.2:19333\/[a-f0-9-]{36}$/.test(analysis)) {
      RuntimeDiagnostics.analysisEndpoint = analysis;
    }
    const value = want.parameters?.linkoraFfmpegSmoke;
    if (typeof value === 'string' && /^http:\/\/10\.0\.2\.2:19333\/[a-f0-9-]{36}$/.test(value)) {
      RuntimeDiagnostics.endpoint = value;
    }
  }
  static async run(context: common.UIAbilityContext): Promise<void> {
    if (RuntimeDiagnostics.analysisEndpoint.length > 0) {
      const endpoint = RuntimeDiagnostics.analysisEndpoint; RuntimeDiagnostics.analysisEndpoint = '';
      await AnalyzerIntegrationSmoke.run(context, endpoint); return;
    }
    if (RuntimeDiagnostics.endpoint.length === 0) return;
    const endpoint = RuntimeDiagnostics.endpoint; RuntimeDiagnostics.endpoint = '';
    await FfmpegRuntimeSmoke.run(context, endpoint);
  }
}
