# Playback Phase 8 Report

> Status: PHASE 8A READY — Mate60 playback foundation validation pending.
> Branch: `feat/playback-capability-phase8`
> Date: 2026-10-06

## Baseline

Inherited accepted architecture includes:

- SystemPlaybackPort;
- MpvPlaybackPort using `@mpv-ohos/mpv-arkts@1.0.0`;
- AdaptivePlaybackPort;
- Auto/System/MPV preference;
- candidate-event isolation and one-shot Auto fallback;
- NetworkPlaybackSourceResolver;
- REMOTE_FILE -> RandomAccessSource -> shared MediaProxy -> backend;
- surface size / seek complete / buffering / tracks / video-info contracts.

Build/static coverage exists, but current architecture lacks accepted real-Mate60 MPV playback runtime evidence.

## Phase 8A scope

Use the controlled WebDAV H.264/AAC MP4 and HEVC/AAC MKV fixtures to validate:

- forced System baseline;
- forced MPV baseline;
- Auto baseline;
- seek/EOF/release;
- MPV surface lifecycle;
- remote MediaProxy playback;
- bounded negative behavior;
- 20-cycle MPV lifecycle.

No broad codec/container claim and no performance policy is authorized by this stage.

## Phase 8B direction

After Phase 8A acceptance, reuse `test-lab/media-compatibility` as the shared Tier A/B/C capability corpus rather than creating a separate playback-only corpus.
