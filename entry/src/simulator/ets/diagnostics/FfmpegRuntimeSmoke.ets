import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RandomAccessSource, SourceCapabilities, RemoteProtocol } from 'linkora_core';
import { NetworkFileProxy, ProxyUrlLease } from 'linkora_proxy';
import { createFfmpegAnalysis } from 'linkora_ffmpeg/Native';
import { FfmpegAnalysis, FfmpegRawThumbnail, NativeProbeResult, NativeFrameResult } from 'linkora_ffmpeg';
import { NetworkDirectoryService } from '../../../main/ets/services/NetworkDirectoryService';
import { NetworkServerEntry } from '../../../main/ets/services/NetworkServerStore';

interface SmokeConfig {
  mp4: string; mkv: string; host: string; port: number; remotePath: string;
  username: string; password: string;
}
interface Evidence {
  case: string; status: string; code?: string; elapsedMs?: number; cycle?: number;
  container?: string; durationMs?: number; sizeBytes?: number; video?: string; audio?: string;
  videoProfile?: string; audioProfile?: string; subtitles?: number;
  width?: number; height?: number; channels?: number; sampleRate?: number; frameRate?: number;
  timeMs?: number; bytes?: number; pixelFormat?: string; pixelHash?: string;
  reads?: number; proxyBytes?: number; activeSources?: number; activeClients?: number;
  releasedSources?: number; closes?: number; startedReads?: number; passed?: number; failed?: number;
}
interface NativeError { code?: string; detail?: string; }

/** Only the test source stalls; all sockets, leases and FFmpeg work are real. */
class StallingSource implements RandomAccessSource {
  reads: number = 0; closes: number = 0;
  private rejectRead: ((error: Error) => void) | null = null;
  private ended: boolean = false;
  id(): string { return 'simulator-stall'; }
  size(): number { return 1000000; }
  capabilities(): SourceCapabilities { return new SourceCapabilities(); }
  readAt(_offset: number, _length: number): Promise<ArrayBuffer> {
    this.reads++;
    if (this.ended) return Promise.reject(new Error('test source closed'));
    return new Promise<ArrayBuffer>((_resolve, reject) => { this.rejectRead = reject; });
  }
  cancel(): void { this.ended = true; this.rejectRead?.(new Error('test source closed')); this.rejectRead = null; }
  async close(): Promise<void> { this.cancel(); this.closes++; }
}

export class FfmpegRuntimeSmoke {
  private static passed: number = 0;
  private static failed: number = 0;
  private static emit(record: Evidence): void {
    // Callers construct whitelisted fields only. Never log native detail/input/config.
    hilog.info(0x0001, 'FFmpegSmoke', '%{public}s', 'LINKORA_FFMPEG_SMOKE:' + JSON.stringify(record));
  }
  private static check(value: boolean): void { if (!value) throw new Error('smoke assertion'); }
  private static code(error: Object): string {
    const code = (error as NativeError).code;
    return typeof code === 'string' && /^FF_[A-Z_]{1,40}$/.test(code) ? code : 'SMOKE_ASSERTION';
  }
  private static async caseRun(name: string, action: () => Promise<void>): Promise<void> {
    const start = Date.now();
    try { await action(); FfmpegRuntimeSmoke.passed++; FfmpegRuntimeSmoke.emit({ case: name, status: 'PASS', elapsedMs: Date.now() - start }); }
    catch (error) { FfmpegRuntimeSmoke.failed++; FfmpegRuntimeSmoke.emit({ case: name, status: 'FAIL', code: FfmpegRuntimeSmoke.code(error), elapsedMs: Date.now() - start }); }
  }
  private static delay(ms: number): Promise<void> { return new Promise<void>((resolve) => { setTimeout(resolve, ms); }); }
  private static async get(url: string, binary: boolean): Promise<http.HttpResponse> {
    const client = http.createHttp();
    try {
      const response = await client.request(url, { method: http.RequestMethod.GET,
        expectDataType: binary ? http.HttpDataType.ARRAY_BUFFER : http.HttpDataType.STRING,
        connectTimeout: 8000, readTimeout: 15000, maxLimit: 16 * 1024 * 1024 });
      FfmpegRuntimeSmoke.check(response.responseCode === 200); return response;
    } finally { client.destroy(); }
  }
  private static async copy(url: string, path: string): Promise<void> {
    FfmpegRuntimeSmoke.check(/^http:\/\/10\.0\.2\.2:19333\/[a-f0-9-]{36}\/(mp4|mkv)$/.test(url));
    const response = await FfmpegRuntimeSmoke.get(url, true); const bytes = response.result as ArrayBuffer;
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try { FfmpegRuntimeSmoke.check(fileIo.writeSync(file.fd, bytes) === bytes.byteLength); }
    finally { fileIo.closeSync(file.fd); }
  }
  private static probeEvidence(name: string, result: NativeProbeResult): void {
    const v = result.video[0]; const a = result.audio[0];
    FfmpegRuntimeSmoke.emit({ case: name, status: 'DATA', container: result.container,
      durationMs: result.durationMs, sizeBytes: result.sizeBytes, video: v?.codec, audio: a?.codec,
      videoProfile: v?.profile, audioProfile: a?.profile, subtitles: result.subtitles.length,
      width: v?.width, height: v?.height, frameRate: v?.frameRate, channels: a?.channels, sampleRate: a?.sampleRate });
  }
  private static async frameEvidence(name: string, frame: NativeFrameResult, target: number,
    sourceWidth: number, sourceHeight: number): Promise<void> {
    FfmpegRuntimeSmoke.check(frame.width > 0 && frame.height > 0 && frame.width <= 480 && frame.height <= 270 &&
      frame.width <= sourceWidth && frame.height <= sourceHeight && Math.abs(frame.width / frame.height - sourceWidth / sourceHeight) < 0.02 &&
      frame.pixelFormat === 'rgba_8888' && frame.pixels.byteLength === frame.width * frame.height * 4 &&
      frame.timeMs >= target - 100 && frame.timeMs <= target + 1000);
    const raw = new FfmpegRawThumbnail(frame); const pixels = await raw.readPixels();
    FfmpegRuntimeSmoke.check(pixels !== frame.pixels && pixels.byteLength === frame.pixels.byteLength);
    const original = new Uint8Array(frame.pixels)[0]; new Uint8Array(pixels)[0] ^= 255;
    FfmpegRuntimeSmoke.check(new Uint8Array(frame.pixels)[0] === original);
    let hash = 2166136261;
    const view = new Uint8Array(frame.pixels);
    for (let i = 0; i < view.length; i++) hash = Math.imul(hash ^ view[i], 16777619) >>> 0;
    await raw.release(); await raw.release();
    let rejected = false; try { await raw.readPixels(); } catch (_error) { rejected = true; }
    FfmpegRuntimeSmoke.check(rejected);
    FfmpegRuntimeSmoke.emit({ case: name, status: 'DATA', width: frame.width, height: frame.height,
      timeMs: frame.timeMs, bytes: frame.pixels.byteLength, pixelFormat: frame.pixelFormat, pixelHash: hash.toString(16) });
  }
  private static async expectError(analysis: FfmpegAnalysis, name: string, input: string, expected: string): Promise<void> {
    let code = ''; let safe = false;
    try { await analysis.probe(name, input, 1000); }
    catch (error) { code = FfmpegRuntimeSmoke.code(error);
      const detail = (error as NativeError).detail ?? ''; safe = detail.length <= 256 && !detail.includes(input) && !detail.includes('127.0.0.1'); }
    FfmpegRuntimeSmoke.emit({ case: name, status: 'DATA', code });
    FfmpegRuntimeSmoke.check(code === expected && safe);
  }
  private static async blocked(proxy: NetworkFileProxy, local: string, cycle: number, cancel: boolean, close: boolean = false): Promise<void> {
    const source = new StallingSource(); const lease = await proxy.buildSourceUrl(source, 'video/mp4');
    const analysis = createFfmpegAnalysis(); const other = createFfmpegAnalysis();
    const start = Date.now(); let code = ''; let completed = false;
    const operation = (cycle % 2 === 0 && cancel ? analysis.extractFrame('blocked', lease.url, 1000, 480, 270, 10000) :
      analysis.probe('blocked', lease.url, cancel ? 10000 : 600)).then(() => { completed = true; },
      (error: Object) => { completed = true; code = FfmpegRuntimeSmoke.code(error); });
    try {
      // Cancellation is issued only after a real proxy source read has begun.
      const waiting = Date.now();
      while (source.reads === 0 && !completed && Date.now() - waiting < 3000) await FfmpegRuntimeSmoke.delay(10);
      FfmpegRuntimeSmoke.check(source.reads > 0 && !completed);
      const independent = other.probe('blocked', local, 5000);
      if (cancel) { if (close) analysis.close(); else analysis.cancel('blocked'); }
      await operation; const result = await independent;
      FfmpegRuntimeSmoke.check(code === (cancel ? 'FF_CANCELLED' : 'FF_TIMEOUT') && Date.now() - start < 4000 && result.video.length > 0);
    } finally { analysis.close(); other.close(); await lease.release(); }
    FfmpegRuntimeSmoke.check(source.closes === 1 && proxy.diagnostics().activeSources === 0);
    FfmpegRuntimeSmoke.emit({ case: close ? 'close-active-data' : cancel ? 'cancel-data' : 'timeout-data', status: 'DATA',
      cycle, code, elapsedMs: Date.now() - start, startedReads: source.reads, closes: source.closes,
      activeSources: proxy.diagnostics().activeSources, activeClients: proxy.diagnostics().activeClients });
  }
  static async run(context: common.UIAbilityContext, endpoint: string): Promise<void> {
    FfmpegRuntimeSmoke.passed = 0; FfmpegRuntimeSmoke.failed = 0;
    const proxy = new NetworkFileProxy();
    const local = `${context.filesDir}/ffmpeg-phase1b.mp4`; const mkv = `${context.filesDir}/ffmpeg-phase1b.mkv`;
    const corrupt = `${context.filesDir}/ffmpeg-phase1b-corrupt.bin`;
    let analysis: FfmpegAnalysis | null = null;
    try {
      analysis = createFfmpegAnalysis();
      FfmpegRuntimeSmoke.emit({ case: 'native-initialize', status: 'PASS' });
      const config = JSON.parse((await FfmpegRuntimeSmoke.get(endpoint, false)).result as string) as SmokeConfig;
      await FfmpegRuntimeSmoke.copy(config.mp4, local); await FfmpegRuntimeSmoke.copy(config.mkv, mkv);
      const invalidFile = fileIo.openSync(corrupt, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try { fileIo.writeSync(invalidFile.fd, 'corrupt fixture'); } finally { fileIo.closeSync(invalidFile.fd); }
      const engine = analysis;
      await FfmpegRuntimeSmoke.caseRun('local-mp4-probe', async () => {
        const result = await engine.probe('mp4', local); FfmpegRuntimeSmoke.probeEvidence('local-mp4', result);
        FfmpegRuntimeSmoke.check(result.container.includes('mov') && Math.abs(result.durationMs - 10000) < 300 && result.video.length === 1 &&
          result.audio.length === 1 && result.video[0].codec === 'h264' && result.video[0].width === 640 && result.video[0].height === 360 &&
          result.audio[0].codec === 'aac' && result.audio[0].sampleRate === 48000 && result.audio[0].channels === 2 && result.sizeBytes > 0);
      });
      await FfmpegRuntimeSmoke.caseRun('local-mkv-probe', async () => {
        const result = await engine.probe('mkv', mkv); FfmpegRuntimeSmoke.probeEvidence('local-mkv', result);
        FfmpegRuntimeSmoke.check(result.container.includes('matroska') && result.video[0].codec === 'hevc' && result.audio[0].codec === 'aac');
      });
      await FfmpegRuntimeSmoke.caseRun('local-frame', async () => {
        await FfmpegRuntimeSmoke.frameEvidence('local-frame-data', await engine.extractFrame('frame', local, 3000), 3000, 640, 360);
        await FfmpegRuntimeSmoke.frameEvidence('small-frame-data', await engine.extractFrame('small', mkv, 1000), 1000, 320, 180);
      });
      await FfmpegRuntimeSmoke.caseRun('mediaproxy-remote', async () => {
        const server = new NetworkServerEntry(0, 'runtime fixture', RemoteProtocol.WEBDAV, config.host, config.port,
          '/', config.username, config.password);
        const service = new NetworkDirectoryService(server); let lease: ProxyUrlLease | null = null;
        try {
          lease = await proxy.buildSourceUrl(await service.openSource(config.remotePath), 'video/x-matroska');
          const before = proxy.diagnostics(); const probeStarted = Date.now();
          const result = await engine.probe('remote', lease.url, 15000);
          const probeElapsed = Date.now() - probeStarted; const afterProbe = proxy.diagnostics();
          FfmpegRuntimeSmoke.emit({ case: 'remote-probe-io', status: 'DATA', elapsedMs: probeElapsed,
            reads: afterProbe.readRequests - before.readRequests, proxyBytes: afterProbe.bytesRead - before.bytesRead });
          FfmpegRuntimeSmoke.probeEvidence('remote-probe-data', result);
          FfmpegRuntimeSmoke.check(result.container.includes('matroska') && result.video.length > 0);
          const target = Math.floor(result.durationMs * 0.7); const started = Date.now();
          const frame = await engine.extractFrame('remote-frame', lease.url, target, 480, 270, 15000);
          const frameElapsed = Date.now() - started;
          await FfmpegRuntimeSmoke.frameEvidence('remote-frame-data', frame, target, result.video[0].width, result.video[0].height);
          const after = proxy.diagnostics();
          FfmpegRuntimeSmoke.emit({ case: 'remote-frame-io', status: 'DATA', elapsedMs: frameElapsed,
            timeMs: target, reads: after.readRequests - afterProbe.readRequests, proxyBytes: after.bytesRead - afterProbe.bytesRead });
        } finally { if (lease !== null) await lease.release(); service.cancel(); }
        const final = proxy.diagnostics(); FfmpegRuntimeSmoke.check(final.activeSources === 0);
        FfmpegRuntimeSmoke.emit({ case: 'remote-cleanup-data', status: 'DATA', activeSources: final.activeSources,
          activeClients: final.activeClients, releasedSources: final.releasedSources });
      });
      await FfmpegRuntimeSmoke.caseRun('timeout', async () => {
        await FfmpegRuntimeSmoke.blocked(proxy, local, 0, false);
        FfmpegRuntimeSmoke.check((await engine.probe('after-timeout', local)).video.length > 0);
      });
      for (let i = 1; i <= 10; i++) await FfmpegRuntimeSmoke.caseRun('cancel-cycle-' + i,
        async () => { await FfmpegRuntimeSmoke.blocked(proxy, local, i, true); });
      await FfmpegRuntimeSmoke.caseRun('close-active', async () => { await FfmpegRuntimeSmoke.blocked(proxy, local, 11, true, true); });
      const inputs: string[] = ['smb://invalid/item', 'http://127.0.0.1:0/token', 'http://user:secret@127.0.0.1:1/token',
        '/invalid\rpath', '/invalid\npath', '/invalid\u0000path', local + '-missing', corrupt];
      const names: string[] = ['invalid-scheme', 'malformed-loopback', 'userinfo', 'control-cr', 'control-lf', 'control-nul', 'missing-file', 'corrupt-file'];
      for (let i = 0; i < inputs.length; i++) await FfmpegRuntimeSmoke.caseRun(names[i], async () => {
        await FfmpegRuntimeSmoke.expectError(engine, names[i], inputs[i], i >= 6 ? 'FF_OPEN_FAILED' : 'FF_INVALID_INPUT');
      });
      await FfmpegRuntimeSmoke.caseRun('concurrent-two-probes', async () => {
        const results = await Promise.all([engine.probe('parallel-a', local), engine.probe('parallel-b', mkv)]);
        FfmpegRuntimeSmoke.check(results.every((r) => r.video.length > 0));
      });
      await FfmpegRuntimeSmoke.caseRun('concurrent-probe-frame', async () => {
        const request = engine.probe('parallel-probe', local); const frame = engine.extractFrame('parallel-frame', local, 4000);
        await FfmpegRuntimeSmoke.frameEvidence('parallel-frame-data', await frame, 4000, 640, 360);
        FfmpegRuntimeSmoke.check((await request).audio.length === 1);
      });
      FfmpegRuntimeSmoke.emit({ case: 'lifecycle-start', status: 'DATA' });
      for (let i = 1; i <= 20; i++) await FfmpegRuntimeSmoke.caseRun('lifecycle-' + i, async () => {
        await FfmpegRuntimeSmoke.delay(1000);
        const session = createFfmpegAnalysis();
        try {
          if (i % 2 === 0) await FfmpegRuntimeSmoke.frameEvidence('lifecycle-frame', await session.extractFrame('reused', local, 2000), 2000, 640, 360);
          else FfmpegRuntimeSmoke.check((await session.probe('reused', local)).video.length === 1);
        } finally { session.close(); session.close(); }
        let rejected = false; try { await session.probe('after-close', local); } catch (_error) { rejected = true; }
        FfmpegRuntimeSmoke.check(rejected);
      });
    } catch (error) {
      FfmpegRuntimeSmoke.failed++; FfmpegRuntimeSmoke.emit({ case: 'runner', status: 'FAIL', code: FfmpegRuntimeSmoke.code(error) });
    } finally {
      analysis?.close(); await proxy.close();
      for (const path of [local, mkv, corrupt]) { try { fileIo.unlinkSync(path); } catch (_error) {} }
      const final = proxy.diagnostics();
      FfmpegRuntimeSmoke.emit({ case: 'complete', status: FfmpegRuntimeSmoke.failed === 0 ? 'PASS' : 'FAIL',
        passed: FfmpegRuntimeSmoke.passed, failed: FfmpegRuntimeSmoke.failed,
        activeSources: final.activeSources, activeClients: final.activeClients });
    }
  }
}
