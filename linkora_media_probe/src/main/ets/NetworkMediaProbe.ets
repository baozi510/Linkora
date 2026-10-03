import { media } from '@kit.MediaKit';
import { image } from '@kit.ImageKit';
import { url } from '@kit.ArkTS';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { SystemMediaMetadataResult, SystemMediaProbe } from './SystemMediaProbe';
import { SystemThumbnailExtractor, SystemThumbnailResult } from './SystemThumbnailExtractor';

export enum ProbeStatus {
  COMPLETE = 'complete', METADATA_ONLY = 'metadata_only', UNAVAILABLE = 'unavailable',
  CANCELLED = 'cancelled', TIMEOUT = 'timeout'
}
export enum ProbeMode { BOTH = 'both', METADATA = 'metadata', THUMBNAIL = 'thumbnail' }
export interface MediaProbeOptions {
  mode?: ProbeMode;
  durationHintMs?: number;
  onMetadata?: (result: MediaProbeResult) => void;
}
/** Milliseconds. null means not started; interrupted stages include time spent before cancellation. */
export interface MediaProbeTimings {
  readonly prepareMs: number | null;
  readonly metadataMs: number | null;
  readonly thumbnailMs: number | null;
  readonly totalMs: number;
}
export interface MediaProbeResult {
  readonly durationMs: number;
  readonly width: number;
  readonly height: number;
  readonly metadataComplete: boolean;
  readonly thumbnail: image.PixelMap | null;
  readonly status: ProbeStatus;
  readonly errorCode: number;
  readonly timings: MediaProbeTimings;
}

class ProbeJob {
  active: boolean = true;
  durationMs: number = 0;
  width: number = 0;
  height: number = 0;
  metadataComplete: boolean = false;
  thumbnail: image.PixelMap | null = null;
  status: ProbeStatus = ProbeStatus.UNAVAILABLE;
  errorCode: number = 0;
  extractor: media.AVMetadataExtractor | null = null;
  releasing: Promise<void> | null = null;
  frameReleasing: Promise<void> | null = null;
  abort: () => void = () => {};
  work: Promise<void> = Promise.resolve();
  started: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
  phaseStarted: number = this.started;
  phase: string = 'prepare';
  prepareMs: number | null = null;
  metadataMs: number | null = null;
  thumbnailMs: number | null = null;
}

/**
 * Compatibility facade for one explicit inspection.
 *
 * Metadata and frame extraction are delegated to separate system stages while
 * this facade keeps shared extractor ownership so a BOTH request still opens
 * the remote source only once.
 */
export class NetworkMediaProbe {
  private current: ProbeJob | null = null;
  private closed: boolean = false;
  private closing: Promise<void> | null = null;
  private readonly createExtractor: () => Promise<media.AVMetadataExtractor>;
  private readonly metadataProbe: SystemMediaProbe;
  private readonly thumbnailExtractor: SystemThumbnailExtractor;

  constructor(createExtractor: () => Promise<media.AVMetadataExtractor> = () => media.createAVMetadataExtractor(),
    metadataProbe: SystemMediaProbe = new SystemMediaProbe(),
    thumbnailExtractor: SystemThumbnailExtractor = new SystemThumbnailExtractor()) {
    this.createExtractor = createExtractor;
    this.metadataProbe = metadataProbe;
    this.thumbnailExtractor = thumbnailExtractor;
  }

  async inspect(sourceUrl: string, headers: Record<string, string> = {},
    options: MediaProbeOptions = {}): Promise<MediaProbeResult> {
    if (this.closed) throw new Error('Probe closed');
    if (this.current !== null) throw new Error('Probe busy');
    const validatedHeaders: Record<string, string> = this.validate(sourceUrl, headers);
    const job: ProbeJob = new ProbeJob();
    this.current = job;
    const aborted: Promise<void> = new Promise((resolve) => { job.abort = resolve; });
    const timer: number = setTimeout(() => this.abort(job, ProbeStatus.TIMEOUT), 8000);
    job.work = this.run(job, sourceUrl, validatedHeaders, options);
    try {
      await Promise.race([job.work, aborted]);
      const frame: image.PixelMap | null = job.active ? job.thumbnail : null;
      job.thumbnail = null;
      return this.result(job, frame);
    } finally {
      clearTimeout(timer);
      if (job.active && this.current === job) this.current = null;
    }
  }

  cancel(): void { if (this.current !== null) this.abort(this.current, ProbeStatus.CANCELLED); }

  close(): Promise<void> {
    if (this.closing !== null) return this.closing;
    this.closed = true;
    this.cancel();
    this.closing = this.current?.work ?? Promise.resolve();
    return this.closing;
  }

  private async run(job: ProbeJob, sourceUrl: string, headers: Record<string, string>,
    options: MediaProbeOptions): Promise<void> {
    try {
      job.extractor = await this.createExtractor();
      if (!job.active) return;
      job.extractor.setUrlSource(sourceUrl, headers);
      this.endPhase(job);
      if (options.mode !== ProbeMode.THUMBNAIL) {
        job.phase = 'metadata';
        job.phaseStarted = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
        const metadata: SystemMediaMetadataResult = await this.metadataProbe.probe(job.extractor);
        this.endPhase(job);
        if (!job.active) return;
        job.durationMs = metadata.durationMs;
        job.width = metadata.width;
        job.height = metadata.height;
        job.metadataComplete = metadata.complete;
        job.status = ProbeStatus.METADATA_ONLY;
        options.onMetadata?.(this.result(job, null));
        if (!job.active || options.mode === ProbeMode.METADATA) return;
      } else {
        const duration: number = options.durationHintMs ?? 0;
        job.durationMs = Number.isFinite(duration) && duration > 0 ? duration : 0;
      }
      job.phase = 'thumbnail';
      job.phaseStarted = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
      const frame: SystemThumbnailResult =
        await this.thumbnailExtractor.extract(job.extractor, job.durationMs, 224, 126);
      job.thumbnail = frame.thumbnail;
      this.endPhase(job);
      if (job.active) job.status = ProbeStatus.COMPLETE;
    } catch (error) {
      if (job.active) {
        const code: number = Number((error as BusinessError).code);
        job.errorCode = Number.isFinite(code) ? code : 0;
      }
    } finally {
      this.endPhase(job);
      await this.releaseExtractor(job);
      if (!job.active) {
        await this.releaseFrame(job);
        if (this.current === job) this.current = null;
      }
    }
  }

  private result(job: ProbeJob, frame: image.PixelMap | null): MediaProbeResult {
    return { durationMs: job.durationMs, width: job.width, height: job.height,
      metadataComplete: job.metadataComplete, thumbnail: frame, status: job.status, errorCode: job.errorCode,
      timings: this.timings(job) };
  }

  private endPhase(job: ProbeJob): void {
    const elapsed: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP) - job.phaseStarted;
    if (job.phase === 'prepare') job.prepareMs = elapsed;
    else if (job.phase === 'metadata') job.metadataMs = elapsed;
    else if (job.phase === 'thumbnail') job.thumbnailMs = elapsed;
    job.phase = '';
  }

  private timings(job: ProbeJob): MediaProbeTimings {
    const now: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
    const elapsed: number = now - job.phaseStarted;
    return { prepareMs: job.phase === 'prepare' ? elapsed : job.prepareMs,
      metadataMs: job.phase === 'metadata' ? elapsed : job.metadataMs,
      thumbnailMs: job.phase === 'thumbnail' ? elapsed : job.thumbnailMs, totalMs: now - job.started };
  }

  private abort(job: ProbeJob, status: ProbeStatus): void {
    if (!job.active) return;
    job.active = false;
    job.status = status;
    this.endPhase(job);
    job.abort();
    this.releaseExtractor(job);
    this.releaseFrame(job);
  }

  private releaseExtractor(job: ProbeJob): Promise<void> {
    if (job.releasing !== null) return job.releasing;
    if (job.extractor === null) return Promise.resolve();
    try { job.releasing = job.extractor.release().catch(() => {}); }
    catch (_error) { job.releasing = Promise.resolve(); }
    return job.releasing;
  }

  private releaseFrame(job: ProbeJob): Promise<void> {
    if (job.thumbnail !== null) {
      const frame: image.PixelMap = job.thumbnail;
      job.thumbnail = null;
      try { job.frameReleasing = frame.release().catch(() => {}); }
      catch (_error) { job.frameReleasing = Promise.resolve(); }
    }
    return job.frameReleasing ?? Promise.resolve();
  }

  private validate(sourceUrl: string, headers: Record<string, string>): Record<string, string> {
    if (sourceUrl.length > 8192 || /[\r\n\0]/.test(sourceUrl)) throw new Error('Invalid source URL');
    try {
      const parsed: url.URL = url.URL.parseURL(sourceUrl);
      if ((parsed.protocol !== 'http:' && parsed.protocol !== 'https:') || parsed.host.length === 0 ||
        parsed.username.length > 0 || parsed.password.length > 0) throw new Error('Invalid source URL');
    } catch (_error) { throw new Error('Invalid source URL'); }
    const keys: string[] = Object.keys(headers);
    if (keys.length > 16) throw new Error('Invalid headers');
    const copy: Record<string, string> = {};
    let total: number = 0;
    for (const key of keys) {
      const value: string = headers[key];
      if (!/^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/.test(key) || typeof value !== 'string' ||
        value.length > 4096 || /[\r\n\0]/.test(value)) throw new Error('Invalid headers');
      try { total += key.length + encodeURIComponent(value).replace(/%[0-9A-F]{2}|[^%]/g, 'x').length; }
      catch (_error) { throw new Error('Invalid headers'); }
      if (total > 16384) throw new Error('Invalid headers');
      copy[key] = value;
    }
    return copy;
  }
}
