export interface EventObserver {
  onEvent(id: number, name: string): void;
}

export enum MpvEvent {
  MPV_EVENT_FILE_LOADED = 8,
  MPV_EVENT_PLAYBACK_RESTART = 21
}

export class Media {
  readonly uri: string;
  constructor(uri: string) { this.uri = uri; }
}

export class StubStream<T> {
  listen(_listener: (value: T) => void): void {}
}

export class VideoTrack {
  id: string = 'auto';
  codec: string = '';
  lang: string = '';
  title: string = '';
}
export class AudioTrack {
  id: string = 'auto';
  codec: string = '';
  lang: string = '';
  title: string = '';
}
export class SubtitleTrack {
  id: string = 'auto';
  codec: string = '';
  lang: string = '';
  title: string = '';
}
export class Track {
  video: VideoTrack = new VideoTrack();
  audio: AudioTrack = new AudioTrack();
  subs: SubtitleTrack = new SubtitleTrack();
}
export class Tracks {
  video: VideoTrack[] = [];
  audio: AudioTrack[] = [];
  subs: SubtitleTrack[] = [];
}
export class VideoParams {
  pixelFormat: string = '';
  hwPixelFormat: string = '';
  w: number = 0;
  h: number = 0;
  dw: number = 0;
  dh: number = 0;
  colormatrix: string = '';
  colorLevels: string = '';
  primaries: string = '';
  gamma: string = '';
  light: string = '';
}
export class PlayerState {
  duration: number = 0;
  position: number = 0;
  tracks: Tracks = new Tracks();
  track: Track = new Track();
}
export class PlayerStream {
  duration: StubStream<number> = new StubStream<number>();
  position: StubStream<number> = new StubStream<number>();
  playing: StubStream<boolean> = new StubStream<boolean>();
  eof: StubStream<boolean> = new StubStream<boolean>();
  buffering: StubStream<boolean> = new StubStream<boolean>();
  bufferingPercentage: StubStream<number> = new StubStream<number>();
  buffer: StubStream<number> = new StubStream<number>();
  videoParams: StubStream<VideoParams> = new StubStream<VideoParams>();
  tracks: StubStream<Tracks> = new StubStream<Tracks>();
  track: StubStream<Track> = new StubStream<Track>();
  error: StubStream<string> = new StubStream<string>();
}
export class StubNativePlayer {
  addEventObserver(_observer: EventObserver): void {}
  removeEventObserver(_observer: EventObserver): void {}
  attachSurface(_surfaceId: string): void {}
  detachSurface(): void {}
  setProperty(_name: string, _value: string | number | boolean): void {}
}
export class Player {
  native: StubNativePlayer = new StubNativePlayer();
  state: PlayerState = new PlayerState();
  stream: PlayerStream = new PlayerStream();

  constructor() {
    throw new Error('MPV is intentionally unavailable in the x86_64 simulator validation target.');
  }

  open(_media: Media, _play: boolean = true): void {}
  play(): void {}
  pause(): void {}
  seek(_seconds: number): void {}
  setSpeed(_speed: number): void {}
  setVolume(_volume: number): void {}
  destroy(): void {}
}
