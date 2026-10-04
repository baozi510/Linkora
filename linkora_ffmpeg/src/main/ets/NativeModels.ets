export class NativeVideoStream {
  index: number = 0; id: number = 0; codec: string = ''; profile: string = ''; level: number = 0;
  width: number = 0; height: number = 0; frameRate: number = 0; bitrate: number = 0;
  pixelFormat: string = ''; bitDepth: number = 0; colorPrimaries: string = ''; transfer: string = '';
  colorSpace: string = ''; dolbyVisionProfile: number = 0;
  hasDolbyVisionConfiguration: boolean = false;
  language: string = ''; title: string = ''; isDefault: boolean = false;
}
export class NativeAudioStream {
  index: number = 0; id: number = 0; codec: string = ''; profile: string = '';
  channels: number = 0; channelLayout: string = ''; sampleRate: number = 0; bitrate: number = 0;
  language: string = ''; title: string = ''; isDefault: boolean = false;
}
export class NativeSubtitleStream {
  index: number = 0; id: number = 0; codec: string = ''; kind: string = 'unknown';
  language: string = ''; title: string = ''; isDefault: boolean = false; isForced: boolean = false;
}
export class NativeChapter {
  startMs: number = 0; endMs: number = 0; title: string = '';
}
export class NativeProbeResult {
  container: string = ''; durationMs: number = 0; bitrate: number = 0; sizeBytes: number = 0;
  video: NativeVideoStream[] = []; audio: NativeAudioStream[] = [];
  subtitles: NativeSubtitleStream[] = []; chapters: NativeChapter[] = [];
  tags: Record<string, string> = {};
}
export class NativeFrameResult {
  width: number = 0; height: number = 0; pixelFormat: string = 'rgba_8888';
  timeMs: number = 0; pixels: ArrayBuffer = new ArrayBuffer(0);
}
export interface NativeFfmpegApi {
  probe(requestId: string, input: string, timeoutMs: number): Promise<NativeProbeResult>;
  extractFrame(requestId: string, input: string, timeMs: number, maxWidth: number,
    maxHeight: number, timeoutMs: number): Promise<NativeFrameResult>;
  cancel(requestId: string): void;
}
export enum FfmpegErrorCode {
  INVALID_INPUT = 'FF_INVALID_INPUT', OPEN_FAILED = 'FF_OPEN_FAILED',
  STREAM_INFO_FAILED = 'FF_STREAM_INFO_FAILED', NO_VIDEO = 'FF_NO_VIDEO',
  DECODER_UNAVAILABLE = 'FF_DECODER_UNAVAILABLE', DECODE_FAILED = 'FF_DECODE_FAILED',
  TIMEOUT = 'FF_TIMEOUT', CANCELLED = 'FF_CANCELLED', SIZE_REJECTED = 'FF_SIZE_REJECTED',
  RELEASED = 'FF_RELEASED', CLOSED = 'FF_CLOSED'
}
export class FfmpegError extends Error {
  readonly code: FfmpegErrorCode;
  readonly detail: string;
  constructor(code: FfmpegErrorCode, detail: string = '') {
    super(code); this.code = code; this.detail = detail.slice(0, 256);
  }
}
