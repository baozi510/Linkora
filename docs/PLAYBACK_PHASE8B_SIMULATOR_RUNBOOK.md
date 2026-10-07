# Phase 8B-SIM — Simulator Functional and Corpus Preflight

> Purpose: stabilize capability-test infrastructure and ordinary application functionality on x86_64 before returning to a batched real-device gate.
>
> Simulator results are not final Mate60 codec capability.

## 1. Build model

Always maintain both:

```text
default   -> ARM64 production build must compile/link/audit
simulator -> x86_64 runtime functional environment
```

Do not postpone ARM64 compile/link failures.

The simulator uses:

- real shared ArkTS/product code;
- real System AVPlayer;
- real WebDAV/HTTP/MediaProxy;
- real x86_64 `linkora_ffmpeg`;
- MPV compile/runtime-unavailable stub at the final native boundary;
- unavailable replacements for native storage transports where configured.

## 2. Fresh gates

Run:

1. one normal `ohpm install`;
2. fresh `./scripts/verify.ps1`;
3. fresh `./scripts/verify-simulator.ps1`;
4. after simulator verification, prove the default dependency graph was restored;
5. run one final default verification or the repository's established post-simulator default dependency/build check required by the latest task.

No simulator-only success may break default ARM64 compilation.

## 3. Corpus preparation

Use `test-lab/media-compatibility/cases.json` and generate all 59 fixtures.

Produce independent ffprobe/hash truth and validate:

- 59 unique case IDs;
- generated/fetched provenance;
- fixture hashes;
- stream/container truth;
- HLS/DASH manifests and referenced files;
- summarizer schema.

Do not commit generated media.

## 4. System simulator matrix

Execute all reachable 59 cases in forced System where the source type is supported by the simulator test environment.

Record one simulator-specific result per case:

- PASS;
- SYSTEM_SIMULATOR_UNSUPPORTED;
- FAIL;
- TIMEOUT;
- NOT_RUN.

This is primarily a functional/orchestration test.

Do not convert `SYSTEM_SIMULATOR_UNSUPPORTED` into a product capability verdict.

For PASS:

- prepare;
- PLAYING;
- first frame for video;
- position progress;
- audio position progress for audio-only;
- bounded leave/release.

## 5. MPV simulator boundary

Do not pretend the stub is real MPV.

Use a representative subset only to verify:

- forced MPV reaches the real PlaybackEngine/AdaptivePlaybackPort and fails at the simulator-native MPV boundary;
- forced MPV does not silently fall back;
- Auto on an MPV-first representative case performs at most the intended one-shot fallback to System;
- candidate errors do not pollute committed session state;
- cleanup/release remains bounded.

Record these as simulator control-flow tests, never MPV codec capability.

Do not create 59 fake MPV UNSUPPORTED rows.

## 6. FFmpeg simulator function

Because `linkora_ffmpeg` has a real x86_64 build, use simulator to exercise representative analyzer/thumbnail function across the shared corpus where test infrastructure already supports it.

This is functional validation, not a reopening of Phase 3/7 policy.

Record simulator/x86 behavior separately from final ARM64 runtime acceptance.

Any x86/ARM divergence discovered at the contract/data level should be fixed before later device validation.

## 7. General functional regression

Prioritize:

- repeated case transitions;
- failure -> next valid case recovery;
- stale-session protection;
- timeout/cancellation;
- WebDAV/MediaProxy open/play/seek where applicable;
- database/settings persistence if capability runner uses them;
- test runner output integrity;
- no crash/ANR/unbounded loading;
- clean resource release.

## 8. Result infrastructure

Validate `scripts/summarize-playback-capability.cjs` against controlled synthetic/real simulator result files.

The final real-device matrix still expects:

```text
59 × System/MPV = 118 official records
```

but this simulator task does not fabricate those 118 records.

## 9. Explicitly deferred to device gate

Do not use simulator to finalize:

- MPV codec/container capability;
- ARM64 FFmpeg runtime;
- Mate60 System codec capability;
- HDR/DV;
- advanced audio;
- hardware decode;
- real native-storage I/O;
- performance/power/thermal.

## 10. UI boundary

Do not stop functional progress for fullscreen/player polish.

Do not implement display-mode UI.

UI follow-up is tracked separately.

## 11. Completion

A successful simulator phase means:

- functionality/test infrastructure is stable enough to continue development without frequent Mate60 round trips;
- ARM64 production builds remain continuously green;
- remaining device-only questions are explicitly catalogued, not guessed.
