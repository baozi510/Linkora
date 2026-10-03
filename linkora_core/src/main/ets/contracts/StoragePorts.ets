import { MediaSource } from '../models/MediaSource';
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

export interface StorageProvider {
  id(): string;
  canHandle(source: MediaSource): boolean;
  stat(source: MediaSource): Promise<StorageEntry | null>;
  list(source: MediaSource): Promise<StorageEntry[]>;
  open(source: MediaSource): Promise<RandomAccessSource>;
}
