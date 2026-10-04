import { MediaSource, MediaSourceKind, MediaFormat, NetworkLinkParser, RandomAccessSource,
  SourceCapabilities, ResolvedMediaInput, ResolvedMediaInputKind } from 'linkora_core';
import { NetworkMediaSourceFactory } from '../services/NetworkMediaSourceFactory';
import { AnalysisOperation, AnalysisError, AnalysisErrorCode } from './AnalysisOperation';

export class AnalysisAccess {
  readRequests: number = 0; bytesRead: number = 0; nonSequentialReads: number = 0;
  readonly supportsRanges: boolean;
  constructor(supportsRanges: boolean = false) { this.supportsRanges = supportsRanges; }
  semantics(): string { return this.nonSequentialReads > 0 ? 'random_access_observed' :
    this.readRequests > 0 && this.supportsRanges ? 'range_available' : 'unavailable'; }
}
class ObservedAnalysisSource implements RandomAccessSource {
  readonly access: AnalysisAccess;
  private nextOffset: number = 0;
  private cancelled: boolean = false;
  private closing: Promise<void> | null = null;
  private readonly source: RandomAccessSource;
  constructor(source: RandomAccessSource) { this.source = source; this.access = new AnalysisAccess(source.capabilities().supportsRanges); }
  id(): string { return this.source.id(); } size(): number { return this.source.size(); }
  capabilities(): SourceCapabilities { return this.source.capabilities(); }
  async readAt(offset: number, length: number): Promise<ArrayBuffer> {
    this.access.readRequests++; if (offset !== this.nextOffset) this.access.nonSequentialReads++;
    const bytes = await this.source.readAt(offset, length); this.nextOffset = offset + bytes.byteLength;
    this.access.bytesRead += bytes.byteLength; return bytes;
  }
  cancel(): void { if (this.cancelled) return; this.cancelled = true; this.source.cancel(); }
  close(): Promise<void> { if (this.closing === null) this.closing = this.source.close(); return this.closing; }
}
export class AnalysisProxyRegistration {
  readonly url: string;
  readonly release: () => Promise<void>;
  constructor(url: string, release: () => Promise<void>) { this.url = url; this.release = release; }
}
export interface AnalysisInputPorts {
  openRemote(source: MediaSource, operation: AnalysisOperation): Promise<RandomAccessSource>;
  openHttp(source: MediaSource, operation: AnalysisOperation): Promise<RandomAccessSource>;
  /** Registration takes ownership even on failure; the observed wrapper makes cleanup idempotent. */
  register(source: RandomAccessSource): Promise<AnalysisProxyRegistration>;
}
export class AnalysisInputLease {
  readonly input: ResolvedMediaInput;
  readonly sourceIdentity: string;
  readonly access: AnalysisAccess;
  private readonly releaseAction: () => Promise<void>;
  private releasing: Promise<void> | null = null;
  constructor(input: ResolvedMediaInput, identity: string, release: () => Promise<void>, access: AnalysisAccess = new AnalysisAccess()) {
    this.input = input; this.sourceIdentity = identity; this.releaseAction = release; this.access = access;
  }
  release(): Promise<void> { if (this.releasing === null) this.releasing = Promise.resolve().then(this.releaseAction); return this.releasing; }
}
export class MediaAnalysisInputResolver {
  private readonly ports: AnalysisInputPorts;
  constructor(ports: AnalysisInputPorts) { this.ports = ports; }
  canResolve(source: MediaSource, engine: string): boolean {
    if (engine !== 'system' && engine !== 'ffmpeg') return false;
    if (source.kind === MediaSourceKind.LOCAL_DOCUMENT) return false;
    const playlist = source.format === MediaFormat.HLS || source.format === MediaFormat.DASH;
    if (source.kind === MediaSourceKind.REMOTE_FILE) return !playlist && NetworkMediaSourceFactory.serverId(source) > 0;
    const parsed = NetworkLinkParser.parse(source.locator);
    if (!parsed.isValid()) return false;
    const nested = playlist || parsed.value?.format === MediaFormat.HLS || parsed.value?.format === MediaFormat.DASH;
    if (nested) return engine === 'system';
    return source.format === MediaFormat.MP4 || source.format === MediaFormat.MATROSKA ||
      source.format === MediaFormat.MPEG_TS || source.format === MediaFormat.AUDIO;
  }
  async resolve(source: MediaSource, engine: string, operation: AnalysisOperation): Promise<AnalysisInputLease> {
    operation.check(); if (!this.canResolve(source, engine)) throw new AnalysisError(AnalysisErrorCode.UNSUPPORTED);
    const identity = this.identity(source);
    const parsed = source.kind === MediaSourceKind.NETWORK_LINK ? NetworkLinkParser.parse(source.locator) : null;
    if (source.kind === MediaSourceKind.NETWORK_LINK && (source.format === MediaFormat.HLS || source.format === MediaFormat.DASH ||
      parsed?.value?.format === MediaFormat.HLS || parsed?.value?.format === MediaFormat.DASH)) {
      return new AnalysisInputLease(new ResolvedMediaInput(ResolvedMediaInputKind.DIRECT_URL, identity, source.locator), identity, async () => {});
    }
    let owned: ObservedAnalysisSource | null = null;
    let lease: AnalysisInputLease | null = null;
    try {
      const sourceHandle = source.kind === MediaSourceKind.REMOTE_FILE ?
        await this.ports.openRemote(source, operation) : await this.ports.openHttp(source, operation);
      owned = new ObservedAnalysisSource(sourceHandle); operation.check();
      const registration = await this.ports.register(owned);
      lease = new AnalysisInputLease(new ResolvedMediaInput(ResolvedMediaInputKind.PROXY_URL, identity, registration.url), identity,
        registration.release, owned.access);
      const currentLease = lease; operation.onCancel(() => { currentLease.release().catch(() => {}); });
      operation.check(); return lease;
    } catch (error) {
      if (lease !== null) await lease.release();
      else if (owned !== null) { owned.cancel(); await owned.close(); }
      throw AnalysisError.from(error as Object, AnalysisErrorCode.RESOLVE_FAILED);
    }
  }
  private identity(source: MediaSource): string {
    const value = source.kind + '\n' + source.sourceId + '\n' + source.locator + '\n' + source.fingerprint;
    let hash: number = 2166136261;
    for (let i = 0; i < value.length; i++) { hash ^= value.charCodeAt(i); hash = Math.imul(hash, 16777619); }
    return 'analysis-source-' + (hash >>> 0).toString(16);
  }
}
