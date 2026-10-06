import { common } from '@kit.AbilityKit';
import { systemDateTime } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import {
  DefaultThumbnailTimePolicy,
  IMediaProbe,
  IThumbnailExtractor,
  MediaSource,
  ProbeCompleteness,
  ProbeRequirement,
  ProbeResult,
  RemoteProtocol,
  RawThumbnail,
  ThumbnailExtractRequest,
  ThumbnailPlan
} from 'linkora_core';
import { NetworkFileProxy, NetworkFileProxyDiagnostics } from 'linkora_proxy';
import { AnalysisComposition } from 'entry/AnalysisComposition';
import { HarmonyAnalysisInputs } from '../analysis/HarmonyAnalysisInputs';
import { MediaAnalysisInputResolver } from '../analysis/MediaAnalysisInputResolver';
import { AnalysisError } from '../analysis/AnalysisOperation';
import { SystemThumbnailFallback } from '../analysis/SystemThumbnailFallback';
import { SystemWebPEncoder } from '../services/SystemWebPEncoder';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind } from '../models/NetworkDirectoryState';
import { NetworkDirectoryService } from '../services/NetworkDirectoryService';
import { NetworkMediaSourceFactory } from '../services/NetworkMediaSourceFactory';
import { NetworkServerEntry, NetworkServerStore } from '../services/NetworkServerStore';

interface AnalysisBenchmarkCase {
  caseId: string;
  directoryPath: string;
  fileName: string;
  container: string;
  expectedDurationMs: number;
  expectedWidth: number;
  expectedHeight: number;
}

interface AnalysisBenchmarkConfig {
  schemaVersion: number;
  serverName: string;
  warmups: number;
  repetitions: number;
  cases: AnalysisBenchmarkCase[];
}

interface AnalysisBenchmarkRecord {
  operation: string;
  engine: string;
  sourceType: string;
  caseId: string;
  container: string;
  requirement: string;
  iteration: number;
  success: boolean;
  correct: boolean;
  completeness: string;
  elapsedMs: number;
  prepareMs: number | null;
  probeMs: number | null;
  extractMs: number | null;
  encodeMs: number | null;
  writeMs: number | null;
  bytesRead: number;
  readRequests: number;
  rangeRequests: number;
  webpBytes: number | null;
  width: number;
  height: number;
  errorCode: number;
  memoryBytes: number | null;
}

interface BenchmarkErrorShape {
  code?: string | number;
}

interface BenchmarkRunState {
  complete: boolean;
  passed: boolean;
  records: number;
  failedRecords: number;
  errorCode: number;
}

/**
 * Debug-only, Want-triggered real-device benchmark runner.
 *
 * It never changes ProductionMediaAnalysisPolicy. Each sample constructs an isolated proxy/resolver
 * and explicitly selects System or FFmpeg so the same production source path can be compared fairly.
 */
export class AnalysisBenchmarkRunner {
  private static readonly outputName: string = 'analysis-benchmark-results.ndjson';
  private static readonly stateName: string = 'analysis-benchmark-state.json';

  static async run(context: common.UIAbilityContext, configUrl: string): Promise<void> {
    AnalysisBenchmarkRunner.benchmarkContext = context;
    const outputPath: string = `${context.cacheDir}/${AnalysisBenchmarkRunner.outputName}`;
    const statePath: string = `${context.cacheDir}/${AnalysisBenchmarkRunner.stateName}`;
    AnalysisBenchmarkRunner.write(outputPath, '');
    let records: number = 0;
    let failed: number = 0;
    let errorCode: number = 0;
    try {
      const config: AnalysisBenchmarkConfig =
        AnalysisBenchmarkRunner.parseConfig(await AnalysisBenchmarkRunner.request(configUrl));
      const server: NetworkServerEntry = await AnalysisBenchmarkRunner.server(context, config.serverName);
      const fixtures: Array<[AnalysisBenchmarkCase, MediaSource]> = [];
      for (const benchmarkCase of config.cases) {
        fixtures.push([benchmarkCase, await AnalysisBenchmarkRunner.source(server, benchmarkCase)]);
      }

      for (const fixture of fixtures) {
        for (let warmup: number = 0; warmup < config.warmups; warmup++) {
          await AnalysisBenchmarkRunner.warm(fixture[1], fixture[0]);
        }
        for (let iteration: number = 0; iteration < config.repetitions; iteration++) {
          const engines: string[] = iteration % 2 === 0 ? ['system', 'ffmpeg'] : ['ffmpeg', 'system'];
          for (const engine of engines) {
            const list: AnalysisBenchmarkRecord =
              await AnalysisBenchmarkRunner.metadata(fixture[1], fixture[0], engine,
                ProbeRequirement.LIST, iteration);
            AnalysisBenchmarkRunner.append(outputPath, list); records++; if (!list.success) failed++;

            const advanced: AnalysisBenchmarkRecord =
              await AnalysisBenchmarkRunner.metadata(fixture[1], fixture[0], engine,
                ProbeRequirement.ADVANCED, iteration);
            AnalysisBenchmarkRunner.append(outputPath, advanced); records++; if (!advanced.success) failed++;

            const thumbnail: AnalysisBenchmarkRecord =
              await AnalysisBenchmarkRunner.thumbnail(context, fixture[1], fixture[0], engine, iteration);
            AnalysisBenchmarkRunner.append(outputPath, thumbnail); records++; if (!thumbnail.success) failed++;
          }
        }
      }
    } catch (error) {
      errorCode = AnalysisBenchmarkRunner.errorCode(error as Object);
    } finally {
      const state: BenchmarkRunState = {
        complete: true,
        passed: errorCode === 0 && records > 0,
        records,
        failedRecords: failed,
        errorCode
      };
      AnalysisBenchmarkRunner.write(statePath, JSON.stringify(state));
      AnalysisBenchmarkRunner.benchmarkContext = null;
    }
  }

  private static async warm(source: MediaSource, benchmarkCase: AnalysisBenchmarkCase): Promise<void> {
    for (const engine of ['system', 'ffmpeg']) {
      await AnalysisBenchmarkRunner.metadataRun(source, engine, ProbeRequirement.LIST).then(() => {}, () => {});
      await AnalysisBenchmarkRunner.thumbnailRun(source, benchmarkCase, engine, '', false).then(() => {}, () => {});
    }
  }

  private static async metadata(source: MediaSource,
    benchmarkCase: AnalysisBenchmarkCase, engine: string, requirement: ProbeRequirement,
    iteration: number): Promise<AnalysisBenchmarkRecord> {
    const started: number = AnalysisBenchmarkRunner.now();
    let result: ProbeResult | null = null;
    let diagnostics: NetworkFileProxyDiagnostics | null = null;
    let errorCode: number = 0;
    try {
      const run = await AnalysisBenchmarkRunner.metadataRun(source, engine, requirement);
      result = run[0]; diagnostics = run[1];
    } catch (error) {
      errorCode = AnalysisBenchmarkRunner.errorCode(error as Object);
    }
    const elapsedMs: number = AnalysisBenchmarkRunner.now() - started;
    const width: number = AnalysisBenchmarkRunner.width(result);
    const height: number = AnalysisBenchmarkRunner.height(result);
    const correct: boolean = result !== null && result.info !== null &&
      Math.abs(result.info.durationMs - benchmarkCase.expectedDurationMs) <= 250 &&
      width === benchmarkCase.expectedWidth && height === benchmarkCase.expectedHeight;
    return {
      operation: 'analysis.metadata',
      engine,
      sourceType: 'webdav',
      caseId: benchmarkCase.caseId,
      container: benchmarkCase.container,
      requirement,
      iteration,
      success: result !== null && result.isUsable() && correct,
      correct,
      completeness: result?.completeness ?? ProbeCompleteness.UNAVAILABLE,
      elapsedMs,
      prepareMs: result === null ? null : result.diagnostics.prepareMs,
      probeMs: result === null ? null : result.diagnostics.probeMs,
      extractMs: null,
      encodeMs: null,
      writeMs: null,
      bytesRead: diagnostics?.bytesRead ?? 0,
      readRequests: diagnostics?.readRequests ?? 0,
      rangeRequests: diagnostics?.rangeRequests ?? 0,
      webpBytes: null,
      width,
      height,
      errorCode: result?.errorCode ?? errorCode,
      memoryBytes: null
    };
  }

  private static async metadataRun(source: MediaSource, engine: string,
    requirement: ProbeRequirement): Promise<[ProbeResult, NetworkFileProxyDiagnostics]> {
    const proxy: NetworkFileProxy = new NetworkFileProxy();
    const resolver = new MediaAnalysisInputResolver(new HarmonyAnalysisInputs(
      AnalysisBenchmarkRunner.context(), proxy));
    const probe: IMediaProbe =
      engine === 'system' ? AnalysisComposition.system(resolver) : AnalysisComposition.ffmpeg(resolver);
    let result: ProbeResult;
    try {
      result = await probe.probe(source, requirement);
    } finally {
      await probe.close().catch(() => {});
      await proxy.close().catch(() => {});
    }
    return [result, proxy.diagnostics()];
  }

  private static async thumbnail(context: common.UIAbilityContext, source: MediaSource,
    benchmarkCase: AnalysisBenchmarkCase, engine: string, iteration: number): Promise<AnalysisBenchmarkRecord> {
    const started: number = AnalysisBenchmarkRunner.now();
    let record: AnalysisBenchmarkRecord | null = null;
    try {
      record = await AnalysisBenchmarkRunner.thumbnailRun(source, benchmarkCase, engine,
        `${context.cacheDir}/analysis-benchmark`, true, iteration);
    } catch (error) {
      record = AnalysisBenchmarkRunner.emptyThumbnail(benchmarkCase, engine, iteration,
        AnalysisBenchmarkRunner.now() - started, AnalysisBenchmarkRunner.errorCode(error as Object));
    }
    return record;
  }

  private static async thumbnailRun(source: MediaSource, benchmarkCase: AnalysisBenchmarkCase,
    engine: string, outputDirectory: string, persist: boolean, iteration: number = -1):
    Promise<AnalysisBenchmarkRecord> {
    const proxy: NetworkFileProxy = new NetworkFileProxy();
    const resolver = new MediaAnalysisInputResolver(new HarmonyAnalysisInputs(
      AnalysisBenchmarkRunner.context(), proxy));
    const plan: ThumbnailPlan = new DefaultThumbnailTimePolicy().plan(
      benchmarkCase.expectedDurationMs, benchmarkCase.expectedWidth, benchmarkCase.expectedHeight);
    const request = new ThumbnailExtractRequest(plan.timeMs, plan.width, plan.height);
    const encoder: SystemWebPEncoder = new SystemWebPEncoder();
    let pixelMap: image.PixelMap | null = null;
    let raw: RawThumbnail | null = null;
    let encoded: ArrayBuffer | null = null;
    let extractMs: number = 0;
    let encodeMs: number = 0;
    let writeMs: number = 0;
    let width: number = 0;
    let height: number = 0;
    let errorCode: number = 0;
    const started: number = AnalysisBenchmarkRunner.now();
    let system: SystemThumbnailFallback | null = null;
    let ffmpeg: IThumbnailExtractor | null = null;
    try {
      if (engine === 'system') {
        system = new SystemThumbnailFallback(resolver);
        const extractStarted: number = AnalysisBenchmarkRunner.now();
        pixelMap = await system.extract(source, request,
          benchmarkCase.expectedDurationMs, benchmarkCase.expectedWidth, benchmarkCase.expectedHeight);
        extractMs = AnalysisBenchmarkRunner.now() - extractStarted;
        if (pixelMap === null) throw new Error('thumbnail unavailable');
        const info: image.ImageInfo = await pixelMap.getImageInfo();
        width = info.size.width; height = info.size.height;
        const encodeStarted: number = AnalysisBenchmarkRunner.now();
        encoded = await encoder.encode(pixelMap, plan.quality);
        encodeMs = AnalysisBenchmarkRunner.now() - encodeStarted;
      } else {
        ffmpeg = AnalysisComposition.thumbnail(resolver);
        const extractStarted: number = AnalysisBenchmarkRunner.now();
        raw = await ffmpeg.extract(source, request);
        extractMs = AnalysisBenchmarkRunner.now() - extractStarted;
        if (raw === null) throw new Error('thumbnail unavailable');
        width = raw.width(); height = raw.height();
        const encodeStarted: number = AnalysisBenchmarkRunner.now();
        encoded = await encoder.encodeRaw(raw, plan.quality);
        encodeMs = AnalysisBenchmarkRunner.now() - encodeStarted;
      }
      if (encoded === null || encoded.byteLength <= 0) throw new Error('webp unavailable');
      if (persist) {
        if (!fileIo.accessSync(outputDirectory)) fileIo.mkdirSync(outputDirectory, true);
        const safe: string = `${benchmarkCase.caseId}-${engine}-${iteration}.webp`;
        const path: string = `${outputDirectory}/${safe}`;
        const writeStarted: number = AnalysisBenchmarkRunner.now();
        AnalysisBenchmarkRunner.write(path, encoded);
        writeMs = AnalysisBenchmarkRunner.now() - writeStarted;
        try { fileIo.unlinkSync(path); } catch (_error) {}
      }
    } catch (error) {
      errorCode = AnalysisBenchmarkRunner.errorCode(error as Object);
    } finally {
      await pixelMap?.release().catch(() => {});
      await raw?.release().catch(() => {});
      await system?.close().catch(() => {});
      await ffmpeg?.close().catch(() => {});
      await proxy.close().catch(() => {});
    }
    const proxyMetrics: NetworkFileProxyDiagnostics = proxy.diagnostics();
    const elapsedMs: number = AnalysisBenchmarkRunner.now() - started;
    const correct: boolean = encoded !== null && encoded.byteLength > 0 &&
      width > 0 && height > 0 && width <= plan.width && height <= plan.height;
    return {
      operation: 'analysis.thumbnail',
      engine,
      sourceType: 'webdav',
      caseId: benchmarkCase.caseId,
      container: benchmarkCase.container,
      requirement: 'thumbnail',
      iteration,
      success: errorCode === 0 && correct,
      correct,
      completeness: correct ? ProbeCompleteness.COMPLETE : ProbeCompleteness.UNAVAILABLE,
      elapsedMs,
      prepareMs: null,
      probeMs: null,
      extractMs,
      encodeMs,
      writeMs,
      bytesRead: proxyMetrics.bytesRead,
      readRequests: proxyMetrics.readRequests,
      rangeRequests: proxyMetrics.rangeRequests,
      webpBytes: encoded?.byteLength ?? null,
      width,
      height,
      errorCode,
      memoryBytes: null
    };
  }

  private static emptyThumbnail(benchmarkCase: AnalysisBenchmarkCase, engine: string,
    iteration: number, elapsedMs: number, errorCode: number): AnalysisBenchmarkRecord {
    return {
      operation: 'analysis.thumbnail', engine, sourceType: 'webdav', caseId: benchmarkCase.caseId,
      container: benchmarkCase.container, requirement: 'thumbnail', iteration, success: false,
      correct: false, completeness: ProbeCompleteness.UNAVAILABLE, elapsedMs, prepareMs: null,
      probeMs: null, extractMs: null, encodeMs: null, writeMs: null, bytesRead: 0, readRequests: 0,
      rangeRequests: 0, webpBytes: null, width: 0, height: 0, errorCode, memoryBytes: null
    };
  }

  private static async server(context: common.UIAbilityContext, name: string): Promise<NetworkServerEntry> {
    const entries: NetworkServerEntry[] = await new NetworkServerStore(context).load();
    const matches: NetworkServerEntry[] = entries.filter((entry: NetworkServerEntry): boolean =>
      entry.displayName === name && entry.protocol === RemoteProtocol.WEBDAV);
    if (matches.length !== 1) throw new Error('benchmark server unavailable');
    return matches[0];
  }

  private static async source(server: NetworkServerEntry,
    benchmarkCase: AnalysisBenchmarkCase): Promise<MediaSource> {
    const entries: NetworkDirectoryEntry[] =
      await new NetworkDirectoryService(server).list(benchmarkCase.directoryPath, true);
    const matches: NetworkDirectoryEntry[] = entries.filter((entry: NetworkDirectoryEntry): boolean =>
      entry.kind === NetworkDirectoryEntryKind.FILE && entry.displayName === benchmarkCase.fileName);
    if (matches.length !== 1) throw new Error('benchmark fixture unavailable');
    return NetworkMediaSourceFactory.fromEntry(server, matches[0]);
  }

  private static parseConfig(payload: string): AnalysisBenchmarkConfig {
    if (payload.length <= 0 || payload.length > 65536) throw new Error('benchmark config size');
    const config: AnalysisBenchmarkConfig = JSON.parse(payload) as AnalysisBenchmarkConfig;
    if (config.schemaVersion !== 1 || typeof config.serverName !== 'string' ||
      config.serverName.length < 1 || config.serverName.length > 128 ||
      !Number.isSafeInteger(config.warmups) || config.warmups < 0 || config.warmups > 5 ||
      !Number.isSafeInteger(config.repetitions) || config.repetitions < 5 || config.repetitions > 50 ||
      !Array.isArray(config.cases) || config.cases.length < 1 || config.cases.length > 16) {
      throw new Error('benchmark config');
    }
    for (const item of config.cases) {
      if (!/^[a-z0-9-]{1,48}$/.test(item.caseId) ||
        typeof item.directoryPath !== 'string' || item.directoryPath.length < 1 || item.directoryPath.length > 1024 ||
        typeof item.fileName !== 'string' || item.fileName.length < 1 || item.fileName.length > 255 ||
        /[\r\n\0]/.test(item.directoryPath + item.fileName) ||
        typeof item.container !== 'string' || !/^[a-z0-9-]{1,24}$/.test(item.container) ||
        !Number.isSafeInteger(item.expectedDurationMs) || item.expectedDurationMs <= 0 ||
        !Number.isSafeInteger(item.expectedWidth) || item.expectedWidth <= 0 ||
        !Number.isSafeInteger(item.expectedHeight) || item.expectedHeight <= 0) {
        throw new Error('benchmark case');
      }
    }
    return config;
  }

  private static async request(source: string): Promise<string> {
    if (!/^http:\/\/127\.0\.0\.1:\d{2,5}\/[a-f0-9-]{36}$/.test(source)) {
      throw new Error('benchmark config endpoint');
    }
    const client: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await client.request(source, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 8000,
        readTimeout: 8000,
        maxLimit: 65536
      });
      if (response.responseCode !== 200) throw new Error('benchmark config unavailable');
      return response.result as string;
    } finally {
      client.destroy();
    }
  }

  private static width(result: ProbeResult | null): number {
    return result?.info?.videoTracks[0]?.width ?? 0;
  }

  private static height(result: ProbeResult | null): number {
    return result?.info?.videoTracks[0]?.height ?? 0;
  }

  private static now(): number {
    return systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
  }

  private static errorCode(error: Object): number {
    const shape: BenchmarkErrorShape = error as BenchmarkErrorShape;
    if (typeof shape.code === 'number' && Number.isFinite(shape.code)) {
      return Math.max(0, Math.floor(shape.code));
    }
    return AnalysisError.from(error).code;
  }

  private static append(path: string, record: AnalysisBenchmarkRecord): void {
    const text: string = JSON.stringify(record) + '\n';
    const offset: number = fileIo.statSync(path).size;
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
    try { fileIo.writeSync(file.fd, text, { offset }); } finally { fileIo.closeSync(file.fd); }
  }

  private static write(path: string, value: string | ArrayBuffer): void {
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try { fileIo.writeSync(file.fd, value); } finally { fileIo.closeSync(file.fd); }
  }

  private static benchmarkContext: common.UIAbilityContext | null = null;

  private static context(): common.UIAbilityContext {
    if (AnalysisBenchmarkRunner.benchmarkContext === null) throw new Error('benchmark context unavailable');
    return AnalysisBenchmarkRunner.benchmarkContext;
  }
}
