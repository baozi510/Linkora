import { BusinessError } from '@kit.BasicServicesKit';
import { socket } from '@kit.NetworkKit';

const CONNECT_TIMEOUT: number = 8000;

export class NetworkConnectionTestResult {
  readonly succeeded: boolean;
  readonly message: string;
  readonly errorCode: number;

  constructor(succeeded: boolean, message: string, errorCode: number = 0) {
    this.succeeded = succeeded;
    this.message = message;
    this.errorCode = errorCode;
  }
}

export class HarmonyNetworkConnectionTester {
  private activeSocket: socket.TCPSocket | null = null;

  async test(host: string, port: number): Promise<NetworkConnectionTestResult> {
    this.cancel();
    const tcpSocket: socket.TCPSocket = socket.constructTCPSocketInstance();
    this.activeSocket = tcpSocket;
    try {
      await tcpSocket.connect({
        address: { address: this.normalizedHost(host), port: port },
        timeout: CONNECT_TIMEOUT
      });
      return new NetworkConnectionTestResult(true, `端口连接成功（${port}）`);
    } catch (error) {
      const code: number = (error as BusinessError).code;
      const suffix: string = code > 0 ? `（错误码 ${code}）` : '';
      return new NetworkConnectionTestResult(false, `无法连接到 ${host}:${port}${suffix}`, code);
    } finally {
      if (this.activeSocket === tcpSocket) {
        this.activeSocket = null;
      }
      try {
        await tcpSocket.close();
      } catch (_error) {
        // The socket may already be closed after a failed connection.
      }
    }
  }

  cancel(): void {
    const tcpSocket: socket.TCPSocket | null = this.activeSocket;
    this.activeSocket = null;
    if (tcpSocket !== null) {
      tcpSocket.close().catch(() => {});
    }
  }

  private normalizedHost(value: string): string {
    if (value.startsWith('[') && value.endsWith(']')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}
