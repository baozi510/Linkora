import { IThumbnailExtractor, MediaSource, ThumbnailExtractRequest, RawThumbnail } from 'linkora_core';
import { FfmpegAnalysis, FfmpegRawThumbnail } from 'linkora_ffmpeg';
import { MediaAnalysisInputResolver } from './MediaAnalysisInputResolver';
import { AnalysisLifecycle, AnalysisOperation, AnalysisError } from './AnalysisOperation';

export class FfmpegThumbnailExtractorAdapter implements IThumbnailExtractor {
  private readonly lifecycle: AnalysisLifecycle = new AnalysisLifecycle();
  private readonly resolver: MediaAnalysisInputResolver;
  private readonly analysis: FfmpegAnalysis;
  private readonly timeoutMs: number;
  constructor(resolver: MediaAnalysisInputResolver, analysis: FfmpegAnalysis, timeoutMs: number = 10000) {
    this.resolver = resolver; this.analysis = analysis; this.timeoutMs = timeoutMs;
  }
  name(): string { return 'ffmpeg'; }
  async canExtract(source: MediaSource): Promise<boolean> { return !this.lifecycle.isClosed() && this.resolver.canResolve(source, 'ffmpeg'); }
  async extract(source: MediaSource, request: ThumbnailExtractRequest): Promise<RawThumbnail | null> {
    let operation: AnalysisOperation | null = null;
    try {
      operation = this.lifecycle.begin(); const raw = await this.perform(source, request, operation);
      try { operation.check(); } catch (error) { await raw.release(); throw AnalysisError.from(error as Object); }
      return raw;
    }
    catch (error) { throw operation !== null ? operation.failure(error as Object) : AnalysisError.from(error as Object); }
    finally { if (operation !== null) this.lifecycle.end(operation); }
  }
  private async perform(source: MediaSource, request: ThumbnailExtractRequest, operation: AnalysisOperation): Promise<RawThumbnail> {
    const lease = await this.resolver.resolve(source, 'ffmpeg', operation);
    let raw: FfmpegRawThumbnail | null = null;
    try {
      operation.onCancel(() => this.analysis.cancel(operation.id)); operation.check();
      const frame = await this.analysis.extractFrame(operation.id, lease.input.uri, request.timeMs, request.maxWidth, request.maxHeight, this.timeoutMs);
      operation.check(); raw = new FfmpegRawThumbnail(frame); return raw;
    } finally {
      try { await lease.release(); } catch (error) { await raw?.release(); throw AnalysisError.from(error as Object); }
    }
  }
  cancel(): void { this.lifecycle.cancel(); }
  async close(): Promise<void> { await this.lifecycle.close(); this.analysis.close(); }
}
