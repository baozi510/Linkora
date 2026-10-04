import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import {
  DefaultThumbnailTimePolicy,
  LocalFileCategory,
  LocalFileFilter,
  MediaSource,
  ThumbnailPlan
} from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind } from '../models/NetworkDirectoryState';
import { CachedNetworkMedia, NetworkMediaCache } from './NetworkMediaCache';
import { NetworkServerEntry } from './NetworkServerStore';
import { NetworkThumbnailCache } from './NetworkThumbnailCache';
import { NetworkMediaAnalysisCoordinator, NetworkMediaAnalysisResult } from '../analysis/NetworkMediaAnalysisCoordinator';
import { NetworkMediaSourceFactory } from './NetworkMediaSourceFactory';

class MediaConsumer {
  readonly path: string;
  readonly id: string;
  readonly generation: number;
  active: boolean = true;
  readonly cancelled: Promise<null>;
  resolve: (value: null) => void = () => {};
  constructor(path: string, id: string, generation: number) {
    this.path = path; this.id = id; this.generation = generation;
    this.cancelled = new Promise((resolve) => { this.resolve = resolve; });
  }
  cancel(): void { this.active = false; this.resolve(null); }
}

class MediaLoadJob {
  readonly entry: NetworkDirectoryEntry;
  readonly key: string;
  readonly generation: number;
  readonly result: Promise<CachedNetworkMedia | null>;
  resolve: (value: CachedNetworkMedia | null) => void = () => {};
  cancelled: boolean = false;
  expired: boolean = false;
  inspecting: boolean = false;
  info: CachedNetworkMedia | null = null;
  analysis: NetworkMediaAnalysisCoordinator | null = null;

  constructor(entry: NetworkDirectoryEntry, key: string, generation: number) {
    this.entry = entry; this.key = key; this.generation = generation;
    this.result = new Promise((resolve) => { this.resolve = resolve; });
  }

  cancel(): void {
    this.cancelled = true;
    this.resolve(null);
    this.analysis?.cancel();
  }
}

export class NetworkMediaLoader {
  private readonly context: common.UIAbilityContext;
  private readonly server: NetworkServerEntry;
  private readonly cache: NetworkMediaCache;
  private readonly thumbnails: NetworkThumbnailCache;
  private readonly thumbnailPolicy: DefaultThumbnailTimePolicy = new DefaultThumbnailTimePolicy();
  private readonly proxy: NetworkFileProxy;
  private readonly ownsProxy: boolean;
  private readonly onMetadata: (entry: NetworkDirectoryEntry, info: CachedNetworkMedia) => void;
  private readonly jobs: Map<string, MediaLoadJob> = new Map();
  private readonly failures: Map<string, number> = new Map();
  private readonly filter: LocalFileFilter = new LocalFileFilter();
  private readonly consumers: Set<MediaConsumer> = new Set();
  private consumerSequence: number = 0;
  private entries: Map<string, NetworkDirectoryEntry> = new Map();
  private generation: number = 0;
  private stopped: boolean = false;
  private running: boolean = false;

  constructor(context: common.UIAbilityContext, server: NetworkServerEntry,
    onMetadata: (entry: NetworkDirectoryEntry, info: CachedNetworkMedia) => void,
    proxy: NetworkFileProxy | null = null) {
    this.context = context;
    this.server = server;
    this.cache = new NetworkMediaCache(context, server.id);
    this.thumbnails = new NetworkThumbnailCache(context, server.id);
    this.onMetadata = onMetadata;
    this.proxy = proxy ?? new NetworkFileProxy();
    this.ownsProxy = proxy === null;
  }

  reset(entries: NetworkDirectoryEntry[], forceRefresh: boolean): void {
    ++this.generation;
    this.consumers.forEach((consumer: MediaConsumer) => consumer.cancel()); this.consumers.clear();
    this.jobs.forEach((job: MediaLoadJob) => job.cancel()); this.jobs.clear();
    this.entries = new Map(entries.map((entry: NetworkDirectoryEntry): [string, NetworkDirectoryEntry] =>
      [entry.path, entry]));
    if (forceRefresh) this.failures.clear();
  }

  async load(entry: NetworkDirectoryEntry, consumerId: string = ''): Promise<image.PixelMap | null> {
    const current = this.entries.get(entry.path);
    if (this.stopped || entry.kind !== NetworkDirectoryEntryKind.FILE ||
      this.filter.categoryOf(entry.displayName) !== LocalFileCategory.VIDEO ||
      current === undefined || current.size !== entry.size || current.modifiedAt !== entry.modifiedAt) return null;
    const consumer = new MediaConsumer(entry.path, consumerId || `${++this.consumerSequence}`, this.generation);
    this.consumers.add(consumer);
    try { return await Promise.race([this.loadForConsumer(entry, consumer), consumer.cancelled]); }
    finally { this.consumers.delete(consumer); }
  }

  private async loadForConsumer(entry: NetworkDirectoryEntry, consumer: MediaConsumer): Promise<image.PixelMap | null> {
    let key: string;
    try { key = await this.cache.key(this.server, entry); } catch (_error) { return null; }
    if (!this.isCurrent(consumer)) return null;
    const cached = await this.cache.get(key);
    if (!this.isCurrent(consumer)) return null;
    if (cached !== null) {
      const plan: ThumbnailPlan = this.thumbnailPolicy.plan(cached.durationMs, cached.width, cached.height);
      try {
        const thumbnailKey: string = await this.thumbnails.key(this.server, entry, plan);
        const encoded: ArrayBuffer | null = this.thumbnails.get(thumbnailKey);
        if (encoded !== null) {
          const currentValue = new CachedNetworkMedia(cached.durationMs, cached.width, cached.height,
            encoded, cached.savedAt, 'webp');
          const thumbnail = await this.decode(currentValue, consumer);
          if (!this.isCurrent(consumer)) return null;
          if (thumbnail !== null) { this.onMetadata(entry, cached); return thumbnail; }
        }
      } catch (_error) {}

      if (cached.imageData !== null) {
        const thumbnail = await this.decode(cached, consumer);
        if (!this.isCurrent(consumer)) return null;
        if (thumbnail !== null) { this.onMetadata(entry, cached); return thumbnail; }
        await this.cache.put(key,
          new CachedNetworkMedia(cached.durationMs, cached.width, cached.height, null, cached.savedAt));
      }
    }

    if (!this.isCurrent(consumer)) return null;
    if (Date.now() - (this.failures.get(key) ?? 0) < 30000) return null;
    let job: MediaLoadJob | undefined = this.jobs.get(entry.path);
    if (job === undefined) {
      if (this.jobs.size >= 32) return null;
      job = new MediaLoadJob(entry, key, consumer.generation);
      if (cached !== null) job.info = new CachedNetworkMedia(
        cached.durationMs, cached.width, cached.height, null, cached.savedAt);
      this.jobs.set(entry.path, job);
      this.pump();
    }
    const value = await job.result;
    if (value === null || job.cancelled || !this.isCurrent(consumer)) return null;
    const thumbnail = await this.decode(value, consumer);
    if (!this.isCurrent(consumer)) return null;
    this.onMetadata(entry, new CachedNetworkMedia(
      value.durationMs, value.width, value.height, null, value.savedAt));
    return thumbnail;
  }

  private async decode(value: CachedNetworkMedia, consumer: MediaConsumer): Promise<image.PixelMap | null> {
    const thumbnail = await this.cache.decode(value);
    if (!this.isCurrent(consumer)) { await thumbnail?.release().catch(() => {}); return null; }
    return thumbnail;
  }

  cancel(path: string, consumerId: string = ''): void {
    this.consumers.forEach((consumer: MediaConsumer) => {
      if (consumer.path === path && (!consumerId || consumer.id === consumerId)) consumer.cancel();
    });
    const interested: boolean = Array.from(this.consumers).some((consumer: MediaConsumer): boolean =>
      consumer.path === path && this.isCurrent(consumer));
    const job = this.jobs.get(path);
    if (!interested && job !== undefined) { job.cancel(); this.jobs.delete(path); }
  }

  close(): void {
    this.stopped = true;
    this.reset([], false);
    if (this.ownsProxy) this.proxy.close().catch(() => {});
  }

  private isCurrent(consumer: MediaConsumer): boolean {
    return consumer.active && !this.stopped && consumer.generation === this.generation;
  }

  private expire(job: MediaLoadJob): void {
    if (job.cancelled || job.expired) return;
    job.expired = true;
    this.rememberFailure(job.key);
    job.analysis?.cancel();
    if (job.info !== null) {
      if (job.generation === this.generation && !this.stopped) {
        this.cache.put(job.key, job.info).catch(() => {});
      }
      job.resolve(job.info);
    } else if (!job.inspecting) {
      job.resolve(null);
    }
  }

  private pump(): void {
    if (this.running || this.stopped) return;
    const job = this.jobs.values().next().value as MediaLoadJob | undefined;
    if (job === undefined) return;
    this.running = true;
    this.run(job).finally(() => {
      if (this.jobs.get(job.entry.path) === job) this.jobs.delete(job.entry.path);
      this.running = false;
      this.pump();
    }).catch(() => {});
  }

  private async run(job: MediaLoadJob): Promise<void> {
    const analysis = new NetworkMediaAnalysisCoordinator(this.context, this.proxy);
    job.analysis = analysis;
    const timer: number = setTimeout(() => this.expire(job), 8000);

    try {
      const source: MediaSource = NetworkMediaSourceFactory.fromEntry(this.server, job.entry);
      job.inspecting = true;
      const result: NetworkMediaAnalysisResult = await analysis.inspect(
        source,
        job.info?.durationMs ?? 0,
        job.info?.width ?? 0,
        job.info?.height ?? 0,
        (durationMs: number, width: number, height: number): void => {
          if (job.cancelled || job.expired || job.generation !== this.generation || this.stopped) return;
          job.info = new CachedNetworkMedia(durationMs, width, height, null);
          this.cache.put(job.key, job.info).catch(() => {});
        }
      );
      job.inspecting = false;

      if (job.cancelled || job.expired || job.generation !== this.generation || this.stopped) return;

      const info = new CachedNetworkMedia(
        result.durationMs || job.info?.durationMs || 0,
        result.width || job.info?.width || 0,
        result.height || job.info?.height || 0,
        null
      );
      job.info = info;

      const hasInfo: boolean =
        info.durationMs > 0 || (info.width > 0 && info.height > 0);
      if (!hasInfo && result.encodedThumbnail === null) {
        this.rememberFailure(job.key);
        return;
      }

      let encoded: ArrayBuffer | null = result.encodedThumbnail;
      const plan: ThumbnailPlan =
        this.thumbnailPolicy.plan(info.durationMs, info.width, info.height);

      if (encoded !== null) {
        const thumbnailKey: string =
          await this.thumbnails.key(this.server, job.entry, plan);
        if (!this.thumbnails.put(thumbnailKey, encoded)) encoded = null;
      }

      const metadataOnly = new CachedNetworkMedia(
        info.durationMs, info.width, info.height, null, Date.now(), 'webp');
      await this.cache.put(job.key, metadataOnly);

      if (encoded === null) this.rememberFailure(job.key);
      const value = new CachedNetworkMedia(
        info.durationMs, info.width, info.height, encoded, Date.now(), 'webp');

      console.info(`Network media analysis: ${JSON.stringify({
        metadataEngine: result.metadataEngine,
        thumbnailEngine: result.thumbnailEngine,
        thumbnailPlan: plan.cacheIdentity()
      })}`);

      if (!job.cancelled && !this.stopped && job.generation === this.generation) {
        job.resolve(value);
      }
    } catch (_error) {
      if (!job.cancelled) this.rememberFailure(job.key);
    } finally {
      clearTimeout(timer);
      job.inspecting = false;
      job.resolve(null);
      await analysis.close().catch(() => {});
    }
  }

  private rememberFailure(key: string): void {
    this.failures.delete(key);
    this.failures.set(key, Date.now());
    while (this.failures.size > 128) this.failures.delete(this.failures.keys().next().value);
  }
}
