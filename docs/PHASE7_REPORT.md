# Phase 7 Report — Playback Contract Enrichment

## Scope

Phase 7 enriches the common playback contract after the initial MPV/System dual-backend foundation.

## Implemented

- Surface-size forwarding from PlaybackEngine to backend.
- SEEKING state and seek-complete event.
- Cached-duration buffering metric.
- Backend identity in PlaybackSnapshot.
- Track list propagation.
- Video color/HDR metadata propagation.
- MPV surface-size property forwarding.
- MPV track mapping.
- MPV seek completion using playback-restart.
- System AVPlayer seekDone forwarding.
- Adaptive backend candidate event buffering before commit.

## Important behavior

Candidate backend events are gated until a backend successfully prepares. This prevents a failed System or MPV candidate from leaking duration/tracks/video metadata into the active PlaybackEngine snapshot before fallback completes.

## Current limitations

- Track selection commands are not yet exposed through the common PlaybackPort.
- External subtitle selection is not yet exposed through the common PlaybackPort.
- System AVPlayer track/HDR metadata is currently much less complete than MPV.
- MPV error stream severity still requires real-media validation.
- Native Dolby Vision output and audio passthrough remain unverified.
- No playback benchmark policy tuning has been performed.

## Validation

Source/diff review completed.

Build status: NOT BUILD VERIFIED in this environment.

Device status: NOT DEVICE TESTED.
