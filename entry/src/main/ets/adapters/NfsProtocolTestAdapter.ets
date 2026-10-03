import { ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult, RemoteProtocol } from 'linkora_core';
import { TcpProtocolTestSupport } from './ProtocolTestSupport';

export class NfsProtocolTestAdapter implements ProtocolTestAdapter {
  private support: TcpProtocolTestSupport = new TcpProtocolTestSupport();

  protocol(): RemoteProtocol {
    return RemoteProtocol.NFS;
  }

  test(request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    return this.support.test(request, 'NFS');
  }

  cancel(): void {
    this.support.cancel();
  }
}
