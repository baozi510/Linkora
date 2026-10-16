import { MediaSource, RandomAccessSource, SourceCapabilities } from 'linkora_core';

export type PlaylistSourceOpener = (index: number,
  setupObserver: (settled: Promise<void>) => void) => Promise<RandomAccessSource>;

class PlaylistItemSource implements RandomAccessSource {
  private readonly owner: NetworkPlaylistSources;
  private readonly index: number;
  private readonly source: MediaSource;

  constructor(owner: NetworkPlaylistSources, index: number, source: MediaSource) {
    this.owner = owner;
    this.index = index;
    this.source = source;
  }

  id(): string { return `${this.source.sourceId}:${this.source.locator}`; }
  size(): number { return this.source.sizeBytes; }
  capabilities(): SourceCapabilities { return new SourceCapabilities(); }
  readAt(offset: number, length: number): Promise<ArrayBuffer> { return this.owner.read(this.index, offset, length); }
  cancel(): void { this.owner.cancel(this.index); }
  close(): Promise<void> { return this.owner.close(this.index); }
}

/** Logical queue URLs are cheap; at most one upstream reader is retained. */
export class NetworkPlaylistSources {
  private readonly items: MediaSource[];
  private readonly opener: PlaylistSourceOpener;
  private readonly cancelled: Set<number> = new Set();
  private active: RandomAccessSource | null = null;
  private activeIndex: number = -1;
  private closed: boolean = false;
  private closeFailure: Error | null = null;
  private tail: Promise<void> = Promise.resolve();
  private releasing: Promise<void> | null = null;

  constructor(items: MediaSource[], opener: PlaylistSourceOpener) {
    if (items.length === 0 || items.some((item) => !Number.isSafeInteger(item.sizeBytes) || item.sizeBytes <= 0)) {
      throw new Error('Network playlist requires known positive file sizes; refresh the directory');
    }
    this.items = items.slice();
    this.opener = opener;
  }

  sources(): RandomAccessSource[] {
    return this.items.map((item, index) => new PlaylistItemSource(this, index, item));
  }

  read(index: number, offset: number, length: number): Promise<ArrayBuffer> {
    const operation: Promise<ArrayBuffer> = this.tail.then(async (): Promise<ArrayBuffer> => {
      this.requireAvailable(index);
      if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset < 0 || length < 0 ||
        offset > this.items[index].sizeBytes || length > this.items[index].sizeBytes - offset) {
        throw new Error('Invalid network playlist byte range');
      }
      if (length === 0) return new ArrayBuffer(0);
      if (this.activeIndex !== index) {
        await this.closeActive();
        this.requireAvailable(index);
        let setupSettled: Promise<void> = Promise.resolve();
        let source: RandomAccessSource;
        try {
          source = await this.opener(index, (settled: Promise<void>) => { setupSettled = settled; });
        } catch (error) {
          try { await setupSettled; } catch (cleanupError) {
            this.closed = true;
            this.closeFailure = cleanupError as Error;
            throw this.closeFailure;
          }
          throw error as Error;
        }
        this.active = source;
        this.activeIndex = index;
        try {
          this.requireAvailable(index);
          const capabilities: SourceCapabilities = source.capabilities();
          if (!capabilities.seekable || !capabilities.sizeKnown || source.size() !== this.items[index].sizeBytes) {
            throw new Error('Network playlist file size or capabilities changed; refresh the directory');
          }
        } catch (error) {
          await this.closeActive();
          throw error as Error;
        }
      }
      const data: ArrayBuffer = await this.active!.readAt(offset, length);
      this.requireAvailable(index);
      return data;
    });
    this.tail = operation.then(() => {}, () => {});
    return operation;
  }

  cancel(index: number): void {
    this.cancelled.add(index);
    if (this.activeIndex === index) this.cancelActive();
  }

  close(index: number): Promise<void> {
    this.cancel(index);
    const operation: Promise<void> = this.tail.then(async () => {
      if (this.activeIndex === index) await this.closeActive();
      if (this.closeFailure !== null) throw this.closeFailure;
    });
    this.tail = operation.then(() => {}, () => {});
    return operation;
  }

  release(): Promise<void> {
    if (this.releasing !== null) return this.releasing;
    this.closed = true;
    this.cancelActive();
    this.releasing = this.tail.then(async () => {
      await this.closeActive();
      if (this.closeFailure !== null) throw this.closeFailure;
    });
    this.tail = this.releasing.then(() => {}, () => {});
    return this.releasing;
  }

  private requireAvailable(index: number): void {
    if (this.closeFailure !== null) throw this.closeFailure;
    if (this.closed || this.cancelled.has(index) || !Number.isInteger(index) || index < 0 || index >= this.items.length) {
      throw new Error('Network playlist source unavailable');
    }
  }

  private async closeActive(): Promise<void> {
    const source: RandomAccessSource | null = this.active;
    this.active = null;
    this.activeIndex = -1;
    if (source !== null) await this.dispose(source);
  }

  private async dispose(source: RandomAccessSource): Promise<void> {
    try {
      try { source.cancel(); } finally { await source.close(); }
    } catch (error) {
      this.closed = true;
      this.closeFailure = error as Error;
      throw this.closeFailure;
    }
  }

  private cancelActive(): void {
    try { this.active?.cancel(); } catch (error) {
      this.closed = true;
      this.closeFailure = error as Error;
    }
  }
}
