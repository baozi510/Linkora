import { RemoteProtocol } from '../models/RemoteSource';

export enum RemoteEntryKind {
  FILE = 'file',
  DIRECTORY = 'directory'
}

export class RemoteConnectionOptions {
  readonly host: string;
  readonly port: number;
  readonly rootPath: string;
  readonly credentialRef: string;
  readonly secureTransport: boolean;

  constructor(host: string, port: number, rootPath: string = '/', credentialRef: string = '',
    secureTransport: boolean = false) {
    this.host = host;
    this.port = port;
    this.rootPath = rootPath;
    this.credentialRef = credentialRef;
    this.secureTransport = secureTransport;
  }
}

export class RemoteEntry {
  readonly path: string;
  readonly displayName: string;
  readonly kind: RemoteEntryKind;
  readonly size: number;
  readonly modifiedAt: number;

  constructor(path: string, displayName: string, kind: RemoteEntryKind,
    size: number = 0, modifiedAt: number = 0) {
    this.path = path;
    this.displayName = displayName;
    this.kind = kind;
    this.size = size;
    this.modifiedAt = modifiedAt;
  }
}

export interface RemoteReadSession {
  size(): number;
  read(offset: number, length: number): Promise<ArrayBuffer>;
  cancel(): void;
  close(): Promise<void>;
}

export interface SourceConnection {
  list(path: string): Promise<RemoteEntry[]>;
  stat(path: string): Promise<RemoteEntry | null>;
  openReader(path: string): Promise<RemoteReadSession>;
  close(): Promise<void>;
}

export interface SourcePlugin {
  protocol(): RemoteProtocol;
  connect(options: RemoteConnectionOptions): Promise<SourceConnection>;
}

export class SourcePluginRegistry {
  private plugins: SourcePlugin[] = [];

  register(plugin: SourcePlugin): void {
    const protocol: RemoteProtocol = plugin.protocol();
    for (let index: number = 0; index < this.plugins.length; index++) {
      if (this.plugins[index].protocol() === protocol) {
        throw new Error(`Source plugin already registered: ${protocol}`);
      }
    }
    this.plugins.push(plugin);
  }

  resolve(protocol: RemoteProtocol): SourcePlugin | null {
    for (let index: number = 0; index < this.plugins.length; index++) {
      if (this.plugins[index].protocol() === protocol) {
        return this.plugins[index];
      }
    }
    return null;
  }

  registeredProtocols(): RemoteProtocol[] {
    const protocols: RemoteProtocol[] = [];
    for (let index: number = 0; index < this.plugins.length; index++) {
      protocols.push(this.plugins[index].protocol());
    }
    return protocols;
  }
}
