import { describe, expect, it } from '@ohos/hypium';
import {
  HdrType,
  MediaInfo,
  MediaProbeDiagnostics,
  MediaSource,
  MediaSourceKind,
  PlayerBackendCapabilities,
  ProbeCompleteness,
  ProbeFieldOrigin,
  ProbeResult,
  RemoteReadSession,
  RemoteReadSessionAdapter,
  ResolvedMediaInput,
  ResolvedMediaInputKind,
  SourceCapabilities,
  ThumbnailEncodeRequest,
  ThumbnailExtractRequest,
  VideoTrackInfo
} from 'linkora_core';

class FakeRemoteReadSession implements RemoteReadSession {
  cancelled: boolean = false;
  closed: boolean = false;

  size(): number {
    return 1024;
  }

  async read(offset: number, length: number): Promise<ArrayBuffer> {
    return new ArrayBuffer(Math.min(length, Math.max(0, 1024 - offset)));
  }

  cancel(): void {
    this.cancelled = true;
  }

  async close(): Promise<void> {
    this.closed = true;
  }
}

export default function architectureContractsTest(): void {
  describe('ArchitectureContracts', () => {
    it('adaptsExistingRemoteReadSessionsToRandomAccess', 0, async () => {
      const legacy = new FakeRemoteReadSession();
      const source = new RemoteReadSessionAdapter(
        'server:file',
        legacy,
        new SourceCapabilities(true, true, true, true)
      );

      const data: ArrayBuffer = await source.readAt(128, 256);

      expect(source.id()).assertEqual('server:file');
      expect(source.size()).assertEqual(1024);
      expect(source.capabilities().reopenable).assertTrue();
      expect(data.byteLength).assertEqual(256);
      source.cancel();
      await source.close();
      expect(legacy.cancelled).assertTrue();
      expect(legacy.closed).assertTrue();
    });

    it('representsRemoteFilesWithoutUsingProgressiveIdentity', 0, () => {
      const source: MediaSource = MediaSource.fromRemoteFile(
        '/Movies/movie.mkv',
        'movie.mkv',
        'NAS',
        4096,
        'server-1:/Movies/movie.mkv',
        'credential-1',
        'fingerprint-1'
      );

      expect(source.kind).assertEqual(MediaSourceKind.REMOTE_FILE);
      expect(source.progressiveKey).assertEqual('');
      expect(source.sourceId).assertEqual('server-1:/Movies/movie.mkv');
      expect(source.credentialRef).assertEqual('credential-1');
    });

    it('keepsResolvedInputsSeparateFromStableMediaIdentity', 0, () => {
      const input = new ResolvedMediaInput(
        ResolvedMediaInputKind.PROXY_URL,
        'source-1',
        'http://127.0.0.1:12345/token'
      );

      expect(input.kind).assertEqual(ResolvedMediaInputKind.PROXY_URL);
      expect(input.sourceId).assertEqual('source-1');
    });

    it('modelsPartialProbeResultsWithFieldOrigins', 0, () => {
      const info = new MediaInfo(
        'matroska',
        120000,
        0,
        0,
        [new VideoTrackInfo('v0', 'hevc', 'main10', '', 3840, 2160, 23.976, 0, 10,
          'p010', 'bt2020', 'smpte2084', 'bt2020nc', HdrType.HDR10)]
      );
      const result = new ProbeResult(
        info,
        ProbeCompleteness.PARTIAL,
        [new ProbeFieldOrigin('durationMs', 'system'), new ProbeFieldOrigin('hdrType', 'ffmpeg')],
        new MediaProbeDiagnostics('merged', 2, 8, 10, 65536, 2)
      );

      expect(result.isUsable()).assertTrue();
      expect(result.info!.videoTracks[0].hdrType).assertEqual(HdrType.HDR10);
      expect(result.fieldOrigins.length).assertEqual(2);
    });

    it('definesStableThumbnailAndBackendDefaults', 0, () => {
      const extract = new ThumbnailExtractRequest(60000);
      const encode = new ThumbnailEncodeRequest();
      const capabilities = new PlayerBackendCapabilities();

      expect(extract.maxWidth).assertEqual(480);
      expect(extract.maxHeight).assertEqual(270);
      expect(encode.quality).assertEqual(80);
      expect(capabilities.proxyUrl).assertTrue();
      expect(capabilities.audioPassthrough).assertFalse();
    });
  });
}
