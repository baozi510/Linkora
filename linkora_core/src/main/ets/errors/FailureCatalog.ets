import { LinkIssue } from '../models/MediaLink';
import {
  AppFailure,
  FailureCode,
  FailureDomain,
  RecoveryAction
} from './AppFailure';

export class FailureCatalog {
  static fromLinkIssue(issue: LinkIssue): AppFailure {
    if (issue === LinkIssue.EMPTY) {
      return FailureCatalog.failure(FailureDomain.INPUT, FailureCode.LINK_EMPTY,
        '请输入媒体地址', '粘贴一个 HTTP 或 HTTPS 媒体地址后重试。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false);
    }
    if (issue === LinkIssue.TOO_LONG) {
      return FailureCatalog.failure(FailureDomain.INPUT, FailureCode.LINK_TOO_LONG,
        '地址过长', '请检查地址是否被重复粘贴，或改用较短的分享链接。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false);
    }
    if (issue === LinkIssue.UNSUPPORTED_PROTOCOL) {
      return FailureCatalog.failure(FailureDomain.INPUT, FailureCode.LINK_UNSUPPORTED_PROTOCOL,
        '暂不支持该协议', '直链播放器目前只接受 HTTP 或 HTTPS 地址。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false);
    }
    if (issue === LinkIssue.MISSING_HOST) {
      return FailureCatalog.failure(FailureDomain.INPUT, FailureCode.LINK_MISSING_HOST,
        '地址缺少服务器', '请填写完整域名或 IP 地址。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false);
    }
    if (issue === LinkIssue.EMBEDDED_CREDENTIALS) {
      return FailureCatalog.failure(FailureDomain.INPUT, FailureCode.LINK_EMBEDDED_CREDENTIALS,
        '地址包含敏感凭据', '不要把账号或密码直接写进链接，后续请通过受保护的认证配置添加。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false);
    }
    return FailureCatalog.failure(FailureDomain.INPUT, FailureCode.LINK_INVALID,
      '地址格式不正确', '请检查空格、端口和地址编码后重试。',
      RecoveryAction.EDIT_SOURCE, '修改地址', false);
  }

  static fromHttpStatus(statusCode: number): AppFailure | null {
    if (statusCode >= 200 && statusCode < 400) {
      return null;
    }
    if (statusCode === 401) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_UNAUTHORIZED,
        '服务器要求身份验证', '该地址需要登录令牌、Cookie 或账号信息，当前直链没有携带认证信息。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false, statusCode);
    }
    if (statusCode === 403) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_FORBIDDEN,
        '服务器拒绝访问', '当前账号、地址或网络没有访问该媒体的权限。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false, statusCode);
    }
    if (statusCode === 404 || statusCode === 410) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_NOT_FOUND,
        '媒体不存在', '服务器找不到该文件，地址可能已失效或被移动。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false, statusCode);
    }
    if (statusCode === 408 || statusCode === 429) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_TIMEOUT,
        statusCode === 429 ? '请求过于频繁' : '服务器响应超时',
        statusCode === 429 ? '服务器暂时限制访问，请稍后重试。' : '服务器没有及时响应，请检查网络后重试。',
        RecoveryAction.RETRY, '重新检查', true, statusCode);
    }
    if (statusCode >= 500) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_SERVER_FAILED,
        '媒体服务器暂时不可用', `服务器返回 HTTP ${statusCode}，请稍后重试。`,
        RecoveryAction.RETRY, '重新检查', true, statusCode);
    }
    return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_REQUEST_FAILED,
      '服务器无法处理该地址', `服务器返回 HTTP ${statusCode}，请检查地址后重试。`,
      RecoveryAction.EDIT_SOURCE, '修改地址', false, statusCode);
  }

  static fromNetworkError(code: number): AppFailure {
    if (code === 201) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_PERMISSION_DENIED,
        '没有网络访问权限', '当前安装包没有获得网络访问能力，请重新安装或联系支持。',
        RecoveryAction.NONE, '', false, code);
    }
    if (code === 2300006) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_HOST_NOT_FOUND,
        '找不到服务器', '域名无法解析，请检查地址、DNS 或当前网络。',
        RecoveryAction.RETRY, '重新检查', true, code);
    }
    if (code === 2300007 || code === 2300052 || code === 2300055 || code === 2300056) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_CONNECTION_FAILED,
        '无法连接服务器', '请确认服务器在线、端口开放且当前网络可以访问。',
        RecoveryAction.RETRY, '重新检查', true, code);
    }
    if (code === 2300028) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_TIMEOUT,
        '连接超时', '服务器没有及时响应，请检查网络后重试。',
        RecoveryAction.RETRY, '重新检查', true, code);
    }
    if (code === 2300047) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_REDIRECT_FAILED,
        '重定向次数过多', '服务器在多个地址间反复跳转，请检查 WebDAV URL 或反向代理配置。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false, code);
    }
    if (code === 2300058 || code === 2300059 || code === 2300060 || code === 2300077) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_TLS_FAILED,
        '安全连接失败', '服务器证书无效、不受信任或与域名不匹配。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false, code);
    }
    if (code === 2300009 || code === 2300094) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_UNAUTHORIZED,
        '服务器要求身份验证', '该媒体需要认证信息，当前直链无法直接访问。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false, code);
    }
    if (code === 2300997) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_CLEARTEXT_BLOCKED,
        '系统阻止了非加密连接', '请改用 HTTPS 地址。',
        RecoveryAction.EDIT_SOURCE, '修改地址', false, code);
    }
    return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_REQUEST_FAILED,
      '无法检查媒体地址', '网络请求失败，请检查地址和网络后重试。',
      RecoveryAction.RETRY, '重新检查', true, code);
  }

  static cellularPlaybackDisabled(): AppFailure {
    return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_CELLULAR_DISABLED,
      '移动网络播放已关闭', '当前正在使用蜂窝网络。请连接 Wi-Fi，或在设置中允许移动网络播放。',
      RecoveryAction.OPEN_SETTINGS, '打开设置', false);
  }

  static fromPlaybackError(code: number, detail: string = ''): AppFailure {
    const normalizedDetail: string = detail.toLowerCase();
    if (code === 5400106 || code === 331350546 || normalizedDetail.includes('unsupported') ||
      normalizedDetail.includes('unsupport video decoder')) {
      return FailureCatalog.failure(FailureDomain.PLAYBACK, FailureCode.MEDIA_UNSUPPORTED,
        '当前设备不支持该媒体', '视频或音频编码超出当前设备的系统解码能力。',
        RecoveryAction.EDIT_SOURCE, '返回修改', false, code);
    }
    if (code === 5400103) {
      return FailureCatalog.failure(FailureDomain.PLAYBACK, FailureCode.MEDIA_READ_FAILED,
        '无法读取媒体', '文件不可读、地址已失效，或服务器没有返回有效媒体数据。',
        RecoveryAction.RETRY, '重试', true, code);
    }
    if (code === 5400104) {
      return FailureCatalog.failure(FailureDomain.PLAYBACK, FailureCode.MEDIA_TIMEOUT,
        '打开媒体超时', '服务器或设备没有及时完成媒体初始化。',
        RecoveryAction.RETRY, '重试', true, code);
    }
    if (code === 5400105) {
      return FailureCatalog.failure(FailureDomain.PLAYBACK, FailureCode.MEDIA_SERVICE_UNAVAILABLE,
        '播放服务暂时不可用', '系统媒体服务未能正常响应，请稍后重试。',
        RecoveryAction.RETRY, '重试', true, code);
    }
    if (code === 5400108) {
      return FailureCatalog.failure(FailureDomain.PLAYBACK, FailureCode.MEDIA_INVALID_SOURCE,
        '媒体地址或参数无效', '请返回检查媒体地址后重试。',
        RecoveryAction.EDIT_SOURCE, '返回修改', false, code);
    }
    if (code === 5400102) {
      return FailureCatalog.failure(FailureDomain.PLAYBACK, FailureCode.MEDIA_STATE_INVALID,
        '播放器状态异常', '播放器没有正确完成初始化，请重试。',
        RecoveryAction.RETRY, '重试', true, code);
    }
    if (code === 5411012) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_CLEARTEXT_BLOCKED,
        '系统阻止了非加密媒体', '请返回并改用 HTTPS 地址。',
        RecoveryAction.EDIT_SOURCE, '返回修改', false, code);
    }
    if (code === 201) {
      return FailureCatalog.failure(FailureDomain.NETWORK, FailureCode.NETWORK_PERMISSION_DENIED,
        '没有网络访问权限', '当前安装包没有获得网络访问能力，请重新安装或联系支持。',
        RecoveryAction.NONE, '', false, code);
    }
    return FailureCatalog.failure(FailureDomain.PLAYBACK, FailureCode.PLAYBACK_FAILED,
      '无法播放该媒体', '播放器未能打开媒体，请检查地址、网络或媒体格式。',
      RecoveryAction.RETRY, '重试', true, code);
  }

  static fromLocalFileError(code: number = 0): AppFailure {
    if (code === 201) {
      return FailureCatalog.failure(FailureDomain.FILE, FailureCode.LOCAL_FILE_PERMISSION_DENIED,
        '没有文件访问权限', '请允许 Linkora 读取所选文件后重试。',
        RecoveryAction.CHOOSE_FILE, '重新选择', true, code);
    }
    return FailureCatalog.failure(FailureDomain.FILE, FailureCode.LOCAL_FILE_UNAVAILABLE,
      '无法打开所选文件', '文件可能已移动、损坏或暂时不可访问。',
      RecoveryAction.CHOOSE_FILE, '重新选择', true, code);
  }

  static fromLocalScanError(code: number = 0): AppFailure {
    if (code === 201 || code === 13900012) {
      return FailureCatalog.failure(FailureDomain.FILE, FailureCode.LOCAL_SCAN_PERMISSION_DENIED,
        '无法读取本机媒体', '请允许 Linkora 访问设备中的照片和视频，然后重新扫描。',
        RecoveryAction.RETRY, '重新授权', true, code);
    }
    return FailureCatalog.failure(FailureDomain.FILE, FailureCode.LOCAL_SCAN_FAILED,
      '本地媒体扫描失败', '系统媒体库暂时无法读取，请稍后重新扫描。',
      RecoveryAction.RETRY, '重新扫描', true, code);
  }

  static localCacheWriteFailed(): AppFailure {
    return FailureCatalog.failure(FailureDomain.STORAGE, FailureCode.STORAGE_WRITE_FAILED,
      '媒体索引未保存', '本次扫描结果仍可使用，但下次启动可能需要重新扫描。',
      RecoveryAction.RETRY, '重新扫描', true);
  }

  static unknown(diagnosticCode: number = 0): AppFailure {
    return FailureCatalog.failure(FailureDomain.SYSTEM, FailureCode.UNKNOWN,
      '操作未完成', '发生了未识别的问题，请重试。',
      RecoveryAction.RETRY, '重试', true, diagnosticCode);
  }

  private static failure(domain: FailureDomain, code: FailureCode, title: string, message: string,
    action: RecoveryAction, actionLabel: string, retryable: boolean, rawCode: number = 0): AppFailure {
    const diagnosticCode: string = rawCode === 0 ? code : `${code}/${rawCode}`;
    return new AppFailure(domain, code, title, message, action, actionLabel, retryable, diagnosticCode);
  }
}
