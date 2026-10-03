import { describe, expect, it, beforeAll, afterAll, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import { url } from '@kit.ArkTS';
import { media } from '@kit.MediaKit';
import { image } from '@kit.ImageKit';
import { NetworkMediaProbe, ProbeStatus } from 'linkora_media_probe';

class ExtractorStub {
  metadata: media.AVMetadata = { duration: '1234', videoWidth: '1920', videoHeight: '1080' };
  releases: number = 0;
  frames: number = 0;
  timeUs: number = -1;
  source: string = '';
  headers: Record<string, string> = {};
  metadataError: boolean = false;
  releaseError: boolean = false;
  frame: () => Promise<image.PixelMap> = async () => { throw new Error('no frame'); };
  setUrlSource(value: string, headers: Record<string, string>): void { this.source = value; this.headers = headers; }
  async fetchMetadata(): Promise<media.AVMetadata> {
    if (this.metadataError) throw new Error('private source failure');
    return this.metadata;
  }
  fetchFrameByTime(time: number, _option: media.AVImageQueryOptions, _params: media.PixelMapParams): Promise<image.PixelMap> {
    this.frames++; this.timeUs = time; return this.frame();
  }
  async release(): Promise<void> { this.releases++; if (this.releaseError) throw new Error('release'); }
}

export default function networkMediaProbeTest(): void {
  describe('NetworkMediaProbe', () => {
    // Hvigor's SDK URL mock has no parser. Device smoke separately checks real URL validation.
    const mocker: MockKit = new MockKit();
    beforeAll(() => {
      const mocked: Function = mocker.mockFunc(url.URL, url.URL.parseURL);
      when(mocked)(ArgumentMatchers.anyString).afterAction((value: string): url.URL => {
        const parsed = new ParsedUrlStub();
        parsed.protocol = value.startsWith('https:') ? 'https:' : (value.startsWith('http:') ? 'http:' : 'file:');
        parsed.host = 'example.com';
        parsed.username = value.includes('@') ? 'user' : '';
        parsed.password = '';
        return parsed as Object as url.URL;
      });
    });
    afterAll(() => { mocker.clear(url.URL); });
    it('keeps metadata after frame failure and releases extractor once', 0, async () => {
      const stub = new ExtractorStub();
      const probe = new NetworkMediaProbe(async () => stub as Object as media.AVMetadataExtractor);
      const headers: Record<string, string> = {};
      headers['Authorization'] = 'Basic test';
      const result = await probe.inspect('https://example.com/video.mp4?token=test', headers);
      expect(result.durationMs).assertEqual(1234);
      expect(result.width).assertEqual(1920);
      expect(result.height).assertEqual(1080);
      expect(result.metadataComplete).assertTrue();
      expect(result.status).assertEqual(ProbeStatus.METADATA_ONLY);
      expect(result.thumbnail === null).assertTrue();
      expect(stub.timeUs).assertEqual(1000000);
      expect(stub.source).assertEqual('https://example.com/video.mp4?token=test');
      expect(stub.headers.Authorization).assertEqual('Basic test');
      await probe.close(); await probe.close();
      expect(stub.releases).assertEqual(1);
    });
    it('normalizes invalid values and skips frame when metadata fails', 0, async () => {
      const stub = new ExtractorStub();
      stub.metadata = { duration: 'NaN', videoWidth: 'Infinity', videoHeight: '-1' };
      const probe = new NetworkMediaProbe(async () => stub as Object as media.AVMetadataExtractor);
      const result = await probe.inspect('http://example.com/v');
      expect(result.durationMs + result.width + result.height).assertEqual(0);
      expect(stub.timeUs).assertEqual(0);
      stub.metadataError = true;
      const failed = await probe.inspect('http://example.com/v');
      expect(failed.status).assertEqual(ProbeStatus.UNAVAILABLE);
      expect(failed.metadataComplete).assertFalse();
      expect(stub.frames).assertEqual(1);
      await probe.close();
    });
    it('cancels pending creation and keeps slot until late cleanup', 0, async () => {
      const stub = new ExtractorStub();
      let finish: (value: media.AVMetadataExtractor) => void = () => {};
      const probe = new NetworkMediaProbe(() => new Promise((resolve) => { finish = resolve; }));
      const pending = probe.inspect('http://example.com/v');
      probe.cancel();
      expect((await pending).status).assertEqual(ProbeStatus.CANCELLED);
      let busy: boolean = false;
      try { await probe.inspect('http://example.com/v'); } catch (_error) { busy = true; }
      expect(busy).assertTrue();
      let closed: boolean = false;
      const closing = probe.close().then(() => { closed = true; });
      await Promise.resolve(); expect(closed).assertFalse();
      finish(stub as Object as media.AVMetadataExtractor);
      await closing; await probe.close();
      expect(stub.releases).assertEqual(1);
      expect(stub.frames).assertEqual(0);
    });
    it('releases late frame once and hands successful frame to caller', 0, async () => {
      const stub = new ExtractorStub();
      let releases: number = 0;
      let finish: (frame: image.PixelMap) => void = () => {};
      const frame = new FrameStub(() => { releases++; }) as Object as image.PixelMap;
      stub.frame = () => new Promise((resolve) => { finish = resolve; });
      const probe = new NetworkMediaProbe(async () => stub as Object as media.AVMetadataExtractor);
      const pending = probe.inspect('http://example.com/v');
      for (let i: number = 0; i < 8; i++) await Promise.resolve();
      probe.cancel();
      expect((await pending).status).assertEqual(ProbeStatus.CANCELLED);
      finish(frame); await probe.close();
      expect(releases).assertEqual(1);
      expect(stub.releases).assertEqual(1);
      const next = new NetworkMediaProbe(async () => stub as Object as media.AVMetadataExtractor);
      stub.frame = async () => frame;
      stub.releaseError = true;
      stub.metadata.duration = '200';
      const result = await next.inspect('http://example.com/v');
      expect(result.status).assertEqual(ProbeStatus.COMPLETE);
      expect(stub.timeUs).assertEqual(199000);
      await next.inspect('http://example.com/v');
      await next.close(); await next.close();
      expect(releases).assertEqual(1);
      await result.thumbnail?.release(); expect(releases).assertEqual(2);
    });
    it('rejects unsafe input and closed calls before creating', 0, async () => {
      let creates: number = 0;
      const probe = new NetworkMediaProbe(async () => { creates++; return new ExtractorStub() as Object as media.AVMetadataExtractor; });
      const bad: string[] = ['file:///tmp/v', 'http://user:pass@example.com/v', 'http://example.com/\r\n', 'http://example.com/' + 'x'.repeat(8192)];
      let rejected: number = 0;
      for (const value of bad) { try { await probe.inspect(value); } catch (_error) { rejected++; } }
      const headers: Record<string, string> = {};
      headers['X-Test'] = 'a\r\nInjected: yes';
      try { await probe.inspect('http://example.com/v', headers); } catch (_error) { rejected++; }
      headers['X-Test'] = 'x'.repeat(4097);
      try { await probe.inspect('http://example.com/v', headers); } catch (_error) { rejected++; }
      headers['X-Test'] = '汉'.repeat(4096);
      headers['X-Other'] = '汉'.repeat(4096);
      try { await probe.inspect('http://example.com/v', headers); } catch (_error) { rejected++; }
      expect(rejected).assertEqual(7); expect(creates).assertEqual(0);
      await probe.close();
      try { await probe.inspect('http://example.com/v'); } catch (_error) { rejected++; }
      expect(rejected).assertEqual(8); expect(creates).assertEqual(0);
    });

  });
}

class FrameStub {
  private readonly onRelease: () => void;
  constructor(onRelease: () => void) { this.onRelease = onRelease; }
  async release(): Promise<void> { this.onRelease(); }
}

class ParsedUrlStub { protocol: string = ''; host: string = ''; username: string = ''; password: string = ''; }
