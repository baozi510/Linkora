import { common } from '@kit.AbilityKit';
import { systemDateTime } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { media } from '@kit.MediaKit';
import { http } from '@kit.NetworkKit';
import {
  DefaultThumbnailTimePolicy,
  IThumbnailExtractor,
  MediaSource,
  ProbeCompleteness,
  RandomAccessSource,
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
import { WebDavBrowserService } from '../services/WebDavBrowserService';
import { HttpRemoteReadSession } from '../services/HttpRemoteReadSession';
import { FfmpegAnalysis, FfmpegRawThumbnail } from 'linkora_ffmpeg';

export interface AnalysisBenchmarkCase {
  caseId: string;
  directoryPath: string;
  fileName: string;
  container: string;
  expectedDurationMs: number;
  expectedWidth: number;
  expectedHeight: number;
  sourceType?: string;
  localPath?: string;
}

export interface AnalysisBenchmarkConfig {
  schemaVersion: number;
  serverName?: string;
  mode?: string;
  warmups?: number;
  repetitions?: number;
  seekRatios?: number[];
  stabilityCycles?: number;
  benchmarkProxy?: http.HttpProxy;
  cases: AnalysisBenchmarkCase[];
}

export interface AnalysisBenchmarkRecord {
  operation: string;
  engine: string;
  sourceType: string;
  caseId: string;
  container: string;
  requirement: string;
  iteration: number;
  seekRatio: number | null;
  targetTimeMs: number | null;
  fileSizeBytes: number | null;
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
  uniqueByteSpan: number | null;
  overlappingBytes: number | null;
  headRereads: number | null;
  rangeTraces: string[] | null;
  openInputMs: number | null;
  findStreamInfoMs: number | null;
  decoderInitMs: number | null;
  seekMs: number | null;
  decodeMs: number | null;
  scaleMs: number | null;
  systemExtractionMs: number | null;
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
  errorMessage?: string;
  mode?: string;
}

interface DiscoveryFileItem {
  displayName: string;
  directoryPath: string;
  kind: string;
  sizeBytes: number;
}

interface DiscoveredServerInfo {
  name: string;
  protocol: string;
}

interface DiscoveryResult {
  complete: boolean;
  serverProtocol: string;
  serverDisplayName: string;
  serverHost?: string;
  serverPort?: number;
  serverRootPath?: string;
  initialPath?: string;
  error?: string;
  allServers?: DiscoveredServerInfo[];
  items: DiscoveryFileItem[];
}

export class AnalysisBenchmarkRunner {
  private static readonly outputName: string = 'analysis-benchmark-results.ndjson';
  private static readonly stateName: string = 'analysis-benchmark-state.json';
  private static readonly discoveryName: string = 'benchmark-discovery.json';
  private static benchmarkContext: common.UIAbilityContext | null = null;

  static async run(context: common.UIAbilityContext, configUrl: string): Promise<void> {
    AnalysisBenchmarkRunner.benchmarkContext = context;
    const outputPath: string = `${context.cacheDir}/${AnalysisBenchmarkRunner.outputName}`;
    const statePath: string = `${context.cacheDir}/${AnalysisBenchmarkRunner.stateName}`;
    AnalysisBenchmarkRunner.write(outputPath, '');
    let records: number = 0;
    let failed: number = 0;
    let errorCode: number = 0;
    let errorMessage: string | undefined = undefined;
    let activeMode: string = 'cost';

    try {
      const config: AnalysisBenchmarkConfig =
        AnalysisBenchmarkRunner.parseConfig(await AnalysisBenchmarkRunner.request(configUrl));
      activeMode = config.mode ?? 'cost';
      if (config.benchmarkProxy) {
        WebDavBrowserService.benchmarkProxy = config.benchmarkProxy;
        HttpRemoteReadSession.benchmarkProxy = config.benchmarkProxy;
      }

      const server: NetworkServerEntry = await AnalysisBenchmarkRunner.server(context, config.serverName);

      if (activeMode === 'discovery') {
        await AnalysisBenchmarkRunner.runDiscovery(context, server);
      } else if (activeMode === 'seek') {
        const result: [number, number] = await AnalysisBenchmarkRunner.runSeek(context, server, config, outputPath);
        records = result[0]; failed = result[1];
      } else if (activeMode === 'compat') {
        const result: [number, number] = await AnalysisBenchmarkRunner.runCompat(context, server, config, outputPath);
        records = result[0]; failed = result[1];
      } else if (activeMode === 'stability') {
        const result: [number, number] = await AnalysisBenchmarkRunner.runStability(context, server, config, outputPath);
        records = result[0]; failed = result[1];
      } else {
        const result: [number, number] = await AnalysisBenchmarkRunner.runCost(context, server, config, outputPath);
        records = result[0]; failed = result[1];
      }
    } catch (error) {
      const errStr: string = String(error);
      errorMessage = errStr;
      console.error(`[Benchmark] Benchmark run failed: ${errStr}`);
      errorCode = AnalysisBenchmarkRunner.errorCode(error as Object);
    } finally {
      WebDavBrowserService.benchmarkProxy = null;
      HttpRemoteReadSession.benchmarkProxy = null;
      const state: BenchmarkRunState = {
        complete: true,
        passed: errorCode === 0 && (records > 0 || activeMode === 'discovery'),
        records,
        failedRecords: failed,
        errorCode,
        errorMessage,
        mode: activeMode
      };
      AnalysisBenchmarkRunner.write(statePath, JSON.stringify(state));
      AnalysisBenchmarkRunner.benchmarkContext = null;
    }
  }

  private static async runDiscovery(context: common.UIAbilityContext, server: NetworkServerEntry): Promise<void> {
    const service: NetworkDirectoryService = new NetworkDirectoryService(server);
    const discoveryPath: string = `${context.cacheDir}/${AnalysisBenchmarkRunner.discoveryName}`;
    const items: DiscoveryFileItem[] = [];

    const startPath: string = service.initialPath().length > 0 ? service.initialPath() : '/';
    const queue: string[] = [startPath];
    const visited: Set<string> = new Set<string>();

    let lastError: string = '';
    while (queue.length > 0 && items.length < 200) {
      const currentDir: string = queue.shift()!;
      if (visited.has(currentDir)) continue;
      visited.add(currentDir);
      try {
        const entries: NetworkDirectoryEntry[] = await service.list(currentDir, true);
        for (const entry of entries) {
          if (entry.kind === NetworkDirectoryEntryKind.DIRECTORY) {
            const sub: string = currentDir.endsWith('/') ? currentDir + entry.displayName : currentDir + '/' + entry.displayName;
            if (visited.size < 10) queue.push(sub);
          } else {
            items.push({
              displayName: entry.displayName,
              directoryPath: currentDir,
              kind: 'file',
              sizeBytes: entry.size
            });
          }
        }
      } catch (_e) {
        lastError = String(_e);
      }
    }

    const all = await new NetworkServerStore(context).load();
    const result: DiscoveryResult = {
      complete: true,
      serverProtocol: server.protocol,
      serverDisplayName: server.displayName,
      serverHost: server.host,
      serverPort: server.port,
      serverRootPath: server.rootPath,
      initialPath: startPath,
      error: lastError.length > 0 ? lastError : undefined,
      allServers: all.map((s: NetworkServerEntry): DiscoveredServerInfo => {
        const info: DiscoveredServerInfo = { name: s.displayName, protocol: s.protocol };
        return info;
      }),
      items
    };
    AnalysisBenchmarkRunner.write(discoveryPath, JSON.stringify(result));
  }

  private static async runCost(context: common.UIAbilityContext, server: NetworkServerEntry,
    config: AnalysisBenchmarkConfig, outputPath: string): Promise<[number, number]> {
    let records: number = 0;
    let failed: number = 0;

    for (const benchmarkCase of config.cases) {
      const localPath: string = await AnalysisBenchmarkRunner.ensureLocalFixture(server, benchmarkCase, context);
      const source: MediaSource = await AnalysisBenchmarkRunner.source(server, benchmarkCase);
      const fileSize: number = fileIo.statSync(localPath).size;

      const warmups: number = config.warmups ?? 2;
      for (let warmup: number = 0; warmup < warmups; warmup++) {
        await AnalysisBenchmarkRunner.thumbnailLocalRun(localPath, benchmarkCase, 'system', fileSize, -1).catch(() => {});
        await AnalysisBenchmarkRunner.thumbnailLocalRun(localPath, benchmarkCase, 'ffmpeg', fileSize, -1).catch(() => {});
        await AnalysisBenchmarkRunner.thumbnailWebdavRun(source, benchmarkCase, 'system', fileSize, -1).catch(() => {});
        await AnalysisBenchmarkRunner.thumbnailWebdavRun(source, benchmarkCase, 'ffmpeg', fileSize, -1).catch(() => {});
      }

      const reps: number = config.repetitions ?? 20;
      for (let iteration: number = 0; iteration < reps; iteration++) {
        const engines: string[] = iteration % 2 === 0 ? ['system', 'ffmpeg'] : ['ffmpeg', 'system'];
        for (const engine of engines) {
          const localRecord: AnalysisBenchmarkRecord =
            await AnalysisBenchmarkRunner.thumbnailLocalRun(localPath, benchmarkCase, engine, fileSize, iteration);
          AnalysisBenchmarkRunner.append(outputPath, localRecord);
          records++;
          if (!localRecord.success) failed++;

          const webdavRecord: AnalysisBenchmarkRecord =
            await AnalysisBenchmarkRunner.thumbnailWebdavRun(source, benchmarkCase, engine, fileSize, iteration);
          AnalysisBenchmarkRunner.append(outputPath, webdavRecord);
          records++;
          if (!webdavRecord.success) failed++;
        }
      }
    }
    return [records, failed];
  }

  private static async runSeek(context: common.UIAbilityContext, server: NetworkServerEntry,
    config: AnalysisBenchmarkConfig, outputPath: string): Promise<[number, number]> {
    let records: number = 0;
    let failed: number = 0;
    const seekRatios: number[] = config.seekRatios && config.seekRatios.length > 0 ?
      config.seekRatios : [0.05, 0.20, 0.50, 0.90];

    const benchmarkCase: AnalysisBenchmarkCase = config.cases[0];
    const source: MediaSource = await AnalysisBenchmarkRunner.source(server, benchmarkCase);
    const localPath: string = await AnalysisBenchmarkRunner.ensureLocalFixture(server, benchmarkCase, context);
    const fileSize: number = fileIo.statSync(localPath).size;

    const reps: number = 5;
    for (const ratio of seekRatios) {
      const targetTimeMs: number = Math.max(0, Math.floor(benchmarkCase.expectedDurationMs * ratio));
      for (let iteration: number = 0; iteration < reps; iteration++) {
        const engines: string[] = iteration % 2 === 0 ? ['system', 'ffmpeg'] : ['ffmpeg', 'system'];
        for (const engine of engines) {
          const rec: AnalysisBenchmarkRecord = await AnalysisBenchmarkRunner.thumbnailWebdavRun(
            source, benchmarkCase, engine, fileSize, iteration, targetTimeMs, ratio, 'analysis.seek');
          AnalysisBenchmarkRunner.append(outputPath, rec);
          records++;
          if (!rec.success) failed++;
        }
      }
    }
    return [records, failed];
  }

  private static async runCompat(context: common.UIAbilityContext, server: NetworkServerEntry,
    config: AnalysisBenchmarkConfig, outputPath: string): Promise<[number, number]> {
    let records: number = 0;
    let failed: number = 0;

    for (const benchmarkCase of config.cases) {
      let source: MediaSource | null = null;
      let fileSize: number = 0;
      let isWebdav: boolean = true;

      try {
        if (benchmarkCase.localPath && fileIo.accessSync(benchmarkCase.localPath)) {
          isWebdav = false;
          fileSize = fileIo.statSync(benchmarkCase.localPath).size;
        } else {
          source = await AnalysisBenchmarkRunner.source(server, benchmarkCase);
        }
      } catch (_e) {}

      for (const engine of ['system', 'ffmpeg']) {
        let rec: AnalysisBenchmarkRecord;
        if (!isWebdav && benchmarkCase.localPath) {
          rec = await AnalysisBenchmarkRunner.thumbnailLocalRun(
            benchmarkCase.localPath, benchmarkCase, engine, fileSize, 0, null, null, 'analysis.compat');
        } else if (source !== null) {
          rec = await AnalysisBenchmarkRunner.thumbnailWebdavRun(
            source, benchmarkCase, engine, fileSize, 0, null, null, 'analysis.compat');
        } else {
          rec = AnalysisBenchmarkRunner.emptyThumbnail(
            benchmarkCase, engine, 'webdav', 0, 0, -1, 'analysis.compat');
        }
        AnalysisBenchmarkRunner.append(outputPath, rec);
        records++;
        if (!rec.success) failed++;
      }
    }
    return [records, failed];
  }

  private static async runStability(context: common.UIAbilityContext, server: NetworkServerEntry,
    config: AnalysisBenchmarkConfig, outputPath: string): Promise<[number, number]> {
    let records: number = 0;
    let failed: number = 0;
    const benchmarkCase: AnalysisBenchmarkCase = config.cases[0];
    const source: MediaSource = await AnalysisBenchmarkRunner.source(server, benchmarkCase);
    const localPath: string = await AnalysisBenchmarkRunner.ensureLocalFixture(server, benchmarkCase, context);
    const fileSize: number = fileIo.statSync(localPath).size;
    const cycles: number = config.stabilityCycles ?? 50;

    for (let i: number = 0; i < cycles; i++) {
      const engine: string = i % 2 === 0 ? 'system' : 'ffmpeg';
      const rec: AnalysisBenchmarkRecord = await AnalysisBenchmarkRunner.thumbnailWebdavRun(
        source, benchmarkCase, engine, fileSize, i, null, null, 'analysis.stability');
      AnalysisBenchmarkRunner.append(outputPath, rec);
      records++;
      if (!rec.success) failed++;
    }

    for (const engine of ['system', 'ffmpeg']) {
      const rec: AnalysisBenchmarkRecord =
        await AnalysisBenchmarkRunner.runCancellationTest(context, source, benchmarkCase, engine, fileSize);
      AnalysisBenchmarkRunner.append(outputPath, rec);
      records++;
      if (!rec.success) failed++;
    }

    return [records, failed];
  }

  private static async runCancellationTest(context: common.UIAbilityContext, source: MediaSource,
    benchmarkCase: AnalysisBenchmarkCase, engine: string, fileSize: number): Promise<AnalysisBenchmarkRecord> {
    const started: number = AnalysisBenchmarkRunner.now();
    const proxy: NetworkFileProxy = new NetworkFileProxy();
    const resolver: MediaAnalysisInputResolver =
      new MediaAnalysisInputResolver(new HarmonyAnalysisInputs(context, proxy));
    const plan: ThumbnailPlan = new DefaultThumbnailTimePolicy().plan(
      benchmarkCase.expectedDurationMs, benchmarkCase.expectedWidth, benchmarkCase.expectedHeight);
    const request: ThumbnailExtractRequest = new ThumbnailExtractRequest(plan.timeMs, plan.width, plan.height);

    let cancelledProperly: boolean = false;
    let errorCode: number = 0;

    try {
      if (engine === 'system') {
        const system: SystemThumbnailFallback = new SystemThumbnailFallback(resolver);
        const promise: Promise<image.PixelMap | null> = system.extract(source, request,
          benchmarkCase.expectedDurationMs, benchmarkCase.expectedWidth, benchmarkCase.expectedHeight);
        system.cancel();
        const res: image.PixelMap | null = await promise;
        cancelledProperly = (res === null);
      } else {
        const ffmpeg: IThumbnailExtractor = AnalysisComposition.thumbnail(resolver);
        const promise: Promise<RawThumbnail | null> = ffmpeg.extract(source, request);
        ffmpeg.cancel();
        const res: RawThumbnail | null = await promise;
        cancelledProperly = (res === null);
      }
    } catch (error) {
      errorCode = AnalysisBenchmarkRunner.errorCode(error as Object);
      cancelledProperly = true;
    } finally {
      await proxy.close().catch(() => {});
    }

    const elapsedMs: number = AnalysisBenchmarkRunner.now() - started;
    return {
      operation: 'analysis.cancellation',
      engine,
      sourceType: 'webdav',
      caseId: benchmarkCase.caseId,
      container: benchmarkCase.container,
      requirement: 'cancellation',
      iteration: 0,
      seekRatio: null,
      targetTimeMs: plan.timeMs,
      fileSizeBytes: fileSize,
      success: cancelledProperly,
      correct: cancelledProperly,
      completeness: cancelledProperly ? ProbeCompleteness.COMPLETE : ProbeCompleteness.UNAVAILABLE,
      elapsedMs,
      prepareMs: null,
      probeMs: null,
      extractMs: elapsedMs,
      encodeMs: null,
      writeMs: null,
      bytesRead: proxy.diagnostics().bytesRead,
      readRequests: proxy.diagnostics().readRequests,
      rangeRequests: proxy.diagnostics().rangeRequests,
      uniqueByteSpan: proxy.diagnostics().uniqueByteSpan(),
      overlappingBytes: proxy.diagnostics().overlappingBytes(),
      headRereads: proxy.diagnostics().headRereads(),
      rangeTraces: proxy.diagnostics().rangeTraces,
      openInputMs: null,
      findStreamInfoMs: null,
      decoderInitMs: null,
      seekMs: null,
      decodeMs: null,
      scaleMs: null,
      systemExtractionMs: engine === 'system' ? elapsedMs : null,
      webpBytes: null,
      width: 0,
      height: 0,
      errorCode,
      memoryBytes: null
    };
  }

  private static async thumbnailLocalRun(localPath: string, benchmarkCase: AnalysisBenchmarkCase,
    engine: string, fileSize: number, iteration: number, targetTimeMsOverride: number | null = null,
    seekRatio: number | null = null, operation: string = 'analysis.thumbnail'): Promise<AnalysisBenchmarkRecord> {
    const started: number = AnalysisBenchmarkRunner.now();
    const encoder: SystemWebPEncoder = new SystemWebPEncoder();
    const plan: ThumbnailPlan = new DefaultThumbnailTimePolicy().plan(
      benchmarkCase.expectedDurationMs, benchmarkCase.expectedWidth, benchmarkCase.expectedHeight);
    const targetTimeMs: number = targetTimeMsOverride !== null ? targetTimeMsOverride : plan.timeMs;

    let pixelMap: image.PixelMap | null = null;
    let raw: FfmpegRawThumbnail | null = null;
    let encoded: ArrayBuffer | null = null;
    let extractMs: number = 0;
    let encodeMs: number = 0;
    let writeMs: number = 0;
    let width: number = 0;
    let height: number = 0;
    let errorCode: number = 0;

    let openInputMs: number | null = null;
    let findStreamInfoMs: number | null = null;
    let decoderInitMs: number | null = null;
    let seekMs: number | null = null;
    let decodeMs: number | null = null;
    let scaleMs: number | null = null;
    let systemExtractionMs: number | null = null;

    try {
      if (engine === 'system') {
        const file: fileIo.File = fileIo.openSync(localPath, fileIo.OpenMode.READ_ONLY);
        const stat: fileIo.Stat = fileIo.statSync(file.fd);
        const extractor: media.AVMetadataExtractor = await media.createAVMetadataExtractor();
        try {
          extractor.fdSrc = { fd: file.fd, offset: 0, length: stat.size };
          const timeUs: number = Math.max(0, Math.floor(targetTimeMs)) * 1000;
          const extractStarted: number = AnalysisBenchmarkRunner.now();
          pixelMap = await extractor.fetchFrameByTime(timeUs, media.AVImageQueryOptions.AV_IMAGE_QUERY_CLOSEST_SYNC, {
            width: plan.width,
            height: plan.height
          });
          extractMs = AnalysisBenchmarkRunner.now() - extractStarted;
          systemExtractionMs = extractMs;
          if (pixelMap === null) throw new Error('system thumbnail unavailable');
          const info: image.ImageInfo = await pixelMap.getImageInfo();
          width = info.size.width; height = info.size.height;
          const encodeStarted: number = AnalysisBenchmarkRunner.now();
          encoded = await encoder.encode(pixelMap, plan.quality);
          encodeMs = AnalysisBenchmarkRunner.now() - encodeStarted;
        } finally {
          await extractor.release().catch(() => {});
          try { fileIo.closeSync(file.fd); } catch (_e) {}
        }
      } else {
        const analysis: FfmpegAnalysis = AnalysisComposition.createAnalysis();
        const opId: string = 'local-' + Math.random().toString(36).substring(2);
        try {
          const extractStarted: number = AnalysisBenchmarkRunner.now();
          const frame = await analysis.extractFrame(opId, localPath, targetTimeMs, plan.width, plan.height, 10000);
          extractMs = AnalysisBenchmarkRunner.now() - extractStarted;
          raw = new FfmpegRawThumbnail(frame);
          width = raw.width(); height = raw.height();
          openInputMs = raw.diagnostics.openInputMs;
          findStreamInfoMs = raw.diagnostics.findStreamInfoMs;
          decoderInitMs = raw.diagnostics.decoderInitMs;
          seekMs = raw.diagnostics.seekMs;
          decodeMs = raw.diagnostics.decodeMs;
          scaleMs = raw.diagnostics.scaleMs;
          const encodeStarted: number = AnalysisBenchmarkRunner.now();
          encoded = await encoder.encodeRaw(raw, plan.quality);
          encodeMs = AnalysisBenchmarkRunner.now() - encodeStarted;
        } finally {
          await analysis.close();
        }
      }

      if (encoded === null || encoded.byteLength <= 0) throw new Error('webp encoding failed');
      const cacheDir: string = AnalysisBenchmarkRunner.context().cacheDir;
      const tmpPath: string = `${cacheDir}/local-${benchmarkCase.caseId}-${engine}-${iteration}.webp`;
      const writeStarted: number = AnalysisBenchmarkRunner.now();
      AnalysisBenchmarkRunner.write(tmpPath, encoded);
      writeMs = AnalysisBenchmarkRunner.now() - writeStarted;
      try { fileIo.unlinkSync(tmpPath); } catch (_e) {}
    } catch (error) {
      errorCode = AnalysisBenchmarkRunner.errorCode(error as Object);
    } finally {
      await pixelMap?.release().catch(() => {});
      await raw?.release().catch(() => {});
    }

    const elapsedMs: number = AnalysisBenchmarkRunner.now() - started;
    const correct: boolean = encoded !== null && encoded.byteLength > 0 &&
      width > 0 && height > 0 && width <= plan.width && height <= plan.height;

    return {
      operation,
      engine,
      sourceType: 'local',
      caseId: benchmarkCase.caseId,
      container: benchmarkCase.container,
      requirement: 'thumbnail',
      iteration,
      seekRatio,
      targetTimeMs,
      fileSizeBytes: fileSize,
      success: errorCode === 0 && correct,
      correct,
      completeness: correct ? ProbeCompleteness.COMPLETE : ProbeCompleteness.UNAVAILABLE,
      elapsedMs,
      prepareMs: 0,
      probeMs: null,
      extractMs,
      encodeMs,
      writeMs,
      bytesRead: 0,
      readRequests: 0,
      rangeRequests: 0,
      uniqueByteSpan: 0,
      overlappingBytes: 0,
      headRereads: 0,
      rangeTraces: [],
      openInputMs,
      findStreamInfoMs,
      decoderInitMs,
      seekMs,
      decodeMs,
      scaleMs,
      systemExtractionMs,
      webpBytes: encoded?.byteLength ?? null,
      width,
      height,
      errorCode,
      memoryBytes: null
    };
  }

  private static async thumbnailWebdavRun(source: MediaSource, benchmarkCase: AnalysisBenchmarkCase,
    engine: string, fileSize: number, iteration: number, targetTimeMsOverride: number | null = null,
    seekRatio: number | null = null, operation: string = 'analysis.thumbnail'): Promise<AnalysisBenchmarkRecord> {
    const started: number = AnalysisBenchmarkRunner.now();
    const proxy: NetworkFileProxy = new NetworkFileProxy();
    const resolver: MediaAnalysisInputResolver = new MediaAnalysisInputResolver(new HarmonyAnalysisInputs(
      AnalysisBenchmarkRunner.context(), proxy));
    const encoder: SystemWebPEncoder = new SystemWebPEncoder();
    const plan: ThumbnailPlan = new DefaultThumbnailTimePolicy().plan(
      benchmarkCase.expectedDurationMs, benchmarkCase.expectedWidth, benchmarkCase.expectedHeight);
    const targetTimeMs: number = targetTimeMsOverride !== null ? targetTimeMsOverride : plan.timeMs;
    const request: ThumbnailExtractRequest = new ThumbnailExtractRequest(targetTimeMs, plan.width, plan.height);

    let pixelMap: image.PixelMap | null = null;
    let raw: RawThumbnail | null = null;
    let encoded: ArrayBuffer | null = null;
    let extractMs: number = 0;
    let encodeMs: number = 0;
    let writeMs: number = 0;
    let width: number = 0;
    let height: number = 0;
    let errorCode: number = 0;

    let openInputMs: number | null = null;
    let findStreamInfoMs: number | null = null;
    let decoderInitMs: number | null = null;
    let seekMs: number | null = null;
    let decodeMs: number | null = null;
    let scaleMs: number | null = null;
    let systemExtractionMs: number | null = null;

    let system: SystemThumbnailFallback | null = null;
    let ffmpeg: IThumbnailExtractor | null = null;

    try {
      if (engine === 'system') {
        system = new SystemThumbnailFallback(resolver);
        const extractStarted: number = AnalysisBenchmarkRunner.now();
        pixelMap = await system.extract(source, request,
          benchmarkCase.expectedDurationMs, benchmarkCase.expectedWidth, benchmarkCase.expectedHeight);
        extractMs = AnalysisBenchmarkRunner.now() - extractStarted;
        systemExtractionMs = extractMs;
        if (pixelMap === null) throw new Error('system webdav thumbnail unavailable');
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
        if (raw === null) throw new Error('ffmpeg webdav thumbnail unavailable');
        width = raw.width(); height = raw.height();
        const rawFfmpeg: FfmpegRawThumbnail = raw as FfmpegRawThumbnail;
        openInputMs = rawFfmpeg.diagnostics.openInputMs;
        findStreamInfoMs = rawFfmpeg.diagnostics.findStreamInfoMs;
        decoderInitMs = rawFfmpeg.diagnostics.decoderInitMs;
        seekMs = rawFfmpeg.diagnostics.seekMs;
        decodeMs = rawFfmpeg.diagnostics.decodeMs;
        scaleMs = rawFfmpeg.diagnostics.scaleMs;
        const encodeStarted: number = AnalysisBenchmarkRunner.now();
        encoded = await encoder.encodeRaw(raw, plan.quality);
        encodeMs = AnalysisBenchmarkRunner.now() - encodeStarted;
      }

      if (encoded === null || encoded.byteLength <= 0) throw new Error('webp encoding failed');
      const cacheDir: string = AnalysisBenchmarkRunner.context().cacheDir;
      const tmpPath: string = `${cacheDir}/webdav-${benchmarkCase.caseId}-${engine}-${iteration}.webp`;
      const writeStarted: number = AnalysisBenchmarkRunner.now();
      AnalysisBenchmarkRunner.write(tmpPath, encoded);
      writeMs = AnalysisBenchmarkRunner.now() - writeStarted;
      try { fileIo.unlinkSync(tmpPath); } catch (_e) {}
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
      operation,
      engine,
      sourceType: 'webdav',
      caseId: benchmarkCase.caseId,
      container: benchmarkCase.container,
      requirement: 'thumbnail',
      iteration,
      seekRatio,
      targetTimeMs,
      fileSizeBytes: fileSize,
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
      uniqueByteSpan: proxyMetrics.uniqueByteSpan(),
      overlappingBytes: proxyMetrics.overlappingBytes(),
      headRereads: proxyMetrics.headRereads(),
      rangeTraces: proxyMetrics.rangeTraces,
      openInputMs,
      findStreamInfoMs,
      decoderInitMs,
      seekMs,
      decodeMs,
      scaleMs,
      systemExtractionMs,
      webpBytes: encoded?.byteLength ?? null,
      width,
      height,
      errorCode,
      memoryBytes: null
    };
  }

  private static emptyThumbnail(benchmarkCase: AnalysisBenchmarkCase, engine: string,
    sourceType: string, iteration: number, elapsedMs: number, errorCode: number,
    operation: string = 'analysis.thumbnail'): AnalysisBenchmarkRecord {
    return {
      operation, engine, sourceType, caseId: benchmarkCase.caseId,
      container: benchmarkCase.container, requirement: 'thumbnail', iteration,
      seekRatio: null, targetTimeMs: null, fileSizeBytes: null,
      success: false, correct: false, completeness: ProbeCompleteness.UNAVAILABLE,
      elapsedMs, prepareMs: null, probeMs: null, extractMs: null, encodeMs: null,
      writeMs: null, bytesRead: 0, readRequests: 0, rangeRequests: 0,
      uniqueByteSpan: null, overlappingBytes: null, headRereads: null, rangeTraces: null,
      openInputMs: null, findStreamInfoMs: null, decoderInitMs: null, seekMs: null,
      decodeMs: null, scaleMs: null, systemExtractionMs: null,
      webpBytes: null, width: 0, height: 0, errorCode, memoryBytes: null
    };
  }

  private static safeExists(filePath: string): boolean {
    try {
      return fileIo.accessSync(filePath);
    } catch (_e) {
      return false;
    }
  }

  private static safeSize(filePath: string): number {
    try {
      return fileIo.statSync(filePath).size;
    } catch (_e) {
      return -1;
    }
  }

  private static async ensureLocalFixture(server: NetworkServerEntry, benchmarkCase: AnalysisBenchmarkCase,
    context: common.UIAbilityContext): Promise<string> {
    const localDir: string = `${context.cacheDir}/benchmark-local`;
    if (!AnalysisBenchmarkRunner.safeExists(localDir)) {
      fileIo.mkdirSync(localDir, true);
    }
    const localPath: string = `${localDir}/${benchmarkCase.fileName}`;
    const service: NetworkDirectoryService = new NetworkDirectoryService(server);
    const fullRemotePath: string = benchmarkCase.directoryPath.endsWith('/') ?
      benchmarkCase.directoryPath + benchmarkCase.fileName :
      benchmarkCase.directoryPath + '/' + benchmarkCase.fileName;
    const source: RandomAccessSource = await service.openSource(fullRemotePath);
    const size: number = source.size();

    if (AnalysisBenchmarkRunner.safeExists(localPath) && AnalysisBenchmarkRunner.safeSize(localPath) === size) {
      console.info(`[Benchmark] Fixture ${benchmarkCase.fileName} already cached (${size} bytes)`);
      await source.close();
      return localPath;
    }

    console.info(`[Benchmark] Mirroring remote fixture ${benchmarkCase.fileName} (${size} bytes) to local...`);
    const chunkSize: number = 262144;
    const file = fileIo.openSync(localPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try {
      let offset: number = 0;
      let lastLog: number = 0;
      while (offset < size) {
        const len: number = Math.min(chunkSize, size - offset);
        const buf: ArrayBuffer = await source.readAt(offset, len);
        fileIo.writeSync(file.fd, buf, { offset });
        offset += len;
        if (offset - lastLog >= 10485760 || offset === size) {
          console.info(`[Benchmark] Mirrored ${benchmarkCase.fileName}: ${(offset / 1024 / 1024).toFixed(1)} / ${(size / 1024 / 1024).toFixed(1)} MB`);
          lastLog = offset;
        }
      }
    } finally {
      fileIo.closeSync(file.fd);
      await source.close();
    }
    if (!AnalysisBenchmarkRunner.safeExists(localPath) || AnalysisBenchmarkRunner.safeSize(localPath) !== size) {
      throw new Error(`Failed to download fixture ${benchmarkCase.fileName} to local cache: size mismatch`);
    }
    return localPath;
  }

  private static async server(context: common.UIAbilityContext, name?: string): Promise<NetworkServerEntry> {
    const entries: NetworkServerEntry[] = await new NetworkServerStore(context).load();
    const webdavEntries: NetworkServerEntry[] = entries.filter((entry: NetworkServerEntry): boolean =>
      entry.protocol === RemoteProtocol.WEBDAV);
    if (webdavEntries.length === 0) {
      throw new Error('No WebDAV server found in Linkora store');
    }
    if (typeof name === 'string' && name.length > 0 && name !== '*') {
      const matches: NetworkServerEntry[] = webdavEntries.filter((entry: NetworkServerEntry): boolean =>
        entry.displayName === name);
      if (matches.length === 1) return matches[0];
    }
    return webdavEntries[0];
  }

  private static async source(server: NetworkServerEntry,
    benchmarkCase: AnalysisBenchmarkCase): Promise<MediaSource> {
    const entries: NetworkDirectoryEntry[] =
      await new NetworkDirectoryService(server).list(benchmarkCase.directoryPath, true);
    const matches: NetworkDirectoryEntry[] = entries.filter((entry: NetworkDirectoryEntry): boolean =>
      entry.kind === NetworkDirectoryEntryKind.FILE && entry.displayName === benchmarkCase.fileName);
    if (matches.length !== 1) throw new Error(`benchmark fixture unavailable: ${benchmarkCase.fileName}`);
    return NetworkMediaSourceFactory.fromEntry(server, matches[0]);
  }

  private static parseConfig(payload: string): AnalysisBenchmarkConfig {
    if (payload.length <= 0 || payload.length > 524288) throw new Error('benchmark config size');
    const config: AnalysisBenchmarkConfig = JSON.parse(payload) as AnalysisBenchmarkConfig;
    if (config.schemaVersion !== 1) {
      throw new Error('benchmark config schemaVersion invalid');
    }
    if (!config.mode) config.mode = 'cost';
    if (!Number.isSafeInteger(config.warmups)) config.warmups = 2;
    if (!Number.isSafeInteger(config.repetitions)) config.repetitions = 20;
    if (!Array.isArray(config.cases)) config.cases = [];
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
        maxLimit: 524288
      });
      if (response.responseCode !== 200) throw new Error('benchmark config unavailable');
      return response.result as string;
    } finally {
      client.destroy();
    }
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

  private static context(): common.UIAbilityContext {
    if (AnalysisBenchmarkRunner.benchmarkContext === null) throw new Error('benchmark context unavailable');
    return AnalysisBenchmarkRunner.benchmarkContext;
  }
}
