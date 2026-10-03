export enum ResolvedMediaInputKind {
  DIRECT_URL = 'direct_url',
  LOCAL_URI = 'local_uri',
  FILE_DESCRIPTOR = 'file_descriptor',
  PROXY_URL = 'proxy_url'
}

export class RequestPolicy {
  readonly headers: Record<string, string>;
  readonly connectTimeoutMs: number;
  readonly readTimeoutMs: number;
  readonly maxRedirects: number;

  constructor(headers: Record<string, string> = {}, connectTimeoutMs: number = 8000,
    readTimeoutMs: number = 8000, maxRedirects: number = 5) {
    this.headers = headers;
    this.connectTimeoutMs = Math.max(0, connectTimeoutMs);
    this.readTimeoutMs = Math.max(0, readTimeoutMs);
    this.maxRedirects = Math.max(0, maxRedirects);
  }
}

export class ResolvedMediaInput {
  readonly kind: ResolvedMediaInputKind;
  readonly sourceId: string;
  readonly uri: string;
  readonly requestPolicy: RequestPolicy;
  readonly fd: number;
  readonly offset: number;
  readonly length: number;

  constructor(kind: ResolvedMediaInputKind, sourceId: string = '', uri: string = '',
    requestPolicy: RequestPolicy = new RequestPolicy(), fd: number = -1,
    offset: number = 0, length: number = 0) {
    this.kind = kind;
    this.sourceId = sourceId;
    this.uri = uri;
    this.requestPolicy = requestPolicy;
    this.fd = fd;
    this.offset = Math.max(0, offset);
    this.length = Math.max(0, length);
  }
}
