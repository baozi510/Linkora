import { ProtocolTestAdapter, ProtocolTestRequest, ProtocolTestResult, RemoteProtocol } from 'linkora_core';
import linkoraSmb from 'liblinkora_smb.so';
import { SmbLocation, SmbBrowserService } from '../services/SmbBrowserService';

export class SmbProtocolTestAdapter implements ProtocolTestAdapter {
  protocol(): RemoteProtocol {
    return RemoteProtocol.SMB;
  }

  async test(request: ProtocolTestRequest): Promise<ProtocolTestResult> {
    const location: SmbLocation = SmbBrowserService.parseLocation(request.rootPath);
    try {
      await linkoraSmb.list(request.host, request.port, location.share, location.initialPath,
        request.username, request.password, request.domain);
      return new ProtocolTestResult(true, 'SMB 连接成功', location.share.length === 0 ?
        '认证和共享列表读取正常' : '认证和共享目录读取正常');
    } catch (error) {
      const raw: string = error instanceof Error ? error.message : `${error}`;
      const normalized: string = raw.toLowerCase();
      if (location.share.length === 0 && normalized.includes('smb_share_enum')) {
        return new ProtocolTestResult(false, '无法读取共享列表',
          '服务器不允许自动发现共享，请手动填写共享目录', 'SMB_SHARE_ENUM_DENIED');
      }
      if (normalized.includes('logon failure') || normalized.includes('access denied') ||
        normalized.includes('status_logon_failure') || normalized.includes('0xc000006d') ||
        normalized.includes('0xc0000022') ||
        (request.username.length > 0 && normalized.includes('errno:9'))) {
        return new ProtocolTestResult(false, '认证失败', '账号或密码不正确，或者当前账号没有访问权限',
          'SMB_AUTH_FAILED');
      }
      if (normalized.includes('bad network name') || normalized.includes('no such file') ||
        normalized.includes('0xc00000cc') || normalized.includes('0xc0000034')) {
        return new ProtocolTestResult(false, '共享目录不存在', '请检查共享名称和目录路径', 'SMB_SHARE_NOT_FOUND');
      }
      if (normalized.includes('timeout') || normalized.includes('timed out')) {
        return new ProtocolTestResult(false, '连接超时', '请检查服务器地址、端口和网络', 'SMB_TIMEOUT');
      }
      return new ProtocolTestResult(false, 'SMB 连接失败', raw.replace(/^Error:\s*/, ''), 'SMB_CONNECT_FAILED');
    }
  }

  cancel(): void {
  }
}
