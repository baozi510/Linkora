import { NetworkMediaProbe, ProbeMode, ProbeStatus } from 'linkora_media_probe';
import { SystemAnalysisBackend, SystemAnalysisSnapshot } from './SystemMediaProbeAdapter';
import { AnalysisError, AnalysisErrorCode } from './AnalysisOperation';

/** Thin wrapper over the existing System stage; no new metadata extraction implementation. */
export class HarmonySystemAnalysisBackend implements SystemAnalysisBackend {
  private readonly probe: NetworkMediaProbe = new NetworkMediaProbe();
  async inspect(input: string): Promise<SystemAnalysisSnapshot> {
    const result = await this.probe.inspect(input, {}, { mode: ProbeMode.METADATA });
    if (result.status === ProbeStatus.CANCELLED) throw new AnalysisError(AnalysisErrorCode.CANCELLED);
    if (result.status === ProbeStatus.TIMEOUT) throw new AnalysisError(AnalysisErrorCode.TIMEOUT);
    if (result.status === ProbeStatus.UNAVAILABLE || result.errorCode !== 0) throw new AnalysisError(AnalysisErrorCode.SYSTEM_FAILED);
    return new SystemAnalysisSnapshot(result.durationMs, result.width, result.height);
  }
  cancel(): void { this.probe.cancel(); }
  close(): Promise<void> { return this.probe.close(); }
}
