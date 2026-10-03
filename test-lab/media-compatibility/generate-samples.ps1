param(
  [string]$OutputDirectory = (Join-Path $PSScriptRoot 'samples')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  throw 'ffmpeg is required to generate the compatibility samples.'
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$videoInput = @(
  '-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=24:duration=3',
  '-f', 'lavfi', '-i', 'sine=frequency=1000:sample_rate=48000:duration=3',
  '-shortest'
)
$smallVideoInput = @(
  '-f', 'lavfi', '-i', 'testsrc2=size=176x144:rate=15:duration=3',
  '-f', 'lavfi', '-i', 'sine=frequency=1000:sample_rate=8000:duration=3',
  '-shortest'
)
$audioInput = @('-f', 'lavfi', '-i', 'sine=frequency=1000:sample_rate=48000:duration=3')
$fullHdVideoInput = @(
  '-f', 'lavfi', '-i', 'testsrc2=size=1920x1080:rate=24:duration=2',
  '-f', 'lavfi', '-i', 'sine=frequency=1000:sample_rate=48000:duration=2',
  '-shortest'
)
$ultraHdVideoInput = @(
  '-f', 'lavfi', '-i', 'testsrc2=size=3840x2160:rate=24:duration=2',
  '-f', 'lavfi', '-i', 'sine=frequency=1000:sample_rate=48000:duration=2',
  '-shortest'
)

function Invoke-Sample {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  Write-Output "Generating $Name"
  & ffmpeg -hide_banner -loglevel error -y @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "ffmpeg failed while generating $Name"
  }
}

function Sample-Path([string]$Name) {
  return Join-Path $OutputDirectory $Name
}

$h264 = @('-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', '-g', '24')
$hevc = @('-c:v', 'libx265', '-preset', 'ultrafast', '-x265-params', 'log-level=error', '-pix_fmt', 'yuv420p', '-g', '24')
$aac = @('-c:a', 'aac', '-b:a', '96k')

Invoke-Sample 'mp4_h264_aac.mp4' ($videoInput + $h264 + $aac + @('-movflags', '+faststart', (Sample-Path 'mp4_h264_aac.mp4')))
Invoke-Sample 'mp4_hevc_aac.mp4' ($videoInput + $hevc + $aac + @('-tag:v', 'hvc1', '-movflags', '+faststart', (Sample-Path 'mp4_hevc_aac.mp4')))
Invoke-Sample 'mp4_av1_aac.mp4' ($videoInput + @('-c:v', 'libaom-av1', '-cpu-used', '8', '-crf', '40', '-b:v', '0', '-row-mt', '1') + $aac + @((Sample-Path 'mp4_av1_aac.mp4')))
Invoke-Sample 'mp4_mpeg4_aac.mp4' ($videoInput + @('-c:v', 'mpeg4', '-q:v', '5') + $aac + @((Sample-Path 'mp4_mpeg4_aac.mp4')))
Invoke-Sample 'm4v_h264_aac.m4v' ($videoInput + $h264 + $aac + @('-f', 'mp4', (Sample-Path 'm4v_h264_aac.m4v')))
Invoke-Sample 'mov_h264_aac.mov' ($videoInput + $h264 + $aac + @((Sample-Path 'mov_h264_aac.mov')))
Invoke-Sample 'mp4_h264_high_1080p.mp4' ($fullHdVideoInput + @('-c:v', 'libx264', '-preset', 'veryfast', '-profile:v', 'high', '-level:v', '4.1', '-pix_fmt', 'yuv420p') + $aac + @('-movflags', '+faststart', (Sample-Path 'mp4_h264_high_1080p.mp4')))
Invoke-Sample 'mp4_h264_high_4k.mp4' ($ultraHdVideoInput + @('-c:v', 'libx264', '-preset', 'veryfast', '-profile:v', 'high', '-level:v', '5.1', '-pix_fmt', 'yuv420p') + $aac + @('-movflags', '+faststart', (Sample-Path 'mp4_h264_high_4k.mp4')))
Invoke-Sample 'mp4_h264_10bit_aac.mp4' ($videoInput + @('-c:v', 'libx264', '-preset', 'ultrafast', '-profile:v', 'high10', '-pix_fmt', 'yuv420p10le') + $aac + @((Sample-Path 'mp4_h264_10bit_aac.mp4')))
Invoke-Sample 'mp4_vp9_aac.mp4' ($videoInput + @('-c:v', 'libvpx-vp9', '-deadline', 'realtime', '-cpu-used', '8', '-b:v', '400k') + $aac + @((Sample-Path 'mp4_vp9_aac.mp4')))

Invoke-Sample 'mkv_h264_aac.mkv' ($videoInput + $h264 + $aac + @((Sample-Path 'mkv_h264_aac.mkv')))
Invoke-Sample 'mkv_hevc_aac.mkv' ($videoInput + $hevc + $aac + @((Sample-Path 'mkv_hevc_aac.mkv')))
Invoke-Sample 'mkv_vp9_opus.mkv' ($videoInput + @('-c:v', 'libvpx-vp9', '-deadline', 'realtime', '-cpu-used', '8', '-b:v', '400k', '-c:a', 'libopus', '-b:a', '96k', (Sample-Path 'mkv_vp9_opus.mkv')))
Invoke-Sample 'mkv_h264_ac3.mkv' ($videoInput + $h264 + @('-c:a', 'ac3', '-b:a', '192k', (Sample-Path 'mkv_h264_ac3.mkv')))
Invoke-Sample 'mkv_h264_eac3.mkv' ($videoInput + $h264 + @('-c:a', 'eac3', '-b:a', '192k', (Sample-Path 'mkv_h264_eac3.mkv')))
Invoke-Sample 'mkv_h264_dts.mkv' ($videoInput + $h264 + @('-strict', '-2', '-c:a', 'dca', '-b:a', '768k', (Sample-Path 'mkv_h264_dts.mkv')))
Invoke-Sample 'mkv_h264_flac.mkv' ($videoInput + $h264 + @('-c:a', 'flac', (Sample-Path 'mkv_h264_flac.mkv')))
Invoke-Sample 'mkv_h264_opus.mkv' ($videoInput + $h264 + @('-c:a', 'libopus', '-b:a', '96k', (Sample-Path 'mkv_h264_opus.mkv')))
Invoke-Sample 'mkv_h264_aac_srt.mkv' ($videoInput[0..7] + @('-i', (Join-Path $PSScriptRoot 'subtitle.srt'), '-shortest') + $h264 + $aac + @('-c:s', 'srt', (Sample-Path 'mkv_h264_aac_srt.mkv')))

Invoke-Sample 'webm_vp8_vorbis.webm' ($videoInput + @('-c:v', 'libvpx', '-deadline', 'realtime', '-cpu-used', '8', '-b:v', '400k', '-c:a', 'libvorbis', '-q:a', '4', (Sample-Path 'webm_vp8_vorbis.webm')))
Invoke-Sample 'webm_vp9_opus.webm' ($videoInput + @('-c:v', 'libvpx-vp9', '-deadline', 'realtime', '-cpu-used', '8', '-b:v', '400k', '-c:a', 'libopus', '-b:a', '96k', (Sample-Path 'webm_vp9_opus.webm')))
Invoke-Sample 'ts_h264_aac.ts' ($videoInput + $h264 + $aac + @('-f', 'mpegts', (Sample-Path 'ts_h264_aac.ts')))
Invoke-Sample 'ts_hevc_aac.ts' ($videoInput + $hevc + $aac + @('-f', 'mpegts', (Sample-Path 'ts_hevc_aac.ts')))
Invoke-Sample 'm2ts_h264_aac.m2ts' ($videoInput + $h264 + $aac + @('-mpegts_m2ts_mode', '1', '-f', 'mpegts', (Sample-Path 'm2ts_h264_aac.m2ts')))

Invoke-Sample 'avi_mpeg4_mp3.avi' ($videoInput + @('-c:v', 'mpeg4', '-q:v', '5', '-c:a', 'libmp3lame', '-b:a', '128k', (Sample-Path 'avi_mpeg4_mp3.avi')))
Invoke-Sample 'avi_mjpeg_pcm.avi' ($videoInput + @('-c:v', 'mjpeg', '-q:v', '5', '-c:a', 'pcm_s16le', (Sample-Path 'avi_mjpeg_pcm.avi')))
Invoke-Sample 'flv_h264_aac.flv' ($videoInput + $h264 + $aac + @('-f', 'flv', (Sample-Path 'flv_h264_aac.flv')))
Invoke-Sample 'mpeg_mpeg2_mp2.mpg' ($videoInput + @('-c:v', 'mpeg2video', '-q:v', '5', '-c:a', 'mp2', '-b:a', '192k', (Sample-Path 'mpeg_mpeg2_mp2.mpg')))
Invoke-Sample 'wmv_wmv2_wma.wmv' ($videoInput + @('-c:v', 'wmv2', '-b:v', '500k', '-c:a', 'wmav2', '-b:a', '128k', (Sample-Path 'wmv_wmv2_wma.wmv')))
Invoke-Sample '3gp_h263_aac.3gp' ($smallVideoInput + @('-c:v', 'h263', '-b:v', '256k', '-c:a', 'aac', '-b:a', '48k', '-ar', '8000', (Sample-Path '3gp_h263_aac.3gp')))
Invoke-Sample 'ogv_theora_vorbis.ogv' ($videoInput + @('-c:v', 'libtheora', '-q:v', '5', '-c:a', 'libvorbis', '-q:a', '4', (Sample-Path 'ogv_theora_vorbis.ogv')))
Invoke-Sample 'mov_prores_pcm.mov' ($videoInput + @('-c:v', 'prores_ks', '-profile:v', '0', '-pix_fmt', 'yuv422p10le', '-c:a', 'pcm_s16le', (Sample-Path 'mov_prores_pcm.mov')))
Invoke-Sample 'vob_mpeg2_ac3.vob' ($videoInput + @('-c:v', 'mpeg2video', '-q:v', '5', '-c:a', 'ac3', '-b:a', '192k', '-f', 'vob', (Sample-Path 'vob_mpeg2_ac3.vob')))
Invoke-Sample 'rm_rv20.rm' (@('-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=24:duration=3', '-an', '-c:v', 'rv20', '-b:v', '400k', '-f', 'rm', (Sample-Path 'rm_rv20.rm')))
Invoke-Sample 'mkv_ffv1_flac.mkv' ($videoInput + @('-c:v', 'ffv1', '-level', '3', '-c:a', 'flac', (Sample-Path 'mkv_ffv1_flac.mkv')))

Invoke-Sample 'audio_mp3.mp3' ($audioInput + @('-c:a', 'libmp3lame', '-b:a', '128k', (Sample-Path 'audio_mp3.mp3')))
Invoke-Sample 'audio_aac.aac' ($audioInput + @('-c:a', 'aac', '-b:a', '96k', '-f', 'adts', (Sample-Path 'audio_aac.aac')))
Invoke-Sample 'audio_m4a_aac.m4a' ($audioInput + @('-c:a', 'aac', '-b:a', '96k', (Sample-Path 'audio_m4a_aac.m4a')))
Invoke-Sample 'audio_m4a_alac.m4a' ($audioInput + @('-c:a', 'alac', (Sample-Path 'audio_m4a_alac.m4a')))
Invoke-Sample 'audio_flac.flac' ($audioInput + @('-c:a', 'flac', (Sample-Path 'audio_flac.flac')))
Invoke-Sample 'audio_ogg_vorbis.ogg' ($audioInput + @('-c:a', 'libvorbis', '-q:a', '4', (Sample-Path 'audio_ogg_vorbis.ogg')))
Invoke-Sample 'audio_opus.opus' ($audioInput + @('-c:a', 'libopus', '-b:a', '96k', (Sample-Path 'audio_opus.opus')))
Invoke-Sample 'audio_wav_pcm.wav' ($audioInput + @('-c:a', 'pcm_s16le', (Sample-Path 'audio_wav_pcm.wav')))
Invoke-Sample 'audio_amr_nb.amr' (@('-f', 'lavfi', '-i', 'sine=frequency=1000:sample_rate=8000:duration=3', '-c:a', 'libopencore_amrnb', '-b:a', '12.2k', (Sample-Path 'audio_amr_nb.amr')))
Invoke-Sample 'audio_amr_wb.amr' (@('-f', 'lavfi', '-i', 'sine=frequency=1000:sample_rate=16000:duration=3', '-c:a', 'libvo_amrwbenc', '-b:a', '23.85k', (Sample-Path 'audio_amr_wb.amr')))
Invoke-Sample 'audio_ac3.ac3' ($audioInput + @('-c:a', 'ac3', '-b:a', '192k', (Sample-Path 'audio_ac3.ac3')))
Invoke-Sample 'audio_eac3.eac3' ($audioInput + @('-c:a', 'eac3', '-b:a', '192k', (Sample-Path 'audio_eac3.eac3')))
Invoke-Sample 'audio_dts.dts' ($audioInput + @('-strict', '-2', '-c:a', 'dca', '-b:a', '768k', (Sample-Path 'audio_dts.dts')))
Invoke-Sample 'audio_wma.wma' ($audioInput + @('-c:a', 'wmav2', '-b:a', '128k', (Sample-Path 'audio_wma.wma')))
Invoke-Sample 'audio_wavpack.wv' ($audioInput + @('-c:a', 'wavpack', (Sample-Path 'audio_wavpack.wv')))
Invoke-Sample 'audio_tta.tta' ($audioInput + @('-c:a', 'tta', (Sample-Path 'audio_tta.tta')))
Invoke-Sample 'audio_truehd.thd' ($audioInput + @('-strict', '-2', '-c:a', 'truehd', '-f', 'truehd', (Sample-Path 'audio_truehd.thd')))
Invoke-Sample 'audio_mlp.mlp' ($audioInput + @('-strict', '-2', '-c:a', 'mlp', '-f', 'mlp', (Sample-Path 'audio_mlp.mlp')))
Invoke-Sample 'audio_aiff_pcm.aiff' ($audioInput + @('-c:a', 'pcm_s16be', (Sample-Path 'audio_aiff_pcm.aiff')))
Invoke-Sample 'audio_caf_alac.caf' ($audioInput + @('-c:a', 'alac', '-f', 'caf', (Sample-Path 'audio_caf_alac.caf')))

$hlsH264 = Join-Path $OutputDirectory 'hls_h264'
$hlsHevc = Join-Path $OutputDirectory 'hls_hevc'
$dashH264 = Join-Path $OutputDirectory 'dash_h264'
New-Item -ItemType Directory -Force -Path $hlsH264, $hlsHevc, $dashH264 | Out-Null

Invoke-Sample 'hls_h264/index.m3u8' ($videoInput + $h264 + $aac + @('-f', 'hls', '-hls_time', '1', '-hls_list_size', '0', '-hls_segment_filename', (Join-Path $hlsH264 'segment_%03d.ts'), (Join-Path $hlsH264 'index.m3u8')))
Invoke-Sample 'hls_hevc/index.m3u8' ($videoInput + $hevc + $aac + @('-f', 'hls', '-hls_time', '1', '-hls_list_size', '0', '-hls_segment_filename', (Join-Path $hlsHevc 'segment_%03d.ts'), (Join-Path $hlsHevc 'index.m3u8')))
Push-Location $dashH264
try {
  Invoke-Sample 'dash_h264/index.mpd' ($videoInput + $h264 + $aac + @('-f', 'dash', '-seg_duration', '1', '-use_template', '1', '-use_timeline', '1', 'index.mpd'))
} finally {
  Pop-Location
}

Write-Output "Generated compatibility samples in $OutputDirectory"
