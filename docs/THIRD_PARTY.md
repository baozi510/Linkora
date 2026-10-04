# Third-party / Native Dependency Manifest

This document records dependencies relevant to the player architecture.

## @mpv-ohos/mpv-arkts

- Package: @mpv-ohos/mpv-arkts
- Version requested by Linkora: 1.0.0
- Upstream repository: mpv-ohos/mpv-arkts
- Compatible SDK declared upstream: HarmonyOS API 20+
- Current architecture use: MPV playback backend
- Current Linkora ABI target after integration: arm64-v8a
- Verification required: ohpm install + arm64 build + target-device playback

The package internally uses libmpv. Linkora must not treat private libmpv-linked FFmpeg symbols as a public libav API for MediaProbe.

## libsmb2

- Location: entry/src/main/cpp/third_party/libsmb2
- Linkora output: liblinkora_smb.so
- Build mode: static third-party library linked into Linkora NAPI shared object
- Purpose: SMB2/3 browsing and positioned file reads

Pin/version should remain tied to the repository submodule/vendor state.

## libnfs

- Location: entry/src/main/cpp/third_party/libnfs
- Linkora output: liblinkora_nfs.so
- Purpose: NFS directory and positioned file access
- Build: static libnfs linked into Linkora NAPI object

## libssh2 + mbedTLS

- Locations:
  - entry/src/main/cpp/third_party/libssh2
  - entry/src/main/cpp/third_party/mbedtls
- Linkora output: liblinkora_sftp.so
- Purpose: SFTP
- Crypto backend: mbedTLS

## FTP native adapter

- Source: entry/src/main/cpp/ftp_init.cpp
- Linkora output: liblinkora_ftp.so
- Purpose: FTP directory/file operations

## FFmpeg / libav

Status: DEPENDENCY BOOTSTRAP IN PROGRESS.

Pinned source:

- FFmpeg 8.1.3
- tag: n8.1.3
- commit: 1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7
- manifest: third_party/ffmpeg/manifest.json

Planned ABIs:

- arm64-v8a
- x86_64

Planned analyzer libraries:

- libavformat
- libavcodec
- libavutil
- libswscale

Initial profile is static, LGPL-oriented, with programs/encoders/muxers/hwaccels disabled.

Do not add ffmpeg or ffprobe CLI binaries to the app.
Do not use private libmpv-linked FFmpeg symbols.

See:

- docs/FFMPEG_BOOTSTRAP.md
- docs/FFMPEG_INTEGRATION_BLOCKER.md
