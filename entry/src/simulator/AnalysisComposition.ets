import { createFfmpegAnalysis } from 'linkora_ffmpeg/Native';
import { MediaAnalysisInputResolver } from '../main/ets/analysis/MediaAnalysisInputResolver';
import { FfmpegMediaProbeAdapter } from '../main/ets/analysis/FfmpegMediaProbeAdapter';
import { FfmpegThumbnailExtractorAdapter } from '../main/ets/analysis/FfmpegThumbnailExtractorAdapter';
import { SystemMediaProbeAdapter } from '../main/ets/analysis/SystemMediaProbeAdapter';
import { HarmonySystemAnalysisBackend } from '../main/ets/analysis/HarmonySystemAnalysisBackend';

/** Available integration plugin. Production loaders do not select these factories. */
export class AnalysisComposition {
  static ffmpeg(resolver: MediaAnalysisInputResolver, timeoutMs: number = 10000): FfmpegMediaProbeAdapter {
    return new FfmpegMediaProbeAdapter(resolver, createFfmpegAnalysis(), timeoutMs);
  }
  static system(resolver: MediaAnalysisInputResolver): SystemMediaProbeAdapter {
    return new SystemMediaProbeAdapter(resolver, () => new HarmonySystemAnalysisBackend());
  }
  static thumbnail(resolver: MediaAnalysisInputResolver, timeoutMs: number = 10000): FfmpegThumbnailExtractorAdapter {
    return new FfmpegThumbnailExtractorAdapter(resolver, createFfmpegAnalysis(), timeoutMs);
  }
}
