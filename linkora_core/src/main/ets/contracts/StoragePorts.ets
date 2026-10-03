import { RemoteReadSession } from '../sources/SourcePlugin';

export class SourceCapabilities {
  readonly seekable: boolean;
  readonly sizeKnown: boolean;
  readonly supportsRanges: boolean;
  readonly reopenable: boolean;
  readonly directUriAvailable: boolean;
  readonly fileDescriptorAvailable: boolean;

  constructor(seekable: boolean = true, sizeKnown: boolean = true,
    supportsRanges: boolean = true, reopenable: boolean = false,
    directUriAvailable: boolean = false, fileDescriptorAvailable: boolean = false) {
    this.seekable = seekable;
    this.sizeKnown = sizeKnown;
    this.supportsRanges = supportsRanges;
    this.reopenable = reopenable;
    this.directUriAvailable = directUriAvailable;
    this.fileDescriptorAvailable = fileDescriptorAvailable;
  }
}

export interface RandomAccessSource {
  id(): string;
  size(): number;
  capabilities(): SourceCapabilities;
  readAt(offset: number, length: number): Promise<ArrayBuffer>;
  cancel(): void;
  close(): Promise<void>;
}

export class RemoteReadSessionAdapter implements RandomAccessSource {
  private readonly sourceId: string;
  private readonly session: RemoteReadSession;
  private readonly sourceCapabilities: SourceCapabilities;

  constructor(sourceId: string, session: RemoteReadSession,
    capabilities: SourceCapabilities = new SourceCapabilities()) {
    this.sourceId = sourceId;
    this.session = session;
    this.sourceCapabilities = capabilities;
  }

  id(): string {
    return this.sourceId;
  }

  size(): number {
    return this.session.size();
  }

  capabilities(): SourceCapabilities {
    return this.sourceCapabilities;
  }

  readAt(offset: number, length: number): Promise<ArrayBuffer> {
    return this.session.read(offset, length);
  }

  cancel(): void {
    this.session.cancel();
  }

  close(): Promise<void> {
    return this.session.close();
  }
}

/**
 * Migration adapter for existing call sites that still consume RemoteReadSession.
 * New code should prefer RandomAccessSource directly.
 */
export class RandomAccessSourceSessionAdapter implements RemoteReadSession {
  private readonly source: RandomAccessSource;

  constructor(source: RandomAccessSource) {
    this.source = source;
  }

  size(): number {
    return this.source.size();
  }

  read(offset: number, length: number): Promise<ArrayBuffer> {
    return this.source.readAt(offset, length);
  }

  cancel(): void {
    this.source.cancel();
  }

  close(): Promise<void> {
    return this.source.close();
  }
}

export enum StorageEntryKind {
  FILE = 'file',
  DIRECTORY = 'directory'
}

export class StorageEntry {
  readonly locator: string;
  readonly displayName: string;
  readonly kind: StorageEntryKind;
  readonly sizeBytes: number;
  readonly modifiedAt: number;

  constructor(locator: string, displayName: string, kind: StorageEntryKind,
    sizeBytes: number = 0, modifiedAt: number = 0) {
    this.locator = locator;
    this.displayName = displayName;
    this.kind = kind;
    this.sizeBytes = Math.max(0, sizeBytes);
    this.modifiedAt = Math.max(0, modifiedAt);
  }
}

export class StorageListOptions {
  readonly forceRefresh: boolean;

  constructor(forceRefresh: boolean = false) {
    this.forceRefresh = forceRefresh;
  }
}

/**
 * A provider is already bound to one logical storage account/server.
 * Locators are provider-relative paths and never contain credentials.
 */
export interface StorageProvider {
  id(): string;
  stat(locator: string): Promise<StorageEntry | null>;
  list(locator: string, options?: StorageListOptions): Promise<StorageEntry[]>;
  open(locator: string): Promise<RandomAccessSource>;
}
