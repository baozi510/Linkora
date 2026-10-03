export enum MediaProtocol {
  HTTP = 'http',
  HTTPS = 'https'
}

export enum MediaFormat {
  HLS = 'HLS',
  DASH = 'DASH',
  MP4 = 'MP4',
  MATROSKA = 'Matroska',
  MPEG_TS = 'MPEG-TS',
  AUDIO = 'Audio',
  UNKNOWN = 'Unknown'
}

export enum LinkIssue {
  NONE = 'none',
  EMPTY = 'empty',
  TOO_LONG = 'too_long',
  INVALID_URL = 'invalid_url',
  UNSUPPORTED_PROTOCOL = 'unsupported_protocol',
  MISSING_HOST = 'missing_host',
  EMBEDDED_CREDENTIALS = 'embedded_credentials'
}

export class MediaLink {
  readonly url: string;
  readonly host: string;
  readonly protocol: MediaProtocol;
  readonly format: MediaFormat;

  constructor(url: string, host: string, protocol: MediaProtocol, format: MediaFormat) {
    this.url = url;
    this.host = host;
    this.protocol = protocol;
    this.format = format;
  }
}

export class LinkParseResult {
  readonly value: MediaLink | null;
  readonly issue: LinkIssue;

  constructor(value: MediaLink | null, issue: LinkIssue) {
    this.value = value;
    this.issue = issue;
  }

  isValid(): boolean {
    return this.value !== null && this.issue === LinkIssue.NONE;
  }
}
