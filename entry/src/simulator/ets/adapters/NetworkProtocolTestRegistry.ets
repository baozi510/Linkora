import { ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult, RemoteProtocol } from 'linkora_core';
import { HttpProtocolTestAdapter } from 'entry/ets/adapters/HttpProtocolTestAdapter';
import { WebDavProtocolTestAdapter } from 'entry/ets/adapters/WebDavProtocolTestAdapter';

/** Simulator runtime registry: native file-protocol adapters are deliberately absent. */
export class NetworkProtocolTestRegistry {
  private adapters: ProtocolTestAdapter[] = [
    new HttpProtocolTestAdapter(),
    new WebDavProtocolTestAdapter()
  ];

  async test(request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    const adapter: ProtocolTestAdapter | null = this.resolve(request.protocol);
    if (adapter === null) {
      return new ProtocolTestResult(false, '模拟器未启用该协议',
        'x86_64 模拟器验证构建仅开放 HTTP/WebDAV；Native 文件协议需要 arm64 真机。');
    }
    return adapter.test(request);
  }

  cancel(): void {
    for (const adapter of this.adapters) {
      adapter.cancel();
    }
  }

  private resolve(protocol: RemoteProtocol): ProtocolTestAdapter | null {
    for (const adapter of this.adapters) {
      if (adapter.protocol() === protocol) return adapter;
    }
    return null;
  }
}
