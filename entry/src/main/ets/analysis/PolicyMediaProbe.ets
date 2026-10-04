import {
  IMediaProbe,
  MediaSource,
  ProbeCompleteness,
  ProbeRequirement,
  ProbeResult
} from 'linkora_core';
import { AnalysisErrorCode } from './AnalysisOperation';
import {
  ProductionAnalysisEngine,
  ProductionMediaAnalysisPolicy
} from './ProductionMediaAnalysisPolicy';

/**
 * Selects a complete result when possible and performs at most one engine fallback.
 * It never merges fields from different engines.
 */
export class PolicyMediaProbe implements IMediaProbe {
  private readonly system: IMediaProbe;
  private readonly ffmpeg: IMediaProbe;
  private readonly policy: ProductionMediaAnalysisPolicy;
  private closed: boolean = false;
  private cancellationGeneration: number = 0;

  constructor(system: IMediaProbe, ffmpeg: IMediaProbe,
    policy: ProductionMediaAnalysisPolicy = new ProductionMediaAnalysisPolicy()) {
    this.system = system;
    this.ffmpeg = ffmpeg;
    this.policy = policy;
  }

  name(): string {
    return 'policy';
  }

  async canProbe(source: MediaSource): Promise<boolean> {
    if (this.closed) return false;
    const order: ProductionAnalysisEngine[] =
      this.policy.probeOrder(source, ProbeRequirement.LIST);
    for (const engine of order) {
      if (await this.adapter(engine).canProbe(source)) return true;
    }
    return false;
  }

  async probe(source: MediaSource, requirement: ProbeRequirement): Promise<ProbeResult> {
    if (this.closed) {
      return new ProbeResult(null, ProbeCompleteness.UNAVAILABLE);
    }

    const generation: number = this.cancellationGeneration;
    const order: ProductionAnalysisEngine[] = this.policy.probeOrder(source, requirement);
    let best: ProbeResult | null = null;

    for (let index: number = 0; index < order.length; index++) {
      if (generation !== this.cancellationGeneration || this.closed) {
        return new ProbeResult(null, ProbeCompleteness.UNAVAILABLE, [], undefined,
          AnalysisErrorCode.CANCELLED);
      }
      const adapter: IMediaProbe = this.adapter(order[index]);
      if (!await adapter.canProbe(source)) continue;

      const result: ProbeResult = await adapter.probe(source, requirement);
      if (generation !== this.cancellationGeneration || this.closed) {
        return new ProbeResult(null, ProbeCompleteness.UNAVAILABLE, [], undefined,
          AnalysisErrorCode.CANCELLED);
      }
      if (result.completeness === ProbeCompleteness.COMPLETE) return result;

      if (result.isUsable()) {
        if (best === null) best = result;
        // FFmpeg is already the richer primary for DETAIL/ADVANCED. A System
        // fallback cannot enrich a usable partial FFmpeg result without merging.
        if (order[index] === ProductionAnalysisEngine.FFMPEG &&
          requirement !== ProbeRequirement.LIST) {
          return result;
        }
      }
    }

    return best ?? new ProbeResult(null, ProbeCompleteness.UNAVAILABLE);
  }

  cancel(): void {
    this.cancellationGeneration++;
    this.system.cancel();
    this.ffmpeg.cancel();
  }

  async close(): Promise<void> {
    if (this.closed) return;
    this.closed = true;
    this.cancel();
    await Promise.allSettled([this.system.close(), this.ffmpeg.close()]);
  }

  private adapter(engine: ProductionAnalysisEngine): IMediaProbe {
    return engine === ProductionAnalysisEngine.FFMPEG ? this.ffmpeg : this.system;
  }
}
