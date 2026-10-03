export class PlaybackBookmark {
  readonly position: number;
  readonly duration: number;
  readonly updatedAt: number;

  constructor(position: number, duration: number, updatedAt: number) {
    this.position = position;
    this.duration = duration;
    this.updatedAt = updatedAt;
  }

  resumePosition(): number {
    if (this.duration < 30000 || this.position < 5000) {
      return 0;
    }
    if (this.duration - this.position < 30000) {
      return 0;
    }
    return Math.min(this.position, this.duration);
  }

  encode(): string {
    return `${Math.round(this.position)},${Math.round(this.duration)},${Math.round(this.updatedAt)}`;
  }

  static decode(value: string): PlaybackBookmark | null {
    const parts: string[] = value.split(',');
    if (parts.length !== 3) {
      return null;
    }
    const position: number = Number(parts[0]);
    const duration: number = Number(parts[1]);
    const updatedAt: number = Number(parts[2]);
    if (!Number.isFinite(position) || !Number.isFinite(duration) || !Number.isFinite(updatedAt) ||
      position < 0 || duration <= 0 || updatedAt <= 0) {
      return null;
    }
    return new PlaybackBookmark(position, duration, updatedAt);
  }
}
