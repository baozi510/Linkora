import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import {
  DefaultThumbnailTimePolicy,
  IMediaProbe,
  IThumbnailExtractor,
  MediaInfo,
  MediaSource,
  ProbeRequirement,
  ProbeResult,
  RawThumbnail,
  ThumbnailExtractRequest,
  ThumbnailPlan
} from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { AnalysisComposition } from 'entry/AnalysisComposition';
import { HarmonyAnalysisInputs } from './HarmonyAnalysisInputs';
import { MediaAnalysisInputResolver } from './MediaAnalysisInputResolver';
import { PolicyMediaProbe } from './PolicyMediaProbe';
import {
  ProductionAnalysisEngine,
  ProductionMediaAnalysisPolicy
} from './ProductionMediaAnalysisPolicy';
import { SystemThumbnailFallback } from './SystemThumbnailFallback';
import { SystemWebPEncoder } from '../services/SystemWebPEncoder';

export class NetworkMediaAnalysisResult {
  readonly durationMs: number;
  readonly width: number;
  readonly height: number;
  readonly encodedThumbnail: ArrayBuffer | null;
  readonly metadataEngine: string;
  readonly thumbnailEngine: string;

  constructor(durationMs: number, width: number, height: number,
    encodedThumbnail: ArrayBuffer | null, metadataEngine: string = '',
    thumbnailEngine: string = '') {
    this.durationMs = Math.max(0, durationMs);
    this.width = Math.max(0, width);
    this.height = Math.max(0, height);
    this.encodedThumbnail = encodedThumbnail;
    this.metadataEngine = metadataEngine;
    this.thumbnailEngine = thumbnailEngine;
  }
}

/**
 * Production functional policy for network file analysis.
 * No field merger and no performance-based routing.
 */
export class NetworkMediaAnalysisCoordinator {
  private readonly policy: ProductionMediaAnalysisPolicy = new ProductionMediaAnalysisPolicy();
  private readonly probe: PolicyMediaProbe;
  private readonly ffmpegThumbnail: IThumbnailExtractor;
  private readonly systemThumbnail: SystemThumbnailFallback;
  private readonly encoder: SystemWebPEncoder = new SystemWebPEncoder();
  private readonly thumbnailPolicy: DefaultThumbnailTimePolicy = new DefaultThumbnailTimePolicy();
  private closed: boolean = false;
  private cancellationGeneration: number = 0;

  constructor(context: common.UIAbilityContext, proxy: NetworkFileProxy) {
    const resolver = new MediaAnalysisInputResolver(new HarmonyAnalysisInputs(context, proxy));
    this.probe = new PolicyMediaProbe(
      AnalysisComposition.system(resolver),
      AnalysisComposition.ffmpeg(resolver),
      this.policy
    );
    this.ffmpegThumbnail = AnalysisComposition.thumbnail(resolver);
    this.systemThumbnail = new SystemThumbnailFallback(resolver);
  }

  async inspect(source: MediaSource, durationHintMs: number = 0,
    widthHint: number = 0, heightHint: number = 0,
    onMetadata: (durationMs: number, width: number, height: number, engine: string) => void = () => {}):
    Promise<NetworkMediaAnalysisResult> {
    if (this.closed) return new NetworkMediaAnalysisResult(
      durationHintMs, widthHint, heightHint, null);
    const generation: number = this.cancellationGeneration;

    let durationMs: number = Math.max(0, durationHintMs);
    let width: number = Math.max(0, widthHint);
    let height: number = Math.max(0, heightHint);
    let metadataEngine: string = '';

    if (durationMs <= 0 || width <= 0 || height <= 0) {
      const result: ProbeResult = await this.probe.probe(source, ProbeRequirement.LIST);
      if (generation !== this.cancellationGeneration || this.closed) {
        return new NetworkMediaAnalysisResult(durationMs, width, height, null);
      }
      if (result.info !== null && result.isUsable()) {
        const values = this.basic(result.info);
        durationMs = values.durationMs || durationMs;
        width = values.width || width;
        height = values.height || height;
        metadataEngine = result.diagnostics.engine;
        onMetadata(durationMs, width, height, metadataEngine);
      }
    }

    const plan: ThumbnailPlan = this.thumbnailPolicy.plan(durationMs, width, height);
    const request = new ThumbnailExtractRequest(plan.timeMs, plan.width, plan.height);
    let encoded: ArrayBuffer | null = null;
    let thumbnailEngine: string = '';

    for (const engine of this.policy.thumbnailOrder(source)) {
      if (generation !== this.cancellationGeneration || this.closed) break;
      if (engine === ProductionAnalysisEngine.FFMPEG) {
        if (!await this.ffmpegThumbnail.canExtract(source)) continue;
        let raw: RawThumbnail | null = null;
        try {
          raw = await this.ffmpegThumbnail.extract(source, request);
          if (generation !== this.cancellationGeneration || this.closed) break;
          if (raw !== null) {
            encoded = await this.encoder.encodeRaw(raw, plan.quality);
            thumbnailEngine = 'ffmpeg';
          }
        } catch (_error) {
          encoded = null;
        } finally {
          await raw?.release().catch(() => {});
        }
      } else {
        if (!await this.systemThumbnail.canExtract(source)) continue;
        const frame: image.PixelMap | null =
          await this.systemThumbnail.extract(source, request, durationMs, width, height);
        if (generation !== this.cancellationGeneration || this.closed) {
          await frame?.release().catch(() => {});
          break;
        }
        if (frame !== null) {
          try {
            encoded = await this.encoder.encode(frame, plan.quality);
            thumbnailEngine = 'system';
          } catch (_error) {
            encoded = null;
          } finally {
            await frame.release().catch(() => {});
          }
        }
      }
      if (encoded !== null) break;
    }

    return new NetworkMediaAnalysisResult(
      durationMs, width, height, encoded, metadataEngine, thumbnailEngine);
  }

  cancel(): void {
    this.cancellationGeneration++;
    this.probe.cancel();
    this.ffmpegThumbnail.cancel();
    this.systemThumbnail.cancel();
  }

  async close(): Promise<void> {
    if (this.closed) return;
    this.closed = true;
    this.cancel();
    await Promise.allSettled([
      this.probe.close(),
      this.ffmpegThumbnail.close(),
      this.systemThumbnail.close()
    ]);
  }

  private basic(info: MediaInfo): { durationMs: number; width: number; height: number } {
    let width: number = 0;
    let height: number = 0;
    const primary = info.videoTracks.find((track) => track.isDefault) ?? info.videoTracks[0];
    if (primary !== undefined) {
      width = primary.width;
      height = primary.height;
    }
    return { durationMs: info.durationMs, width, height };
  }
}
