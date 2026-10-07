import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  IMediaProbe,
  MediaSource,
  ProbeCompleteness,
  ProbeRequirement,
  ProbeResult,
  RemoteProtocol
} from 'linkora_core';
import { NetworkFileProxy, NetworkFileProxyDiagnostics } from 'linkora_proxy';
import { AnalysisComposition } from '../../AnalysisComposition';
import { HarmonyAnalysisInputs } from '../../../main/ets/analysis/HarmonyAnalysisInputs';
import { MediaAnalysisInputResolver } from '../../../main/ets/analysis/MediaAnalysisInputResolver';
import { AnalysisError } from '../../../main/ets/analysis/AnalysisOperation';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind } from '../../../main/ets/models/NetworkDirectoryState';
import { NetworkDirectoryService } from '../../../main/ets/services/NetworkDirectoryService';
import { NetworkMediaSourceFactory } from '../../../main/ets/services/NetworkMediaSourceFactory';
import { NetworkServerEntry, NetworkServerStore } from '../../../main/ets/services/NetworkServerStore';
import { common } from '@kit.AbilityKit';

interface AudioMetadataFixture {
  caseId: string;
  directoryPath: string;
  fileName: string;
  expectedCodec: string;
}

interface AudioMetadataConfig {
  schemaVersion: number;
  serverName: string;
  fixtures: AudioMetadataFixture[];
}

interface AudioMetadataEvidence {
  caseId: string;
  status: string;
  errorCode?: number;
  completeness?: string;
  container?: string;
  durationMs?: number;
  videoTracks?: number;
  audioTracks?: number;
  codec?: string;
  channels?: number;
  sampleRate?: number;
  bytesRead?: number;
  readRequests?: number;
  rangeRequests?: number;
  activeSources?: number;
  total?: number;
  passed?: number;
  failed?: number;
}

/**
 * Simulator-only diagnostic for audio-only FFmpeg metadata.
 *
 * This intentionally exercises only IMediaProbe. It never creates a thumbnail
 * request and therefore does not invent video dimensions for audio fixtures.
 */
export class AudioMetadataSmoke {
  private static endpoint: string = '';

  static async run(context: common.UIAbilityContext, endpoint: string): Promise<void> {
    AudioMetadataSmoke.endpoint = endpoint;
    let passed: number = 0;
    let failed: number = 0;
    let total: number = 0;
    try {
      const config: AudioMetadataConfig = AudioMetadataSmoke.parseConfig(
        await AudioMetadataSmoke.request(endpoint));
      const server: NetworkServerEntry = await AudioMetadataSmoke.server(context, config.serverName);
      for (const fixture of config.fixtures) {
        total++;
        try {
          await AudioMetadataSmoke.runFixture(context, server, fixture);
          passed++;
        } catch (error) {
          failed++;
          await AudioMetadataSmoke.emit({
            caseId: fixture.caseId,
            status: 'FAIL',
            errorCode: AnalysisError.from(error as Object).code
          });
        }
      }
    } catch (error) {
      failed++;
      await AudioMetadataSmoke.emit({
        caseId: 'harness',
        status: 'FAIL',
        errorCode: AnalysisError.from(error as Object).code
      });
    } finally {
      await AudioMetadataSmoke.emit({
        caseId: 'summary',
        status: failed === 0 && total > 0 ? 'PASS' : 'FAIL',
        total,
        passed,
        failed
      });
    }
  }

  private static async runFixture(context: common.UIAbilityContext, server: NetworkServerEntry,
    fixture: AudioMetadataFixture): Promise<void> {
    const source: MediaSource = await AudioMetadataSmoke.source(server, fixture);
    const proxy: NetworkFileProxy = new NetworkFileProxy();
    const resolver = new MediaAnalysisInputResolver(new HarmonyAnalysisInputs(context, proxy));
    const probe: IMediaProbe = AnalysisComposition.ffmpeg(resolver, 10000);
    let result: ProbeResult;
    let diagnostics: NetworkFileProxyDiagnostics;
    try {
      AudioMetadataSmoke.check(await probe.canProbe(source));
      result = await probe.probe(source, ProbeRequirement.DETAIL);
    } finally {
      await probe.close().catch(() => {});
    }
    diagnostics = proxy.diagnostics();
    AudioMetadataSmoke.check(diagnostics.activeSources === 0);
    await proxy.close().catch(() => {});

    const finalDiagnostics: NetworkFileProxyDiagnostics = proxy.diagnostics();
    AudioMetadataSmoke.check(finalDiagnostics.activeSources === 0);
    const info = result.info;
    const track = info?.audioTracks[0];
    const success: boolean = result.isUsable() && result.errorCode === 0 && info !== null &&
      info.durationMs > 0 && info.videoTracks.length === 0 && info.audioTracks.length > 0 &&
      track !== undefined && track.codec.toLowerCase() === fixture.expectedCodec.toLowerCase() &&
      track.channels > 0 && track.sampleRate > 0 &&
      result.completeness !== ProbeCompleteness.UNAVAILABLE &&
      finalDiagnostics.activeSources === 0;

    await AudioMetadataSmoke.emit({
      caseId: fixture.caseId,
      status: success ? 'PASS' : 'FAIL',
      errorCode: result.errorCode,
      completeness: result.completeness,
      container: info?.container ?? '',
      durationMs: info?.durationMs ?? 0,
      videoTracks: info?.videoTracks.length ?? 0,
      audioTracks: info?.audioTracks.length ?? 0,
      codec: track?.codec ?? '',
      channels: track?.channels ?? 0,
      sampleRate: track?.sampleRate ?? 0,
      bytesRead: finalDiagnostics.bytesRead,
      readRequests: finalDiagnostics.readRequests,
      rangeRequests: finalDiagnostics.rangeRequests,
      activeSources: finalDiagnostics.activeSources
    });
    AudioMetadataSmoke.check(success);
  }

  private static async source(server: NetworkServerEntry,
    fixture: AudioMetadataFixture): Promise<MediaSource> {
    const service: NetworkDirectoryService = new NetworkDirectoryService(server);
    try {
      const entries: NetworkDirectoryEntry[] = await service.list(fixture.directoryPath, true);
      const matches: NetworkDirectoryEntry[] = entries.filter((entry: NetworkDirectoryEntry): boolean =>
        entry.kind === NetworkDirectoryEntryKind.FILE && entry.displayName === fixture.fileName);
      AudioMetadataSmoke.check(matches.length === 1);
      return NetworkMediaSourceFactory.fromEntry(server, matches[0]);
    } finally {
      service.cancel();
    }
  }

  private static async server(context: common.UIAbilityContext, name: string): Promise<NetworkServerEntry> {
    const entries: NetworkServerEntry[] = await new NetworkServerStore(context).load();
    const matches: NetworkServerEntry[] = entries.filter((entry: NetworkServerEntry): boolean =>
      entry.displayName === name && entry.protocol === RemoteProtocol.WEBDAV);
    AudioMetadataSmoke.check(matches.length === 1);
    return matches[0];
  }

  private static parseConfig(payload: string): AudioMetadataConfig {
    AudioMetadataSmoke.check(payload.length > 0 && payload.length <= 32768);
    const config: AudioMetadataConfig = JSON.parse(payload) as AudioMetadataConfig;
    AudioMetadataSmoke.check(config.schemaVersion === 1 &&
      typeof config.serverName === 'string' && config.serverName.length > 0 && config.serverName.length <= 128 &&
      Array.isArray(config.fixtures) && config.fixtures.length > 0 && config.fixtures.length <= 16);
    const ids: Set<string> = new Set<string>();
    for (const fixture of config.fixtures) {
      AudioMetadataSmoke.check(/^[a-z0-9-]{1,48}$/.test(fixture.caseId) && !ids.has(fixture.caseId));
      ids.add(fixture.caseId);
      AudioMetadataSmoke.check(typeof fixture.directoryPath === 'string' &&
        fixture.directoryPath.length > 0 && fixture.directoryPath.length <= 1024 &&
        typeof fixture.fileName === 'string' && fixture.fileName.length > 0 && fixture.fileName.length <= 255 &&
        typeof fixture.expectedCodec === 'string' && /^[a-z0-9._-]{1,32}$/i.test(fixture.expectedCodec) &&
        !/[\r\n\0]/.test(fixture.directoryPath + fixture.fileName));
    }
    return config;
  }

  private static async request(source: string): Promise<string> {
    AudioMetadataSmoke.check(/^http:\/\/10\.0\.2\.2:19333\/[a-f0-9-]{36}$/.test(source));
    const client: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await client.request(source, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 8000,
        readTimeout: 8000,
        maxLimit: 32768
      });
      AudioMetadataSmoke.check(response.responseCode === 200);
      return response.result as string;
    } finally {
      client.destroy();
    }
  }

  private static async emit(record: AudioMetadataEvidence): Promise<void> {
    hilog.info(0x0001, 'AudioMetadataSmoke', '%{public}s',
      'LINKORA_AUDIO_METADATA:' + JSON.stringify(record));
    if (AudioMetadataSmoke.endpoint.length === 0) {
      return;
    }
    const client: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await client.request(AudioMetadataSmoke.endpoint + '/evidence', {
        method: http.RequestMethod.POST,
        extraData: JSON.stringify(record),
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 8000,
        readTimeout: 8000
      });
      AudioMetadataSmoke.check(response.responseCode === 200);
    } finally {
      client.destroy();
    }
  }

  private static check(value: boolean): void {
    if (!value) {
      throw new Error('audio metadata smoke assertion');
    }
  }
}
