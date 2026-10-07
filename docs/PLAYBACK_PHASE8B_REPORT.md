# Playback Phase 8B Capability Report

> Status: STRATEGY UPDATED — simulator functional/corpus preflight first; real-arm64 System/MPV capability matrix deferred to a later batched device gate.
> Branch: `feat/playback-capability-phase8`
> Date: 2026-10-07

## Accepted prerequisite

Phase 8A playback functional foundation is accepted from Mate60 evidence:

`e894775c0bc81b39a6217a0a0516cec46158b82b`

Fullscreen/player-layout refinement is non-blocking UI work and is not part of this phase.

## Phase 8B purpose

Execute the 59-case permanent compatibility corpus against forced System and forced MPV and produce a structured 118-record capability matrix.

This phase measures compatibility/function only.

No performance, Auto policy, UI scaling-mode or advanced-AV conclusion is authorized.


## Execution strategy update — 2026-10-07

The previously dispatched immediate Mate60 118-record matrix is superseded before execution.

New order:

1. simulator functional/corpus preflight;
2. continue mainline functional work using simulator-first validation;
3. keep default ARM64 build/link/artifact gates green continuously;
4. batch real MPV, ARM64 FFmpeg runtime, device-specific System codec and advanced native/hardware capability into later real-device acceptance gates.

Simulator results are platform observations, not final product codec capability.

Real MPV remains unavailable in simulator because the simulator target intentionally uses the MPV package stub. The stub is useful for candidate/fallback/error-boundary behavior only.

The x86_64 `linkora_ffmpeg` module is real native FFmpeg and can be functionally exercised in simulator; ARM64 runtime correctness remains a later device gate.
