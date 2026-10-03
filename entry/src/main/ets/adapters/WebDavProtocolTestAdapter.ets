import { FailureCatalog, ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult, RemoteProtocol } from 'linkora_core';
import { HarmonyNetworkProbe } from './HarmonyNetworkProbe';

export class WebDavProtocolTestAdapter implements ProtocolTestAdapter {
  private probe: HarmonyNetworkProbe = new HarmonyNetworkProbe();

  protocol(): RemoteProtocol {
    return RemoteProtocol.WEBDAV;
  }

  async test(request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    try {
      const result = await this.probe.inspectWebDavWithCredentials(
        this.url(request), request.username, request.password);
      if (result.failure === null) {
        return new ProtocolTestResult(true, 'WebDAV 连接成功', `服务器返回 HTTP ${result.statusCode}`);
      }
      return new ProtocolTestResult(false, result.failure.title, result.failure.message,
        result.failure.diagnosticCode);
    } catch (_error) {
      const failure = FailureCatalog.fromNetworkError(0);
      return new ProtocolTestResult(false, failure.title, failure.message, failure.diagnosticCode);
    }
  }

  cancel(): void {
    this.probe.cancel();
  }

  private url(request: ProtocolTestRequest): string {
    const scheme: string = request.secureTransport ? 'https' : 'http';
    const defaultPort: number = request.secureTransport ? 443 : 80;
    const portLabel: string = request.port === defaultPort ? '' : `:${request.port}`;
    const path: string = request.rootPath.startsWith('/') ? request.rootPath : `/${request.rootPath}`;
    return `${scheme}://${request.host}${portLabel}${path}`;
  }
}
