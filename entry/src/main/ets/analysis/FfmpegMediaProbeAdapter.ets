import { IMediaProbe, MediaSource, MediaInfo, ProbeResult, ProbeRequirement, ProbeCompleteness,
  MediaProbeDiagnostics } from 'linkora_core';
import { FfmpegAnalysis, FfmpegMediaInfoMapper } from 'linkora_ffmpeg';
import { MediaAnalysisInputResolver, AnalysisInputLease } from './MediaAnalysisInputResolver';
import { AnalysisLifecycle, AnalysisOperation, AnalysisError } from './AnalysisOperation';

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
    try { operation = this.lifecycle.begin(); return await this.perform(source, requirement, operation); }
    catch (error) { const failed = AnalysisError.from(error as Object); return new ProbeResult(null, ProbeCompleteness.UNAVAILABLE, [],
      new MediaProbeDiagnostics('ffmpeg', 0, 0, 0, 0, 0, ['error=' + failed.code]), failed.code); }
    finally { if (operation !== null) this.lifecycle.end(operation); }
  }
  private async perform(source: MediaSource, requirement: ProbeRequirement, operation: AnalysisOperation): Promise<ProbeResult> {
    const lease = await this.resolver.resolve(source, 'ffmpeg', operation);
    try {
      operation.onCancel(() => this.analysis.cancel(operation.id)); operation.check();
      const native = await this.analysis.probe(operation.id, lease.input.uri, this.timeoutMs); operation.check();
      const mapped = FfmpegMediaInfoMapper.map(native);
      return new ProbeResult(mapped.info, FfmpegMediaProbeAdapter.completeness(mapped.info, requirement), mapped.fieldOrigins,
        FfmpegMediaProbeAdapter.diagnostics('ffmpeg', lease));
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
  static diagnostics(engine: string, lease: AnalysisInputLease): MediaProbeDiagnostics {
    // Source reads are not proxy HTTP request counts. Existing timing fields remain zero and are not compared.
    return new MediaProbeDiagnostics(engine, 0, 0, 0, lease.access.bytesRead, 0,
      ['access=' + lease.access.semantics(), 'source_reads=' + lease.access.readRequests]);
  }
  cancel(): void { this.lifecycle.cancel(); }
  async close(): Promise<void> { await this.lifecycle.close(); this.analysis.close(); }
}
