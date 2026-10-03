export class LocalMediaPlaybackProgress {
  readonly uri: string;
  readonly positionMs: number;
  readonly durationMs: number;
  readonly updatedAt: number;

  constructor(uri: string, positionMs: number, durationMs: number, updatedAt: number) {
    this.uri = uri;
    this.positionMs = Math.max(0, positionMs);
    this.durationMs = Math.max(0, durationMs);
    this.updatedAt = Math.max(0, updatedAt);
  }

  ratio(): number {
    if (this.durationMs <= 0) {
      return 0;
    }
    return Math.max(0, Math.min(1, this.positionMs / this.durationMs));
  }
}
