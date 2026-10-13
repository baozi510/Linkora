import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { createFfmpegAnalysis } from 'linkora_ffmpeg/Native';
import { FfmpegRawThumbnail, NativeFrameResult } from 'linkora_ffmpeg';
import { MediaSource, MediaSourceKind, MediaFormat, PlaybackBackend, PlaybackPortObserver,
  PlaybackPortError, PortPlaybackState } from 'linkora_core';
import { SystemWebPEncoder } from '../../../main/ets/services/SystemWebPEncoder';
import { SystemPlaybackPort } from '../../../main/ets/playback/SystemPlaybackPort';
import { NetworkFileProxy } from 'linkora_proxy';
import { StallingSource } from './FfmpegRuntimeSmoke';

interface Config { extraOnly: boolean; }
interface ErrorCode { code?: string | number; }
interface Evidence {
  case: string; status: string; code?: string; width?: number; height?: number;
  bytes?: number; timeMs?: number; pixelHash?: string; video?: string; audio?: string;
  durationMs?: number; frames?: number; position?: number; seekPosition?: number;
  firstFrame?: boolean; states?: string[]; reads?: number; closes?: number;
  activeSources?: number; activeClients?: number; pending?: boolean; released?: boolean;
}

/** Simulator-only native acceptance, never substitutes mocks for media results. */
export class MediaFunctionSmoke {
  private static running: boolean = false;
  private static delay(ms: number): Promise<void> { return new Promise<void>((resolve) => setTimeout(resolve, ms)); }
  private static check(value: boolean): void { if (!value) throw new Error('media acceptance assertion'); }
  private static async emit(endpoint: string, data: Evidence): Promise<void> {
    hilog.info(0x0001, 'MediaFunctionSmoke', '%{public}s', 'LINKORA_MEDIA_FUNCTION:' + JSON.stringify(data));
    const client = http.createHttp();
    try {
      const reply = await client.request(endpoint + '/evidence', { method: http.RequestMethod.POST,
        extraData: JSON.stringify(data), header: { 'Content-Type': 'application/json' }, connectTimeout: 5000, readTimeout: 5000 });
      MediaFunctionSmoke.check(reply.responseCode === 200);
    } finally { client.destroy(); }
  }
  private static async request(url: string, binary: boolean): Promise<http.HttpResponse> {
    const client = http.createHttp();
    try {
      const reply = await client.request(url, { expectDataType: binary ? http.HttpDataType.ARRAY_BUFFER : http.HttpDataType.STRING,
        connectTimeout: 5000, readTimeout: 8000, maxLimit: 8 * 1024 * 1024 });
      MediaFunctionSmoke.check(reply.responseCode === 200); return reply;
    } finally { client.destroy(); }
  }
  private static async caseRun(endpoint: string, name: string, action: () => Promise<void>): Promise<void> {
    await MediaFunctionSmoke.emit(endpoint, { case: name, status: 'START' });
    try { await action(); await MediaFunctionSmoke.emit(endpoint, { case: name, status: 'PASS' }); }
    catch (error) {
      const value = (error as ErrorCode).code;
      const code = value === undefined ? 'ACCEPTANCE_ASSERTION' : String(value);
      await MediaFunctionSmoke.emit(endpoint, { case: name, status: 'FAIL', code: /^[A-Za-z0-9_]{1,40}$/.test(code) ? code : 'PLATFORM_ERROR' });
    }
  }
  private static async system(endpoint: string, path: string): Promise<void> {
    const states: string[] = []; let position: number = 0; let seekPosition: number = -1;
    let firstFrame: boolean = false; let received: number = 0; let errorCode: number = 0;
    const observer = new PlaybackPortObserver(
      (state: PortPlaybackState) => { states.push(state); },
      (error: PlaybackPortError) => { errorCode = error.code; }, () => {},
      (value: number) => { position = value; }, () => {}, () => { firstFrame = true; },
      () => {}, () => {}, (value: number) => { seekPosition = value; });
    const receiver = image.createImageReceiver({ width: 320, height: 180 }, image.ImageFormat.JPEG, 4);
    let draining: Promise<void> = Promise.resolve();
    receiver.on('imageArrival', () => {
      draining = draining.then(async () => {
        const next = await receiver.readLatestImage();
        try { received++; } finally { await next.release(); }
      }).catch(() => {});
    });
    let backend: PlaybackBackend | null = null;
    try {
      backend = await SystemPlaybackPort.create(observer);
      backend.configure(new MediaSource(MediaSourceKind.LOCAL_DOCUMENT, path, 'owned-h264.mp4', '', MediaFormat.MP4),
        await receiver.getReceivingSurfaceId());
      await backend.prepare(); await backend.play(); await MediaFunctionSmoke.delay(1200);
      MediaFunctionSmoke.check(states.includes(PortPlaybackState.PREPARED) && states.includes(PortPlaybackState.PLAYING) && position > 0 && errorCode === 0);
      const beforePause = position; await backend.pause(); await MediaFunctionSmoke.delay(150);
      MediaFunctionSmoke.check(states.includes(PortPlaybackState.PAUSED));
      backend.seek(2500); await MediaFunctionSmoke.delay(400);
      MediaFunctionSmoke.check(seekPosition >= 2000 && seekPosition <= 3000);
      await backend.play(); await MediaFunctionSmoke.delay(600);
      MediaFunctionSmoke.check(position > seekPosition && errorCode === 0);
      await MediaFunctionSmoke.emit(endpoint, { case: 'system-mp4-data', status: 'DATA', position: beforePause,
        seekPosition, frames: received, firstFrame, states });
    } finally {
      if (backend !== null) await backend.release();
      receiver.off('imageArrival'); await draining; await receiver.release();
    }
    MediaFunctionSmoke.check(states.includes(PortPlaybackState.RELEASED));
    await MediaFunctionSmoke.emit(endpoint, { case: 'system-release-data', status: 'DATA', states });
  }
  private static async cancel(endpoint: string): Promise<void> {
    const proxy = new NetworkFileProxy(); const source = new StallingSource();
    const lease = await proxy.buildSourceUrl(source, 'video/mp4');
    const analysis = createFfmpegAnalysis(); let code: string = ''; let settled: boolean = false;
    const pending = analysis.probe('owned-cancel', lease.url, 8000).then(() => { settled = true; },
      (error: Object) => { settled = true; code = String((error as ErrorCode).code); });
    try {
      const start = Date.now();
      while (source.reads === 0 && !settled && Date.now() - start < 3000) await MediaFunctionSmoke.delay(10);
      MediaFunctionSmoke.check(source.reads > 0 && !settled);
      analysis.cancel('owned-cancel'); await pending;
      MediaFunctionSmoke.check(code === 'FF_CANCELLED');
    } finally { analysis.close(); await lease.release(); await proxy.close(); }
    const final = proxy.diagnostics();
    MediaFunctionSmoke.check(source.closes === 1 && final.activeSources === 0 && final.activeClients === 0);
    await MediaFunctionSmoke.emit(endpoint, { case: 'ffmpeg-cancel-data', status: 'DATA', code,
      reads: source.reads, closes: source.closes, activeSources: final.activeSources, activeClients: final.activeClients });
  }
  private static async hls(endpoint: string): Promise<void> {
    const states: string[] = []; let settled: boolean = false; let released: boolean = false;
    const observer = new PlaybackPortObserver((state: PortPlaybackState) => { states.push(state); },
      () => {}, () => {}, () => {}, () => {}, () => {}, () => {}, () => {});
    const receiver = image.createImageReceiver({ width: 320, height: 180 }, image.ImageFormat.JPEG, 4);
    const backend = await SystemPlaybackPort.create(observer);
    try {
      backend.configure(new MediaSource(MediaSourceKind.NETWORK_LINK, endpoint + '/pending.m3u8', 'owned-pending.m3u8', '', MediaFormat.HLS),
        await receiver.getReceivingSurfaceId());
      const pending = backend.prepare().then(() => { settled = true; }, () => { settled = true; });
      await MediaFunctionSmoke.delay(1500);
      MediaFunctionSmoke.check(states.includes(PortPlaybackState.INITIALIZED) && !states.includes(PortPlaybackState.PREPARED) && !settled);
      await MediaFunctionSmoke.emit(endpoint, { case: 'hls-before-cancel', status: 'DATA', pending: !settled, states });
      await backend.release(); released = true; await pending;
      MediaFunctionSmoke.check(states.includes(PortPlaybackState.RELEASED) && !states.includes(PortPlaybackState.PREPARED));
      await MediaFunctionSmoke.delay(3500);
      await MediaFunctionSmoke.emit(endpoint, { case: 'hls-early', status: 'DATA', released: true, states });
      await MediaFunctionSmoke.delay(21000);
      MediaFunctionSmoke.check(!states.includes(PortPlaybackState.PREPARED));
      await MediaFunctionSmoke.emit(endpoint, { case: 'hls-later', status: 'DATA', released: true, states });
      // Native release alone is not proof of all audio/surface/service resource zeros.
      await MediaFunctionSmoke.emit(endpoint, { case: 'hls-resource-recovery', status: 'NOT_PROVEN' });
    } finally { if (!released) await backend.release(); await receiver.release(); }
  }
  static async run(context: common.UIAbilityContext, endpoint: string): Promise<void> {
    if (MediaFunctionSmoke.running) return;
    MediaFunctionSmoke.running = true;
    const path = context.filesDir + '/media-function-owned.mp4';
    let frame: NativeFrameResult | null = null;
    try {
      const config = JSON.parse((await MediaFunctionSmoke.request(endpoint, false)).result as string) as Config;
      const bytes = (await MediaFunctionSmoke.request(endpoint + '/mp4', true)).result as ArrayBuffer;
      const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try { MediaFunctionSmoke.check(fileIo.writeSync(file.fd, bytes) === bytes.byteLength); } finally { fileIo.closeSync(file.fd); }
      if (config.extraOnly) {
        await MediaFunctionSmoke.caseRun(endpoint, 'ffmpeg-active-cancel', () => MediaFunctionSmoke.cancel(endpoint));
        await MediaFunctionSmoke.caseRun(endpoint, 'hls-pending-native-release', () => MediaFunctionSmoke.hls(endpoint));
        await MediaFunctionSmoke.emit(endpoint, { case: 'extra-complete', status: 'DONE' }); return;
      }
      {
        const analysis = createFfmpegAnalysis();
        try {
          await MediaFunctionSmoke.caseRun(endpoint, 'ffmpeg-probe', async () => {
            const probe = await analysis.probe('owned-probe', path, 8000);
            MediaFunctionSmoke.check(probe.video[0]?.codec === 'h264' && probe.audio[0]?.codec === 'aac' && probe.durationMs > 7000);
            await MediaFunctionSmoke.emit(endpoint, { case: 'ffmpeg-probe-data', status: 'DATA', video: probe.video[0].codec,
              audio: probe.audio[0].codec, durationMs: probe.durationMs, width: probe.video[0].width, height: probe.video[0].height });
          });
          await MediaFunctionSmoke.caseRun(endpoint, 'ffmpeg-frame', async () => {
            const decoded = await analysis.extractFrame('owned-frame', path, 1000, 480, 270, 8000);
            MediaFunctionSmoke.check(decoded.width > 0 && decoded.height > 0 && decoded.pixels.byteLength === decoded.width * decoded.height * 4 &&
              decoded.timeMs >= 900 && decoded.timeMs <= 2000 && decoded.pixelFormat === 'rgba_8888');
            let hash: number = 2166136261; const pixels = new Uint8Array(decoded.pixels);
            for (let i = 0; i < pixels.length; i++) hash = Math.imul(hash ^ pixels[i], 16777619) >>> 0;
            frame = decoded;
            await MediaFunctionSmoke.emit(endpoint, { case: 'ffmpeg-frame-data', status: 'DATA', width: decoded.width,
              height: decoded.height, bytes: decoded.pixels.byteLength, timeMs: decoded.timeMs, pixelHash: hash.toString(16) });
          });
        } finally { analysis.close(); }
        if (frame !== null) {
          const decoded: NativeFrameResult = frame;
          await MediaFunctionSmoke.caseRun(endpoint, 'webp-roundtrip', async () => {
            const raw = new FfmpegRawThumbnail(decoded);
            try {
              const encoded = await new SystemWebPEncoder().encodeRaw(raw, 80);
              const bytes = new Uint8Array(encoded);
              MediaFunctionSmoke.check(bytes.length > 12 && bytes[0] === 82 && bytes[1] === 73 && bytes[2] === 70 && bytes[3] === 70 &&
                bytes[8] === 87 && bytes[9] === 69 && bytes[10] === 66 && bytes[11] === 80);
              const source = image.createImageSource(encoded);
              try {
                const pixels = await source.createPixelMap();
                try {
                  const info = await pixels.getImageInfo();
                  MediaFunctionSmoke.check(info.size.width === decoded.width && info.size.height === decoded.height);
                  await MediaFunctionSmoke.emit(endpoint, { case: 'webp-data', status: 'DATA', bytes: encoded.byteLength,
                    width: info.size.width, height: info.size.height });
                } finally { await pixels.release(); }
              } finally { await source.release(); }
            } finally { await raw.release(); }
          });
        } else { await MediaFunctionSmoke.emit(endpoint, { case: 'webp-roundtrip', status: 'BLOCKED' }); }
      }
      await MediaFunctionSmoke.caseRun(endpoint, 'system-mp4', () => MediaFunctionSmoke.system(endpoint, path));
      await MediaFunctionSmoke.emit(endpoint, { case: 'complete', status: 'DONE' });
    } catch (error) {
      const value = (error as ErrorCode).code;
      const code = value === undefined ? 'HARNESS_ERROR' : String(value);
      await MediaFunctionSmoke.emit(endpoint, { case: 'runner', status: 'FAIL',
        code: /^[A-Za-z0-9_]{1,40}$/.test(code) ? code : 'PLATFORM_ERROR' }).catch(() => {});
    } finally {
      try { fileIo.unlinkSync(path); } catch (_error) {}
      MediaFunctionSmoke.running = false;
    }
  }
}
