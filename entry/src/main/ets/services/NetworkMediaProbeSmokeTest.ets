import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { RemoteProtocol, RemoteReadSession } from 'linkora_core';
import { MediaProbeResult, MediaProbeTimings, NetworkMediaProbe, ProbeMode, ProbeStatus } from 'linkora_media_probe';
import { NetworkFileProxy, ProxyUrlLease } from 'linkora_proxy';
import { LinkoraFeatures } from '../foundation/LinkoraFeatures';
import { NetworkDirectoryService } from './NetworkDirectoryService';
import { NetworkAdvancedOptions, NetworkServerEntry, SftpHostKeyPolicy } from './NetworkServerStore';

interface ProbeFixture {
  label: string; protocol: string; host: string; port: number; rootPath: string; remotePath: string;
  username: string; password: string; fingerprint: string; sourceUrl: string;
  expectedDurationMs: number; expectedWidth: number; expectedHeight: number;
  mode: string; controlUrl: string;
  probeMode: string;
}
interface ProbeConfig { cases: ProbeFixture[]; }
interface ProbeEvidence {
  label: string; passed: boolean; status: string; durationMs: number; width: number; height: number;
  frameWidth: number; frameHeight: number; file: string; elapsedMs: number; closeMs: number;
  readCount: number; readBytes: number; errorCode: number; headerCount: number; cleanupComplete: boolean;
  sourcePrepareMs: number; timings: MediaProbeTimings | null; metadataReadyMs: number | null;
  imageEncodingMs: number | null;
}

class CountingReader implements RemoteReadSession {
  reads: number = 0; bytes: number = 0;
  private readonly reader: RemoteReadSession;
  constructor(reader: RemoteReadSession) { this.reader = reader; }
  size(): number { return this.reader.size(); }
  async read(offset: number, length: number): Promise<ArrayBuffer> {
    this.reads++;
    const data = await this.reader.read(offset, length); this.bytes += data.byteLength; return data;
  }
  cancel(): void { this.reader.cancel(); }
  close(): Promise<void> { return this.reader.close(); }
}

/** Dedicated Debug-only invocation; never writes to user media, history, or database. */
export class NetworkMediaProbeSmokeTest {
  private static readonly pendingCleanup: Set<Promise<void>> = new Set();
  static async run(context: common.UIAbilityContext, configUrl: string): Promise<void> {
    const results: ProbeEvidence[] = [];
    let failed: boolean = false;
    let validation: boolean = false;
    try {
      if (!/^http:\/\/10\.0\.2\.2:\d+\/[a-f0-9-]{36}$/.test(configUrl)) throw new Error('fixture address');
      const payload = await NetworkMediaProbeSmokeTest.request(configUrl);
      if (payload.length > 65536) throw new Error('fixture size');
      const config = JSON.parse(payload) as ProbeConfig;
      if (config.cases.length > 16) throw new Error('fixture count');
      const validator = LinkoraFeatures.createNetworkMediaProbe();
      let rejected: number = 0;
      for (const source of ['file:///tmp/test', 'http://user:pass@example.com/v', 'http:///']) {
        try { await validator.inspect(source); } catch (_error) { rejected++; }
      }
      await validator.close(); validation = rejected === 3;
      for (let i: number = 0; i < config.cases.length; i++) {
        const fixture = config.cases[i];
        if (!/^[a-z0-9-]{1,32}$/.test(fixture.label)) throw new Error('fixture label');
        const result = await NetworkMediaProbeSmokeTest.inspect(context, fixture, i);
        results.push(result);
        if (!result.cleanupComplete) break;
      }
    } catch (_error) { failed = true; }
    NetworkMediaProbeSmokeTest.write(`${context.cacheDir}/media-probe-smoke-result.json`, JSON.stringify({ complete: true,
      passed: !failed && validation && results.length > 0 && results.every((item: ProbeEvidence) => item.passed),
      validation, results }));
  }

  private static async inspect(context: common.UIAbilityContext, fixture: ProbeFixture, index: number): Promise<ProbeEvidence> {
    const probe: NetworkMediaProbe = LinkoraFeatures.createNetworkMediaProbe();
    const proxy: NetworkFileProxy = LinkoraFeatures.createNetworkFileProxy();
    let lease: ProxyUrlLease | null = null;
    let reader: CountingReader | null = null;
    let leaseClosing: Promise<void> | null = null;
    let thumbnail: image.PixelMap | null = null;
    const evidence: ProbeEvidence = { label: fixture.label, passed: false, status: 'failed', durationMs: 0,
      width: 0, height: 0, frameWidth: 0, frameHeight: 0, file: '', elapsedMs: 0, closeMs: 0,
      readCount: 0, readBytes: 0, errorCode: 0, headerCount: 0, cleanupComplete: false,
      sourcePrepareMs: 0, timings: null, metadataReadyMs: null, imageEncodingMs: null };
    const sourceStarted: number = Date.now();
    try {
      let source: string = fixture.sourceUrl;
      let headers: Record<string, string> = {};
      if (fixture.protocol !== 'http') {
        const options = new NetworkAdvancedOptions();
        if (fixture.protocol === RemoteProtocol.SFTP) options.sftpHostKeyPolicy = SftpHostKeyPolicy.STRICT;
        const server = new NetworkServerEntry(0, 'media fixture', fixture.protocol as RemoteProtocol,
          fixture.host, fixture.port, fixture.rootPath, fixture.username, fixture.password, false, 0, options);
        const service = new NetworkDirectoryService(server);
        reader = new CountingReader(await service.openReader(fixture.remotePath, fixture.fingerprint));
        lease = await proxy.buildProxyUrl(reader, 'video/mp4'); source = lease.url;
      }
      evidence.headerCount = Object.keys(headers).length;
      evidence.sourcePrepareMs = Date.now() - sourceStarted;
      const started: number = Date.now();
      const mode: ProbeMode = fixture.probeMode === ProbeMode.METADATA ? ProbeMode.METADATA :
        fixture.probeMode === ProbeMode.THUMBNAIL ? ProbeMode.THUMBNAIL : ProbeMode.BOTH;
      const pending: Promise<MediaProbeResult> = probe.inspect(source, headers, { mode,
        durationHintMs: fixture.expectedDurationMs, onMetadata: () => { evidence.metadataReadyMs = Date.now() - started; } });
      if (fixture.mode === 'cancel') {
        await NetworkMediaProbeSmokeTest.request(`${fixture.controlUrl}/entered`);
        const cancelled: number = Date.now();
        probe.cancel();
        if (lease !== null) { leaseClosing = lease.release(); leaseClosing.catch(() => {}); }
        const result = await pending;
        evidence.timings = result.timings ?? null;
        evidence.elapsedMs = Date.now() - cancelled;
        evidence.status = result.status;
        evidence.passed = result.status === ProbeStatus.CANCELLED && evidence.elapsedMs < 1000;
      } else {
        const result = await pending;
        evidence.timings = result.timings ?? null;
        evidence.elapsedMs = Date.now() - started;
        evidence.status = result.status; evidence.durationMs = result.durationMs;
        evidence.width = result.width; evidence.height = result.height; evidence.errorCode = result.errorCode;
        thumbnail = result.thumbnail;
        if (fixture.mode === 'timeout') {
          evidence.passed = result.status === ProbeStatus.TIMEOUT && evidence.elapsedMs >= 7500 && evidence.elapsedMs < 10000;
        } else if (fixture.mode === 'unavailable') {
          evidence.passed = (result.status === ProbeStatus.UNAVAILABLE || result.status === ProbeStatus.METADATA_ONLY) &&
            result.durationMs === 0 && result.width === 0 && result.height === 0 && thumbnail === null;
        } else {
          const metadataExpected: boolean = mode !== ProbeMode.THUMBNAIL;
          evidence.passed = result.status === (mode === ProbeMode.METADATA ? ProbeStatus.METADATA_ONLY : ProbeStatus.COMPLETE) &&
            result.metadataComplete === metadataExpected && (thumbnail !== null) === (mode !== ProbeMode.METADATA) &&
            Math.abs(result.durationMs - fixture.expectedDurationMs) <= 250 &&
            result.width === (metadataExpected ? fixture.expectedWidth : 0) &&
            result.height === (metadataExpected ? fixture.expectedHeight : 0);
          if (thumbnail !== null) {
            const info = await thumbnail.getImageInfo();
            evidence.frameWidth = info.size.width; evidence.frameHeight = info.size.height;
            evidence.passed = evidence.passed && info.size.width > 0 && info.size.height > 0;
            const packer = image.createImagePacker();
            try {
              const format: string = packer.supportedFormats.includes('image/webp') ? 'webp' : 'jpg';
              const encodingStarted: number = Date.now();
              const data = await packer.packing(thumbnail, { format: format === 'webp' ? 'image/webp' : 'image/jpeg', quality: 85 });
              evidence.imageEncodingMs = Date.now() - encodingStarted;
              evidence.file = `media-probe-${index}.${format}`;
              NetworkMediaProbeSmokeTest.write(`${context.cacheDir}/${evidence.file}`, data);
            } finally { await packer.release(); }
          }
        }
      }
    } catch (_error) {
      evidence.status = ProbeStatus.UNAVAILABLE;
      evidence.passed = fixture.mode === 'unavailable';
    }
    finally {
      const closing = Date.now();
      probe.cancel();
      const readerClosing: Promise<void> = leaseClosing ?? lease?.release() ?? reader?.close() ?? Promise.resolve();
      const probeClosing: Promise<void> = probe.close();
      const cleanup: Promise<void> = (async (): Promise<void> => {
        try {
          if (fixture.controlUrl.length > 0) {
            try { await NetworkMediaProbeSmokeTest.request(`${fixture.controlUrl}/resume`); } catch (_error) {}
          }
          await Promise.all([readerClosing, probeClosing]);
        } finally {
          try { await thumbnail?.release(); } finally { await proxy.close(); }
        }
      })();
      // Keep ownership on a failed watchdog; the host stops this test process after receiving failure evidence.
      NetworkMediaProbeSmokeTest.pendingCleanup.add(cleanup);
      cleanup.then(() => NetworkMediaProbeSmokeTest.pendingCleanup.delete(cleanup),
        () => NetworkMediaProbeSmokeTest.pendingCleanup.delete(cleanup));
      let timer: number = -1;
      const timely = await Promise.race([cleanup.then(() => true, () => false),
        new Promise<boolean>((resolve) => { timer = setTimeout(() => resolve(false), 10000); })]);
      clearTimeout(timer);
      evidence.closeMs = Date.now() - closing; evidence.passed = evidence.passed && timely;
      evidence.cleanupComplete = timely;
      evidence.readCount = reader?.reads ?? 0; evidence.readBytes = reader?.bytes ?? 0;
    }
    return evidence;
  }

  private static async request(source: string): Promise<string> {
    const client = http.createHttp();
    try {
      const response = await client.request(source, { method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING, maxLimit: 65536, connectTimeout: 8000, readTimeout: 8000 });
      if (response.responseCode !== 200) throw new Error('fixture request');
      return response.result as string;
    } finally { client.destroy(); }
  }
  private static write(path: string, value: string | ArrayBuffer): void {
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try { fileIo.writeSync(file.fd, value); } finally { fileIo.closeSync(file.fd); }
  }
}
