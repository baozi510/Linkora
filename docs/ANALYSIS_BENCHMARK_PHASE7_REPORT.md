# Analysis Benchmark + Policy Phase 7 Report

> Status: GPT-REVIEWED BUILD FAILURE CORRECTED — fresh Phase 7A rerun required; real-arm64 benchmark still NOT RUN.
> Branch: `feat/analysis-benchmark-policy-phase7`
> Date: 2026-10-06

## GPT review of first Phase 7A failure — 2026-10-06

Reviewed remote evidence:

`36593af5263684cd1c687bcda4621c0f21a8197e`

Classification:

**VALID BUILD/TEST-INFRASTRUCTURE COMPATIBILITY DEFECT IN PHASE 7A SOURCE.**

The failure is accurately reported:

```text
Unexpected dependency: @kit.BasicServicesKit
-> FfmpegMediaProbeAdapter
-> scripts/check-ffmpeg-phase1.cjs --phase2
```

The adapter/policy desktop harness deliberately loads the analysis adapters without platform Kit modules. Phase 7A introduced `systemDateTime` directly into both metadata adapters, violating that existing pure-load boundary.

### Correction

The fix does **not** add a fake `@kit.BasicServicesKit` shim to the desktop harness.

Instead:

- `FfmpegMediaProbeAdapter` receives an injectable clock function;
- `SystemMediaProbeAdapter` receives the same style of injectable clock;
- their platform-free default remains suitable for direct/pure construction;
- target-specific default/simulator `AnalysisComposition` supplies HarmonyOS monotonic `systemDateTime.getUptime(STARTUP)`;
- a pure regression test verifies prepare/probe/total timing with a deterministic injected clock.

This preserves:

- real Mate60 monotonic benchmark timing;
- the existing desktop pure-adapter boundary;
- production policy behavior;
- MediaProxy/range instrumentation;
- benchmark schema and sampling design.

`ProductionMediaAnalysisPolicy` is unchanged.

The first run remains historically `FAIL — BUILD` below. No benchmark record from that run exists or is promoted.

## Current validation — phase7a-analysis-benchmark-foundation-mate60-webdav

**Final decision: FAIL — BUILD.** Measured benchmark records: **0**. The real-arm64 baseline was not executed because the required first build/static gate failed; no performance/policy conclusion follows.

- Accepted Phase 3 base: `4c7a4abe40295d86bb2799efe34c82cb9b505d58`.
- Phase 7A source: `4f4f583d1f32c412d8f6f5afedd2b8507267e0bf`; actual tested HEAD: `de50b0fc0c9da2f508312412751447d592a08bde`.
- Correct repository/branch: `baozi510/Linkora`, `feat/analysis-benchmark-policy-phase7`; new independent checkout `D:/Linkora-benchmark-phase7a`.
- Both prescribed ancestry checks pass. Source-to-HEAD drift is exactly `docs/CODEX_VALIDATION_TASK.md`; initial checkout clean; pinned submodules initialized. All eleven required documents completely read in task order, SESSION_HANDOFF CURRENT STATE first. Historical Phase 3 results were not reused as Phase 7A PASS.
- Evidence: [phase7a-mate60-webdav-20261006](../test-lab/benchmark/phase7a-mate60-webdav-20261006/).

### Fresh preparation and gates

| Step | Result | Scope |
| --- | --- | --- |
| One normal DevEco bundled ohpm install | PASS, exit 0 | Exactly once; no package-resolution flags |
| Four allowlisted EOL proofs + restore | PASS | Git-normalized blobs, CRLF->LF bytes, line content equal HEAD; no semantic dependency/version/checksum/graph/comment delta or other tracked drift; clean, no reinstall |
| Generated FFmpeg dependency inputs | PASS, reuse only | Eight arm64/x86 archives freshly hashed/all-member ABI checked, exact pin/manifests verified; no old HAP/HAR or old test result reused |
| `node --check scripts/summarize-benchmark.cjs` | PASS | Fresh syntax check, bundled Node v24.14.1 |
| Architecture boundary guard | PASS | Fresh completion marker |
| Architecture guard fixtures | PASS, 5/5 | Failures 0 |
| Static simulator product isolation | PASS | No simulator build implied |
| FFmpeg Phase1 pure suite | PASS, 15/15 | Fresh desktop execution |
| Analysis Phase2 adapter/policy pure suite | FAIL at module loading | `Unexpected dependency: @kit.BasicServicesKit`; case bodies not executed |
| Full first default verifier | FAIL, exit 1 | Exactly one unmodified invocation; stopped at verify.ps1 line 37 |

PowerShell 7.6.6, ohpm 26.0.0.630, HDC 3.2.0f. The SDK/Hvigor environment is provided by the existing verifier. First default invocation UTC 2026-10-06 14:21:08–14:21:11; incidental command timing is not benchmark data.

### Exact stop and read-only assessment

Actual top-level invocation: bundled PowerShell `-NoProfile -File scripts/verify.ps1` from the isolated checkout. Failing nested command is bundled Node running `scripts/check-ffmpeg-phase1.cjs <DevEco Studio root> --phase2`; this standalone command was extracted from the verifier, **not rerun** after STOP.

Original error:

```text
Error: Unexpected dependency: @kit.BasicServicesKit
    at scripts/check-ffmpeg-phase1.cjs:26:11
    at entry/src/main/ets/analysis/FfmpegMediaProbeAdapter.ets:7:33
Analysis Phase2 pure tests failed.
```

The adapter's original source line 6 adds `systemDateTime` from `@kit.BasicServicesKit` for prepare/probe/total timing. The stack's line 7 is the transpiled VM location. The desktop loader require handler accepts Hypium, linkora_core, linkora_ffmpeg and relative imports, then throws for every other dependency. This directly supports a benchmark timing dependency / desktop harness compatibility failure. It does not establish an ArkTS compile failure, native load failure, bad target clock, slow engine, incomplete ADVANCED result or benchmark runtime defect.

No Kit mock/shim, loader patch, clock substitution, test expectation change, standalone reproduction or retry was applied. GPT owns the reviewed correction and next source/READY dispatch.

### Range integrity, unexecuted scope and protection

Read-only review confirms `rangeRequests` has its zero assertion in NetworkFileProxy unit coverage; increments only for GET with Range resolving to 206; aggregate diagnostics retain released-source range counts; `readRequests` remains separate. **Actual new range unit/runtime validation is NOT RUN**, because the failed desktop gate precedes Hvigor/Hypium.

NOT RUN after STOP: subsequent native artifact fixtures, persistence/HTTP/Loader/MPV gates; actual Hypium (executed 0, result file absent); all default Debug/Release HAR/HAP and exact-nine native ABI audits; simulator verifier and immediate default; post-simulator dependency normalization; signing overlay/fresh signed HAP/hash/install/launch; saved-server/corpus target preflight; ephemeral config/reverse/Want launch; warmups/repetitions; 240-record acquisition and structure checks; numerical summary/observations. No fabricated dataset/state/metrics or Phase 3 target installation substitutes for this source. No benchmark configuration or signing material was collected.

All 2,243 tracked regular files remain byte-identical before report publication, three submodules pinned/clean, checkout clean. Original dirty `D:/Linkora` HEAD/status/diff hashes match before/after. `ProductionMediaAnalysisPolicy` has no diff from accepted Phase 3 base. No source/test/script/build expectation/profile/semantic-lock/task/corpus change, production policy conclusion, Direct I/O, merge or next phase.

Evidence reviewed for credentials/Authorization/Cookie values, private URLs/server/device/SSH identities, proxy tokens and signing material: no sensitive values found. Only public repo source context, hashes, command output and integrity metadata are published.

Only this report and the named evidence directory are committed; normal push/re-fetch/remote containment required before completion. Return the remotely visible evidence SHA separately. Push failure would be `BLOCKED — EVIDENCE NOT PUSHED` while preserving the build failure.

## Foundation scope (implementation description; execution status above)

Phase 7A implements benchmark infrastructure and a real-arm64 WebDAV baseline.

It does not change `ProductionMediaAnalysisPolicy`.

## Foundation changes

- debug-only Want-triggered `AnalysisBenchmarkRunner`;
- explicit System vs FFmpeg execution on the same production source path;
- metadata LIST + ADVANCED benchmark records;
- thumbnail extraction + common WebP encode + temporary write records;
- MediaProxy valid HTTP Range GET counter;
- real adapter prepare/probe timing fields;
- NDJSON output and improved summarizer;
- stable `docs/ANALYSIS_BENCHMARK_PHASE7_MANUAL.md`.

## Initial baseline

Target:

- real Mate60 arm64;
- WebDAV source through production storage -> RandomAccessSource -> MediaProxy.

Initial controlled cases:

- H.264/AAC MP4 1280x720 ~20 s;
- HEVC/AAC MKV 1280x720 ~20 s.

Default sampling:

- 2 warm-ups;
- 20 measured repetitions;
- alternating System/FFmpeg order;
- LIST, ADVANCED and thumbnail per engine.

## Policy boundary

No production routing change is authorized until fresh benchmark evidence is independently reviewed.

The two-case WebDAV baseline validates the measurement path and provides preliminary data only. Broader policy claims require a sufficient permanent corpus and source-family coverage.
