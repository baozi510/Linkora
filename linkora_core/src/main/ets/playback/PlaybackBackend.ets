import { PlaybackPort } from './PlaybackPort';

export enum PlayerBackendKind {
  SYSTEM = 'system',
  MPV = 'mpv'
}

export enum PlayerBackendPreference {
  AUTO = 'auto',
  SYSTEM = 'system',
  MPV = 'mpv'
}

export class PlayerBackendCapabilities {
  readonly directUrl: boolean;
  readonly localFile: boolean;
  readonly proxyUrl: boolean;
  readonly assSubtitle: boolean;
  readonly pgsSubtitle: boolean;
  readonly hdr10: boolean;
  readonly hlg: boolean;
  readonly dolbyVisionAware: boolean;
  readonly nativeDolbyVisionOutput: boolean;
  readonly audioPassthrough: boolean;

  constructor(directUrl: boolean = true, localFile: boolean = true, proxyUrl: boolean = true,
    assSubtitle: boolean = false, pgsSubtitle: boolean = false, hdr10: boolean = false,
    hlg: boolean = false, dolbyVisionAware: boolean = false,
    nativeDolbyVisionOutput: boolean = false, audioPassthrough: boolean = false) {
    this.directUrl = directUrl;
    this.localFile = localFile;
    this.proxyUrl = proxyUrl;
    this.assSubtitle = assSubtitle;
    this.pgsSubtitle = pgsSubtitle;
    this.hdr10 = hdr10;
    this.hlg = hlg;
    this.dolbyVisionAware = dolbyVisionAware;
    this.nativeDolbyVisionOutput = nativeDolbyVisionOutput;
    this.audioPassthrough = audioPassthrough;
  }
}

export interface PlaybackBackend extends PlaybackPort {
  backendKind(): PlayerBackendKind;
  capabilities(): PlayerBackendCapabilities;
}
