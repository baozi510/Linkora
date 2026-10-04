import { describe, expect, it } from '@ohos/hypium';
import { HdrType, SubtitleKind, ThumbnailPixelFormat } from 'linkora_core';
import { NativeProbeResult, NativeVideoStream, NativeAudioStream, NativeSubtitleStream,
  NativeFrameResult, NativeChapter, FfmpegMediaInfoMapper, FfmpegRawThumbnail, FfmpegAnalysis,
  NativeFfmpegApi } from 'linkora_ffmpeg';

class PendingNative implements NativeFfmpegApi {
  cancelled: string[] = [];
  started: string[] = [];
  resolve: ((result: NativeProbeResult) => void) | null = null;
  probe(_id: string, _input: string, _timeout: number): Promise<NativeProbeResult> {
    this.started.push(_id);
    return new Promise<NativeProbeResult>((resolve) => { this.resolve = resolve; });
  }
  async extractFrame(_id: string, _input: string, _time: number, _width: number,
    _height: number, _timeout: number): Promise<NativeFrameResult> { return new NativeFrameResult(); }
  cancel(id: string): void { this.cancelled.push(id); }
}

class SharedNative extends PendingNative {
  pending: Map<string, (result: NativeProbeResult) => void> = new Map<string, (result: NativeProbeResult) => void>();
  probe(id: string, _input: string, _timeout: number): Promise<NativeProbeResult> {
    this.started.push(id);
    if (this.pending.has(id)) return Promise.reject(new Error('duplicate native id'));
    return new Promise<NativeProbeResult>((resolve) => { this.pending.set(id, resolve); });
  }
  complete(): void {
    this.pending.forEach((resolve) => resolve(new NativeProbeResult())); this.pending.clear();
  }
}

export default function ffmpegAnalysisTest(): void {
  describe('FfmpegAnalysisPhase1', () => {
    it('maps format video audio chapters and field origins', 0, () => {
      const result = new NativeProbeResult();
      result.container = 'mov,mp4,m4a,3gp,3g2,mj2'; result.durationMs = 60000;
      result.bitrate = 800000; result.sizeBytes = 6000000;
      const video = new NativeVideoStream(); video.index = 2; video.id = 7;
      video.codec = 'h264'; video.width = 1920; video.height = 1080; video.frameRate = 24;
      const audio = new NativeAudioStream(); audio.codec = 'aac'; audio.channels = 2;
      audio.channelLayout = 'stereo'; audio.sampleRate = 48000;
      result.video = [video]; result.audio = [audio];
      result.tags['title'] = 'fixture';
      const chapter = new NativeChapter(); chapter.startMs = 1000; chapter.endMs = 2000; chapter.title = 'scene';
      result.chapters = [chapter];
      const mapped = FfmpegMediaInfoMapper.map(result);
      expect(mapped.info.durationMs).assertEqual(60000);
      expect(mapped.info.sizeBytes).assertEqual(6000000);
      expect(mapped.info.videoTracks[0].id).assertEqual('2:7');
      expect(mapped.info.videoTracks[0].codec).assertEqual('h264');
      expect(mapped.info.audioTracks[0].sampleRate).assertEqual(48000);
      expect(mapped.info.tags['title']).assertEqual('fixture');
      expect(mapped.info.chapters[0].startMs).assertEqual(1000);
      expect(mapped.info.chapters[0].title).assertEqual('scene');
      expect(mapped.fieldOrigins.every((origin) => origin.engine === 'ffmpeg')).assertTrue();
    });
    it('maps PQ conservatively as metadata HDR10', 0, () => {
      const result = new NativeProbeResult(); const video = new NativeVideoStream();
      video.transfer = 'smpte2084'; result.video = [video];
      expect(FfmpegMediaInfoMapper.map(result).info.videoTracks[0].hdrType).assertEqual(HdrType.HDR10);
    });
    it('maps HLG transfer', 0, () => {
      const result = new NativeProbeResult(); const video = new NativeVideoStream();
      video.transfer = 'arib-std-b67'; result.video = [video];
      expect(FfmpegMediaInfoMapper.map(result).info.videoTracks[0].hdrType).assertEqual(HdrType.HLG);
    });
    it('requires explicit Dolby Vision configuration', 0, () => {
      const result = new NativeProbeResult(); const video = new NativeVideoStream();
      video.hasDolbyVisionConfiguration = true;
      video.dolbyVisionProfile = 8; video.transfer = 'smpte2084'; result.video = [video];
      const track = FfmpegMediaInfoMapper.map(result).info.videoTracks[0];
      expect(track.hdrType).assertEqual(HdrType.DOLBY_VISION);
      expect(track.dolbyVisionProfile).assertEqual('8');
      video.dolbyVisionProfile = 0;
      expect(FfmpegMediaInfoMapper.map(result).info.videoTracks[0].hdrType).assertEqual(HdrType.DOLBY_VISION);
    });
    it('does not infer HDR from BT2020 or ten bits alone', 0, () => {
      const result = new NativeProbeResult(); const video = new NativeVideoStream();
      video.colorPrimaries = 'bt2020'; video.bitDepth = 10; result.video = [video];
      expect(FfmpegMediaInfoMapper.map(result).info.videoTracks[0].hdrType).assertEqual(HdrType.UNKNOWN);
    });
    it('maps text bitmap unknown and subtitle dispositions', 0, () => {
      const result = new NativeProbeResult(); const sub = new NativeSubtitleStream();
      sub.kind = 'bitmap'; sub.isForced = true; sub.isDefault = true; result.subtitles = [sub];
      const track = FfmpegMediaInfoMapper.map(result).info.subtitleTracks[0];
      expect(track.kind).assertEqual(SubtitleKind.BITMAP); expect(track.isForced).assertTrue();
      sub.kind = 'text'; expect(FfmpegMediaInfoMapper.map(result).info.subtitleTracks[0].kind).assertEqual(SubtitleKind.TEXT);
      sub.kind = 'other'; expect(FfmpegMediaInfoMapper.map(result).info.subtitleTracks[0].kind).assertEqual(SubtitleKind.UNKNOWN);
    });
    it('caps arbitrary tag values and total tag bytes', 0, () => {
      const result = new NativeProbeResult();
      for (let i = 0; i < 100; i++) result.tags['tag' + i] = '中'.repeat(5000);
      const tags = FfmpegMediaInfoMapper.map(result).info.tags;
      expect(Object.keys(tags).length <= 64).assertTrue();
      let bytes = 0;
      Object.keys(tags).forEach((key: string) => { bytes += key.length + tags[key].length * 3; });
      expect(bytes <= 16384).assertTrue();
    });
    it('caps stream and chapter counts', 0, () => {
      const result = new NativeProbeResult();
      for (let i = 0; i < 200; i++) result.video.push(new NativeVideoStream());
      for (let i = 0; i < 200; i++) result.chapters.push(new NativeChapter());
      expect(FfmpegMediaInfoMapper.map(result).info.videoTracks.length).assertEqual(64);
      expect(FfmpegMediaInfoMapper.map(result).info.chapters.length).assertEqual(128);
    });
    it('rejects invalid raw frame byte count', 0, () => {
      const frame = new NativeFrameResult(); frame.width = 2; frame.height = 2; frame.pixels = new ArrayBuffer(15);
      let rejected = false; try { new FfmpegRawThumbnail(frame); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue();
    });
    it('rejects unbounded frame allocation dimensions', 0, () => {
      const frame = new NativeFrameResult(); frame.width = 100000; frame.height = 100000;
      let rejected = false; try { new FfmpegRawThumbnail(frame); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue();
    });
    it('releases frame idempotently and rejects later reads', 0, async () => {
      const frame = new NativeFrameResult(); frame.width = 2; frame.height = 1; frame.pixels = new ArrayBuffer(8);
      const raw = new FfmpegRawThumbnail(frame);
      expect(raw.pixelFormat()).assertEqual(ThumbnailPixelFormat.RGBA_8888);
      expect((await raw.readPixels()).byteLength).assertEqual(8);
      await raw.release(); await raw.release();
      let rejected = false; try { await raw.readPixels(); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue();
    });
    it('does not cancel unrelated request ids', 0, async () => {
      const native = new PendingNative(); const analysis = new FfmpegAnalysis(native);
      const promise = analysis.probe('own', '/data/test.mp4');
      analysis.cancel('unrelated'); expect(native.cancelled.length).assertEqual(0);
      analysis.cancel('own'); expect(native.cancelled[0]).assertEqual(native.started[0]);
      native.resolve!(new NativeProbeResult()); await promise;
    });
    it('isolates identical external ids between wrappers', 0, async () => {
      const native = new SharedNative();
      const first = new FfmpegAnalysis(native); const second = new FfmpegAnalysis(native);
      const a = first.probe('same', '/data/test.mp4');
      const b = second.probe('same', '/data/test.mp4');
      const caught = b.catch(() => new NativeProbeResult());
      second.close();
      const isolated = native.started[0] !== native.started[1] && native.cancelled[0] === native.started[1];
      native.complete(); await a; await caught;
      expect(isolated).assertTrue();
    });
    it('rejects duplicate active request ids without replacing state', 0, async () => {
      const native = new PendingNative(); const analysis = new FfmpegAnalysis(native);
      const pending = analysis.probe('same', '/data/test.mp4');
      let rejected = false; try { await analysis.probe('same', '/data/test.mp4'); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue(); native.resolve!(new NativeProbeResult()); await pending;
    });
    it('close cancels owned work and rejects new requests', 0, async () => {
      const native = new PendingNative(); const analysis = new FfmpegAnalysis(native);
      const pending = analysis.probe('first', '/data/test.mp4'); analysis.close(); analysis.close();
      expect(native.cancelled.length).assertEqual(1);
      let rejected = false; try { await analysis.probe('new', '/data/test.mp4'); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue(); native.resolve!(new NativeProbeResult()); await pending;
    });
  });
}
