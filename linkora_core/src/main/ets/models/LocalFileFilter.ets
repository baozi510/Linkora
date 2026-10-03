export enum LocalBrowseMode {
  VIDEO = 'video',
  DIRECTORY = 'directory'
}

export enum LocalFileCategory {
  VIDEO = 'video',
  IMAGE = 'image',
  AUDIO = 'audio',
  SUBTITLE = 'subtitle',
  UNSUPPORTED = 'unsupported'
}

export const DEFAULT_VIDEO_EXTENSIONS: string[] = [
  '.mp4', '.m4v', '.mov', '.mkv', '.webm', '.avi', '.wmv', '.flv', '.ts', '.m2ts',
  '.mts', '.mpg', '.mpeg', '.3gp', '.vob', '.ogv'
];

export const DEFAULT_IMAGE_EXTENSIONS: string[] = [
  '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif', '.bmp', '.tif', '.tiff', '.avif'
];

export const DEFAULT_SUBTITLE_EXTENSIONS: string[] = [
  '.srt', '.ass', '.ssa', '.vtt', '.sub', '.smi', '.sami'
];

export const DEFAULT_AUDIO_EXTENSIONS: string[] = [
  '.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.opus', '.amr', '.aiff', '.wma'
];

export class LocalFileFilter {
  readonly videoExtensions: string[];
  readonly imageExtensions: string[];
  readonly subtitleExtensions: string[];
  readonly audioExtensions: string[];

  constructor(videoExtensions: string[] = DEFAULT_VIDEO_EXTENSIONS,
    subtitleExtensions: string[] = DEFAULT_SUBTITLE_EXTENSIONS,
    audioExtensions: string[] = DEFAULT_AUDIO_EXTENSIONS,
    imageExtensions: string[] = DEFAULT_IMAGE_EXTENSIONS) {
    this.videoExtensions = LocalFileFilter.normalize(videoExtensions);
    this.imageExtensions = LocalFileFilter.normalize(imageExtensions);
    this.subtitleExtensions = LocalFileFilter.normalize(subtitleExtensions);
    this.audioExtensions = LocalFileFilter.normalize(audioExtensions);
  }

  categoryOf(fileName: string): LocalFileCategory {
    const extension: string = LocalFileFilter.extensionOf(fileName);
    if (this.videoExtensions.includes(extension)) {
      return LocalFileCategory.VIDEO;
    }
    if (this.imageExtensions.includes(extension)) {
      return LocalFileCategory.IMAGE;
    }
    if (this.audioExtensions.includes(extension)) {
      return LocalFileCategory.AUDIO;
    }
    if (this.subtitleExtensions.includes(extension)) {
      return LocalFileCategory.SUBTITLE;
    }
    return LocalFileCategory.UNSUPPORTED;
  }

  accepts(fileName: string): boolean {
    return this.categoryOf(fileName) !== LocalFileCategory.UNSUPPORTED;
  }

  extensionsFor(categories: LocalFileCategory[]): string[] {
    const result: string[] = [];
    for (const category of categories) {
      let extensions: string[] = [];
      if (category === LocalFileCategory.VIDEO) {
        extensions = this.videoExtensions;
      } else if (category === LocalFileCategory.IMAGE) {
        extensions = this.imageExtensions;
      } else if (category === LocalFileCategory.AUDIO) {
        extensions = this.audioExtensions;
      } else if (category === LocalFileCategory.SUBTITLE) {
        extensions = this.subtitleExtensions;
      }
      for (const extension of extensions) {
        if (!result.includes(extension)) {
          result.push(extension);
        }
      }
    }
    return result;
  }

  static extensionOf(fileName: string): string {
    const normalized: string = fileName.trim().toLowerCase();
    const dot: number = normalized.lastIndexOf('.');
    if (dot < 0 || dot === normalized.length - 1) {
      return '';
    }
    return normalized.substring(dot);
  }

  private static normalize(values: string[]): string[] {
    const result: string[] = [];
    for (const value of values) {
      let extension: string = value.trim().toLowerCase();
      if (extension.length === 0) {
        continue;
      }
      if (!extension.startsWith('.')) {
        extension = `.${extension}`;
      }
      if (!result.includes(extension)) {
        result.push(extension);
      }
    }
    return result;
  }
}
