import { RemoteProtocol } from 'linkora_core';

export class ParsedWebUrl {
  host: string;
  port: number;
  explicitPort: boolean;
  explicitScheme: boolean;
  rootPath: string;
  secureTransport: boolean;
  username: string;
  password: string;

  constructor(host: string, port: number, explicitPort: boolean, explicitScheme: boolean,
    rootPath: string, secureTransport: boolean, username: string, password: string) {
    this.host = host;
    this.port = port;
    this.explicitPort = explicitPort;
    this.explicitScheme = explicitScheme;
    this.rootPath = rootPath;
    this.secureTransport = secureTransport;
    this.username = username;
    this.password = password;
  }
}

export class ParsedServerAddress {
  host: string;
  port: number;
  explicitPort: boolean;
  rootPath: string;
  username: string;
  password: string;
  scheme: string;

  constructor(host: string, port: number, explicitPort: boolean, rootPath: string,
    username: string, password: string, scheme: string) {
    this.host = host;
    this.port = port;
    this.explicitPort = explicitPort;
    this.rootPath = rootPath;
    this.username = username;
    this.password = password;
    this.scheme = scheme;
  }
}

/** Pure parsing and validation used by the network server form. */
export class NetworkAddressParser {
  static acceptedSchemes(protocol: RemoteProtocol): string[] {
    if (protocol === RemoteProtocol.SMB) {
      return ['smb', 'cifs'];
    }
    if (protocol === RemoteProtocol.SFTP) {
      return ['sftp'];
    }
    if (protocol === RemoteProtocol.FTP) {
      return ['ftp', 'ftps'];
    }
    return ['nfs'];
  }

  static parseServer(rawValue: string, protocol: RemoteProtocol,
    defaultPort: number): ParsedServerAddress | null {
    const value: string = rawValue.trim();
    if (value.length === 0 || /\s/.test(value)) {
      return null;
    }
    let scheme: string = '';
    let authority: string = value;
    let rootPath: string = '/';
    const schemeEnd: number = value.indexOf('://');
    if (schemeEnd >= 0) {
      scheme = value.substring(0, schemeEnd).toLowerCase();
      if (schemeEnd === 0 || !NetworkAddressParser.acceptedSchemes(protocol).includes(scheme)) {
        return null;
      }
      const authorityStart: number = schemeEnd + 3;
      const pathStart: number = value.indexOf('/', authorityStart);
      authority = pathStart >= 0 ? value.substring(authorityStart, pathStart) : value.substring(authorityStart);
      rootPath = pathStart >= 0 ? value.substring(pathStart) : '/';
    } else if (protocol === RemoteProtocol.NFS) {
      const exportSeparator: number = value.indexOf(':/');
      if (exportSeparator > 0 && value.indexOf(':') === exportSeparator) {
        authority = value.substring(0, exportSeparator);
        rootPath = value.substring(exportSeparator + 1);
      } else if (value.includes('/')) {
        return null;
      }
    } else if (value.includes('/') || value.includes('?') || value.includes('#')) {
      return null;
    }

    let username: string = '';
    let password: string = '';
    const userInfoSeparator: number = authority.lastIndexOf('@');
    if (userInfoSeparator >= 0) {
      const userInfo: string = authority.substring(0, userInfoSeparator);
      authority = authority.substring(userInfoSeparator + 1);
      const passwordSeparator: number = userInfo.indexOf(':');
      try {
        username = decodeURIComponent(passwordSeparator >= 0 ?
          userInfo.substring(0, passwordSeparator) : userInfo);
        password = passwordSeparator >= 0 ? decodeURIComponent(userInfo.substring(passwordSeparator + 1)) : '';
      } catch (_error) {
        return null;
      }
      if (username.length === 0 || authority.length === 0) {
        return null;
      }
    }

    let host: string = authority;
    let port: number = defaultPort;
    let explicitPort: boolean = false;
    if (authority.startsWith('[')) {
      const bracketEnd: number = authority.indexOf(']');
      if (bracketEnd <= 1) {
        return null;
      }
      host = authority.substring(0, bracketEnd + 1);
      const suffix: string = authority.substring(bracketEnd + 1);
      if (suffix.length > 0) {
        if (!/^:\d+$/.test(suffix)) {
          return null;
        }
        port = Number(suffix.substring(1));
        explicitPort = true;
      }
    } else {
      const colonIndex: number = authority.lastIndexOf(':');
      if (colonIndex >= 0) {
        if (authority.indexOf(':') !== colonIndex) {
          return null;
        }
        host = authority.substring(0, colonIndex);
        const portText: string = authority.substring(colonIndex + 1);
        if (host.length === 0 || !/^\d+$/.test(portText)) {
          return null;
        }
        port = Number(portText);
        explicitPort = true;
      }
    }
    if (host.length === 0 || port < 1 || port > 65535 || rootPath.includes('?') || rootPath.includes('#')) {
      return null;
    }
    return new ParsedServerAddress(host, port, explicitPort, rootPath, username, password, scheme);
  }

  static serverValidationError(rawValue: string, protocol: RemoteProtocol,
    defaultPort: number): string {
    const value: string = rawValue.trim();
    if (value.length === 0) {
      return '请输入服务器地址';
    }
    if (/\s/.test(value)) {
      return '服务器地址不能包含空格';
    }
    if (NetworkAddressParser.parseServer(value, protocol, defaultPort) === null) {
      const scheme: string = NetworkAddressParser.acceptedSchemes(protocol)[0];
      return `地址格式不正确，可输入 IP、域名或 ${scheme}:// 地址`;
    }
    return '';
  }

  static parseWeb(rawValue: string): ParsedWebUrl | null {
    const value: string = rawValue.trim();
    if (value.length === 0 || /\s/.test(value)) {
      return null;
    }
    const rawSchemeEnd: number = value.indexOf('://');
    const explicitScheme: boolean = rawSchemeEnd > 0;
    if (rawSchemeEnd === 0) {
      return null;
    }
    let normalizedValue: string = value;
    if (explicitScheme) {
      const explicitSchemeValue: string = value.substring(0, rawSchemeEnd).toLowerCase();
      if (explicitSchemeValue !== 'http' && explicitSchemeValue !== 'https') {
        return null;
      }
    } else {
      normalizedValue = `https://${value}`;
    }
    const schemeEnd: number = normalizedValue.indexOf('://');
    const scheme: string = normalizedValue.substring(0, schemeEnd).toLowerCase();
    const authorityStart: number = schemeEnd + 3;
    let authorityEnd: number = normalizedValue.length;
    const slashIndex: number = normalizedValue.indexOf('/', authorityStart);
    const queryIndex: number = normalizedValue.indexOf('?', authorityStart);
    const fragmentIndex: number = normalizedValue.indexOf('#', authorityStart);
    if (slashIndex >= 0 && slashIndex < authorityEnd) authorityEnd = slashIndex;
    if (queryIndex >= 0 && queryIndex < authorityEnd) authorityEnd = queryIndex;
    if (fragmentIndex >= 0 && fragmentIndex < authorityEnd) authorityEnd = fragmentIndex;
    let authority: string = normalizedValue.substring(authorityStart, authorityEnd);
    if (authority.length === 0) {
      return null;
    }

    let username: string = '';
    let password: string = '';
    const userInfoSeparator: number = authority.lastIndexOf('@');
    if (userInfoSeparator >= 0) {
      const userInfo: string = authority.substring(0, userInfoSeparator);
      authority = authority.substring(userInfoSeparator + 1);
      if (userInfo.length === 0 || authority.length === 0) {
        return null;
      }
      const passwordSeparator: number = userInfo.indexOf(':');
      const rawUsername: string = passwordSeparator >= 0 ? userInfo.substring(0, passwordSeparator) : userInfo;
      const rawPassword: string = passwordSeparator >= 0 ? userInfo.substring(passwordSeparator + 1) : '';
      try {
        username = decodeURIComponent(rawUsername);
        password = decodeURIComponent(rawPassword);
      } catch (_error) {
        return null;
      }
      if (username.length === 0) {
        return null;
      }
    }

    let host: string = authority;
    let port: number = scheme === 'https' ? 443 : 80;
    let explicitPort: boolean = false;
    if (authority.startsWith('[')) {
      const bracketEnd: number = authority.indexOf(']');
      if (bracketEnd <= 1) return null;
      host = authority.substring(0, bracketEnd + 1);
      const portSuffix: string = authority.substring(bracketEnd + 1);
      if (portSuffix.length > 0) {
        if (!/^:\d+$/.test(portSuffix)) return null;
        port = Number(portSuffix.substring(1));
        explicitPort = true;
      }
    } else {
      const colonIndex: number = authority.lastIndexOf(':');
      if (colonIndex >= 0) {
        if (authority.indexOf(':') !== colonIndex) return null;
        host = authority.substring(0, colonIndex);
        const portText: string = authority.substring(colonIndex + 1);
        if (host.length === 0 || !/^\d+$/.test(portText)) return null;
        port = Number(portText);
        explicitPort = true;
      }
    }
    if (host.length === 0 || port < 1 || port > 65535) {
      return null;
    }
    const rootPath: string = normalizedValue.substring(authorityEnd).length === 0 ?
      '/' : normalizedValue.substring(authorityEnd);
    return new ParsedWebUrl(host, port, explicitPort, explicitScheme, rootPath,
      scheme === 'https', username, password);
  }

  static webValidationError(rawValue: string): string {
    const value: string = rawValue.trim();
    if (value.length === 0) return '请输入服务器地址或 URL';
    if (/\s/.test(value)) return '地址不能包含空格';
    const schemeEnd: number = value.indexOf('://');
    if (schemeEnd === 0) return '服务器地址格式不正确';
    if (schemeEnd > 0) {
      const scheme: string = value.substring(0, schemeEnd).toLowerCase();
      if (scheme !== 'http' && scheme !== 'https') {
        return '仅支持 HTTP 或 HTTPS 地址，也可以省略协议';
      }
    }
    const authorityStart: number = schemeEnd > 0 ? schemeEnd + 3 : 0;
    let authorityEnd: number = value.length;
    const slashIndex: number = value.indexOf('/', authorityStart);
    const queryIndex: number = value.indexOf('?', authorityStart);
    const fragmentIndex: number = value.indexOf('#', authorityStart);
    if (slashIndex >= 0 && slashIndex < authorityEnd) authorityEnd = slashIndex;
    if (queryIndex >= 0 && queryIndex < authorityEnd) authorityEnd = queryIndex;
    if (fragmentIndex >= 0 && fragmentIndex < authorityEnd) authorityEnd = fragmentIndex;
    let authority: string = value.substring(authorityStart, authorityEnd);
    if (authority.length === 0) return '请输入服务器地址';
    const userInfoSeparator: number = authority.lastIndexOf('@');
    if (userInfoSeparator >= 0) {
      const userInfo: string = authority.substring(0, userInfoSeparator);
      authority = authority.substring(userInfoSeparator + 1);
      if (userInfo.length === 0) return '地址中的账号信息不完整';
      const passwordSeparator: number = userInfo.indexOf(':');
      const rawUsername: string = passwordSeparator >= 0 ? userInfo.substring(0, passwordSeparator) : userInfo;
      try {
        if (decodeURIComponent(rawUsername).length === 0 ||
          (passwordSeparator >= 0 && decodeURIComponent(userInfo.substring(passwordSeparator + 1)).length === 0)) {
          return '地址中的账号信息不完整';
        }
      } catch (_error) {
        return '地址中的账号信息编码无效';
      }
    }
    if (authority.length === 0) return '请输入服务器地址';
    if (authority.startsWith('[')) {
      const bracketEnd: number = authority.indexOf(']');
      if (bracketEnd <= 1) return '服务器地址格式不正确';
      const portSuffix: string = authority.substring(bracketEnd + 1);
      if (portSuffix.length > 0 && !/^:\d+$/.test(portSuffix)) return '端口必须是数字';
    } else {
      const colonIndex: number = authority.lastIndexOf(':');
      if (colonIndex >= 0) {
        if (authority.indexOf(':') !== colonIndex) return 'IPv6 地址请使用方括号，例如：[::1]';
        const portText: string = authority.substring(colonIndex + 1);
        if (!/^\d+$/.test(portText)) return '端口必须是数字';
        const port: number = Number(portText);
        if (port < 1 || port > 65535) return '端口范围为 1–65535';
      }
    }
    return NetworkAddressParser.parseWeb(value) === null ? '地址格式不正确，请检查协议、主机和端口' : '';
  }
}
