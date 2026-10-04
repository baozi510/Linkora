import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { IMediaProbe, MediaInfo, MediaSource, MediaSourceKind, MediaFormat, ProbeResult, ProbeRequirement,
  RandomAccessSource, SourceCapabilities, RemoteProtocol, ThumbnailExtractRequest } from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { NetworkMediaProbe, ProbeMode } from 'linkora_media_probe';
import { AnalysisComposition } from '../../AnalysisComposition';
import { HarmonyAnalysisInputs } from '../../../main/ets/analysis/HarmonyAnalysisInputs';
import { MediaAnalysisInputResolver, AnalysisInputPorts, AnalysisProxyRegistration } from '../../../main/ets/analysis/MediaAnalysisInputResolver';
import { AnalysisOperation, AnalysisError, AnalysisErrorCode } from '../../../main/ets/analysis/AnalysisOperation';
import { MediaAnalysisComparison } from '../../../main/ets/analysis/MediaAnalysisComparison';
import { NetworkServerStore, NetworkServerDraft } from '../../../main/ets/services/NetworkServerStore';
import { SystemWebPEncoder } from '../../../main/ets/services/SystemWebPEncoder';

interface Fixture { name: string; url: string; durationMs: number; width: number; height: number; }
interface SmokeConfig { fixtures: Fixture[]; host: string; port: number; remotePath: string; remoteSize: number; corrupt: string; }
interface Evidence {
  case: string; status: string; engine?: string; requirement?: ProbeRequirement; errorCode?: number;
  info?: MediaInfo; completeness?: string; comparison?: MediaAnalysisComparison; notes?: string[];
  activeSources?: number; sourceCloses?: number; reads?: number; width?: number; height?: number;
  requestedTimeMs?: number; pixelFormat?: string; bytesValid?: boolean; webp?: boolean;
  passed?: number; failed?: number; removedOwnedServer?: boolean;
}

/** Only test data stalls. Native analyzer, System stage, and proxy sockets are real. */
class StallingSource implements RandomAccessSource {
  reads: number = 0; closes: number = 0;
  private ended: boolean = false;
  private rejects: ((error: Error) => void)[] = [];
  readonly started: Promise<void>;
  private start: () => void = () => {};
  constructor() { this.started = new Promise((resolve) => { this.start = resolve; }); }
  id(): string { return 'analysis-stall'; } size(): number { return 1000000; }
  capabilities(): SourceCapabilities { return new SourceCapabilities(); }
  readAt(_offset: number, _length: number): Promise<ArrayBuffer> {
    this.reads++; this.start();
    if (this.ended) return Promise.reject(new Error('test source closed'));
    return new Promise((_resolve, reject) => { this.rejects.push(reject); });
  }
  cancel(): void { this.ended = true; for (const reject of this.rejects) reject(new Error('test source closed')); this.rejects = []; }
  async close(): Promise<void> { this.cancel(); this.closes++; }
}
class StallingInputs implements AnalysisInputPorts {
  readonly source: StallingSource = new StallingSource();
  private readonly proxy: NetworkFileProxy;
  constructor(proxy: NetworkFileProxy) { this.proxy = proxy; }
  async openHttp(_source: MediaSource, _operation: AnalysisOperation): Promise<RandomAccessSource> { return this.source; }
  async openRemote(_source: MediaSource, _operation: AnalysisOperation): Promise<RandomAccessSource> { return this.source; }
  async register(source: RandomAccessSource): Promise<AnalysisProxyRegistration> {
    const lease = await this.proxy.buildSourceUrl(source, 'application/octet-stream'); return new AnalysisProxyRegistration(lease.url, () => lease.release());
  }
}

/** Functional evidence only. No engine execution times, speed rankings, or cache persistence. */
export class AnalyzerIntegrationSmoke {
  private static endpoint: string = '';
  private static passed: number = 0; private static failed: number = 0;
  private static check(value: boolean): void { if (!value) throw new AnalysisError(AnalysisErrorCode.FAILED); }
  private static async emit(record: Evidence): Promise<void> {
    hilog.info(0x0001, 'AnalyzerSmoke', '%{public}s', 'LINKORA_ANALYZER:' + JSON.stringify(record));
    const client = http.createHttp();
    try {
      const response = await client.request(AnalyzerIntegrationSmoke.endpoint + '/evidence', {
        method: http.RequestMethod.POST, extraData: JSON.stringify(record),
        header: { 'Content-Type': 'application/json' }, connectTimeout: 8000, readTimeout: 8000 });
      AnalyzerIntegrationSmoke.check(response.responseCode === 200);
    } finally { client.destroy(); }
  }
  private static async caseRun(name: string, action: () => Promise<void>): Promise<void> {
    await AnalyzerIntegrationSmoke.emit({ case: name, status: 'START' });
    try { await action(); AnalyzerIntegrationSmoke.passed++; await AnalyzerIntegrationSmoke.emit({ case: name, status: 'PASS' }); }
    catch (error) { AnalyzerIntegrationSmoke.failed++; await AnalyzerIntegrationSmoke.emit({ case: name, status: 'FAIL', errorCode: AnalysisError.from(error as Object).code }); }
  }
  private static source(url: string, name: string): MediaSource {
    return new MediaSource(MediaSourceKind.NETWORK_LINK, url, name, '', name.endsWith('.mp4') ? MediaFormat.MP4 : MediaFormat.MATROSKA);
  }
  private static makeProbe(engine: string, resolver: MediaAnalysisInputResolver, timeout: number = 10000): IMediaProbe {
    return engine === 'system' ? AnalysisComposition.system(resolver) : AnalysisComposition.ffmpeg(resolver, timeout);
  }
  private static async probe(name: string, source: MediaSource, engine: string, requirement: ProbeRequirement,
    resolver: MediaAnalysisInputResolver, proxy: NetworkFileProxy): Promise<ProbeResult> {
    const probe = AnalyzerIntegrationSmoke.makeProbe(engine, resolver);
    await AnalyzerIntegrationSmoke.emit({ case: name, status: 'START', engine });
    let result: ProbeResult;
    try { AnalyzerIntegrationSmoke.check(await probe.canProbe(source)); result = await probe.probe(source, requirement); }
    finally { await probe.close(); await probe.close(); }
    AnalyzerIntegrationSmoke.check(proxy.diagnostics().activeSources === 0);
    await AnalyzerIntegrationSmoke.emit({ case: name, status: result.isUsable() && result.errorCode === 0 ? 'SUCCESS' : 'UNAVAILABLE',
      engine, requirement, errorCode: result.errorCode, completeness: result.completeness, info: result.info ?? undefined,
      notes: result.diagnostics.notes, activeSources: proxy.diagnostics().activeSources });
    return result;
  }
  private static async webp(frame: image.PixelMap): Promise<boolean> {
    const bytes = new Uint8Array(await new SystemWebPEncoder().encode(frame, 80));
    return bytes.length > 12 && bytes[0] === 82 && bytes[1] === 73 && bytes[2] === 70 && bytes[3] === 70 &&
      bytes[8] === 87 && bytes[9] === 69 && bytes[10] === 66 && bytes[11] === 80;
  }
  private static async thumbnails(fixture: Fixture, source: MediaSource, resolver: MediaAnalysisInputResolver, proxy: NetworkFileProxy): Promise<void> {
    const time = Math.floor(fixture.durationMs * 0.7); const width = Math.min(480, fixture.width);
    const height = Math.max(1, Math.floor(width * fixture.height / fixture.width));
    await AnalyzerIntegrationSmoke.caseRun(fixture.name + '-ffmpeg-thumbnail', async () => {
      const extractor = AnalysisComposition.thumbnail(resolver); let frame: image.PixelMap | null = null;
      try {
        const raw = await extractor.extract(source, new ThumbnailExtractRequest(time, 480, 270));
        AnalyzerIntegrationSmoke.check(raw !== null);
        try {
          const pixels = await raw!.readPixels();
          AnalyzerIntegrationSmoke.check(raw!.width() > 0 && raw!.height() > 0 && raw!.width() <= 480 && raw!.height() <= 270 &&
            Math.abs(raw!.width() / raw!.height() - fixture.width / fixture.height) < 0.02 && raw!.pixelFormat() === 'rgba_8888' &&
            pixels.byteLength === raw!.width() * raw!.height() * 4);
          frame = await image.createPixelMap(pixels, { size: { width: raw!.width(), height: raw!.height() }, pixelFormat: image.PixelMapFormat.RGBA_8888 });
          const webp = await AnalyzerIntegrationSmoke.webp(frame); AnalyzerIntegrationSmoke.check(webp);
          await AnalyzerIntegrationSmoke.emit({ case: fixture.name + '-thumbnail', status: 'SUCCESS', engine: 'ffmpeg',
            width: raw!.width(), height: raw!.height(), requestedTimeMs: time, pixelFormat: raw!.pixelFormat(), bytesValid: true, webp,
            activeSources: proxy.diagnostics().activeSources });
        } finally { await raw!.release(); await raw!.release(); }
      } finally { await frame?.release(); await extractor.close(); await extractor.close(); }
      AnalyzerIntegrationSmoke.check(proxy.diagnostics().activeSources === 0);
    });
    await AnalyzerIntegrationSmoke.caseRun(fixture.name + '-system-thumbnail', async () => {
      const operation = new AnalysisOperation(); const lease = await resolver.resolve(source, 'system', operation);
      const probe = new NetworkMediaProbe(); let frame: image.PixelMap | null = null;
      try {
        const result = await probe.inspect(lease.input.uri, {}, { mode: ProbeMode.THUMBNAIL, durationHintMs: fixture.durationMs,
          widthHint: fixture.width, heightHint: fixture.height, thumbnailPlan: () => { return { timeMs: time, width, height }; } });
        frame = result.thumbnail;
        if (frame === null) { await AnalyzerIntegrationSmoke.emit({ case: fixture.name + '-thumbnail', engine: 'system', status: 'UNAVAILABLE', errorCode: result.errorCode, requestedTimeMs: time }); return; }
        const data = await frame.getImageInfo(); const webp = await AnalyzerIntegrationSmoke.webp(frame);
        AnalyzerIntegrationSmoke.check(data.size.width > 0 && data.size.height > 0 && data.size.width <= 480 && data.size.height <= 270 &&
          Math.abs(data.size.width / data.size.height - fixture.width / fixture.height) < 0.02 && webp);
        await AnalyzerIntegrationSmoke.emit({ case: fixture.name + '-thumbnail', engine: 'system', status: 'SUCCESS',
          width: data.size.width, height: data.size.height, requestedTimeMs: time, pixelFormat: '' + data.pixelFormat, webp });
      } finally { await frame?.release(); await probe.close(); await lease.release(); operation.complete(); }
      AnalyzerIntegrationSmoke.check(proxy.diagnostics().activeSources === 0);
    });
  }
  private static async blocked(engine: string, mode: string, proxy: NetworkFileProxy): Promise<void> {
    const ports = new StallingInputs(proxy); const resolver = new MediaAnalysisInputResolver(ports);
    const source = AnalyzerIntegrationSmoke.source('https://fixture.invalid/stall.mp4', 'stall.mp4');
    const probe = AnalyzerIntegrationSmoke.makeProbe(engine, resolver, mode === 'timeout' ? 600 : 10000);
    let done: boolean = false;
    const pending = probe.probe(source, ProbeRequirement.DETAIL).then((result) => { done = true; return result; });
    let timer: number = -1;
    try {
      await Promise.race([ports.source.started, new Promise<void>((_resolve, reject) => { timer = setTimeout(() => reject(new Error('source never started')), 5000); })]);
      if (timer >= 0) clearTimeout(timer);
      AnalyzerIntegrationSmoke.check(ports.source.reads > 0 && !done);
      if (mode === 'cancel') probe.cancel();
      const closing = mode === 'close' ? probe.close() : Promise.resolve();
      const result = await pending; await closing;
      AnalyzerIntegrationSmoke.check(result.errorCode === (mode === 'timeout' ? AnalysisErrorCode.TIMEOUT : AnalysisErrorCode.CANCELLED));
      await AnalyzerIntegrationSmoke.emit({ case: engine + '-' + mode, status: 'DATA', engine, errorCode: result.errorCode,
        reads: ports.source.reads, sourceCloses: ports.source.closes, activeSources: proxy.diagnostics().activeSources });
    } finally { if (timer >= 0) clearTimeout(timer); await probe.close(); }
    AnalyzerIntegrationSmoke.check(ports.source.closes === 1 && proxy.diagnostics().activeSources === 0);
  }
  private static async blockedThumbnail(mode: string, proxy: NetworkFileProxy): Promise<void> {
    const ports = new StallingInputs(proxy); const resolver = new MediaAnalysisInputResolver(ports);
    const extractor = AnalysisComposition.thumbnail(resolver, mode === 'timeout' ? 600 : 10000);
    let code: number = 0; let timer: number = -1;
    const pending = extractor.extract(AnalyzerIntegrationSmoke.source('https://fixture.invalid/stall.mp4', 'stall.mp4'),
      new ThumbnailExtractRequest(1000)).then(async (raw) => { await raw?.release(); }, (error: Object) => { code = AnalysisError.from(error).code; });
    try {
      await Promise.race([ports.source.started, new Promise<void>((_resolve, reject) => { timer = setTimeout(() => reject(new Error('source never started')), 5000); })]);
      if (timer >= 0) clearTimeout(timer);
      if (mode === 'cancel') extractor.cancel();
      const closed = mode === 'close' ? extractor.close() : Promise.resolve();
      await pending; await closed;
      AnalyzerIntegrationSmoke.check(code === (mode === 'timeout' ? AnalysisErrorCode.TIMEOUT : AnalysisErrorCode.CANCELLED));
    } finally { if (timer >= 0) clearTimeout(timer); await extractor.close(); }
    AnalyzerIntegrationSmoke.check(ports.source.closes === 1 && proxy.diagnostics().activeSources === 0);
    await AnalyzerIntegrationSmoke.emit({ case: 'thumbnail-' + mode, status: 'DATA', errorCode: code,
      reads: ports.source.reads, sourceCloses: ports.source.closes, activeSources: proxy.diagnostics().activeSources });
  }
  static async run(context: common.UIAbilityContext, endpoint: string): Promise<void> {
    AnalyzerIntegrationSmoke.endpoint = endpoint; AnalyzerIntegrationSmoke.passed = 0; AnalyzerIntegrationSmoke.failed = 0;
    const proxy = new NetworkFileProxy(); const ports = new HarmonyAnalysisInputs(context, proxy);
    const resolver = new MediaAnalysisInputResolver(ports); const store = new NetworkServerStore(context); let ownedServer: number = 0;
    try {
      const client = http.createHttp(); let config: SmokeConfig;
      try { const response = await client.request(endpoint, { expectDataType: http.HttpDataType.STRING });
        AnalyzerIntegrationSmoke.check(response.responseCode === 200); config = JSON.parse(response.result as string) as SmokeConfig; }
      finally { client.destroy(); }
      await AnalyzerIntegrationSmoke.emit({ case: 'begin', status: 'DATA' });
      for (const fixture of config.fixtures) {
        const source = AnalyzerIntegrationSmoke.source(fixture.url, fixture.name);
        await AnalyzerIntegrationSmoke.caseRun(fixture.name + '-probes', async () => {
          const system = await AnalyzerIntegrationSmoke.probe(fixture.name, source, 'system', ProbeRequirement.DETAIL, resolver, proxy);
          const ffmpeg = await AnalyzerIntegrationSmoke.probe(fixture.name, source, 'ffmpeg', ProbeRequirement.DETAIL, resolver, proxy);
          AnalyzerIntegrationSmoke.check(ffmpeg.isUsable() && ffmpeg.errorCode === 0);
          await AnalyzerIntegrationSmoke.emit({ case: fixture.name + '-comparison', status: 'DATA', comparison: MediaAnalysisComparison.compare(system, ffmpeg) });
          if (fixture.name === 'h264.mp4') {
            for (const requirement of [ProbeRequirement.LIST, ProbeRequirement.ADVANCED]) {
              for (const engine of ['system', 'ffmpeg']) await AnalyzerIntegrationSmoke.probe(fixture.name, source, engine, requirement, resolver, proxy);
            }
          }
        });
        await AnalyzerIntegrationSmoke.thumbnails(fixture, source, resolver, proxy);
      }
      await AnalyzerIntegrationSmoke.caseRun('webdav', async () => {
        const display = 'Phase2-owned-' + endpoint.substring(endpoint.lastIndexOf('/') + 1);
        const servers = await store.add(new NetworkServerDraft(display, RemoteProtocol.WEBDAV, config.host, config.port));
        const own = servers.find((server) => server.displayName === display);
        AnalyzerIntegrationSmoke.check(own !== undefined); ownedServer = own!.id;
        const source = MediaSource.fromRemoteFile(config.remotePath, 'remote.mkv', '', config.remoteSize, 'network-server:' + ownedServer);
        const system = await AnalyzerIntegrationSmoke.probe('webdav', source, 'system', ProbeRequirement.DETAIL, resolver, proxy);
        const ffmpeg = await AnalyzerIntegrationSmoke.probe('webdav', source, 'ffmpeg', ProbeRequirement.ADVANCED, resolver, proxy);
        AnalyzerIntegrationSmoke.check(ffmpeg.isUsable() && ffmpeg.errorCode === 0);
        await AnalyzerIntegrationSmoke.emit({ case: 'webdav-comparison', status: 'DATA', comparison: MediaAnalysisComparison.compare(system, ffmpeg) });
        const fixture: Fixture = { name: 'webdav', url: '', durationMs: 60000, width: 640, height: 360 };
        await AnalyzerIntegrationSmoke.thumbnails(fixture, source, resolver, proxy);
      });
      for (const engine of ['system', 'ffmpeg']) {
        await AnalyzerIntegrationSmoke.caseRun(engine + '-corrupt', async () => {
          const result = await AnalyzerIntegrationSmoke.probe('corrupt', AnalyzerIntegrationSmoke.source(config.corrupt, 'corrupt.mp4'), engine, ProbeRequirement.DETAIL, resolver, proxy);
          AnalyzerIntegrationSmoke.check(!result.isUsable() && result.errorCode > 0);
        });
        for (const mode of ['cancel', 'close', 'timeout']) await AnalyzerIntegrationSmoke.caseRun(engine + '-' + mode, () => AnalyzerIntegrationSmoke.blocked(engine, mode, proxy));
      }
      for (const mode of ['cancel', 'close', 'timeout']) await AnalyzerIntegrationSmoke.caseRun('thumbnail-' + mode, () => AnalyzerIntegrationSmoke.blockedThumbnail(mode, proxy));
      await AnalyzerIntegrationSmoke.caseRun('concurrent-independent', async () => {
        const source = AnalyzerIntegrationSmoke.source(config.fixtures[0].url, config.fixtures[0].name);
        const left = AnalysisComposition.ffmpeg(resolver); const right = AnalysisComposition.system(resolver);
        try { const result = await Promise.all([left.probe(source, ProbeRequirement.DETAIL), right.probe(source, ProbeRequirement.LIST)]);
          AnalyzerIntegrationSmoke.check(result.every((probe) => probe.isUsable() && probe.errorCode === 0)); }
        finally { await left.close(); await right.close(); }
        AnalyzerIntegrationSmoke.check(proxy.diagnostics().activeSources === 0);
      });
    } catch (error) { AnalyzerIntegrationSmoke.failed++; await AnalyzerIntegrationSmoke.emit({ case: 'harness', status: 'FAIL', errorCode: AnalysisError.from(error as Object).code }); }
    finally {
      await proxy.close(); if (ownedServer > 0) await store.remove(ownedServer);
      await AnalyzerIntegrationSmoke.emit({ case: 'summary', status: AnalyzerIntegrationSmoke.failed === 0 ? 'PASS' : 'FAIL',
        passed: AnalyzerIntegrationSmoke.passed, failed: AnalyzerIntegrationSmoke.failed, activeSources: proxy.diagnostics().activeSources, removedOwnedServer: ownedServer > 0 });
    }
  }
}
