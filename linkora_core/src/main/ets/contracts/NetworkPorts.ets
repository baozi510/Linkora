import { AppFailure } from '../errors/AppFailure';
import { RemoteProtocol } from '../models/RemoteSource';

export class NetworkProbeResult {
  readonly statusCode: number;
  readonly verified: boolean;
  readonly failure: AppFailure | null;

  constructor(statusCode: number, verified: boolean, failure: AppFailure | null) {
    this.statusCode = statusCode;
    this.verified = verified;
    this.failure = failure;
  }

  isAvailable(): boolean {
    return this.failure === null;
  }
}

export interface NetworkProbePort {
  inspect(url: string): Promise<NetworkProbeResult>;
  cancel(): void;
}

export interface NetworkAccessPolicyPort {
  check(): Promise<AppFailure | null>;
}

export class ProtocolTestRequest {
  readonly protocol: RemoteProtocol;
  readonly host: string;
  readonly port: number;
  readonly rootPath: string;
  readonly username: string;
  readonly password: string;
  readonly secureTransport: boolean;
  readonly domain: string;
  readonly sftpFingerprint: string;
  readonly strictSftp: boolean;

  constructor(protocol: RemoteProtocol, host: string, port: number, rootPath: string = '/',
    username: string = '', password: string = '', secureTransport: boolean = false, domain: string = '',
    sftpFingerprint: string = '', strictSftp: boolean = false) {
    this.protocol = protocol;
    this.host = host;
    this.port = port;
    this.rootPath = rootPath;
    this.username = username;
    this.password = password;
    this.secureTransport = secureTransport;
    this.domain = domain;
    this.sftpFingerprint = sftpFingerprint; this.strictSftp = strictSftp;
  }
}

export class ProtocolTestResult {
  readonly succeeded: boolean;
  readonly title: string;
  readonly message: string;
  readonly diagnosticCode: string;

  constructor(succeeded: boolean, title: string, message: string, diagnosticCode: string = '') {
    this.succeeded = succeeded;
    this.title = title;
    this.message = message;
    this.diagnosticCode = diagnosticCode;
  }
}

export interface ProtocolTestAdapter {
  protocol(): RemoteProtocol;
  test(request: ProtocolTestRequest): Promise<ProtocolTestResult>;
  cancel(): void;
}
