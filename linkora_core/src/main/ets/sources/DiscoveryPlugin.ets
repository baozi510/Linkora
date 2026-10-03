import { DiscoveryMethod, RemoteProtocol } from '../models/RemoteSource';

export class DiscoveryRequest {
  readonly methods: DiscoveryMethod[];
  readonly timeoutMs: number;

  constructor(methods: DiscoveryMethod[], timeoutMs: number = 8000) {
    this.methods = methods;
    this.timeoutMs = timeoutMs;
  }
}

export class DiscoveredService {
  readonly protocol: RemoteProtocol;
  readonly host: string;
  readonly port: number;
  readonly displayName: string;
  readonly method: DiscoveryMethod;

  constructor(protocol: RemoteProtocol, host: string, port: number,
    displayName: string, method: DiscoveryMethod) {
    this.protocol = protocol;
    this.host = host;
    this.port = port;
    this.displayName = displayName;
    this.method = method;
  }
}

export type DiscoveryObserver = (service: DiscoveredService) => void;

export interface DiscoverySession {
  cancel(): void;
  completion(): Promise<void>;
}

export interface DiscoveryPlugin {
  start(request: DiscoveryRequest, observer: DiscoveryObserver): DiscoverySession;
}
