import { FailureCatalog, ProtocolTestRequest, ProtocolTestResult } from 'linkora_core';
import { HarmonyNetworkConnectionTester } from './HarmonyNetworkConnectionTester';

export class TcpProtocolTestSupport {
  private tester: HarmonyNetworkConnectionTester = new HarmonyNetworkConnectionTester();

  async test(request: ProtocolTestRequest, protocolLabel: string): Promise<ProtocolTestResult> {
    const result = await this.tester.test(request.host, request.port);
    if (result.succeeded) {
      return new ProtocolTestResult(true, `${protocolLabel}连接成功`, result.message);
    }
    const failure = FailureCatalog.fromNetworkError(result.errorCode);
    const message: string = `${failure.message}（${request.host}:${request.port}）`;
    return new ProtocolTestResult(false, `${protocolLabel}连接失败`, message, failure.diagnosticCode);
  }

  cancel(): void {
    this.tester.cancel();
  }
}
