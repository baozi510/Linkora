interface NativeVideoStream {
  index: number; id: number; codec: string; profile: string; level: number;
  width: number; height: number; frameRate: number; bitrate: number; pixelFormat: string;
  bitDepth: number; colorPrimaries: string; transfer: string; colorSpace: string;
  dolbyVisionProfile: number; language: string; title: string; isDefault: boolean;
  hasDolbyVisionConfiguration: boolean;
}
interface NativeAudioStream {
  index: number; id: number; codec: string; profile: string; channels: number;
  channelLayout: string; sampleRate: number; bitrate: number; language: string;
  title: string; isDefault: boolean;
}
interface NativeSubtitleStream {
  index: number; id: number; codec: string; kind: string; language: string;
  title: string; isDefault: boolean; isForced: boolean;
}
interface NativeChapter { startMs: number; endMs: number; title: string; }
interface NativeProbeResult {
  container: string; durationMs: number; bitrate: number; sizeBytes: number;
  video: NativeVideoStream[]; audio: NativeAudioStream[]; subtitles: NativeSubtitleStream[];
  chapters: NativeChapter[]; tags: Record<string, string>;
}
interface NativeFrameResult {
  width: number; height: number; pixelFormat: string; timeMs: number; pixels: ArrayBuffer;
}
interface NativeFfmpegApi {
  probe(id: string, input: string, timeoutMs: number): Promise<NativeProbeResult>;
  extractFrame(id: string, input: string, timeMs: number, maxWidth: number,
    maxHeight: number, timeoutMs: number): Promise<NativeFrameResult>;
  cancel(id: string): void;
}
declare const native: NativeFfmpegApi;
export default native;
