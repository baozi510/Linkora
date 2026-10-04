import { ProbeResult, ProbeCompleteness, HdrType } from 'linkora_core';

export enum AnalysisDifferenceKind {
  MATCH = 'MATCH', SYSTEM_MISSING = 'SYSTEM_MISSING', FFMPEG_MISSING = 'FFMPEG_MISSING',
  VALUE_DIFFERENCE = 'VALUE_DIFFERENCE', ENGINE_UNAVAILABLE = 'ENGINE_UNAVAILABLE'
}
export class AnalysisEngineSummary {
  readonly success: boolean; readonly errorCode: number; readonly completeness: ProbeCompleteness;
  readonly fields: Record<string, string>; readonly access: string;
  constructor(result: ProbeResult) {
    this.success = result.isUsable() && result.errorCode === 0; this.errorCode = result.errorCode; this.completeness = result.completeness;
    this.fields = {}; this.access = result.diagnostics.notes.find((note) => note.startsWith('access='))?.substring(7) ?? 'unavailable';
    const info = result.info; if (info === null) return;
    this.fields['durationMs'] = info.durationMs > 0 ? '' + info.durationMs : '';
    this.fields['container'] = info.container;
    const video = info.videoTracks[0]; const audio = info.audioTracks[0];
    this.fields['width'] = video?.width > 0 ? '' + video.width : '';
    this.fields['height'] = video?.height > 0 ? '' + video.height : '';
    this.fields['videoCodec'] = video?.codec ?? ''; this.fields['videoProfile'] = video?.profile ?? '';
    this.fields['bitDepth'] = video?.bitDepth > 0 ? '' + video.bitDepth : '';
    this.fields['hdr'] = video !== undefined && video.hdrType !== HdrType.UNKNOWN ? video.hdrType : '';
    this.fields['audioCodec'] = audio?.codec ?? ''; this.fields['audioChannels'] = audio?.channels > 0 ? '' + audio.channels : '';
    // Current System stage does not enumerate streams. Empty arrays are unclaimed, not true zero counts.
    for (const kind of ['video', 'audio', 'subtitle']) {
      const claimed = result.fieldOrigins.some((origin) => origin.field === kind + 'Tracks') || result.diagnostics.engine === 'ffmpeg';
      const count = kind === 'video' ? info.videoTracks.length : kind === 'audio' ? info.audioTracks.length : info.subtitleTracks.length;
      this.fields[kind + 'Count'] = claimed ? '' + count : '';
    }
  }
}
export class AnalysisDifference {
  readonly field: string; readonly kind: AnalysisDifferenceKind;
  constructor(field: string, kind: AnalysisDifferenceKind) { this.field = field; this.kind = kind; }
}
export class MediaAnalysisComparison {
  readonly system: AnalysisEngineSummary; readonly ffmpeg: AnalysisEngineSummary; readonly differences: AnalysisDifference[];
  constructor(system: AnalysisEngineSummary, ffmpeg: AnalysisEngineSummary, differences: AnalysisDifference[]) {
    this.system = system; this.ffmpeg = ffmpeg; this.differences = differences;
  }
  static compare(system: ProbeResult, ffmpeg: ProbeResult): MediaAnalysisComparison {
    const left = new AnalysisEngineSummary(system); const right = new AnalysisEngineSummary(ffmpeg); const differences: AnalysisDifference[] = [];
    if (!left.success || !right.success) differences.push(new AnalysisDifference('engine', AnalysisDifferenceKind.ENGINE_UNAVAILABLE));
    for (const field of ['durationMs', 'width', 'height', 'container', 'videoCount', 'audioCount', 'subtitleCount',
      'videoCodec', 'videoProfile', 'bitDepth', 'hdr', 'audioCodec', 'audioChannels']) {
      const a = left.fields[field] ?? ''; const b = right.fields[field] ?? '';
      const kind = !left.success || !right.success ? AnalysisDifferenceKind.ENGINE_UNAVAILABLE :
        a === b ? AnalysisDifferenceKind.MATCH : a.length === 0 ? AnalysisDifferenceKind.SYSTEM_MISSING :
          b.length === 0 ? AnalysisDifferenceKind.FFMPEG_MISSING : AnalysisDifferenceKind.VALUE_DIFFERENCE;
      differences.push(new AnalysisDifference(field, kind));
    }
    return new MediaAnalysisComparison(left, right, differences);
  }
}
