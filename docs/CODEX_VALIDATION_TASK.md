# Codex Validation Task

> State: READY
> Task ID: phase7a-rerun-1-analysis-clock-injection
> Repository: `baozi510/Linkora`
> Branch: `feat/analysis-benchmark-policy-phase7`
> Phase 3 accepted base SHA: `4c7a4abe40295d86bb2799efe34c82cb9b505d58`
> Prior failed Phase 7A evidence SHA: `36593af5263684cd1c687bcda4621c0f21a8197e`
> Corrected Phase 7A source SHA: `df88a0514acaf18b003c5fe1115ced965b1bc285`
> Role: BUILD / TEST / BENCHMARK EVIDENCE / REPORT ONLY

## 1. Why this rerun exists

The first Phase 7A attempt correctly stopped at:

```text
FAIL — BUILD
Unexpected dependency: @kit.BasicServicesKit
scripts/check-ffmpeg-phase1.cjs --phase2
```

GPT independently reviewed the remote evidence and accepted that failure.

Root cause:

- Phase 7A timing instrumentation imported HarmonyOS `systemDateTime` directly into `FfmpegMediaProbeAdapter` and `SystemMediaProbeAdapter`;
- those adapters are intentionally loaded by the desktop pure VM harness;
- the harness correctly rejects platform Kit dependencies.

Correction in `df88a0514acaf18b003c5fe1115ced965b1bc285`:

- both adapters now receive an injectable clock;
- their direct/pure construction no longer imports `@kit.BasicServicesKit`;
- target-specific default/simulator `AnalysisComposition` injects HarmonyOS monotonic `systemDateTime.getUptime(STARTUP)`;
- a deterministic pure regression test verifies prepare/probe/total timing;
- `ProductionMediaAnalysisPolicy` is unchanged.

Do not patch the desktop harness to fake the Kit module.

## 2. Source safety

Use an isolated Phase 7A checkout/worktree. Reusing the prior isolated checkout is allowed only if it is clean before fetch; the user's dirty `D:\Linkora` must remain untouched.

Before execution:

1. fetch `feat/analysis-benchmark-policy-phase7`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove tracked checkout clean;
5. confirm `df88a0514acaf18b003c5fe1115ced965b1bc285` is an ancestor of HEAD;
6. run:

```powershell
git diff --name-only df88a0514acaf18b003c5fe1115ced965b1bc285..HEAD
```

The only permitted path is:

```text
docs/CODEX_VALIDATION_TASK.md
```

Anything else => STOP.

Also confirm:

- `4c7a4abe40295d86bb2799efe34c82cb9b505d58` is an ancestor of `df88a0514acaf18b003c5fe1115ced965b1bc285`;
- prior failed evidence `36593af5263684cd1c687bcda4621c0f21a8197e` is an ancestor of `df88a0514acaf18b003c5fe1115ced965b1bc285`.

The old failed evidence remains historical and must not be rewritten.

## 3. Required reading

Read completely:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md`
6. `docs/SESSION_HANDOFF.md` — CURRENT STATE first
7. `docs/CODEX_VALIDATION_TASK.md`
8. `docs/ANALYSIS_BENCHMARK_PHASE7_MANUAL.md`
9. `docs/ANALYSIS_BENCHMARK_PHASE7_REPORT.md`
10. `test-lab/benchmark/README.md`
11. `test-lab/benchmark/cases.json`

## 4. Correction review before execution

Read-only confirm:

- `FfmpegMediaProbeAdapter.ets` contains no `@kit.BasicServicesKit` import;
- `SystemMediaProbeAdapter.ets` contains no `@kit.BasicServicesKit` import;
- both adapters accept an injected clock;
- default `AnalysisComposition.ets` injects HarmonyOS STARTUP uptime;
- simulator `AnalysisComposition.ets` injects HarmonyOS STARTUP uptime;
- timing regression exists in `MediaAnalysisAdapters.test.ets`;
- `scripts/check-ffmpeg-phase1.cjs` was not weakened with a Kit shim;
- `ProductionMediaAnalysisPolicy.ets` has no diff from the accepted Phase 3 base.

Any contradiction => STOP.

## 5. Dependency preparation

Run exactly one normal:

```powershell
ohpm install
```

Known Windows EOL-only self-heal remains allowed only for:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

Apply the same strict proof:

- exact allowlisted paths only;
- Git-normalized blob equality;
- CRLF->LF normalized byte equality;
- line-content equality;
- no semantic dependency/version/checksum/graph/comment change.

Then restore only proven EOL-only drift.

No reinstall just because of restore.

Any semantic or extra tracked drift => STOP.

## 6. Fresh corrected build/static sequence

Run:

```powershell
node --check scripts/summarize-benchmark.cjs
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Do not reuse the first failed run's PASS sub-gates as fresh PASS.

Expected corrected early gate:

```text
Analysis Phase2 pure tests: 46/46 PASS
```

because the clock regression adds one test.

Expected full Hypium count, if all current tests compile/run:

```text
210 PASS
0 Failure
0 Error
```

If the repository reports a different count, record the actual count and investigate source/test inventory before claiming PASS.

Rules:

- exactly one normal `ohpm install`;
- no manual reinstall between simulator and immediate default;
- simulator restore may use only the established strict EOL-only self-heal;
- return clean before signing preparation.

Any gate failure => STOP as `FAIL — BUILD` with original raw output.

Do not fix or retry source after a failed gate.

## 7. Range-counter integrity

After build/static passes, confirm from fresh tests/source:

- `NetworkFileProxyDiagnostics.rangeRequests` zero baseline;
- increments only for GET + Range + resolved 206;
- released-source range counts survive aggregation;
- `readRequests` remains separate;
- no transport behavior change was introduced merely for metrics.

## 8. Fresh signed Mate60 artifact

After the complete build sequence passes, create a fresh signed default/debug arm64 HAP from this exact corrected checkout.

Use the accepted signing-overlay rules:

- only root `build-profile.json5`;
- signing-only semantics;
- no SDK/module/dependency/ABI/build/source change;
- secrets/private signing paths not committed;
- record sanitized overlay summary + overlay SHA-256;
- build exact HAP once;
- run existing arm64 artifact checker on exact HAP;
- record exact HAP SHA-256;
- restore `build-profile.json5` to HEAD and prove clean;
- explicitly install that exact HAP on Mate60.

If replacement install fails due signature mismatch, do not auto-uninstall:

`BLOCKED — SIGNING/DEPLOYMENT`

## 9. Benchmark environment

Use the real Mate60 arm64 target and the already controlled HTTPS WebDAV fixtures, if still available.

Freshly verify:

- target reachable;
- installed exact HAP launches;
- controlled MP4/MKV hashes still match;
- saved app-side WebDAV server still reaches those fixtures.

Private endpoint, server name, credentials, remote paths, SSH identity and device identifier must not enter committed evidence.

## 10. Runtime-private config

Use HDC reverse + ephemeral loopback HTTP config endpoint exactly as defined in:

`docs/ANALYSIS_BENCHMARK_PHASE7_MANUAL.md`

Want parameter:

`linkoraAnalysisBenchmarkConfig`

must contain only:

```text
http://127.0.0.1:<reversed-port>/<uuid>
```

Config:

- schemaVersion 1;
- warmups 2;
- repetitions 20;
- two controlled cases:
  - `mp4-h264-aac`;
  - `mkv-hevc-aac`.

Do not commit the private JSON.

## 11. Execute benchmark once

After all preflight/build/deploy conditions pass, launch the benchmark exactly once.

Expected measured record count:

```text
2 cases
x 20 iterations
x 2 engines
x 3 operations
= 240
```

Warm-ups are not recorded.

Expected output:

```text
analysis-benchmark-state.json
analysis-benchmark-results.ndjson
```

State must report:

- complete = true;
- errorCode = 0;
- records = 240.

Engine sample `success=false` is benchmark data, not automatically infrastructure FAIL.

A runner crash, incomplete/malformed output, wrong record count, secret leak or invalid metric semantics => STOP as:

`FAIL — BENCHMARK RUNNER`

## 12. Raw structure validation

Require exactly 20 measured records for every expected case/engine/operation group.

Validate:

- iteration 0..19 exactly;
- alternating engine order;
- non-negative timing/count fields;
- nullable memory stays null if unavailable;
- successful thumbnail has positive WebP bytes;
- no private server/path/config/token fields;
- no simulator/x86 samples.

Retain all valid slow/failing engine samples. Do not delete outliers to improve results.

## 13. Generate numerical summary

Run:

```powershell
node scripts/summarize-benchmark.cjs <results.ndjson> <benchmark-report.md>
```

Publish descriptive observations only:

- success/completeness;
- P50/P95;
- prepare/probe or extract/encode/write;
- bytes;
- actual HTTP Range count;
- WebP size;
- memory availability.

Do not recommend or modify production routing.

Do not claim the two-case WebDAV baseline proves Local/SMB/HDR/Main10/4K/general codec superiority.

## 14. Security

Scan evidence for:

- Authorization;
- Cookie;
- passwords;
- private endpoint/server/path;
- proxy token;
- private target ID;
- signing material/path;
- SSH identity.

No secret-bearing raw config or signing diff may be committed.

## 15. Authorized repository output

Update only:

- `docs/ANALYSIS_BENCHMARK_PHASE7_REPORT.md`
- one new directory:
  `test-lab/benchmark/phase7a-rerun-1-analysis-clock-20261006/`

Do **not** modify the previous failed evidence directory.

Include fresh:

- source/ancestry/drift proof;
- correction review;
- dependency/EOL proof;
- all build gate outputs/summaries;
- signing/artifact provenance;
- target/fixture sanitized preflight;
- benchmark state;
- full 240-record NDJSON if execution reaches runtime;
- structure check;
- generated benchmark report;
- descriptive observations;
- security/protected audit.

Do not commit HAP, credentials, private config or signing material.

## 16. Handoff

After completion:

1. restore signing overlay;
2. prove checkout contains only authorized report/new evidence changes;
3. fetch remote;
4. reject unexpected protected drift;
5. commit report + new evidence directory only;
6. push without force;
7. fetch again;
8. prove remote containment;
9. return the remotely visible evidence SHA.

## 17. Final classification

Use exactly one evidence-supported classification:

- `PASS — PHASE 7A BENCHMARK BASELINE COLLECTED`;
- `FAIL — BUILD`;
- `FAIL — BENCHMARK RUNNER`;
- `BLOCKED — SIGNING/DEPLOYMENT`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification.

Do not modify `ProductionMediaAnalysisPolicy`.
Do not implement Direct I/O.
Do not start Phase 7B.
