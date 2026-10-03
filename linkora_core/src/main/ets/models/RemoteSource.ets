export enum SourceFamily {
  STREAM_LINK = 'stream_link',
  NETWORK_STORAGE = 'network_storage'
}

export enum RemoteProtocol {
  WEBDAV = 'webdav',
  SMB = 'smb',
  SFTP = 'sftp',
  FTP = 'ftp',
  HTTP = 'http',
  NFS = 'nfs'
}

export enum DiscoveryMethod {
  MDNS_DNS_SD = 'mdns_dns_sd',
  WS_DISCOVERY = 'ws_discovery',
  NETBIOS = 'netbios',
  SSDP = 'ssdp',
  RPCBIND = 'rpcbind',
  MANUAL = 'manual'
}

export enum AdapterRuntime {
  ARKTS = 'arkts',
  NATIVE = 'native'
}

export class ProtocolCapability {
  readonly protocol: RemoteProtocol;
  readonly defaultPort: number;
  readonly runtime: AdapterRuntime;
  readonly discoveryMethods: DiscoveryMethod[];
  readonly secureByDefault: boolean;

  constructor(protocol: RemoteProtocol, defaultPort: number, runtime: AdapterRuntime,
    discoveryMethods: DiscoveryMethod[], secureByDefault: boolean) {
    this.protocol = protocol;
    this.defaultPort = defaultPort;
    this.runtime = runtime;
    this.discoveryMethods = discoveryMethods;
    this.secureByDefault = secureByDefault;
  }
}

export const NETWORK_PROTOCOL_CAPABILITIES: ProtocolCapability[] = [
  new ProtocolCapability(
    RemoteProtocol.WEBDAV,
    443,
    AdapterRuntime.ARKTS,
    [DiscoveryMethod.MDNS_DNS_SD, DiscoveryMethod.MANUAL],
    true
  ),
  new ProtocolCapability(
    RemoteProtocol.SMB,
    445,
    AdapterRuntime.NATIVE,
    [DiscoveryMethod.WS_DISCOVERY, DiscoveryMethod.NETBIOS, DiscoveryMethod.MDNS_DNS_SD,
      DiscoveryMethod.MANUAL],
    false
  ),
  new ProtocolCapability(
    RemoteProtocol.SFTP,
    22,
    AdapterRuntime.NATIVE,
    [DiscoveryMethod.MDNS_DNS_SD, DiscoveryMethod.MANUAL],
    true
  ),
  new ProtocolCapability(
    RemoteProtocol.FTP,
    21,
    AdapterRuntime.NATIVE,
    [DiscoveryMethod.MDNS_DNS_SD, DiscoveryMethod.MANUAL],
    false
  ),
  new ProtocolCapability(
    RemoteProtocol.HTTP,
    80,
    AdapterRuntime.ARKTS,
    [DiscoveryMethod.MDNS_DNS_SD, DiscoveryMethod.MANUAL],
    false
  ),
  new ProtocolCapability(
    RemoteProtocol.NFS,
    2049,
    AdapterRuntime.NATIVE,
    [DiscoveryMethod.RPCBIND, DiscoveryMethod.MDNS_DNS_SD, DiscoveryMethod.MANUAL],
    false
  )
];
