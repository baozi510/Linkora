# Analysis Benchmark + Policy Phase 7 Report

> Status: ACCEPTED — PHASE 7A BENCHMARK BASELINE; 240 real-Mate60 records independently reviewed. Production analysis policy unchanged.
> Branch: `feat/analysis-benchmark-policy-phase7`
> Date: 2026-10-06

## GPT final Phase 7A review — 2026-10-06

Reviewed remote evidence commit:

`92017b8fd95cb944c03a30c2eb909cd8ad70dff5`

Final ruling:

**ACCEPTED — PHASE 7A BENCHMARK BASELINE.**

Independent review confirms:

- 240 measured records, 12 groups, 20 records/group;
- all records are real arm64 target data;
- all samples succeeded/correct;
- System ADVANCED is correctly PARTIAL rather than misclassified as failure;
- `rangeRequests` measures valid proxy GET+Range requests resolved as 206;
- `readRequests` remains the distinct upstream RandomAccessSource read count;
- `bytesRead` is upstream delivered bytes and may exceed file size because repeated/overlapping reads are real work;
- memory is unavailable/null, never coerced to zero;
- no production policy or Direct I/O change was made during evidence collection.

Observed two-case WebDAV baseline:

- LIST: FFmpeg lower aggregate P50/P95 than System;
- ADVANCED: FFmpeg lower aggregate P50/P95 and COMPLETE, while System remains PARTIAL;
- thumbnail: System lower aggregate latency and dramatically lower upstream bytes than FFmpeg on both controlled cases.

These differences are real for this corpus, but the corpus is only H.264/AAC MP4 and HEVC/AAC MKV over WebDAV. They do not justify a global thumbnail-routing rewrite across Main10/HDR/Dolby Vision/4K/long-GOP/other containers or source families.

### Policy decision

`ProductionMediaAnalysisPolicy` remains unchanged.

Reason:

- functional Phase 3 routing is already accepted;
- the Phase 7A sample is intentionally a measurement-foundation baseline, not a representative full capability corpus;
- changing global routing from two files would violate the benchmark-driven policy rule by over-generalizing sparse data.

No standalone Analysis-corpus expansion is scheduled now. Broader codec/container/audio coverage will be collected later using the shared Media Capability Corpus during Playback/Advanced AV validation, with Analyzer and Playback outcomes recorded independently.

Direct I/O remains deferred: this evidence does not establish MediaProxy itself as the bottleneck.

## Current validation — phase7a-rerun-1-analysis-clock-injection

**PASS — PHASE 7A BENCHMARK BASELINE COLLECTED.** This accepts this two-case measurement baseline, not final production routing or all of Phase 7.

- Corrected source: `df88a0514acaf18b003c5fe1115ced965b1bc285`; actual tested checkout: `ccc3b850478f92e864c91b258a163d371066fa50`.
- Accepted base `4c7a4abe40295d86bb2799efe34c82cb9b505d58` and prior failed evidence `36593af5263684cd1c687bcda4621c0f21a8197e` are ancestors of corrected source; sole post-source drift is `docs/CODEX_VALIDATION_TASK.md`.
- Fresh independent clean `D:/Linkora-benchmark-phase7a-rerun1`, correct branch/repository, pinned submodules. Eleven required files fully read, CURRENT STATE first. Previous failed evidence remains unchanged and supplies no fresh PASS.
- Evidence: [phase7a-rerun-1-analysis-clock-20261006](../test-lab/benchmark/phase7a-rerun-1-analysis-clock-20261006/). [Numerical report](../test-lab/benchmark/phase7a-rerun-1-analysis-clock-20261006/benchmark-report.md) and [descriptive observations](../test-lab/benchmark/phase7a-rerun-1-analysis-clock-20261006/benchmark-observations.md).

### Correction and fresh gates

Read-only checks confirm both adapters accept a clock and import no BasicServicesKit; both compositions supply real monotonic STARTUP uptime; the deterministic timing regression exists; pure harness unchanged/no fake Kit shim; production policy has no diff from accepted Phase 3 base.

Exactly one normal ohpm install, then summarizer `node --check`, first `verify.ps1`, `verify-simulator.ps1`, immediate `verify.ps1`, all PASS. Initial and post-simulator four-lock EOL drift proved by normalized Git blobs, CRLF->LF bytes and line-content equality with no other tracked drift, then exact allowed restore; no manual reinstall between simulator/default. Simulator itself performed the normal automatic dependency restore. Eight generated FFmpeg archive dependency inputs reused and freshly hashed/audited against the exact pin/ABIs; no old HAP/HAR/result reused.

| Fresh gate | First default | Immediate default |
| --- | --- | --- |
| Architecture boundary/fixtures | PASS, 5/5 | PASS, 5/5 |
| FFmpeg Phase1 pure | PASS, 15/15 | PASS, 15/15 |
| Adapter/policy pure + injected-clock regression | PASS, 46/46 | PASS, 46/46 |
| Artifact guard fixtures | PASS, 17/17 | PASS, 17/17 |
| Persistence/HTTP/whole Loader/cache/lifecycle | PASS, complete markers | PASS, complete markers |
| MPV mapping | PASS, 5/5 | PASS, 5/5 |
| Actual Hypium | 210 Pass, Failure/Error/Ignore 0 | 210 Pass, Failure/Error/Ignore 0 |
| Debug/Release HAR core/proxy/media_probe/ffmpeg | PASS, each | PASS, each |
| Debug/Release default HAP/exact-nine AArch64 | PASS, both | PASS, both |
| Full verifier/final marker | PASS, exit0 | PASS, exit0 |

Simulator Debug: PASS, exactly one x86_64 liblinkora_ffmpeg.so, whitelist/ABI, automatic default dependency restore. No simulator performance samples. Fresh actual zero-baseline unit and read-only GET+Range+206 guard/released aggregation confirm rangeRequests semantics; readRequests stays distinct.

### Exact signed artifact and target

Root build-profile signing-only overlay from existing local DevEco references was canonical-semantics checked; only signing fields/path changed. Overlay SHA256 `5143AE29AFDA4A20ECECCDD7495E1B1759FD40A77A0312BBCFD63F97E04E9F6C`. Private diff/material/paths omitted. Fresh default/debug assembleHap once, signed artifact 64,546,408 bytes, SHA256 **`99D3D4A51A114C9916F46D4E3386F49149611415CE3E46D3342DE5D2D7E47FF6`**. Existing checker on that exact HAP PASS (9 AArch64); native hashes retained. Overlay restored to HEAD/clean before runtime. Explicit exact-HAP replacement install and launch succeeded; bundle com.linkora.player version0.1.0 debug; no uninstall/data clear.

Real Mate60, aarch64/arm64-v8a/API26, HDC3.2.0f. Controlled HTTPS fixture hashes freshly match the prepared MP4/MKV. The saved server initially opened its normal `/` root; normal UI navigated to the existing controlled child, then both files were independently observed. This resolved a preflight navigation assumption without changing app configuration/source or launching a benchmark early. Private names/endpoint/paths/SSH/device data withheld.

### One benchmark execution and dataset integrity

Runtime-private schema1 config was served only at a loopback UUID route and exposed through HDC reverse. Defaults: warmups2/repetitions20/two cases. Want `linkoraAnalysisBenchmarkConfig` sent exactly once after preflight. Normal Network UI was not operated during sampling; the private config service stopped afterward.

State: **complete=true, errorCode=0, records=240, failedRecords=0**. Raw NDJSON is preserved byte-for-byte, SHA256 `632ca13760d4266aaac993c57ac5590409bf691133245a56a0c48e7cd2b6638c`. Exactly 12 case/engine/requirement groups, 20 records/group and iteration0..19, alternation by iteration verified. No record/outlier removed. Nonnegative timing/count fields, stage sums <= total, successful thumbnail positive WebP bytes/plan bounds, no private fields or values, no x86 records; memoryBytes null throughout. Completeness: 200 COMPLETE and 40 valid System ADVANCED PARTIAL. All measured samples success/correct; PARTIAL is not infrastructure failure.

The unchanged repository summarizer generated aggregate and per-case tables. Descriptive aggregate figures:

| Operation | System P50/P95 ms | FFmpeg P50/P95 ms | Completeness |
| --- | --- | --- | --- |
| metadata LIST | 366 / 454 | 245 / 404 | both 40/40 COMPLETE |
| metadata ADVANCED | 331 / 464 | 230 / 391 | System 40 PARTIAL; FFmpeg 40 COMPLETE |
| thumbnail | 719 / 794 | 1030 / 1894 | both 40/40 COMPLETE |

Average thumbnail bytesRead: System 681,500 vs FFmpeg 7,190,498; valid HTTP Range average 3.0 each. Average WebP 6,495 vs 7,051 bytes. Timing/extraction/encode/write and per-case details remain in the generated report; aggregate combines two distributions. Memory unavailable, not zero. These numbers do not prove a final engine choice, general codec superiority, Local/SMB/HDR/Main10/4K/long-GOP performance, a proxy bottleneck or Direct I/O need.

### Protection/security/publication

All 2,263 tracked regular files byte-identical before report output, submodules pinned/clean; original dirty main HEAD/status/diff hashes unchanged, including read-only signing access. Prior failed evidence untouched; production policy unchanged; no source/test/expectation/long-term profile/semantic lock/task/corpus edit, merge or Phase7B.

Exact secret/private server/path/device/SSH/header value scans passed. Only sanitized report/new evidence; no HAP, private config, raw signing material/diff, private UI layouts or app database published. Incidental build/harness times are not mixed into target performance data. Normal push, re-fetch and remote evidence containment required before handoff; final SHA returned separately.

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

## Historical validation — phase7a-analysis-benchmark-foundation-mate60-webdav

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
