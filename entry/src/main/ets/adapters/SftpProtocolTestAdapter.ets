import { ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult, RemoteProtocol } from 'linkora_core';
import linkoraSftp from 'liblinkora_sftp.so';

export class SftpProtocolTestAdapter implements ProtocolTestAdapter {
  protocol(): RemoteProtocol {
    return RemoteProtocol.SFTP;
  }

  async test(request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    try {
      if (request.strictSftp && !request.sftpFingerprint) throw new Error('严格匹配需要填写已信任的服务器指纹。');
      await linkoraSftp.list(request.host, request.port, request.rootPath.length === 0 ? '/' : request.rootPath,
        request.username, request.password, '', '', request.sftpFingerprint, request.strictSftp ? 1 : 0, 0);
      return new ProtocolTestResult(true, 'SFTP 连接成功', 'SSH 认证和目录读取正常');
    } catch (error) {
      const raw: string = error instanceof Error ? error.message : `${error}`;
      const normalized: string = raw.toLowerCase();
      if (normalized.includes('auth') || normalized.includes('账号') || normalized.includes('密码') ||
        normalized.includes('permission')) {
        return new ProtocolTestResult(false, '认证失败', '账号或密码不正确，或者当前账号没有访问权限',
          'SFTP_AUTH_FAILED');
      }
      if (normalized.includes('resolve')) {
        return new ProtocolTestResult(false, '地址无法解析', '请检查主机名或 IP 地址', 'SFTP_RESOLVE_FAILED');
      }
      if (normalized.includes('timeout') || normalized.includes('超时')) {
        return new ProtocolTestResult(false, '连接超时', '请检查服务器地址、端口和网络', 'SFTP_TIMEOUT');
      }
      if (normalized.includes('directory') || normalized.includes('目录')) {
        return new ProtocolTestResult(false, '目录不可用', '请检查远程目录路径', 'SFTP_PATH_FAILED');
      }
      return new ProtocolTestResult(false, 'SFTP 连接失败', raw.replace(/^Error:\s*/, ''), 'SFTP_CONNECT_FAILED');
    }
  }

  cancel(): void {
  }
}
