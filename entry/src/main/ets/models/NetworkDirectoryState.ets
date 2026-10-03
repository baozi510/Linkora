export enum NetworkDirectoryEntryKind {
  DIRECTORY = 'directory',
  FILE = 'file'
}

@ObservedV2
export class NetworkDirectoryEntry {
  readonly displayName: string;
  readonly path: string;
  readonly kind: NetworkDirectoryEntryKind;
  readonly size: number;
  readonly modifiedAt: number;
  @Trace durationMs: number;
  @Trace width: number;
  @Trace height: number;
  @Trace mediaPreviewReady: boolean = false;

  constructor(displayName: string, path: string, kind: NetworkDirectoryEntryKind,
    size: number = 0, modifiedAt: number = 0, durationMs: number = 0, width: number = 0, height: number = 0) {
    this.displayName = displayName;
    this.path = path;
    this.kind = kind;
    this.size = size;
    this.modifiedAt = modifiedAt;
    this.durationMs = durationMs; this.width = width; this.height = height;
  }
}

export class NetworkDirectoryLoadGuard {
  private generation: number = 0;

  next(): number {
    return ++this.generation;
  }

  isCurrent(generation: number): boolean {
    return generation === this.generation;
  }

  cancel(): void {
    ++this.generation;
  }
}
