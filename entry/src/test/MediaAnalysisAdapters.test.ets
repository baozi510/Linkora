import { describe, it, expect } from '@ohos/hypium';
import { MediaSource, MediaSourceKind, MediaFormat, RandomAccessSource, SourceCapabilities,
  ProbeRequirement, ProbeCompleteness, ResolvedMediaInputKind, ThumbnailExtractRequest,
  MediaInfo, VideoTrackInfo, ProbeResult, MediaProbeDiagnostics } from 'linkora_core';
import { FfmpegAnalysis, NativeFfmpegApi, NativeProbeResult, NativeVideoStream, NativeAudioStream,
  NativeFrameResult, FfmpegError, FfmpegErrorCode } from 'linkora_ffmpeg';
import { AnalysisOperation, AnalysisError, AnalysisErrorCode } from '../main/ets/analysis/AnalysisOperation';
import { MediaAnalysisInputResolver, AnalysisInputPorts, AnalysisProxyRegistration } from '../main/ets/analysis/MediaAnalysisInputResolver';
import { FfmpegMediaProbeAdapter } from '../main/ets/analysis/FfmpegMediaProbeAdapter';
import { FfmpegThumbnailExtractorAdapter } from '../main/ets/analysis/FfmpegThumbnailExtractorAdapter';
import { SystemMediaProbeAdapter, SystemAnalysisBackend, SystemAnalysisSnapshot } from '../main/ets/analysis/SystemMediaProbeAdapter';
import { MediaAnalysisComparison, AnalysisDifferenceKind } from '../main/ets/analysis/MediaAnalysisComparison';

class TestSource implements RandomAccessSource {
  closes: number = 0; cancels: number = 0;
  id(): string { return 'opaque'; } size(): number { return 1024; }
  capabilities(): SourceCapabilities { return new SourceCapabilities(); }
  async readAt(_offset: number, length: number): Promise<ArrayBuffer> { return new ArrayBuffer(length); }
  cancel(): void { this.cancels++; } async close(): Promise<void> { this.closes++; }
}
class TestInputs implements AnalysisInputPorts {
  opened: number = 0; released: number = 0; registered: number = 0;
  fail: boolean = false; source: TestSource = new TestSource();
  observed: RandomAccessSource | null = null;
  registration: (() => Promise<void>) | null = null;
  cleanup: (() => Promise<void>) | null = null;
  open: () => Promise<RandomAccessSource> = async () => this.source;
  async openRemote(_source: MediaSource, _operation: AnalysisOperation): Promise<RandomAccessSource> { this.opened++; return this.open(); }
  async openHttp(_source: MediaSource, _operation: AnalysisOperation): Promise<RandomAccessSource> { this.opened++; return this.open(); }
  async register(source: RandomAccessSource): Promise<AnalysisProxyRegistration> {
    this.registered++;
    this.observed = source; if (this.registration !== null) await this.registration();
    if (this.fail) { source.cancel(); await source.close(); throw new Error('http://secret:token@private/locator'); }
    return new AnalysisProxyRegistration('http://127.0.0.1:99/private-token', async () => {
      this.released++; source.cancel(); await source.close(); if (this.cleanup !== null) await this.cleanup();
    });
  }
}
class TestNative implements NativeFfmpegApi {
  result: NativeProbeResult = new NativeProbeResult();
  code: FfmpegErrorCode | null = null; calls: number = 0; cancelled: string[] = [];
  time: number = 0; width: number = 0; height: number = 0;
  work: (() => Promise<NativeProbeResult>) | null = null;
  frameWork: (() => Promise<NativeFrameResult>) | null = null;
  constructor() { this.result.container = 'mov,mp4'; this.result.durationMs = 1000;
    const video = new NativeVideoStream(); video.codec = 'h264'; video.profile = 'High';
    video.width = 640; video.height = 360; video.frameRate = 24; video.bitDepth = 8; this.result.video = [video]; }
  async probe(_id: string, _input: string, _timeout: number): Promise<NativeProbeResult> {
    this.calls++; if (this.work !== null) return this.work();
    if (this.code !== null) throw new FfmpegError(this.code, 'locator/private-token'); return this.result;
  }
  async extractFrame(_id: string, _input: string, time: number, width: number, height: number, _timeout: number): Promise<NativeFrameResult> {
    this.time = time; this.width = width; this.height = height;
    this.calls++; if (this.frameWork !== null) return this.frameWork();
    if (this.code !== null) throw new FfmpegError(this.code);
    const frame = new NativeFrameResult(); frame.width = 2; frame.height = 1; frame.timeMs = time;
    frame.pixels = new ArrayBuffer(8); return frame;
  }
  cancel(id: string): void { this.cancelled.push(id); }
}
class TestSystem implements SystemAnalysisBackend {
  cancelled: number = 0; closed: number = 0;
  work: () => Promise<SystemAnalysisSnapshot> = async () => new SystemAnalysisSnapshot(1000, 640, 360);
  started: boolean = false;
  async inspect(_input: string): Promise<SystemAnalysisSnapshot> { this.started = true; return this.work(); }
  cancel(): void { this.cancelled++; } async close(): Promise<void> { this.closed++; }
}
function file(format: MediaFormat = MediaFormat.MP4): MediaSource {
  return new MediaSource(MediaSourceKind.NETWORK_LINK, 'https://example.test/file.mp4?token=secret', 'file', '', format);
}
function resolver(inputs: TestInputs): MediaAnalysisInputResolver { return new MediaAnalysisInputResolver(inputs); }

export default function mediaAnalysisAdaptersTest(): void {
  describe('MediaAnalysisAdapters', () => {
    for (const stage of ['open', 'registration']) {
      it('review cancellation retains identity when delayed ' + stage + ' rejects', 0, async () => {
        const ports = new TestInputs(); let rejectWork: (error: Error) => void = () => {};
        if (stage === 'open') ports.open = () => new Promise((_resolve, reject) => { rejectWork = reject; });
        else ports.registration = () => new Promise((_resolve, reject) => { rejectWork = reject; });
        const operation = new AnalysisOperation(); const pending = resolver(ports).resolve(file(), 'ffmpeg', operation);
        while (stage === 'registration' && ports.registered === 0) await Promise.resolve();
        operation.cancel(); rejectWork(new Error('late private locator failure'));
        let code = 0; try { await pending; } catch (error) { code = (error as AnalysisError).code; }
        expect(code).assertEqual(AnalysisErrorCode.CANCELLED);
        expect(ports.source.closes).assertEqual(stage === 'open' ? 0 : 1);
      });
    }
    for (const engine of ['ffmpeg', 'system']) {
      it('review ' + engine + ' cancellation retains identity when backend rejects', 0, async () => {
        const ports = new TestInputs(); const native = new TestNative(); const backend = new TestSystem();
        let rejectWork: (error: Error) => void = () => {};
        native.work = () => new Promise((_resolve, reject) => { rejectWork = reject; });
        backend.work = () => new Promise((_resolve, reject) => { rejectWork = reject; });
        const probe = engine === 'ffmpeg' ? new FfmpegMediaProbeAdapter(resolver(ports), new FfmpegAnalysis(native)) :
          new SystemMediaProbeAdapter(resolver(ports), () => backend);
        const pending = probe.probe(file(), ProbeRequirement.DETAIL);
        while (engine === 'ffmpeg' ? native.calls === 0 : !backend.started) await Promise.resolve();
        probe.cancel(); rejectWork(new FfmpegError(FfmpegErrorCode.OPEN_FAILED));
        const result = await pending; await probe.close();
        expect(result.errorCode).assertEqual(AnalysisErrorCode.CANCELLED); expect(ports.source.closes).assertEqual(1);
      });
      it('review ' + engine + ' close during release suppresses completed metadata until cleanup', 0, async () => {
        const ports = new TestInputs(); let finish: () => void = () => {};
        ports.cleanup = () => new Promise((resolve) => { finish = resolve; });
        const probe = engine === 'ffmpeg' ? new FfmpegMediaProbeAdapter(resolver(ports), new FfmpegAnalysis(new TestNative())) :
          new SystemMediaProbeAdapter(resolver(ports), () => new TestSystem());
        const pending = probe.probe(file(), ProbeRequirement.DETAIL);
        while (ports.released === 0) await Promise.resolve();
        // Wait until the cleanup action's deferred promise has been installed.
        while (ports.source.closes === 0) await Promise.resolve(); await Promise.resolve();
        let closed = false; const closing = probe.close().then(() => { closed = true; });
        await Promise.resolve(); expect(closed).assertEqual(false);
        expect((await probe.probe(file(), ProbeRequirement.LIST)).errorCode).assertEqual(AnalysisErrorCode.CLOSED);
        finish(); const result = await pending; await closing;
        expect(result.errorCode).assertEqual(AnalysisErrorCode.CANCELLED); expect(ports.source.closes).assertEqual(1);
      });
    }
    it('review thumbnail cancellation retains identity when native frame rejects', 0, async () => {
      const ports = new TestInputs(); const native = new TestNative(); let rejectWork: (error: Error) => void = () => {};
      native.frameWork = () => new Promise((_resolve, reject) => { rejectWork = reject; });
      const extractor = new FfmpegThumbnailExtractorAdapter(resolver(ports), new FfmpegAnalysis(native));
      const pending = extractor.extract(file(), new ThumbnailExtractRequest(1000));
      while (native.calls === 0) await Promise.resolve(); extractor.cancel(); rejectWork(new FfmpegError(FfmpegErrorCode.OPEN_FAILED));
      let code = 0; try { await pending; } catch (error) { code = (error as AnalysisError).code; }
      await extractor.close(); expect(code).assertEqual(AnalysisErrorCode.CANCELLED); expect(ports.source.closes).assertEqual(1);
    });
    it('review thumbnail close during release suppresses completed pixels until cleanup', 0, async () => {
      const ports = new TestInputs(); let finish: () => void = () => {};
      ports.cleanup = () => new Promise((resolve) => { finish = resolve; });
      const extractor = new FfmpegThumbnailExtractorAdapter(resolver(ports), new FfmpegAnalysis(new TestNative()));
      const pending = extractor.extract(file(), new ThumbnailExtractRequest(1000));
      while (ports.released === 0) await Promise.resolve();
      while (ports.source.closes === 0) await Promise.resolve(); await Promise.resolve();
      let closed = false; const closing = extractor.close().then(() => { closed = true; });
      await Promise.resolve(); expect(closed).assertEqual(false); finish();
      let code = 0; try { const raw = await pending; await raw?.release(); } catch (error) { code = (error as AnalysisError).code; }
      await closing; expect(code).assertEqual(AnalysisErrorCode.CANCELLED); expect(ports.source.closes).assertEqual(1);
    });
    it('canResolve is pure and rejects unsafe links unresolved local and FFmpeg playlists', 0, async () => {
      const ports = new TestInputs(); const input = resolver(ports);
      expect(input.canResolve(file(), 'ffmpeg')).assertTrue();
      expect(input.canResolve(file(MediaFormat.HLS), 'ffmpeg')).assertEqual(false);
      expect(input.canResolve(file(MediaFormat.DASH), 'ffmpeg')).assertEqual(false);
      expect(input.canResolve(file(MediaFormat.HLS), 'system')).assertTrue();
      expect(input.canResolve(MediaSource.fromLocalDocument('content://document/item.mp4'), 'ffmpeg')).assertEqual(false);
      expect(input.canResolve(new MediaSource(MediaSourceKind.NETWORK_LINK, 'https://user:secret@example.test/v.mp4', '', '', MediaFormat.MP4), 'ffmpeg')).assertEqual(false);
      expect(ports.opened).assertEqual(0);
    });
    it('HTTP and remote resolution own proxy sources with idempotent release and stable identity', 0, async () => {
      const ports = new TestInputs(); const input = resolver(ports);
      const lease = await input.resolve(file(), 'ffmpeg', new AnalysisOperation());
      expect(lease.input.kind).assertEqual(ResolvedMediaInputKind.PROXY_URL);
      const identity = lease.sourceIdentity; await lease.release(); await lease.release();
      expect(ports.released).assertEqual(1); expect(ports.source.closes).assertEqual(1);
      ports.source = new TestSource(); const again = await input.resolve(file(), 'system', new AnalysisOperation());
      expect(again.sourceIdentity).assertEqual(identity); await again.release();
      const remote = MediaSource.fromRemoteFile('/video.mkv', 'video.mkv', '', 1024, 'network-server:1');
      ports.source = new TestSource(); const remoteLease = await input.resolve(remote, 'ffmpeg', new AnalysisOperation());
      expect(ports.opened).assertEqual(3); await remoteLease.release();
    });
    it('registration failure closes once even if registration already took ownership', 0, async () => {
      const ports = new TestInputs(); ports.fail = true;
      let code = 0; try { await resolver(ports).resolve(file(), 'ffmpeg', new AnalysisOperation()); }
      catch (error) { code = (error as AnalysisError).code; }
      expect(code).assertEqual(AnalysisErrorCode.RESOLVE_FAILED); expect(ports.source.closes).assertEqual(1);
    });
    it('late proxy registration after cancellation releases registered source once', 0, async () => {
      const ports = new TestInputs(); let finish: () => void = () => {};
      ports.registration = () => new Promise((resolve) => { finish = resolve; });
      const operation = new AnalysisOperation(); const pending = resolver(ports).resolve(file(), 'ffmpeg', operation);
      while (ports.registered === 0) await Promise.resolve(); operation.cancel(); finish();
      let code = 0; try { await pending; } catch (error) { code = (error as AnalysisError).code; }
      expect(code).assertEqual(AnalysisErrorCode.CANCELLED); expect(ports.released).assertEqual(1); expect(ports.source.closes).assertEqual(1);
    });
    it('access diagnostics distinguish observed nonsequential source reads', 0, async () => {
      const ports = new TestInputs(); const lease = await resolver(ports).resolve(file(), 'ffmpeg', new AnalysisOperation());
      await ports.observed!.readAt(0, 10); expect(lease.access.semantics()).assertEqual('range_available');
      await ports.observed!.readAt(700, 20); expect(lease.access.semantics()).assertEqual('random_access_observed');
      expect(lease.access.bytesRead).assertEqual(30); expect(lease.access.readRequests).assertEqual(2); await lease.release();
    });
    it('cancel during late source open releases source without registering', 0, async () => {
      const ports = new TestInputs(); let finish: (source: RandomAccessSource) => void = () => {};
      ports.open = () => new Promise((resolve) => { finish = resolve; });
      const operation = new AnalysisOperation(); const pending = resolver(ports).resolve(file(), 'ffmpeg', operation);
      operation.cancel(); finish(ports.source); let code = 0;
      try { await pending; } catch (error) { code = (error as AnalysisError).code; }
      expect(code).assertEqual(AnalysisErrorCode.CANCELLED); expect(ports.source.closes).assertEqual(1);
      expect(ports.registered).assertEqual(0);
    });
    for (const requirement of [ProbeRequirement.LIST, ProbeRequirement.DETAIL, ProbeRequirement.ADVANCED]) {
      it('FFmpeg completeness satisfies ' + requirement + ' without optional chapters/tags', 0, async () => {
        const ports = new TestInputs(); const native = new TestNative();
        const probe = new FfmpegMediaProbeAdapter(resolver(ports), new FfmpegAnalysis(native));
        const result = await probe.probe(file(), requirement);
        expect(result.completeness).assertEqual(ProbeCompleteness.COMPLETE);
        expect(result.fieldOrigins.every((origin) => origin.engine === 'ffmpeg')).assertTrue();
        expect(ports.released).assertEqual(1); await probe.close(); await probe.close();
      });
    }
    it('FFmpeg partial and unavailable reflect requested structural completeness', 0, async () => {
      const native = new TestNative(); native.result.video[0].bitDepth = 0;
      const probe = new FfmpegMediaProbeAdapter(resolver(new TestInputs()), new FfmpegAnalysis(native));
      expect((await probe.probe(file(), ProbeRequirement.DETAIL)).completeness).assertEqual(ProbeCompleteness.COMPLETE);
      expect((await probe.probe(file(), ProbeRequirement.ADVANCED)).completeness).assertEqual(ProbeCompleteness.PARTIAL);
      native.result = new NativeProbeResult();
      expect((await probe.probe(file(), ProbeRequirement.LIST)).completeness).assertEqual(ProbeCompleteness.UNAVAILABLE);
      await probe.close();
    });
    for (const code of [FfmpegErrorCode.INVALID_INPUT, FfmpegErrorCode.OPEN_FAILED, FfmpegErrorCode.STREAM_INFO_FAILED,
      FfmpegErrorCode.NO_VIDEO, FfmpegErrorCode.DECODER_UNAVAILABLE, FfmpegErrorCode.DECODE_FAILED,
      FfmpegErrorCode.TIMEOUT, FfmpegErrorCode.CANCELLED, FfmpegErrorCode.SIZE_REJECTED, FfmpegErrorCode.CLOSED]) {
      it('maps stable numeric error and releases lease for ' + code, 0, async () => {
        const native = new TestNative(); native.code = code; const ports = new TestInputs();
        const probe = new FfmpegMediaProbeAdapter(resolver(ports), new FfmpegAnalysis(native));
        const result = await probe.probe(file(), ProbeRequirement.DETAIL);
        expect(result.errorCode > 0).assertTrue(); expect(result.completeness).assertEqual(ProbeCompleteness.UNAVAILABLE);
        expect(JSON.stringify(result.diagnostics).includes('private-token')).assertEqual(false);
        expect(JSON.stringify(result.diagnostics).includes('example.test')).assertEqual(false);
        expect(result.diagnostics.engine).assertEqual('ffmpeg'); expect(ports.released).assertEqual(1); await probe.close();
      });
    }
    it('cancel rejects late native success and close waits lease cleanup', 0, async () => {
      const native = new TestNative(); const ports = new TestInputs();
      let finish: (result: NativeProbeResult) => void = () => {};
      native.work = () => new Promise((resolve) => { finish = resolve; });
      const probe = new FfmpegMediaProbeAdapter(resolver(ports), new FfmpegAnalysis(native));
      const pending = probe.probe(file(), ProbeRequirement.DETAIL);
      while (native.calls === 0) await Promise.resolve();
      probe.cancel(); const closed = probe.close(); finish(native.result);
      const result = await pending; await closed; await probe.close();
      expect(result.errorCode).assertEqual(AnalysisErrorCode.CANCELLED);
      expect(native.cancelled.length > 0).assertTrue(); expect(ports.source.closes).assertEqual(1);
      expect(await probe.canProbe(file())).assertEqual(false);
    });
    it('System maps only claimed basic metadata and provenance with requirement completeness', 0, async () => {
      const ports = new TestInputs(); const backends: TestSystem[] = [];
      const probe = new SystemMediaProbeAdapter(resolver(ports), () => { const backend = new TestSystem(); backends.push(backend); return backend; });
      const list = await probe.probe(file(), ProbeRequirement.LIST);
      expect(list.completeness).assertEqual(ProbeCompleteness.COMPLETE);
      expect(list.info!.videoTracks[0].codec).assertEqual(''); expect(list.info!.audioTracks.length).assertEqual(0);
      expect(list.fieldOrigins.every((origin) => origin.engine === 'system')).assertTrue();
      expect((await probe.probe(file(), ProbeRequirement.DETAIL)).completeness).assertEqual(ProbeCompleteness.PARTIAL);
      expect((await probe.probe(file(), ProbeRequirement.ADVANCED)).completeness).assertEqual(ProbeCompleteness.PARTIAL);
      expect(backends.every((backend) => backend.closed === 1)).assertTrue(); await probe.close();
    });
    it('System unavailable values are not fabricated into usable metadata', 0, async () => {
      const backend = new TestSystem(); backend.work = async () => new SystemAnalysisSnapshot(NaN, -1, Infinity);
      const ports = new TestInputs(); const probe = new SystemMediaProbeAdapter(resolver(ports), () => backend);
      const result = await probe.probe(file(), ProbeRequirement.LIST);
      expect(result.info).assertEqual(null); expect(result.completeness).assertEqual(ProbeCompleteness.UNAVAILABLE);
      expect(result.errorCode).assertEqual(AnalysisErrorCode.SYSTEM_FAILED);
      expect(result.fieldOrigins.length).assertEqual(0); expect(backend.closed).assertEqual(1); expect(ports.released).assertEqual(1); await probe.close();
    });
    it('System errors and timeout retain numeric failure state and clean up', 0, async () => {
      for (const code of [AnalysisErrorCode.TIMEOUT, AnalysisErrorCode.SYSTEM_FAILED]) {
        const backend = new TestSystem(); backend.work = async () => { throw new AnalysisError(code); };
        const ports = new TestInputs(); const probe = new SystemMediaProbeAdapter(resolver(ports), () => backend);
        const result = await probe.probe(file(), ProbeRequirement.DETAIL);
        expect(result.errorCode).assertEqual(code); expect(result.isUsable()).assertEqual(false);
        expect(backend.closed).assertEqual(1); expect(ports.released).assertEqual(1); await probe.close();
      }
    });
    it('System close cancels active job rejects late result and awaits cleanup', 0, async () => {
      const backend = new TestSystem(); let finish: (result: SystemAnalysisSnapshot) => void = () => {};
      backend.work = () => new Promise((resolve) => { finish = resolve; });
      const ports = new TestInputs(); const probe = new SystemMediaProbeAdapter(resolver(ports), () => backend);
      const pending = probe.probe(file(), ProbeRequirement.LIST);
      while (!backend.started) await Promise.resolve(); const closing = probe.close();
      finish(new SystemAnalysisSnapshot(1000, 640, 360)); const result = await pending; await closing; await probe.close();
      expect(result.errorCode).assertEqual(AnalysisErrorCode.CANCELLED); expect(backend.cancelled).assertEqual(1);
      expect(backend.closed).assertEqual(1); expect(ports.source.closes).assertEqual(1);
    });
    it('thumbnail passes requested bounds/time and owns raw output separately from source', 0, async () => {
      const native = new TestNative(); const ports = new TestInputs();
      const extractor = new FfmpegThumbnailExtractorAdapter(resolver(ports), new FfmpegAnalysis(native));
      const raw = await extractor.extract(file(), new ThumbnailExtractRequest(3000, 480, 270));
      expect(raw!.width()).assertEqual(2); expect(raw!.height()).assertEqual(1); expect(raw!.pixelFormat()).assertEqual('rgba_8888');
      expect(native.time).assertEqual(3000); expect(native.width).assertEqual(480); expect(native.height).assertEqual(270);
      expect(ports.released).assertEqual(1); expect((await raw!.readPixels()).byteLength).assertEqual(8);
      await raw!.release(); await raw!.release(); await extractor.close(); await extractor.close();
      expect(await extractor.canExtract(file())).assertEqual(false);
    });
    it('thumbnail error releases source and reports stable cancellation', 0, async () => {
      const native = new TestNative(); native.code = FfmpegErrorCode.CANCELLED; const ports = new TestInputs();
      const extractor = new FfmpegThumbnailExtractorAdapter(resolver(ports), new FfmpegAnalysis(native));
      let code = 0; try { await extractor.extract(file(), new ThumbnailExtractRequest(1000)); } catch (error) { code = (error as AnalysisError).code; }
      expect(code).assertEqual(AnalysisErrorCode.CANCELLED); expect(ports.released).assertEqual(1); await extractor.close();
    });
    it('thumbnail close cancels active native work discards late pixels and releases once', 0, async () => {
      const native = new TestNative(); let finish: (result: NativeFrameResult) => void = () => {};
      native.frameWork = () => new Promise((resolve) => { finish = resolve; });
      const ports = new TestInputs(); const extractor = new FfmpegThumbnailExtractorAdapter(resolver(ports), new FfmpegAnalysis(native));
      const pending = extractor.extract(file(), new ThumbnailExtractRequest(1000));
      while (native.calls === 0) await Promise.resolve(); const closing = extractor.close();
      const frame = new NativeFrameResult(); frame.width = 2; frame.height = 1; frame.pixels = new ArrayBuffer(8); finish(frame);
      let code = 0; try { await pending; } catch (error) { code = (error as AnalysisError).code; }
      await closing; expect(code).assertEqual(AnalysisErrorCode.CANCELLED); expect(native.cancelled.length > 0).assertTrue();
      expect(ports.released).assertEqual(1); expect(ports.source.closes).assertEqual(1);
    });
    it('comparison distinguishes unclaimed System structure from a true empty stream count', 0, () => {
      const system = new ProbeResult(new MediaInfo('', 1000, 0, 0, [new VideoTrackInfo('primary', '', '', '', 640, 360)]), ProbeCompleteness.PARTIAL, [], new MediaProbeDiagnostics('system'));
      const ff = new ProbeResult(new MediaInfo('mp4', 1000, 0, 0, [new VideoTrackInfo('v', 'h264', 'High', '', 640, 360)]), ProbeCompleteness.COMPLETE, [], new MediaProbeDiagnostics('ffmpeg'));
      const comparison = MediaAnalysisComparison.compare(system, ff);
      expect(comparison.differences.some((difference) => difference.field === 'container' && difference.kind === AnalysisDifferenceKind.SYSTEM_MISSING)).assertTrue();
      expect(comparison.differences.some((difference) => difference.field === 'durationMs' && difference.kind === AnalysisDifferenceKind.MATCH)).assertTrue();
      expect(JSON.stringify(comparison).includes('probeMs')).assertEqual(false);
      const unavailable = new ProbeResult(null, ProbeCompleteness.UNAVAILABLE, [], new MediaProbeDiagnostics('system'), 1);
      expect(MediaAnalysisComparison.compare(unavailable, ff).differences.some((d) => d.kind === AnalysisDifferenceKind.ENGINE_UNAVAILABLE)).assertTrue();
    });
    it('comparison classifies both missing ffmpeg missing and value differences independently', 0, () => {
      const system = new ProbeResult(new MediaInfo('system-format', 1000), ProbeCompleteness.PARTIAL, [], new MediaProbeDiagnostics('system'));
      const ff = new ProbeResult(new MediaInfo('', 1100), ProbeCompleteness.PARTIAL, [], new MediaProbeDiagnostics('ffmpeg'));
      const result = MediaAnalysisComparison.compare(system, ff);
      expect(result.differences.some((d) => d.field === 'container' && d.kind === AnalysisDifferenceKind.FFMPEG_MISSING)).assertTrue();
      expect(result.differences.some((d) => d.field === 'durationMs' && d.kind === AnalysisDifferenceKind.VALUE_DIFFERENCE)).assertTrue();
      expect(result.differences.some((d) => d.field === 'videoCodec' && d.kind === AnalysisDifferenceKind.MATCH)).assertTrue();
    });
  });
}
