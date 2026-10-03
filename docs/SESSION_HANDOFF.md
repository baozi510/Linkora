# Linkora Session Handoff

## Purpose

This file is the durable context handoff for a new ChatGPT/Codex session.

If a new session has no prior conversation context, read this file first and then follow the repository documents referenced below.

## Repository

Repository:

`baozi510/Linkora`

Current architecture baseline branch:

`feat/player-architecture-phase8`

Validation branch:

`test/player-architecture-validation`

Do not start new work from `main` until the stacked architecture work is reviewed and merged.

## Current stacked branch/PR chain

```text
main
 ↓
Phase 0  chore/player-architecture-phase0
 ↓
Phase 1  feat/player-architecture-phase1
 ↓
Phase 2  feat/player-architecture-phase2
 ↓
Phase 3  feat/player-architecture-phase3
 ↓
Phase 4  feat/player-architecture-phase4
 ↓
Phase 5  feat/player-architecture-phase5
 ↓
Phase 6  feat/player-architecture-phase6
 ↓
Phase 7  feat/player-architecture-phase7
 ↓
Phase 8  feat/player-architecture-phase8
```

Pull requests:

- PR #1 — Phase 0
- PR #2 — Phase 1
- PR #3 — Phase 2
- PR #4 — Phase 3
- PR #5 — Phase 4
- PR #6 — Phase 5
- PR #7 — Phase 6
- PR #8 — Phase 7
- PR #9 — Phase 8

## Product direction

Linkora is a modular HarmonyOS NEXT network media player.

Primary sources:

- local files;
- WebDAV;
- SMB;
- SFTP;
- FTP;
- NFS;
- future Jellyfin / Emby / Plex integrations.

Playback architecture:

```text
StorageProvider
    ↓
RandomAccessSource
    ↓
MediaSource / MediaProxy
    ↓
AdaptivePlaybackPort
   /                  \
System AVPlayer      MPV
```

Media analysis architecture:

```text
MediaSource
   ↓
MediaProbeService (target)
   ├─ SystemMediaProbe
   └─ FFmpegMediaProbe (blocked)
```

Thumbnail architecture:

```text
metadata
  ↓
ThumbnailTimePolicy
  ↓
thumbnail extractor
  ↓
PixelMap/raw frame
  ↓
WebP encoder
  ↓
thumbnail cache
```

## Non-negotiable architecture rules

1. Protocol/storage code must not know player implementation.
2. Player implementation must not know WebDAV/SMB/SFTP/FTP/NFS implementations.
3. MediaProbe must not know UI.
4. UI must not know FFmpeg internals or concrete player backend internals.
5. Thumbnail extraction, image processing/encoding and cache persistence are separate responsibilities.
6. New remote playback should use RandomAccessSource -> shared MediaProxy -> backend.
7. Do not force all media bytes through ArkTS if a lower-level fast path is later justified, but do not implement direct I/O before benchmark evidence.
8. Auto backend selection must eventually be data driven.
9. Failed backend candidates must not leak events into the committed playback session.
10. Credentials must be referenced through configuration/session identity and never logged in URLs.
11. Newly generated video thumbnails are WebP, not JPEG.
12. Architecture/specification from the latest phase wins when old code conflicts.

## Current thumbnail standard

- short video (<30s): approximately 20%;
- normal video: min(duration * 10%, 60 seconds);
- bounding box 480x270;
- preserve aspect ratio;
- WebP;
- quality 80;
- algorithmVersion participates in cache identity;
- legacy JPEG may be read but new JPEG should not be generated.

## Current network/data rules

Random-access semantics are central.

Important edge cases:

- Range / 206;
- 416;
- unknown length;
- auth expiry;
- ETag / Last-Modified/fingerprint;
- seek cancellation;
- reconnect;
- bounded prefetch;
- no full-file read for a remote seek.

MediaProxy is shared infrastructure and should remain localhost-only with random token URLs.

## Current playback rules

Three user modes:

- Auto;
- System;
- MPV.

Current Auto policy is only a temporary baseline.

Do not treat it as a final ranking.

System is preferred for ordinary native/direct-play cases when it actually works.

MPV is the compatibility path for complex media.

Fallback in Auto is one-shot and occurs around prepare/open, not arbitrary mid-session switching.

Unified state includes:

- IDLE;
- PREPARING;
- READY;
- PLAYING;
- PAUSED;
- SEEKING;
- BUFFERING;
- COMPLETED;
- ERROR;
- RELEASED.

## MPV integration

Current dependency target:

`@mpv-ohos/mpv-arkts@1.0.0`

Current public upstream package is arm64-v8a oriented and declares HarmonyOS compatible SDK 20+.

Linkora currently adapts:

- surface attach/detach;
- surface size;
- open/prepare;
- play/pause;
- seek;
- position/duration;
- buffering;
- EOF;
- tracks;
- video params/color information.

All of this still requires real DevEco/arm64 target validation.

## FFmpeg analyzer status

BLOCKED.

Do not implement against private libmpv-linked FFmpeg symbols.

Required first:

- pinned FFmpeg version/revision;
- reproducible HarmonyOS arm64 build;
- headers;
- libavformat;
- libavcodec;
- libavutil;
- libswscale;
- build manifest/checksums;
- clean CMake link;
- smoke tests.

Read:

`docs/FFMPEG_INTEGRATION_BLOCKER.md`

## Claims that require device evidence

Do not claim these are proven merely from code:

- native HDR output;
- native Dolby Vision output;
- Dolby Vision mode signaling;
- DTS-HD MA passthrough;
- TrueHD passthrough;
- Atmos passthrough/object rendering;
- DTS:X passthrough/object rendering;
- Audio Vivid behavior;
- power efficiency;
- real hardware decode coverage.

## What to read for current status

Read in this order:

1. `docs/IMPLEMENTATION_STATUS.md`
2. `docs/TEST_MANUAL.md`
3. `docs/CODEX_TEST_RUNBOOK.md`
4. `docs/FFMPEG_INTEGRATION_BLOCKER.md`
5. `docs/ARCHITECTURE_TARGET.md`
6. `docs/ARCHITECTURE_MIGRATION.md`
7. latest phase reports

## Current next action

Do not continue feature development first.

Run validation on:

`test/player-architecture-validation`

Follow:

`docs/CODEX_TEST_RUNBOOK.md`

Expected first commands:

```powershell
git fetch --all
git checkout test/player-architecture-validation
git status
ohpm install
./scripts/verify.ps1
```

Then perform target-device smoke tests and write:

`docs/VALIDATION_REPORT.md`

## When to return to architecture/design work

Return with evidence after one of these milestones:

- verify.ps1 fully passes;
- arm64 Debug and Release HAP both build;
- System + MPV + Auto target-device smoke test results exist;
- benchmark data exists;
- an adapter/API mismatch requires redesign;
- FFmpeg dependency artifacts are ready.

The next architecture session should read VALIDATION_REPORT.md first.

## Preferred engineering style

- modular and pluggable;
- small reviewable commits;
- reuse existing protocol/native implementations;
- confirmed facts separated from inference;
- no fake support claims;
- no speculative large refactors when measurement can answer the question;
- errors and logs must not expose credentials;
- preserve rollback paths during migration.

## New-session prompt

A user can start a new assistant session with:

```text
Open GitHub repository baozi510/Linkora.
Read docs/SESSION_HANDOFF.md first, then docs/IMPLEMENTATION_STATUS.md,
docs/VALIDATION_REPORT.md if it exists, docs/TEST_MANUAL.md, and
docs/FFMPEG_INTEGRATION_BLOCKER.md.

Use the latest repository documents as the source of truth.
Continue from the documented current branch/status.
Do not redesign or merge branches until you have reviewed the validation evidence.
```


## Post-validation review update

Architecture review after the first validation pass is complete.

Before any further runtime testing or feature work, read:

`docs/CODEX_POST_VALIDATION_ACTIONS.md`

Current next action is:

1. keep the accepted validation fixes;
2. correct MPV error-log handling;
3. wire surface size from PlayerPage -> PlayerFeatureController -> PlaybackEngine;
4. correct HDR labeling so BT.2020 alone is not treated as HDR;
5. tighten the architecture-boundary scanner;
6. rerun the full verify.ps1;
7. attempt the current HAP on the available x86_64 emulator without production ABI hacks;
8. update VALIDATION_REPORT.md and stop for architecture review.

Do not start FFmpeg or Auto-policy tuning before this review loop is complete.
