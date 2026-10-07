# Playback Phase 8A — Mate60 Runtime Foundation

> Scope: real-arm64 functional acceptance of the existing System / MPV / Auto playback foundation.
>
> This is not the broad codec/container capability matrix and not the playback performance benchmark.

## 1. Goal

Prove on the real Mate60 that the current production playback architecture works end-to-end:

```text
MediaSource
-> NetworkPlaybackSourceResolver
-> RandomAccessSource
-> NetworkFileProxy
-> AdaptivePlaybackPort
   -> SystemPlaybackPort
   -> MpvPlaybackPort
-> XComponent surface
```

Phase 8A validates infrastructure before Phase 8B expands to the shared Media Capability Corpus.

## 2. Controlled sources

Reuse the already-controlled HTTPS WebDAV fixtures:

1. H.264/AAC MP4, 1280x720, ~20 s.
2. HEVC/AAC MKV, 1280x720, ~20 s.
3. corrupt MP4 negative fixture if still present and hash-controlled.

Do not create a new private server merely for this phase if the existing controlled environment remains valid.

Freshly verify hashes before testing.

## 3. Required gates

Release-gated Phase 8A cases:

### P01 — forced System / H.264 MP4

Must demonstrate:

- backend = System;
- prepare succeeds;
- visible first frame;
- duration/resolution plausible and correct;
- play;
- pause/resume;
- seek around 50%;
- seek around 90%;
- playback resumes after seek;
- completion/EOF;
- leave/release cleanly;
- no automatic fallback in forced System mode.

### P02 — forced MPV / H.264 MP4

Same functional expectations as P01, plus:

- MPV surface attach works;
- surface receives real video;
- rendered video uses the actual XComponent surface bounds and is not confined to a density-scaled lower-left rectangle;
- fullscreen surface is constrained to the real viewport and does not crop a 16:9 source by deriving height from full landscape width;
- unified state becomes PLAYING after autoplay command and exposes a pause action;
- EOF remains COMPLETED even if the wrapper subsequently reports playing=false;
- no recoverable MPV log line is promoted to fatal playback failure;
- release destroys the active player cleanly.

### P03 — forced MPV / HEVC MKV

Must demonstrate:

- backend = MPV;
- prepare/first frame/playback;
- seek 50% and 90%;
- completion/EOF;
- release cleanly.

This is the minimum MPV compatibility gate for Phase 8A.

### P04 — Auto / H.264 MP4

Current selector baseline should choose System candidate for MP4.

Require:

- committed backend = System when System succeeds;
- no MPV candidate events leak into the committed session;
- normal playback/seek/release.

### P05 — Auto / HEVC MKV

Current selector baseline should choose MPV candidate for Matroska.

Require:

- committed backend = MPV when MPV succeeds;
- no System candidate events leak;
- normal playback/seek/release.

## 4. Capability observation, not release gate

### O01 — forced System / HEVC MKV

Run once if safely reachable.

Record one of:

- PASS;
- UNSUPPORTED;
- FAIL with stable platform error.

Do not fail Phase 8A merely because System cannot play HEVC/MKV, provided:

- no crash/ANR;
- no infinite prepare;
- no fallback occurs in forced System mode;
- resources release cleanly.

This result feeds the future capability matrix.

## 5. Negative-path gate

Use the controlled corrupt fixture if available.

At minimum test MPV forced mode.

Require:

- bounded prepare/open failure;
- no infinite loading;
- no crash/ANR;
- no repeated fallback loop;
- diagnostic does not contain credentials/private upstream URL/token;
- player can leave and open a valid file afterward.

If the fixture is no longer available, record NOT RUN with hash/preflight reason; do not synthesize a new corrupt fixture during the validation task.

## 6. Lifecycle

Run 20 open/play/leave cycles with MPV on a known-good controlled source.

Each cycle must show:

- new session opens;
- visible first frame;
- short playback;
- leave/release;
- same app process may continue;
- no stale old-session state;
- no residual audio;
- no accumulating black surface;
- no crash/ANR.

Also exercise one background/foreground cycle and one fullscreen/orientation round trip if safe.

## 7. Remote transport behavior

Playback of REMOTE_FILE must go through:

```text
NetworkDirectoryService.openSource
-> RandomAccessSource
-> NetworkFileProxy
-> localhost token URL
-> selected backend
```

Confirm by source/runtime evidence:

- localhost-only proxy URL;
- upstream credentials/path not embedded in proxy URL;
- remote seek produces non-sequential/high-offset range behavior rather than downloading from byte zero to the target;
- release removes the active playback lease behaviorally.

Production shared-proxy direct counters are not mandatory because no external production diagnostics endpoint exists. Do not add instrumentation solely for this validation.

## 8. What Phase 8A does not decide

Do not conclude:

- final Auto backend policy;
- System-vs-MPV performance ranking;
- HDR/Dolby Vision support;
- DTS-HD/TrueHD/Atmos passthrough;
- broad codec/container compatibility;
- Direct I/O necessity.

Those belong to later phases.

## 9. Phase 8B after acceptance

Once Phase 8A foundation is accepted, upgrade `test-lab/media-compatibility` into the shared real-arm64 Media Capability Matrix.

The same fixture set will record independent outcomes for:

- System metadata;
- FFmpeg metadata;
- System thumbnail;
- FFmpeg thumbnail;
- System playback;
- MPV playback;
- advanced AV behavior.

Use Tier A/B/C gating from `docs/MASTER_IMPLEMENTATION_PLAN.md`.

Legacy/rare Tier C formats are testable but are not required to PASS; crashes, hangs, leaks and unsafe behavior are always failures.
