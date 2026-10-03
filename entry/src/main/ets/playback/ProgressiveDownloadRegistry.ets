/** Process-local state for a remote file being downloaded into a playback cache. */
export class ProgressiveDownloadTask {
  readonly cachePath: string;
  readonly sizeBytes: number;
  private finished: boolean = false;
  private failed: boolean = false;
  private failureMessage: string = '';

  constructor(cachePath: string, sizeBytes: number) {
    this.cachePath = cachePath;
    this.sizeBytes = sizeBytes;
  }

  start(download: Promise<number>): void {
    download.then(() => {
      this.finished = true;
    }).catch((error: Object) => {
      this.failed = true;
      this.failureMessage = error instanceof Error ? error.message : String(error);
    });
  }

  isFinished(): boolean {
    return this.finished;
  }

  isFailed(): boolean {
    return this.failed;
  }

  errorMessage(): string {
    return this.failureMessage;
  }
}

export class ProgressiveDownloadRegistry {
  private static tasks: Map<string, ProgressiveDownloadTask> = new Map<string, ProgressiveDownloadTask>();

  static start(cachePath: string, sizeBytes: number, download: Promise<number>): string {
    const task: ProgressiveDownloadTask = new ProgressiveDownloadTask(cachePath, sizeBytes);
    ProgressiveDownloadRegistry.tasks.set(cachePath, task);
    task.start(download);
    return cachePath;
  }

  static get(key: string): ProgressiveDownloadTask | null {
    return key.length === 0 ? null : (ProgressiveDownloadRegistry.tasks.get(key) ?? null);
  }
}
