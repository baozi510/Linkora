export enum HdrType {
  UNKNOWN = 'unknown',
  SDR = 'sdr',
  HDR10 = 'hdr10',
  HLG = 'hlg',
  DOLBY_VISION = 'dolby_vision'
}

export enum SubtitleKind {
  UNKNOWN = 'unknown',
  TEXT = 'text',
  BITMAP = 'bitmap'
}

export class VideoTrackInfo {
  readonly id: string;
  readonly codec: string;
  readonly profile: string;
  readonly level: string;
  readonly width: number;
  readonly height: number;
  readonly frameRate: number;
  readonly bitrate: number;
  readonly bitDepth: number;
  readonly pixelFormat: string;
  readonly colorPrimaries: string;
  readonly transfer: string;
  readonly colorSpace: string;
  readonly hdrType: HdrType;
  readonly dolbyVisionProfile: string;
  readonly language: string;
  readonly title: string;
  readonly isDefault: boolean;

  constructor(id: string = '', codec: string = '', profile: string = '', level: string = '',
    width: number = 0, height: number = 0, frameRate: number = 0, bitrate: number = 0,
    bitDepth: number = 0, pixelFormat: string = '', colorPrimaries: string = '',
    transfer: string = '', colorSpace: string = '', hdrType: HdrType = HdrType.UNKNOWN,
    dolbyVisionProfile: string = '', language: string = '', title: string = '',
    isDefault: boolean = false) {
    this.id = id;
    this.codec = codec;
    this.profile = profile;
    this.level = level;
    this.width = Math.max(0, width);
    this.height = Math.max(0, height);
    this.frameRate = Math.max(0, frameRate);
    this.bitrate = Math.max(0, bitrate);
    this.bitDepth = Math.max(0, bitDepth);
    this.pixelFormat = pixelFormat;
    this.colorPrimaries = colorPrimaries;
    this.transfer = transfer;
    this.colorSpace = colorSpace;
    this.hdrType = hdrType;
    this.dolbyVisionProfile = dolbyVisionProfile;
    this.language = language;
    this.title = title;
    this.isDefault = isDefault;
  }
}

export class AudioTrackInfo {
  readonly id: string;
  readonly codec: string;
  readonly profile: string;
  readonly channels: number;
  readonly channelLayout: string;
  readonly sampleRate: number;
  readonly bitrate: number;
  readonly language: string;
  readonly title: string;
  readonly isDefault: boolean;

  constructor(id: string = '', codec: string = '', profile: string = '', channels: number = 0,
    channelLayout: string = '', sampleRate: number = 0, bitrate: number = 0,
    language: string = '', title: string = '', isDefault: boolean = false) {
    this.id = id;
    this.codec = codec;
    this.profile = profile;
    this.channels = Math.max(0, channels);
    this.channelLayout = channelLayout;
    this.sampleRate = Math.max(0, sampleRate);
    this.bitrate = Math.max(0, bitrate);
    this.language = language;
    this.title = title;
    this.isDefault = isDefault;
  }
}

export class SubtitleTrackInfo {
  readonly id: string;
  readonly codec: string;
  readonly kind: SubtitleKind;
  readonly language: string;
  readonly title: string;
  readonly isForced: boolean;
  readonly isDefault: boolean;

  constructor(id: string = '', codec: string = '', kind: SubtitleKind = SubtitleKind.UNKNOWN,
    language: string = '', title: string = '', isForced: boolean = false,
    isDefault: boolean = false) {
    this.id = id;
    this.codec = codec;
    this.kind = kind;
    this.language = language;
    this.title = title;
    this.isForced = isForced;
    this.isDefault = isDefault;
  }
}

export class ChapterInfo {
  readonly startMs: number;
  readonly endMs: number;
  readonly title: string;

  constructor(startMs: number = 0, endMs: number = 0, title: string = '') {
    this.startMs = Math.max(0, startMs);
    this.endMs = Math.max(this.startMs, endMs);
    this.title = title;
  }
}

export class MediaInfo {
  readonly container: string;
  readonly durationMs: number;
  readonly bitrate: number;
  readonly sizeBytes: number;
  readonly videoTracks: VideoTrackInfo[];
  readonly audioTracks: AudioTrackInfo[];
  readonly subtitleTracks: SubtitleTrackInfo[];
  readonly chapters: ChapterInfo[];
  readonly tags: Record<string, string>;

  constructor(container: string = '', durationMs: number = 0, bitrate: number = 0,
    sizeBytes: number = 0, videoTracks: VideoTrackInfo[] = [], audioTracks: AudioTrackInfo[] = [],
    subtitleTracks: SubtitleTrackInfo[] = [], chapters: ChapterInfo[] = [],
    tags: Record<string, string> = {}) {
    this.container = container;
    this.durationMs = Math.max(0, durationMs);
    this.bitrate = Math.max(0, bitrate);
    this.sizeBytes = Math.max(0, sizeBytes);
    this.videoTracks = videoTracks;
    this.audioTracks = audioTracks;
    this.subtitleTracks = subtitleTracks;
    this.chapters = chapters;
    this.tags = tags;
  }

  hasVideo(): boolean {
    return this.videoTracks.length > 0;
  }

  hasAudio(): boolean {
    return this.audioTracks.length > 0;
  }
}
