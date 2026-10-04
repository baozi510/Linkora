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
    return directory.openSource(source.locator, source.fingerprint);
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
