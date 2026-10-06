# Codex Validation Task

> State: READY
> Task ID: phase7a-analysis-benchmark-foundation-mate60-webdav
> Repository: `baozi510/Linkora`
> Branch: `feat/analysis-benchmark-policy-phase7`
> Phase 3 accepted base SHA: `4c7a4abe40295d86bb2799efe34c82cb9b505d58`
> Phase 7A source SHA: `4f4f583d1f32c412d8f6f5afedd2b8507267e0bf`
> Role: BUILD / TEST / BENCHMARK EVIDENCE / REPORT ONLY

## 1. Purpose

Validate the new Phase 7A benchmark foundation and collect the first **real-arm64 System vs FFmpeg WebDAV analysis baseline** on Mate60.

This task does **not** authorize a production policy change.

Codex must not edit:

- `ProductionMediaAnalysisPolicy`;
- production routing;
- benchmark expectations after seeing results;
- test scripts/source/build configuration;
- the permanent corpus to make an engine look better.

Raw benchmark failures are data unless the runner/infrastructure itself is broken.

Stable benchmark manual:

`docs/ANALYSIS_BENCHMARK_PHASE7_MANUAL.md`

Read it completely.

## 2. Source safety

Use a new isolated checkout/worktree for this phase, for example:

`D:\Linkora-benchmark-phase7a`

Do not reuse or mutate the user's dirty `D:\Linkora`.

Before work:

1. fetch `feat/analysis-benchmark-policy-phase7`;
2. checkout current remote HEAD;
3. initialize pinned submodules;
4. confirm tracked checkout clean;
5. confirm `4f4f583d1f32c412d8f6f5afedd2b8507267e0bf` is an ancestor of HEAD;
6. run:

```powershell
git diff --name-only 4f4f583d1f32c412d8f6f5afedd2b8507267e0bf..HEAD
```

The only permitted post-source path is:

```text
docs/CODEX_VALIDATION_TASK.md
```

Anything else => STOP.

Record both:

- Phase 7A source SHA;
- actual tested checkout SHA.

Also confirm `4c7a4abe40295d86bb2799efe34c82cb9b505d58` is an ancestor of the Phase 7A source.

## 3. Required reading

Read completely, in this order:

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

Do not infer current state from old Phase 3 tasks in Git history.

## 4. What changed in Phase 7A

Review, do not modify:

- `entry/src/main/ets/benchmark/AnalysisBenchmarkRunner.ets`
  - debug-only Want-triggered runner;
  - explicitly forces System or FFmpeg;
  - same saved WebDAV server -> NetworkDirectoryService -> MediaSource -> resolver -> MediaProxy path;
  - metadata LIST + ADVANCED;
  - thumbnail extraction + common WebP encode + temporary write;
  - 2 warm-ups / 20 measured reps supported;
  - alternates engine order.

- `entry/src/main/ets/analysis/SystemMediaProbeAdapter.ets`
- `entry/src/main/ets/analysis/FfmpegMediaProbeAdapter.ets`
  - populate existing prepare/probe/total timing diagnostics.

- `linkora_proxy/src/main/ets/NetworkFileProxy.ets`
  - adds `rangeRequests`;
  - counts only valid GET requests carrying Range and resolved as 206;
  - does not change transport routing.

- `scripts/summarize-benchmark.cjs`
  - analysis benchmark aggregate + per-case report.

- `EntryAbility`
  - debug-trigger parameter `linkoraAnalysisBenchmarkConfig`.

Confirm `ProductionMediaAnalysisPolicy.ets` has no diff from the accepted Phase 3 base.

## 5. Dependency preparation

Run exactly one normal:

```powershell
ohpm install
```

inside the isolated validation checkout.

Known Windows LF->CRLF-only lock normalization may be repaired only for:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

Use the previously established strict proof:

- exact affected paths only;
- HEAD Git-normalized blob equality;
- CRLF->LF bytes equal;
- line contents equal;
- no dependency/version/checksum/graph/comment semantic difference.

Then restore only proven EOL-only files.

No reinstall merely because they were restored.

Any semantic dependency drift or extra tracked path => STOP.

## 6. Fresh build/static validation

Because Phase 7A adds executable source, fresh validation is required.

Run:

```powershell
node --check scripts/summarize-benchmark.cjs
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Rules:

- exactly one normal `ohpm install` before the sequence;
- no manual reinstall between simulator and immediate default;
- apply only the established EOL-only self-heal if simulator dependency restoration rewrites the allowlisted locks;
- return clean before signing overlay.

Record all existing gate counts, including Hypium count and native ABI audits.

This is a new-phase source validation, not a rerun of Phase 3 evidence.

Any compile/test/build gate failure => STOP and publish evidence as `FAIL — BUILD`.

## 7. Range-counter integrity

Freshly confirm:

- `NetworkFileProxyDiagnostics.rangeRequests` starts at zero in unit coverage;
- source review shows increment only for:
  - method GET;
  - Range header present;
  - resolved response status 206;
- released-source counts are retained in aggregate diagnostics;
- `readRequests` remains a distinct RandomAccessSource metric.

Do not rename readRequests into rangeRequests.

## 8. Exact-source signed Mate60 artifact

After the clean build sequence, prepare a fresh signed default/debug arm64 HAP.

Use the same signing-provenance rules accepted in Phase 3:

- temporary local signing overlay only in root `build-profile.json5`;
- only signing-related semantics;
- no SDK/module/dependency/ABI/build-option/source changes;
- secret paths/material never committed;
- sanitize the overlay evidence;
- record overlay hash;
- build exact debug/default HAP once;
- run existing arm64 artifact checker on that exact HAP;
- record HAP SHA-256;
- restore `build-profile.json5` to HEAD and prove clean;
- explicitly install that exact HAP on Mate60.

If replacement install is blocked by signature mismatch, do not automatically uninstall existing app. STOP as:

`BLOCKED — SIGNING/DEPLOYMENT`

## 9. Target and benchmark environment

Use the real Mate60 arm64 target.

Freshly record:

- HDC version;
- target architecture/API;
- installed app bundle/version;
- app launch/process state.

Reuse the already controlled HTTPS WebDAV benchmark environment if still available.

Do not commit:

- endpoint;
- credentials;
- SSH identity;
- private server display name;
- private remote paths.

The benchmark runner intentionally reads the already-saved WebDAV server from Linkora's secure app configuration.

## 10. Runtime-private benchmark config

Serve one ephemeral config JSON on a host loopback HTTP endpoint and expose it to the Mate60 with HDC reverse forwarding.

Want parameter:

`linkoraAnalysisBenchmarkConfig`

must contain only:

```text
http://127.0.0.1:<reversed-port>/<uuid>
```

The private JSON should use:

```json
{
  "schemaVersion": 1,
  "serverName": "<runtime-private saved server name>",
  "warmups": 2,
  "repetitions": 20,
  "cases": [
    {
      "caseId": "mp4-h264-aac",
      "directoryPath": "<runtime-private path>",
      "fileName": "<controlled H264/AAC MP4 filename>",
      "container": "mp4",
      "expectedDurationMs": 20000,
      "expectedWidth": 1280,
      "expectedHeight": 720
    },
    {
      "caseId": "mkv-hevc-aac",
      "directoryPath": "<runtime-private path>",
      "fileName": "<controlled HEVC/AAC MKV filename>",
      "container": "matroska",
      "expectedDurationMs": 20021,
      "expectedWidth": 1280,
      "expectedHeight": 720
    }
  ]
}
```

Use the actual verified fixture duration from the existing local manifest if it differs by a few ms; do not edit source for fixture variance.

Never commit the actual private config.

Freshly verify the fixture hashes still match the controlled Phase 3 corpus before benchmark execution.

## 11. Execute benchmark exactly once after successful preflight

Launch the freshly installed debug app with the benchmark Want parameter.

Do not interact with normal Network UI during the benchmark.

Wait for:

```text
<context.cacheDir>/analysis-benchmark-state.json
```

to report:

- `complete = true`;
- `errorCode = 0`;
- `records = 240`.

Expected record count:

```text
2 cases
x 20 measured iterations
x 2 engines
x 3 operations
= 240
```

Warm-ups are not recorded.

Copy out:

```text
analysis-benchmark-results.ndjson
analysis-benchmark-state.json
```

Do not rerun merely because some engine samples have `success=false`; those can be benchmark data.

A runner crash, malformed/incomplete output, wrong record count, leaked secrets, or invalid metric semantics is:

`FAIL — BENCHMARK RUNNER`

and must STOP.

## 12. Validate raw benchmark structure

Require exactly 20 measured records for every combination of:

- caseId;
- engine = system / ffmpeg;
- metadata requirement = list / advanced;
- thumbnail operation.

Check:

- iteration set = 0..19 for every group;
- engine order alternates by iteration as designed;
- all elapsed/timing/count fields are non-negative or explicitly null where allowed;
- `memoryBytes` may be null;
- no x86/simulator records;
- no private endpoint/path/server/credential fields;
- no impossible WebP byte count on a successful thumbnail;
- no negative bytes/read/range counts.

Do not delete failed/outlier records.

## 13. Generate report

Run:

```powershell
node scripts/summarize-benchmark.cjs <copied-results.ndjson> <benchmark-report.md>
```

The report must include:

- aggregate System vs FFmpeg groups;
- LIST and ADVANCED separately;
- thumbnail separately;
- per-case table;
- success/complete rates;
- P50/P95;
- bytes;
- HTTP Range count;
- thumbnail encode/write/WebP sizes where present;
- memory as unavailable rather than zero when not collected.

Also create a concise analysis note that states observed numerical differences without recommending a production policy.

Codex may say, for example:

- System LIST P50 was lower/higher than FFmpeg by X on this corpus;
- FFmpeg ADVANCED completeness was higher/lower;
- FFmpeg/System thumbnail bytes/ranges differed.

Codex must **not** conclude the final routing policy.

## 14. Benchmark interpretation limits

This first baseline covers only:

- real Mate60 arm64;
- WebDAV;
- H.264/AAC MP4;
- HEVC/AAC MKV.

It does not prove:

- SMB performance;
- Local performance;
- HDR/Main10/4K/long-GOP behavior;
- broad container superiority;
- final memory ranking;
- MediaProxy is a bottleneck;
- Direct I/O is warranted.

Do not modify `ProductionMediaAnalysisPolicy` or implement Direct I/O.

## 15. Security review

Scan committed evidence for:

- Authorization;
- Cookie;
- passwords;
- private server names;
- private URL/path;
- proxy token;
- HDC private target identifier;
- signing material/path;
- private SSH data.

Generic case IDs and benchmark metrics are safe.

## 16. Authorized repository output

Codex may update only:

- `docs/ANALYSIS_BENCHMARK_PHASE7_REPORT.md`
- one new evidence directory:
  `test-lab/benchmark/phase7a-mate60-webdav-20261006/`

Suggested evidence:

- source-state.json;
- required-reading.json;
- tool-versions.json;
- dependency/EOL proof;
- build gate summaries;
- signing-overlay sanitized summary;
- signed artifact hash/audit;
- target-state sanitized summary;
- fixture-manifest sanitized hashes;
- benchmark-state.json;
- results.ndjson;
- benchmark-report.md;
- benchmark-structure-check.json;
- benchmark-observations.md;
- security-review.json;
- protected-audit.json.

Do not commit:

- HAP;
- credentials;
- private config;
- raw signing diff;
- private device/server identifiers.

## 17. Handoff

After evidence is complete:

1. ensure signing overlay restored;
2. ensure checkout contains only authorized report/evidence changes;
3. fetch remote branch;
4. stop on unexpected protected drift;
5. commit report + evidence only;
6. push without force;
7. fetch again;
8. prove remote containment;
9. return the remotely visible evidence SHA.

Push failure => `BLOCKED — EVIDENCE NOT PUSHED`.

## 18. Final classification

Use one of:

- `PASS — PHASE 7A BENCHMARK BASELINE COLLECTED`;
- `FAIL — BUILD`;
- `FAIL — BENCHMARK RUNNER`;
- `BLOCKED — SIGNING/DEPLOYMENT`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise evidence-supported infrastructure classification.

A slow System/FFmpeg result is not itself FAIL.

Do not merge. Do not change production policy. Do not start Phase 7B.
