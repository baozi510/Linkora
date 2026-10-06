import { IMediaProbe, MediaSource, MediaInfo, ProbeResult, ProbeRequirement, ProbeCompleteness,
  MediaProbeDiagnostics } from 'linkora_core';
import { FfmpegAnalysis, FfmpegMediaInfoMapper } from 'linkora_ffmpeg';
import { MediaAnalysisInputResolver, AnalysisInputLease } from './MediaAnalysisInputResolver';
import { AnalysisLifecycle, AnalysisOperation, AnalysisError } from './AnalysisOperation';
import { systemDateTime } from '@kit.BasicServicesKit';

export class FfmpegMediaProbeAdapter implements IMediaProbe {
  private readonly lifecycle: AnalysisLifecycle = new AnalysisLifecycle();
  private readonly resolver: MediaAnalysisInputResolver;
  private readonly analysis: FfmpegAnalysis;
  private readonly timeoutMs: number;
  constructor(resolver: MediaAnalysisInputResolver, analysis: FfmpegAnalysis, timeoutMs: number = 10000) {
    this.resolver = resolver; this.analysis = analysis; this.timeoutMs = timeoutMs;
  }
  name(): string { return 'ffmpeg'; }
  async canProbe(source: MediaSource): Promise<boolean> { return !this.lifecycle.isClosed() && this.resolver.canResolve(source, 'ffmpeg'); }
  async probe(source: MediaSource, requirement: ProbeRequirement): Promise<ProbeResult> {
    let operation: AnalysisOperation | null = null;
    try { operation = this.lifecycle.begin(); const result = await this.perform(source, requirement, operation); operation.check(); return result; }
    catch (error) { const failed = operation !== null ? operation.failure(error as Object) : AnalysisError.from(error as Object); return new ProbeResult(null, ProbeCompleteness.UNAVAILABLE, [],
      new MediaProbeDiagnostics('ffmpeg', 0, 0, 0, 0, 0, ['error=' + failed.code]), failed.code); }
    finally { if (operation !== null) this.lifecycle.end(operation); }
  }
  private async perform(source: MediaSource, requirement: ProbeRequirement, operation: AnalysisOperation): Promise<ProbeResult> {
    const totalStarted: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
    const prepareStarted: number = totalStarted;
    const lease = await this.resolver.resolve(source, 'ffmpeg', operation);
    const prepareMs: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP) - prepareStarted;
    try {
      operation.onCancel(() => this.analysis.cancel(operation.id)); operation.check();
      const probeStarted: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
      const native = await this.analysis.probe(operation.id, lease.input.uri, this.timeoutMs); operation.check();
      const probeMs: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP) - probeStarted;
      const mapped = FfmpegMediaInfoMapper.map(native);
      const totalMs: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP) - totalStarted;
      return new ProbeResult(mapped.info, FfmpegMediaProbeAdapter.completeness(mapped.info, requirement), mapped.fieldOrigins,
        FfmpegMediaProbeAdapter.diagnostics('ffmpeg', lease, prepareMs, probeMs, totalMs));
    } finally { await lease.release(); }
  }
  static completeness(info: MediaInfo, requirement: ProbeRequirement): ProbeCompleteness {
    const useful = info.durationMs > 0 || info.videoTracks.length + info.audioTracks.length + info.subtitleTracks.length > 0;
    if (!useful) return ProbeCompleteness.UNAVAILABLE;
    const dimensions = info.videoTracks.every((v) => v.width > 0 && v.height > 0);
    const basic = info.durationMs > 0 && dimensions;
    if (requirement === ProbeRequirement.LIST) return basic ? ProbeCompleteness.COMPLETE : ProbeCompleteness.PARTIAL;
    const structure = info.container.length > 0 && dimensions &&
      info.videoTracks.every((v) => v.codec.length > 0) && info.audioTracks.every((a) => a.codec.length > 0 && a.channels > 0 && a.sampleRate > 0) &&
      info.subtitleTracks.every((s) => s.codec.length > 0 && s.kind !== 'unknown');
    const advanced = structure && basic && info.videoTracks.every((v) => v.bitDepth > 0 && v.frameRate > 0);
    return (requirement === ProbeRequirement.DETAIL ? structure : advanced) ? ProbeCompleteness.COMPLETE : ProbeCompleteness.PARTIAL;
  }
  static diagnostics(engine: string, lease: AnalysisInputLease, prepareMs: number = 0,
    probeMs: number = 0, totalMs: number = 0): MediaProbeDiagnostics {
    // rangeRequests is measured by NetworkFileProxy in the benchmark runner. Source reads remain a separate metric.
    return new MediaProbeDiagnostics(engine, prepareMs, probeMs, totalMs, lease.access.bytesRead, 0,
      ['access=' + lease.access.semantics(), 'source_reads=' + lease.access.readRequests]);
  }
  cancel(): void { this.lifecycle.cancel(); }
  async close(): Promise<void> { await this.lifecycle.close(); this.analysis.close(); }
}
