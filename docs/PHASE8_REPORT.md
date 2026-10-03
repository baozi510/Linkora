# Phase 8 Report — Validation and Benchmark Baseline

## Scope

Phase 8 adds engineering validation infrastructure. It intentionally does not add new playback behavior.

## Added

- docs/PHASE7_REPORT.md
- docs/IMPLEMENTATION_STATUS.md
- docs/THIRD_PARTY.md
- docs/TEST_MANUAL.md
- test-lab/benchmark/README.md
- test-lab/benchmark/cases.json
- scripts/check-architecture-boundaries.cjs
- scripts/summarize-benchmark.cjs

Updated:

- scripts/verify.ps1

## Architecture guard

The verification pipeline now checks:

- linkora_core stays platform free
- playback does not import protocol implementations
- media probe does not own storage/cache/WebP
- UI does not directly import concrete player backends
- NetworkDirectoryService remains provider based

This is intended to prevent future Codex/refactor work from silently undoing the modular boundaries.

## Benchmark baseline

A stable NDJSON record format and report generator now exist for:

- analysis metadata
- analysis thumbnail
- playback first frame
- playback seek
- playback long run

The report generator groups by operation / engine / source and calculates:

- success rate
- P50 latency
- P95 latency
- average bytes read
- average Range requests

## Full test manual

TEST_MANUAL.md covers:

- build verification
- unit tests
- protocol lab
- MediaProxy
- metadata
- WebP thumbnail
- MPV
- System AVPlayer
- Auto fallback
- seek
- tracks/subtitles
- HDR/Dolby Vision
- audio
- benchmark
- long-run
- fault injection
- security
- FFmpeg analyzer acceptance
- release gates

## Hard blockers after this phase

### 1. HarmonyOS build/device validation

This environment cannot run the repository's DevEco/Hvigor build or target-device tests.

Required next action on a development machine:

- ohpm install
- scripts/verify.ps1
- arm64 Debug HAP
- arm64 Release HAP
- target-device test manual

### 2. FFmpeg media analyzer

Still blocked because no reproducible Linkora-owned HarmonyOS FFmpeg/libav artifacts exist.

Do not create a fake CMake target against undeclared local headers.

### 3. Advanced playback capability claims

HDR/DV/passthrough/Atmos/DTS:X behavior requires target hardware.

Do not mark these capabilities supported from code inspection alone.

### 4. Common track-selection commands

MPV exposes track state and command capabilities, but a safe common System/MPV selection API was not added in this environment because current System AVPlayer selection semantics were not sufficiently verified against the target SDK.

## Conclusion

The architecture migration has reached the point where further production implementation should be driven by actual build/device evidence rather than additional speculative code.
