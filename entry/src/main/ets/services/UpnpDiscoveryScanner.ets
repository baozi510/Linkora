import { socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { DiscoveredService, DiscoveryMethod, RemoteProtocol } from 'linkora_core';

const SSDP_ADDRESS: string = '239.255.255.250';
const SSDP_PORT: number = 1900;
const DEFAULT_SCAN_TIMEOUT: number = 4500;

class ParsedEndpoint {
  readonly host: string;
  readonly port: number;

  constructor(host: string, port: number) {
    this.host = host;
    this.port = port;
  }
}

export class UpnpDiscoveryScanner {
  static async scan(timeoutMs: number = DEFAULT_SCAN_TIMEOUT): Promise<DiscoveredService[]> {
    const udp: socket.UDPSocket = socket.constructUDPSocketInstance();
    const services: DiscoveredService[] = [];
    const seenLocations: string[] = [];
    const onMessage = (event: socket.SocketMessageInfo): void => {
      const response: string = new util.TextDecoder('utf-8').decodeToString(new Uint8Array(event.message));
      const location: string = UpnpDiscoveryScanner.header(response, 'location');
      if (location.length === 0 || seenLocations.indexOf(location) >= 0) {
        return;
      }
      const endpoint: ParsedEndpoint | null =
        UpnpDiscoveryScanner.endpoint(location);
      if (endpoint === null) {
        return;
      }
      seenLocations.push(location);
      const serverHeader: string = UpnpDiscoveryScanner.header(response, 'server');
      const displayName: string = serverHeader.length > 0 ? serverHeader : 'UPnP / DLNA 设备';
      services.push(new DiscoveredService(
        RemoteProtocol.HTTP,
        endpoint.host,
        endpoint.port,
        displayName,
        DiscoveryMethod.SSDP
      ));
    };

    try {
      udp.on('message', onMessage);
      await udp.bind({ address: '0.0.0.0', port: 0 });
      await udp.send({
        data: 'M-SEARCH * HTTP/1.1\r\n' +
          `HOST: ${SSDP_ADDRESS}:${SSDP_PORT}\r\n` +
          'MAN: "ssdp:discover"\r\n' +
          'MX: 3\r\n' +
          'ST: ssdp:all\r\n\r\n',
        address: { address: SSDP_ADDRESS, port: SSDP_PORT }
      });
      await new Promise<void>((resolve: () => void) => {
        setTimeout(resolve, timeoutMs);
      });
    } catch (_error) {
    } finally {
      udp.off('message', onMessage);
      try {
        await udp.close();
      } catch (_error) {
      }
    }
    return services;
  }

  private static header(response: string, name: string): string {
    const lines: string[] = response.split(/\r?\n/);
    const expected: string = name.toLowerCase();
    for (let index: number = 0; index < lines.length; index++) {
      const separator: number = lines[index].indexOf(':');
      if (separator <= 0 || lines[index].substring(0, separator).trim().toLowerCase() !== expected) {
        continue;
      }
      return lines[index].substring(separator + 1).trim();
    }
    return '';
  }

  private static endpoint(location: string): ParsedEndpoint | null {
    const separator: number = location.indexOf('://');
    if (separator <= 0) {
      return null;
    }
    const scheme: string = location.substring(0, separator).toLowerCase();
    if (scheme !== 'http' && scheme !== 'https') {
      return null;
    }
    const authorityStart: number = separator + 3;
    let authorityEnd: number = location.length;
    const slashIndex: number = location.indexOf('/', authorityStart);
    const queryIndex: number = location.indexOf('?', authorityStart);
    const fragmentIndex: number = location.indexOf('#', authorityStart);
    if (slashIndex >= 0 && slashIndex < authorityEnd) {
      authorityEnd = slashIndex;
    }
    if (queryIndex >= 0 && queryIndex < authorityEnd) {
      authorityEnd = queryIndex;
    }
    if (fragmentIndex >= 0 && fragmentIndex < authorityEnd) {
      authorityEnd = fragmentIndex;
    }
    const authority: string = location.substring(authorityStart, authorityEnd);
    if (authority.length === 0 || authority.includes('@')) {
      return null;
    }
    let host: string = authority;
    let port: number = scheme === 'https' ? 443 : 80;
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
      }
    }
    if (host.length === 0 || port < 1 || port > 65535) {
      return null;
    }
    return new ParsedEndpoint(host, port);
  }
}
