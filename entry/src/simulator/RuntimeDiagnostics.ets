import { common, Want } from '@kit.AbilityKit';
import { FfmpegRuntimeSmoke } from './ets/diagnostics/FfmpegRuntimeSmoke';

export class RuntimeDiagnostics {
  private static endpoint: string = '';
  static configure(want: Want): void {
    const value = want.parameters?.linkoraFfmpegSmoke;
    if (typeof value === 'string' && /^http:\/\/10\.0\.2\.2:19333\/[a-f0-9-]{36}$/.test(value)) {
      RuntimeDiagnostics.endpoint = value;
    }
  }
  static async run(context: common.UIAbilityContext): Promise<void> {
    if (RuntimeDiagnostics.endpoint.length === 0) return;
    const endpoint = RuntimeDiagnostics.endpoint; RuntimeDiagnostics.endpoint = '';
    await FfmpegRuntimeSmoke.run(context, endpoint);
  }
}
