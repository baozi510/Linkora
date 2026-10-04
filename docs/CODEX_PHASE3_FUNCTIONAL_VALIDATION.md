# Codex Phase 3 Functional Validation — Test Only

> Branch: `feat/ffmpeg-analyzer-policy-phase3`  
> Role: TEST AND REPORT ONLY.  
> Do not modify source code. Do not fix failures. Do not merge.


## Post-review rerun requirement

The first execution against source `72e74d11a790bd0d258e219e3a8de18f3c59fd17` stopped at the default verifier because a service method callback parameter matched an ArkUI plain-output regex. Evidence is committed at `50fc19fbc91337e21180fc8c8a856750a4a20b95`.

ChatGPT architecture review corrected the checker scope; it did not waive the gate and did not mark any unexecuted runtime case PASS.

For the next run:

- start from a clean checkout of the current `feat/ffmpeg-analyzer-policy-phase3` HEAD;
- rerun the manual from the beginning, including `ohpm install` and full default `scripts/verify.ps1`;
- do not splice the previous partial pure-test results into the new run;
- if the default gate passes, continue every achievable functional/runtime section below;
- keep Codex test/report-only; any new source failure returns to ChatGPT.

## 1. What changed

Phase 3 implements production functional routing for media analysis.

### Probe policy

```text
LOCAL_DOCUMENT
HLS / DASH
  -> System only

file-like REMOTE_FILE / HTTP
  LIST
    -> System first
    -> FFmpeg only when System is incomplete/unusable

  DETAIL / ADVANCED
    -> FFmpeg first
    -> System only when FFmpeg is unusable
    -> no field merger
```

A usable partial FFmpeg DETAIL/ADVANCED result is retained as-is. It is not merged with System fields.

### Thumbnail policy

For file-like remote sources:

```text
FFmpeg extractor
  -> common SystemWebPEncoder
  -> cache

on functional failure:
System existing thumbnail extractor
  -> common SystemWebPEncoder
  -> cache
```

For LOCAL_DOCUMENT / HLS / DASH, policy remains System-only.

### Production integration

`NetworkMediaLoader` now uses `NetworkMediaAnalysisCoordinator`.

The loader no longer directly owns the old System probe/source/proxy lease chain.

### Security/lifecycle correction

`HarmonyAnalysisInputs` no longer passes `MediaSource.fingerprint` as an SFTP host-key fingerprint. Native providers obtain protocol trust settings from the persisted server configuration.

## 2. Test-only rule

Do not edit:

- ArkTS source;
- C/C++;
- build profiles;
- lockfiles;
- test expectations.

If anything fails:

1. preserve exact failing command/output;
2. record branch SHA;
3. record whether failure is compile, unit, simulator runtime, or fixture/environment;
4. update only `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md` and sanitized evidence;
5. stop if the failure requires a source change.

No "small Codex fix" in this round.

## 3. Build gate

From a clean checkout:

```powershell
git checkout feat/ffmpeg-analyzer-policy-phase3
git status
ohpm install
./scripts/verify.ps1
```

Required:

- architecture guards PASS;
- FFmpeg artifact guard PASS;
- all Hypium tests PASS;
- Debug/Release default HAP PASS;
- exactly the expected 9 AArch64 native libraries;
- no unexpected native library.

Then:

```powershell
./scripts/verify-simulator.ps1
```

Required:

- simulator HAP PASS;
- x86_64 `liblinkora_ffmpeg.so` present;
- real MPV/native storage SOs absent;
- automatic default dependency restoration completes.

Immediately rerun:

```powershell
./scripts/verify.ps1
```

No manual `ohpm install` between simulator verify and this default verify.

## 4. Policy unit behavior

Confirm tests cover and pass:

- LIST: complete System result stops before FFmpeg;
- LIST: partial System falls back to FFmpeg;
- DETAIL: FFmpeg unusable falls back to System;
- DETAIL: usable partial FFmpeg does not merge System fields;
- policy cancel does not start the fallback engine;
- LOCAL_DOCUMENT policy = System only;
- HLS/DASH thumbnail policy = System only;
- file-like remote thumbnail policy = FFmpeg then System.

Record final test count.

## 5. WebDAV production loader — MP4

Use the real Network page/list flow, not the Phase-2 diagnostic comparison harness.

Fixture: H.264/AAC MP4 on WebDAV.

Required:

- list opens;
- metadata appears;
- thumbnail appears;
- duration/width/height plausible;
- persistent thumbnail is WebP;
- reopen uses cache;
- active proxy sources return to zero;
- no crash.

Expected functional routing:

- LIST metadata normally resolves with System when System returns complete;
- thumbnail should use FFmpeg first.

Capture sanitized log line:

```text
Network media analysis: ...
```

Expected engines for a normal supported MP4:

- metadataEngine may be `system` or empty when metadata was already cached;
- thumbnailEngine = `ffmpeg`.

Do not collect speed/timing comparisons.

## 6. WebDAV production loader — HEVC/MKV

Use HEVC/AAC MKV.

Required:

- metadata appears;
- thumbnail appears;
- no System-only MKV thumbnail regression;
- thumbnailEngine should normally be `ffmpeg`;
- cache/reopen works;
- activeSources returns to zero.

If System LIST metadata is complete for duration/dimensions, FFmpeg metadata need not run for LIST.

This is expected policy, not a failure.

## 7. FFmpeg thumbnail fallback to System

Create a test condition where FFmpeg frame extraction fails but System can extract the same source.

Use an existing safe fixture/configuration; do not patch production code.

Required:

- FFmpeg failure does not crash list loading;
- System fallback produces thumbnail;
- resulting persistent file is WebP;
- log reports thumbnailEngine = `system`;
- source/proxy cleanup completes.

If no natural fixture can trigger this safely, mark NOT RUN. Do not alter source to force it.

## 8. Both thumbnail engines unavailable

Use an unsupported/corrupt media case.

Required:

- list remains usable;
- no crash;
- metadata can still persist if available;
- no invalid thumbnail file is persisted;
- retry/backoff behavior remains bounded;
- resources release.

## 9. Cache compatibility

Verify:

- existing metadata-only cache still works;
- existing WebP cache still loads;
- legacy JPEG read compatibility remains;
- newly generated thumbnails are WebP only;
- cache key still includes source identity + plan;
- no new JPEG fallback is written.

## 10. Cancellation / refresh

While a WebDAV file is being analyzed:

- navigate away;
- refresh directory;
- cancel/re-enter;
- repeat several times.

Required:

- no late old-generation metadata update;
- no late thumbnail inserted into a new generation;
- no fallback engine starts after policy cancellation;
- activeSources returns to zero;
- no stale UI rows.

## 11. 20-cycle loader lifecycle

Repeat 20 times:

```text
open network directory
-> allow one or more video previews
-> leave directory
-> reopen
```

Required:

- no crash/ANR;
- no persistent proxy source growth;
- no duplicate rows;
- cached thumbnails remain decodable.

This is functional lifecycle validation, not a performance benchmark.

## 12. HTTP file-like functional path

For direct HTTP/HTTPS MP4/MKV analysis where a production consumer is available:

- verify resolver proxies the file-like URL;
- no external credential-bearing URL reaches native FFmpeg;
- functional probe succeeds where supported.

If there is no user-facing production metadata consumer for this path yet, validate the policy/resolver through existing tests and mark UI/runtime production consumer as NOT APPLICABLE.

## 13. HLS / DASH

Confirm policy behavior only.

Required:

- no FFmpeg native analysis is attempted for HLS/DASH;
- existing System playback/probe behavior is unchanged;
- no attempt is made to proxy only a manifest and call that full FFmpeg support.

Use logs/tests to prove routing where available.

## 14. LOCAL_DOCUMENT

Confirm:

- existing local media flow remains functional;
- this Phase does not route LOCAL_DOCUMENT into native FFmpeg;
- no content-URI to native-path workaround was added.

Local thumbnail behavior must remain the existing System/local implementation.

## 15. Detailed FFmpeg policy contract

The generic production `PolicyMediaProbe` must functionally satisfy:

### DETAIL

file-like source:

- FFmpeg COMPLETE -> return FFmpeg;
- FFmpeg PARTIAL but usable -> return FFmpeg partial;
- FFmpeg UNAVAILABLE -> fallback System;
- never merge fields.

### ADVANCED

same rules.

Use unit tests or a target-only diagnostic invocation. There is no requirement to add a production UI for advanced metadata in this phase.

## 16. SFTP regression check

No SFTP runtime is required on x86 simulator.

Static/unit review must confirm:

- `HarmonyAnalysisInputs.openRemote()` does not pass `MediaSource.fingerprint` into the provider's `expectedFingerprint`;
- persisted SFTP trust configuration remains owned by `NetworkServerEntry.advancedOptions`.

If an arm64 SFTP target is already available, a simple open/read smoke is useful but optional.

Do not make a performance claim.

## 17. Security

Scan logs/evidence for:

- Authorization;
- Cookie;
- passwords;
- SFTP fingerprint secrets beyond intended public fingerprint value;
- proxy token;
- upstream full URL/path.

The new `Network media analysis` log must contain only:

- metadataEngine;
- thumbnailEngine;
- thumbnailPlan.

## 18. Performance exclusion

Do NOT collect or interpret:

- System vs FFmpeg latency;
- median/p95;
- CPU/GPU;
- memory ranking;
- throughput ranking;
- power;
- thermal.

Performance remains deferred to arm64 real-device testing.

## 19. Required report

Fill:

`docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

Use only:

- PASS
- FAIL
- NOT RUN
- NOT APPLICABLE
- BLOCKED

Do not call an unexecuted item PASS.

## 20. Stop condition

Stop and report immediately if:

- default build fails;
- simulator build fails;
- policy fallback violates expected order;
- cancellation starts a new engine after cancel;
- FFmpeg thumbnail cannot be encoded by common WebP encoder;
- production NetworkMediaLoader regresses;
- cache format/key behavior regresses;
- a source change would be required.

Otherwise complete all achievable functional cases, commit report/evidence only, and stop.

Do not merge.
