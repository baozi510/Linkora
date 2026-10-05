import { common } from '@kit.AbilityKit';
import { MediaSource, RandomAccessSource, RemoteReadSessionAdapter } from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { NetworkServerStore } from '../services/NetworkServerStore';
import { NetworkMediaSourceFactory } from '../services/NetworkMediaSourceFactory';
import { NetworkDirectoryService } from '../services/NetworkDirectoryService';
import { HttpRemoteReadSession } from '../services/HttpRemoteReadSession';
import { AnalysisInputPorts, AnalysisProxyRegistration } from './MediaAnalysisInputResolver';
import { AnalysisOperation, AnalysisError, AnalysisErrorCode } from './AnalysisOperation';

/** Composition supplies one shared proxy. This class contains no protocol selection. */
export class HarmonyAnalysisInputs implements AnalysisInputPorts {
  private readonly store: NetworkServerStore;
  private readonly proxy: NetworkFileProxy;
  constructor(context: common.UIAbilityContext, proxy: NetworkFileProxy) {
    this.store = new NetworkServerStore(context); this.proxy = proxy;
  }
  async openRemote(source: MediaSource, operation: AnalysisOperation): Promise<RandomAccessSource> {
    const servers = await this.store.load(); operation.check();
    const server = servers.find((entry) => entry.id === NetworkMediaSourceFactory.serverId(source));
    if (server === undefined) throw new AnalysisError(AnalysisErrorCode.RESOLVE_FAILED);
    const directory = new NetworkDirectoryService(server);
    operation.onCancel(() => directory.cancel());
    // MediaSource.fingerprint is a media/cache identity, not an SFTP host-key fingerprint.
    // Pass an empty per-open override so the SFTP provider keeps ownership of persisted trust.
    let setupSettled: Promise<void> = Promise.resolve();
    try {
      return await directory.openSource(source.locator, '',
        (settled: Promise<void>) => { setupSettled = settled; });
    } catch (error) {
      // Native setup may time out before a late handle finishes opening/closing. Preserve the
      // pre-Phase-3 serialization guarantee so the next loader job does not overlap that cleanup.
      await setupSettled.catch(() => {});
      // ArkTS only permits throwing Error values. Keep the analysis-domain/cancellation mapping
      // used by the resolver instead of rethrowing the arbitrary catch value.
      throw operation.failure(error as Object, AnalysisErrorCode.RESOLVE_FAILED);
    }
  }
  async openHttp(source: MediaSource, _operation: AnalysisOperation): Promise<RandomAccessSource> {
    // The resolver closes a late HEAD result if cancellation happened while opening.
    return new RemoteReadSessionAdapter(source.sourceId, await HttpRemoteReadSession.open(source.locator, {}));
  }
  async register(source: RandomAccessSource): Promise<AnalysisProxyRegistration> {
    const lease = await this.proxy.buildSourceUrl(source, 'application/octet-stream');
    return new AnalysisProxyRegistration(lease.url, () => lease.release());
  }
}
