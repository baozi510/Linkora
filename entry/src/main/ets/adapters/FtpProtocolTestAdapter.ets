import { ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult, RemoteProtocol } from 'linkora_core';
import { TcpProtocolTestSupport } from './ProtocolTestSupport';

export class FtpProtocolTestAdapter implements ProtocolTestAdapter {
  private support: TcpProtocolTestSupport = new TcpProtocolTestSupport();

  protocol(): RemoteProtocol {
    return RemoteProtocol.FTP;
  }

  test(request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    return this.support.test(request, 'FTP');
  }

  cancel(): void {
    this.support.cancel();
  }
}
