# Codex Validation Task

> State: WAITING_FOR_RUNTIME_TARGET
> Task ID: phase3-runtime-acceptance-gate-1
> Repository: `baozi510/Linkora`
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Implementation source SHA: `44d0f62816b73ebd3bab8069be5b74f51e2c6999`
> Review baseline SHA: `197e7147d2c0a2fa460cf5b31b4668ecfc112017`
> Role when activated: TEST / EVIDENCE / REPORT ONLY

## 1. Do not execute yet

This task is intentionally **not READY**.

Codex must not rerun the Phase 3 build/static suite merely to reproduce the current environment block.

Latest reviewed evidence:

`e95feef35fa2541322216f9ce9336da3cad9060f`

establishes fresh build/static/pure acceptance:

- default verifier PASS;
- simulator verifier PASS;
- immediate-default verifier PASS;
- Hypium 209/209 PASS twice;
- Debug/Release HAR/HAP and exact-nine AArch64 audits PASS twice;
- simulator whitelist/ABI PASS;
- Loader/cache/lifecycle and MPV desktop harnesses PASS twice;
- Phase 3 pure policy suite and supplemental ADVANCED/error-boundary checks PASS.

No failed implementation gate currently requires a source fix.

## 2. Why this task is waiting

Production runtime acceptance remains unexecuted because the latest environment had:

```text
hdc list targets
[Empty]
```

both before and after validation.

Runtime cycles executed: 0.

The production runbook cases cannot be promoted from desktop mocks, static review, pure tests or successful packaging.

## 3. Prerequisites for a future READY dispatch

GPT may change this task from WAITING to READY only after the validation environment can demonstrate all required prerequisites.

Minimum prerequisites:

1. **Connected HarmonyOS runtime target**
   - `hdc list targets` returns at least one usable HarmonyOS device/emulator target;
   - the target is reachable for install/launch/log collection.

2. **Deployable application path**
   - a supported development signing/install path is available without weakening or committing insecure production signing configuration;
   - tracked build profiles must not be patched merely to bypass signing/runtime restrictions.

3. **Reachable WebDAV fixture environment**
   - target can reach a test WebDAV server;
   - sanitized credentials/configuration can be supplied without committing secrets;
   - fixtures include at minimum:
     - H.264/AAC MP4;
     - HEVC/AAC MKV;
     - one unsupported/corrupt media fixture suitable for no-invalid-thumbnail/bounded-retry behavior;
   - a natural FFmpeg-thumbnail-failure/System-success fixture is desirable; if unavailable it may remain NOT RUN.

4. **Evidence collection**
   - HDC/app logs can be captured and sanitized;
   - persistent cache/app files can be inspected sufficiently to verify WebP/cache behavior;
   - proxy/source diagnostics needed for cleanup checks are observable.

If these prerequisites are not available, remain WAITING. Do not repeatedly rerun the green build chain.

## 4. Runtime validation scope when activated

Stable execution manual:

`docs/PHASE3_RUNTIME_ACCEPTANCE_MANUAL.md`

When GPT later publishes a READY version of this task, Codex must read that manual completely and follow it together with the new READY task. The task remains the dispatch authority for exact source SHA, permissions, required cases, stop conditions and evidence paths.

The primary scope will be production runtime rather than another exploratory build cycle.

Required production path:

`Network page/list -> NetworkMediaLoader -> NetworkMediaAnalysisCoordinator`

Runtime cases to execute where applicable:

### WebDAV MP4

Use H.264/AAC MP4.

Verify:

- directory/list opens;
- metadata appears;
- thumbnail appears;
- duration/width/height are plausible;
- persistent thumbnail is WebP;
- reopen uses cache;
- production log reports safe engine diagnostics;
- active proxy/source count returns to zero.

### WebDAV HEVC/MKV

Verify:

- metadata appears;
- thumbnail appears;
- FFmpeg thumbnail path works;
- cache/reopen works;
- no System-only MKV thumbnail regression;
- sources/proxy clean up.

### Thumbnail fallback

Using a natural safe fixture/condition where FFmpeg extraction fails but System succeeds, if available:

- no crash;
- System fallback thumbnail appears;
- persistent output is WebP;
- thumbnailEngine reports `system`;
- resources clean up.

If no natural safe case exists, mark NOT RUN. Do not patch source to force it.

### Both thumbnail engines unavailable

Use unsupported/corrupt media.

Verify:

- list remains usable;
- no crash;
- useful metadata may persist when available;
- no invalid thumbnail file is persisted;
- retry/backoff remains bounded;
- resources release.

### Cache compatibility

Verify on target:

- metadata-only cache;
- WebP cache reopen;
- legacy JPEG read compatibility where an existing fixture is safely available;
- newly generated thumbnails remain WebP only.

### Cancellation / refresh

Exercise navigate-away, refresh, cancel/re-enter.

Verify:

- no old-generation metadata delivery;
- no stale thumbnail insertion;
- no fallback begins after cancellation;
- no stale rows;
- source/proxy count returns to zero.

### 20-cycle lifecycle

Repeat production network-directory open/preview/leave/reopen 20 times.

Verify:

- no crash/ANR;
- no persistent source/proxy growth;
- no duplicate rows;
- cached thumbnails remain decodable.

This is functional lifecycle validation, not a performance benchmark.

### HLS / DASH / LOCAL_DOCUMENT

Verify production user-facing flow remains System-only and functional.

Do not route these paths into native FFmpeg analysis.

### ADVANCED / SFTP

- actual ADVANCED native target execution is useful where a safe diagnostic path exists;
- SFTP native smoke is optional if an arm64 target/server is already available;
- do not create unrelated infrastructure solely for optional coverage.

## 5. Runtime security boundaries

Do not commit or expose:

- Authorization values;
- Cookie values;
- passwords;
- private credentials;
- proxy tokens;
- private signing keys;
- sensitive full upstream paths/URLs.

Production analysis logs should contain only safe diagnostics such as:

- `metadataEngine`;
- `thumbnailEngine`;
- `thumbnailPlan`.

Use sanitized fixture identities in committed evidence.

## 6. Performance remains excluded

Do not collect or interpret System-vs-FFmpeg:

- latency rankings;
- p50/p95;
- throughput;
- CPU/GPU ranking;
- memory-efficiency ranking;
- power;
- thermal results.

Real arm64 performance policy remains a later benchmark phase.

## 7. What to do now

Because this task is WAITING_FOR_RUNTIME_TARGET:

- do not execute validation;
- do not edit source/tests/build configuration;
- do not create an evidence commit;
- do not merge or start the next phase.

When the environment prerequisites in section 3 become available, return to GPT.

GPT will re-check the repository/environment state and publish a new **READY** task revision before Codex executes anything.
