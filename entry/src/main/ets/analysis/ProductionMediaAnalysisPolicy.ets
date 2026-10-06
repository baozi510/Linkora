import {
  MediaFormat,
  MediaSource,
  MediaSourceKind,
  ProbeRequirement
} from 'linkora_core';

export enum ProductionAnalysisEngine {
  SYSTEM = 'system',
  FFMPEG = 'ffmpeg'
}

/**
 * Functional routing only. Performance-based selection is intentionally deferred
 * to arm64 device validation.
 */
export class ProductionMediaAnalysisPolicy {
  probeOrder(source: MediaSource, requirement: ProbeRequirement): ProductionAnalysisEngine[] {
    if (this.systemOnly(source)) {
      return [ProductionAnalysisEngine.SYSTEM];
    }
    if (requirement === ProbeRequirement.LIST) {
      return [ProductionAnalysisEngine.SYSTEM, ProductionAnalysisEngine.FFMPEG];
    }
    return [ProductionAnalysisEngine.FFMPEG, ProductionAnalysisEngine.SYSTEM];
  }

  thumbnailOrder(source: MediaSource): ProductionAnalysisEngine[] {
    return this.systemOnly(source) ?
      [ProductionAnalysisEngine.SYSTEM] :
      [ProductionAnalysisEngine.FFMPEG, ProductionAnalysisEngine.SYSTEM];
  }

  private systemOnly(source: MediaSource): boolean {
    return source.kind === MediaSourceKind.LOCAL_DOCUMENT ||
      source.format === MediaFormat.HLS ||
      source.format === MediaFormat.DASH;
  }
}
