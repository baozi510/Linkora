import { image } from '@kit.ImageKit';
import {
  MediaSource,
  ThumbnailExtractRequest
} from 'linkora_core';
import {
  MediaProbeResult,
  NetworkMediaProbe,
  ProbeMode,
  ProbeStatus,
  ProbeThumbnailPlan
} from 'linkora_media_probe';
import { MediaAnalysisInputResolver } from './MediaAnalysisInputResolver';
import {
  AnalysisLifecycle,
  AnalysisOperation
} from './AnalysisOperation';

/** Thin production fallback over the existing System thumbnail implementation. */
export class SystemThumbnailFallback {
  private readonly lifecycle: AnalysisLifecycle = new AnalysisLifecycle();
  private readonly resolver: MediaAnalysisInputResolver;

  constructor(resolver: MediaAnalysisInputResolver) {
    this.resolver = resolver;
  }

  async canExtract(source: MediaSource): Promise<boolean> {
    return !this.lifecycle.isClosed() && this.resolver.canResolve(source, 'system');
  }

  async extract(source: MediaSource, request: ThumbnailExtractRequest,
    durationHintMs: number = 0, widthHint: number = 0, heightHint: number = 0): Promise<image.PixelMap | null> {
    let operation: AnalysisOperation | null = null;
    let probe: NetworkMediaProbe | null = null;
    let frame: image.PixelMap | null = null;

    try {
      operation = this.lifecycle.begin();
      const lease = await this.resolver.resolve(source, 'system', operation);
      try {
        probe = new NetworkMediaProbe();
        const currentProbe: NetworkMediaProbe = probe;
        operation.onCancel(() => currentProbe.cancel());
        const result: MediaProbeResult = await probe.inspect(lease.input.uri, {}, {
          mode: ProbeMode.THUMBNAIL,
          durationHintMs,
          widthHint,
          heightHint,
          thumbnailPlan: (): ProbeThumbnailPlan => ({
            timeMs: request.timeMs,
            width: request.maxWidth,
            height: request.maxHeight
          })
        });
        operation.check();
        if (result.status !== ProbeStatus.COMPLETE || result.thumbnail === null) return null;
        frame = result.thumbnail;
        return frame;
      } finally {
        try { await probe?.close(); }
        finally { await lease.release(); }
      }
    } catch (_error) {
      if (frame !== null) await frame.release().catch(() => {});
      return null;
    } finally {
      if (operation !== null) this.lifecycle.end(operation);
    }
  }

  cancel(): void {
    this.lifecycle.cancel();
  }

  close(): Promise<void> {
    return this.lifecycle.close();
  }
}
