import {
  ProtocolTestAdapter,
  ProtocolTestRequest,
  ProtocolTestResult,
  RemoteProtocol
} from 'linkora_core';
import { FtpProtocolTestAdapter } from 'entry/ets/adapters/FtpProtocolTestAdapter';
import { HttpProtocolTestAdapter } from 'entry/ets/adapters/HttpProtocolTestAdapter';
import { NfsProtocolTestAdapter } from 'entry/ets/adapters/NfsProtocolTestAdapter';
import { WebDavProtocolTestAdapter } from 'entry/ets/adapters/WebDavProtocolTestAdapter';

class SimulatorNativeProtocolTestAdapter implements ProtocolTestAdapter {
  private readonly value: RemoteProtocol;

  constructor(protocol: RemoteProtocol) {
    this.value = protocol;
  }

  protocol(): RemoteProtocol {
    return this.value;
  }

  async test(_request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    return new ProtocolTestResult(
      false,
      '模拟器缺少 Native 传输层',
      `${this.value.toUpperCase()} 的配置、数据库和页面流程与正式版一致；连接认证/目录读取需要 arm64 Native transport 真机验证。`,
      'SIMULATOR_NATIVE_TRANSPORT_UNAVAILABLE'
    );
  }

  cancel(): void {}
}

/**
 * Keep the production protocol surface intact.
 *
 * HTTP/WebDAV and the production FTP/NFS reachability tests remain real ArkTS paths.
 * SMB/SFTP authentication/list testing stops only at the native transport boundary.
 */
export class NetworkProtocolTestRegistry {
  private adapters: ProtocolTestAdapter[] = [
    new HttpProtocolTestAdapter(),
    new WebDavProtocolTestAdapter(),
    new SimulatorNativeProtocolTestAdapter(RemoteProtocol.SMB),
    new SimulatorNativeProtocolTestAdapter(RemoteProtocol.SFTP),
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
      if (adapter.protocol() === protocol) return adapter;
    }
    return null;
  }
}
