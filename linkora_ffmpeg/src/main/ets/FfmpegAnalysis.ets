import { NativeFfmpegApi, NativeProbeResult, NativeFrameResult, FfmpegError, FfmpegErrorCode } from './NativeModels';

export class FfmpegAnalysis {
  private static sequence: number = 0;
  private readonly active: Map<string, string> = new Map<string, string>();
  private closed: boolean = false;
  private readonly native: NativeFfmpegApi;
  constructor(native: NativeFfmpegApi) { this.native = native; }
  async probe(requestId: string, input: string, timeoutMs: number = 10000): Promise<NativeProbeResult> {
    const nativeId = this.begin(requestId);
    try { return await this.native.probe(nativeId, input, timeoutMs); }
    finally { this.active.delete(requestId); }
  }
  async extractFrame(requestId: string, input: string, timeMs: number,
    maxWidth: number = 480, maxHeight: number = 270, timeoutMs: number = 10000): Promise<NativeFrameResult> {
    const nativeId = this.begin(requestId);
    try { return await this.native.extractFrame(nativeId, input, timeMs, maxWidth, maxHeight, timeoutMs); }
    finally { this.active.delete(requestId); }
  }
  cancel(requestId: string): void {
    const nativeId = this.active.get(requestId);
    if (nativeId !== undefined) this.native.cancel(nativeId);
  }
  close(): void {
    if (this.closed) return;
    this.closed = true;
    this.active.forEach((id: string) => this.native.cancel(id));
  }
  private begin(id: string): string {
    if (this.closed) throw new FfmpegError(FfmpegErrorCode.CLOSED);
    if (id.length < 1 || id.length > 128 || !/^[A-Za-z0-9_-]+$/.test(id) || this.active.has(id)) {
      throw new FfmpegError(FfmpegErrorCode.INVALID_INPUT);
    }
    if (FfmpegAnalysis.sequence >= Number.MAX_SAFE_INTEGER) throw new FfmpegError(FfmpegErrorCode.INVALID_INPUT);
    const nativeId = 'q' + (++FfmpegAnalysis.sequence).toString();
    this.active.set(id, nativeId);
    return nativeId;
  }
}
