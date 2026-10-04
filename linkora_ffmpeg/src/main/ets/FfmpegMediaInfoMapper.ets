import { MediaInfo, VideoTrackInfo, AudioTrackInfo, SubtitleTrackInfo, ChapterInfo,
  HdrType, SubtitleKind, ProbeFieldOrigin } from 'linkora_core';
import { NativeProbeResult, NativeVideoStream } from './NativeModels';

export class FfmpegMappedProbe {
  readonly info: MediaInfo;
  readonly fieldOrigins: ProbeFieldOrigin[];
  constructor(info: MediaInfo, fieldOrigins: ProbeFieldOrigin[]) {
    this.info = info; this.fieldOrigins = fieldOrigins;
  }
}

export class FfmpegMediaInfoMapper {
  static map(result: NativeProbeResult): FfmpegMappedProbe {
    const videos = result.video.slice(0, 64).map((v) => new VideoTrackInfo(`${v.index}:${v.id}`,
      v.codec, v.profile, v.level > 0 ? `${v.level}` : '', v.width, v.height, v.frameRate,
      v.bitrate, v.bitDepth, v.pixelFormat, v.colorPrimaries, v.transfer, v.colorSpace,
      FfmpegMediaInfoMapper.hdr(v),
      v.hasDolbyVisionConfiguration ? `${v.dolbyVisionProfile}` : '',
      v.language.slice(0, 512), v.title.slice(0, 512), v.isDefault));
    const audio = result.audio.slice(0, 64).map((a) => new AudioTrackInfo(`${a.index}:${a.id}`,
      a.codec, a.profile, a.channels, a.channelLayout, a.sampleRate, a.bitrate,
      a.language.slice(0, 512), a.title.slice(0, 512), a.isDefault));
    const subtitles = result.subtitles.slice(0, 64).map((s) => new SubtitleTrackInfo(`${s.index}:${s.id}`,
      s.codec, s.kind === 'text' ? SubtitleKind.TEXT : s.kind === 'bitmap' ? SubtitleKind.BITMAP : SubtitleKind.UNKNOWN,
      s.language.slice(0, 512), s.title.slice(0, 512), s.isForced, s.isDefault));
    const chapters = result.chapters.slice(0, 128).map((c) => new ChapterInfo(c.startMs, c.endMs, c.title.slice(0, 512)));
    const tags: Record<string, string> = {};
    let budget = 16384;
    for (const key of Object.keys(result.tags).slice(0, 64)) {
      // Three UTF-8 bytes per UTF-16 code unit is a conservative bound, including surrogate pairs.
      const boundedKey = key.slice(0, 128);
      const value = result.tags[key].slice(0, Math.max(0, Math.min(512, Math.floor(budget / 3) - boundedKey.length)));
      const used = (boundedKey.length + value.length) * 3;
      if (used > budget || budget === 0) break;
      tags[boundedKey] = value; budget -= used;
    }
    const info = new MediaInfo(result.container, result.durationMs, result.bitrate, result.sizeBytes,
      videos, audio, subtitles, chapters, tags);
    const origins: ProbeFieldOrigin[] = [];
    if (result.container.length > 0) origins.push(new ProbeFieldOrigin('container', 'ffmpeg'));
    if (result.durationMs > 0) origins.push(new ProbeFieldOrigin('durationMs', 'ffmpeg'));
    if (result.bitrate > 0) origins.push(new ProbeFieldOrigin('bitrate', 'ffmpeg'));
    if (result.sizeBytes > 0) origins.push(new ProbeFieldOrigin('sizeBytes', 'ffmpeg'));
    if (videos.length > 0) origins.push(new ProbeFieldOrigin('videoTracks', 'ffmpeg'));
    if (audio.length > 0) origins.push(new ProbeFieldOrigin('audioTracks', 'ffmpeg'));
    if (subtitles.length > 0) origins.push(new ProbeFieldOrigin('subtitleTracks', 'ffmpeg'));
    if (chapters.length > 0) origins.push(new ProbeFieldOrigin('chapters', 'ffmpeg'));
    if (Object.keys(tags).length > 0) origins.push(new ProbeFieldOrigin('tags', 'ffmpeg'));
    return new FfmpegMappedProbe(info, origins);
  }
  private static hdr(video: NativeVideoStream): HdrType {
    if (video.hasDolbyVisionConfiguration) return HdrType.DOLBY_VISION;
    if (video.transfer === 'smpte2084') return HdrType.HDR10;
    if (video.transfer === 'arib-std-b67') return HdrType.HLG;
    return video.transfer.length === 0 || video.transfer === 'unknown' || video.transfer === 'reserved' ? HdrType.UNKNOWN : HdrType.SDR;
  }
}
