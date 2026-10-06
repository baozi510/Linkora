import { IMediaProbe, MediaSource, MediaInfo, VideoTrackInfo, ProbeResult, ProbeRequirement, ProbeCompleteness,
  ProbeFieldOrigin, MediaProbeDiagnostics } from 'linkora_core';
import { MediaAnalysisInputResolver } from './MediaAnalysisInputResolver';
import { AnalysisLifecycle, AnalysisOperation, AnalysisError, AnalysisErrorCode } from './AnalysisOperation';
import { FfmpegMediaProbeAdapter } from './FfmpegMediaProbeAdapter';

export class SystemAnalysisSnapshot {
  readonly durationMs: number; readonly width: number; readonly height: number;
  constructor(durationMs: number, width: number, height: number) { this.durationMs = durationMs; this.width = width; this.height = height; }
}
export interface SystemAnalysisBackend {
  inspect(input: string): Promise<SystemAnalysisSnapshot>;
  cancel(): void;
  close(): Promise<void>;
}
export class SystemMediaProbeAdapter implements IMediaProbe {
  private readonly lifecycle: AnalysisLifecycle = new AnalysisLifecycle();
  private readonly resolver: MediaAnalysisInputResolver;
  private readonly factory: () => SystemAnalysisBackend;
  private readonly now: () => number;
  constructor(resolver: MediaAnalysisInputResolver, factory: () => SystemAnalysisBackend,
    now: () => number = () => Date.now()) {
    this.resolver = resolver; this.factory = factory; this.now = now;
  }
  name(): string { return 'system'; }
  async canProbe(source: MediaSource): Promise<boolean> { return !this.lifecycle.isClosed() && this.resolver.canResolve(source, 'system'); }
  async probe(source: MediaSource, requirement: ProbeRequirement): Promise<ProbeResult> {
    let operation: AnalysisOperation | null = null;
    try { operation = this.lifecycle.begin(); const result = await this.perform(source, requirement, operation); operation.check(); return result; }
    catch (error) { const failed = operation !== null ? operation.failure(error as Object, AnalysisErrorCode.SYSTEM_FAILED) : AnalysisError.from(error as Object, AnalysisErrorCode.SYSTEM_FAILED); return new ProbeResult(null, ProbeCompleteness.UNAVAILABLE, [],
      new MediaProbeDiagnostics('system', 0, 0, 0, 0, 0, ['error=' + failed.code]), failed.code); }
    finally { if (operation !== null) this.lifecycle.end(operation); }
  }
  private async perform(source: MediaSource, requirement: ProbeRequirement, operation: AnalysisOperation): Promise<ProbeResult> {
    const totalStarted: number = this.now();
    const prepareStarted: number = totalStarted;
    const lease = await this.resolver.resolve(source, 'system', operation);
    const prepareMs: number = this.now() - prepareStarted;
    let backend: SystemAnalysisBackend | null = null;
    try {
      backend = this.factory(); const currentBackend = backend;
      operation.onCancel(() => currentBackend.cancel()); operation.check();
      const probeStarted: number = this.now();
      const data = await backend.inspect(lease.input.uri); operation.check();
      const probeMs: number = this.now() - probeStarted;
      const duration = Number.isFinite(data.durationMs) && data.durationMs > 0 ? data.durationMs : 0;
      const width = Number.isFinite(data.width) && data.width > 0 ? data.width : 0;
      const height = Number.isFinite(data.height) && data.height > 0 ? data.height : 0;
      const useful = duration > 0 || width > 0 || height > 0;
      if (!useful) throw new AnalysisError(AnalysisErrorCode.SYSTEM_FAILED);
      const origins: ProbeFieldOrigin[] = [];
      if (duration > 0) origins.push(new ProbeFieldOrigin('durationMs', 'system'));
      if (width > 0) origins.push(new ProbeFieldOrigin('videoTracks.width', 'system'));
      if (height > 0) origins.push(new ProbeFieldOrigin('videoTracks.height', 'system'));
      const info = useful ? new MediaInfo('', duration, 0, 0,
        width > 0 || height > 0 ? [new VideoTrackInfo('primary', '', '', '', width, height)] : []) : null;
      const completeness = !useful ? ProbeCompleteness.UNAVAILABLE :
        requirement === ProbeRequirement.LIST && duration > 0 && width > 0 && height > 0 ? ProbeCompleteness.COMPLETE : ProbeCompleteness.PARTIAL;
      const totalMs: number = this.now() - totalStarted;
      return new ProbeResult(info, completeness, origins,
        FfmpegMediaProbeAdapter.diagnostics('system', lease, prepareMs, probeMs, totalMs));
    } finally { try { await backend?.close(); } finally { await lease.release(); } }
  }
  cancel(): void { this.lifecycle.cancel(); }
  close(): Promise<void> { return this.lifecycle.close(); }
}
