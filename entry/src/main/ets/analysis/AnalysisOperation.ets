export enum AnalysisErrorCode {
  UNSUPPORTED = 21001, RESOLVE_FAILED = 21002, CLOSED = 21003, BUSY = 21004,
  CANCELLED = 21005, TIMEOUT = 21006, FAILED = 21007, SYSTEM_FAILED = 22001,
  INVALID_INPUT = 23001, OPEN_FAILED = 23002, STREAM_INFO_FAILED = 23003,
  NO_VIDEO = 23004, DECODER_UNAVAILABLE = 23005, DECODE_FAILED = 23006,
  SIZE_REJECTED = 23007, RELEASED = 23008
}
interface ErrorShape { code?: string | number; }
export class AnalysisError extends Error {
  readonly code: AnalysisErrorCode;
  constructor(code: AnalysisErrorCode) { super('analysis_error_' + code); this.code = code; }
  static from(error: Object, fallback: AnalysisErrorCode = AnalysisErrorCode.FAILED): AnalysisError {
    if (error instanceof AnalysisError) return error;
    const code = (error as ErrorShape).code;
    switch (code) {
      case 'FF_INVALID_INPUT': return new AnalysisError(AnalysisErrorCode.INVALID_INPUT);
      case 'FF_OPEN_FAILED': return new AnalysisError(AnalysisErrorCode.OPEN_FAILED);
      case 'FF_STREAM_INFO_FAILED': return new AnalysisError(AnalysisErrorCode.STREAM_INFO_FAILED);
      case 'FF_NO_VIDEO': return new AnalysisError(AnalysisErrorCode.NO_VIDEO);
      case 'FF_DECODER_UNAVAILABLE': return new AnalysisError(AnalysisErrorCode.DECODER_UNAVAILABLE);
      case 'FF_DECODE_FAILED': return new AnalysisError(AnalysisErrorCode.DECODE_FAILED);
      case 'FF_TIMEOUT': return new AnalysisError(AnalysisErrorCode.TIMEOUT);
      case 'FF_CANCELLED': return new AnalysisError(AnalysisErrorCode.CANCELLED);
      case 'FF_SIZE_REJECTED': return new AnalysisError(AnalysisErrorCode.SIZE_REJECTED);
      case 'FF_RELEASED': return new AnalysisError(AnalysisErrorCode.RELEASED);
      case 'FF_CLOSED': return new AnalysisError(AnalysisErrorCode.CLOSED);
      default: return new AnalysisError(fallback);
    }
  }
}
export class AnalysisOperation {
  private static sequence: number = 0;
  readonly id: string = 'analysis_' + (++AnalysisOperation.sequence);
  private cancelled: boolean = false;
  private actions: (() => void)[] = [];
  readonly finished: Promise<void>;
  private finish: () => void = () => {};
  constructor() { this.finished = new Promise((resolve) => { this.finish = resolve; }); }
  check(): void { if (this.cancelled) throw new AnalysisError(AnalysisErrorCode.CANCELLED); }
  onCancel(action: () => void): void { if (this.cancelled) action(); else this.actions.push(action); }
  cancel(): void { if (this.cancelled) return; this.cancelled = true;
    for (const action of this.actions) { try { action(); } catch (_error) {} } this.actions = []; }
  complete(): void { this.actions = []; this.finish(); }
}
export class AnalysisLifecycle {
  private closed: boolean = false;
  private current: AnalysisOperation | null = null;
  private closing: Promise<void> | null = null;
  isClosed(): boolean { return this.closed; }
  begin(): AnalysisOperation {
    if (this.closed) throw new AnalysisError(AnalysisErrorCode.CLOSED);
    if (this.current !== null) throw new AnalysisError(AnalysisErrorCode.BUSY);
    this.current = new AnalysisOperation(); return this.current;
  }
  end(operation: AnalysisOperation): void { operation.complete(); if (this.current === operation) this.current = null; }
  cancel(): void { this.current?.cancel(); }
  close(): Promise<void> { if (this.closing !== null) return this.closing;
    this.closed = true; this.cancel(); this.closing = this.current?.finished ?? Promise.resolve(); return this.closing; }
}
