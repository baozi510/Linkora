import { ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult, RemoteProtocol } from 'linkora_core';
import { FtpProtocolTestAdapter } from './FtpProtocolTestAdapter';
import { HttpProtocolTestAdapter } from './HttpProtocolTestAdapter';
import { NfsProtocolTestAdapter } from './NfsProtocolTestAdapter';
import { SftpProtocolTestAdapter } from './SftpProtocolTestAdapter';
import { SmbProtocolTestAdapter } from './SmbProtocolTestAdapter';
import { WebDavProtocolTestAdapter } from './WebDavProtocolTestAdapter';

export class NetworkProtocolTestRegistry {
  private adapters: ProtocolTestAdapter[] = [
    new HttpProtocolTestAdapter(),
    new WebDavProtocolTestAdapter(),
    new SmbProtocolTestAdapter(),
    new SftpProtocolTestAdapter(),
    new FtpProtocolTestAdapter(),
    new NfsProtocolTestAdapter()
  ];

  async test(request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    const adapter: ProtocolTestAdapter | null = this.resolve(request.protocol);
    if (adapter === null) {
      return new ProtocolTestResult(false, '协议未接入', '当前协议没有可用的测试适配器');
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
      if (adapter.protocol() === protocol) {
        return adapter;
      }
    }
    return null;
  }
}
