# FFmpeg Analyzer Production Policy Phase 3 Report

> Status: FAIL — first default verification gate.
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Codex role: test/report only; no source fixes.
> Date: 2026-10-05 (Asia/Shanghai).

## Git / Environment

- Starting/tested source SHA: `72e74d11a790bd0d258e219e3a8de18f3c59fd17`.
- Report/evidence commit: supplied in final handoff after this report is committed.
- Windows host, PowerShell7; isolated checkout `D:/Linkora-validation`; original `D:/Linkora` main untouched.
- Existing DevEco26.0.0.821, SDK26.0.0.105/API26, Hvigor6.26.4, ohpm26.0.0.630; bundled Node24.14.1.
- HDC inventory: `127.0.0.1:5557` x86 emulator available. Phase3 install/launch: NOT RUN.
- arm64 device/runtime: NOT RUN; no arm64 target in HDC inventory.
- Protected-file audit: PASS. All 791 recorded ArkTS/C++/header/profile/lock/test files have identical before/after SHA256. Git changes contain this report and sanitized evidence only.

## Build Gates

| Gate | Result | Actual evidence |
| --- | --- | --- |
| Clean branch checkout | PASS | Fetched branch; starting Git status clean |
| Initial `ohpm install` | PASS | Exit0; tracked lockfiles unchanged |
| Architecture boundaries | PASS | Existing script completion marker |
| Architecture guard fixtures | PASS | 5/5, failure0 |
| Simulator product static isolation | PASS | Existing static-check completion marker; no simulator build implied |
| FFmpeg Phase1 pure cases | PASS | 15/15 |
| Adapter/policy pure cases | PASS | 45/45, including seven new production-policy cases |
| Native artifact guard fixtures | PASS | 17/17, including unknown arm64-native rejection; these are guard fixtures, not a new HAP audit |
| First full `scripts/verify.ps1` | FAIL | Exit1 at scripts/verify.ps1:57, static ArkUI output-field check |
| Hvigor Hypium compilation/execution | NOT RUN | Verifier stopped before `hvigor test`; no prior Phase2 results reused |
| Default Debug/Release HAR/HAP | NOT RUN | Build loop not reached |
| Actual default exact9 AArch64 HAP audit | NOT RUN | No Phase3 HAP built/audited |
| `verify-simulator.ps1` | NOT RUN | Runbook section20 requires stopping on default gate failure |
| Immediate post-simulator default verifier | NOT RUN | Simulator gate not reached; no manual restore/install inserted |

## Exact Failure / Feedback

Classification: **FAIL — default verification static gate**, before ArkTS compiler, Hvigor Hypium or simulator runtime. This is not evidence of a runtime loader failure or an SDK/device failure.

Failing top-level command, from `D:/Linkora-validation` with bundled Node on PATH:

```powershell
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File scripts/verify.ps1
```

Original relevant output:

```text
D:\Linkora-validation\entry\src\main\ets\analysis\NetworkMediaAnalysisCoordinator.ets:87:    onMetadata: (durationMs: number, width: number, height: number, engine: string) => void = () => {}):
Exception: D:\Linkora-validation\scripts\verify.ps1:57
Line |
  57 |      throw 'ArkUI state management V1 usage remains.'
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | ArkUI state management V1 usage remains.
```

Verifier lines52–57 collect matches with this existing rule:

```text
^\s+(on[A-Z][A-Za-z0-9]*|load[A-Z][A-Za-z0-9]*):\s*\([^)]*\)\s*=>.*=\s*
```

Exact triggering source context, unchanged:

```typescript
async inspect(source: MediaSource, durationHintMs: number = 0,
  widthHint: number = 0, heightHint: number = 0,
  onMetadata: (durationMs: number, width: number, height: number, engine: string) => void = () => {}):
  Promise<NetworkMediaAnalysisResult> {
```

Read-only root-cause assessment: the rule scans every main ArkTS source line and matches the defaulted `onMetadata` method parameter in the service class. The triggering line is a function parameter, not an ArkUI component output-field declaration. The static rule appears to produce a false positive for this new signature. ChatGPT must review the signature/rule compatibility and authorize any source/checker change. No rename, regex adjustment, expectation change, workaround, bypass, retry or fix was applied.

The exact stdout/stderr and exit record are preserved in sanitized evidence. Per sections2 and20, further validation stopped immediately after this failure was confirmed; only read-only source/output inspection and report/evidence work followed.

## Policy Unit Semantics

These results come from the existing deterministic ArkTS-to-TypeScript pure runner loading the unchanged Hypium cases; they are **not a Hvigor Hypium run**. Total executed pure cases: Phase1 15 plus adapter/policy45, all passing.

| Case | Result | Evidence / scope |
| --- | --- | --- |
| LIST System complete stops before FFmpeg | PASS | `LIST accepts complete System result without invoking FFmpeg`; System1/FFmpeg0 |
| LIST partial System falls back to FFmpeg | PASS | `LIST falls back from partial System to complete FFmpeg without merging`; both1 |
| DETAIL unusable FFmpeg falls back to System | PASS | `DETAIL falls back to System only when FFmpeg is unusable`; both1 |
| DETAIL usable partial FFmpeg retained | PASS | `DETAIL keeps usable partial FFmpeg result and does not merge System fields`; System0 |
| No field merger | PASS | FFmpeg partial width640 retained instead of System1920; FFmpeg result provenance retained |
| Cancellation prevents fallback after active probe settles | PASS | Existing policy-cancel case; fallback calls0, numeric CANCELLED |
| LOCAL_DOCUMENT System-only order | PASS | Existing pure case checks local ADVANCED order length1/System |
| HLS/DASH System-only thumbnail order | PASS | Existing pure case checks HLS and DASH first engine System; static policy confirms single-engine arrays |
| File-like thumbnail FFmpeg then System order | PASS | Existing pure case checks first engine FFmpeg; unchanged policy source explicitly returns `[FFMPEG, SYSTEM]`. Actual fallback extraction NOT RUN |
| ADVANCED file-like primary order | PASS | Existing order case invokes ADVANCED and checks FFmpeg first |
| ADVANCED generic probe complete/partial/unavailable execution | NOT RUN | Separate execution cases not reached/added; DETAIL cases are not relabeled ADVANCED coverage |

Final Hypium count: **NOT RUN**, because the first verification gate exits before `hvigor test`. Baseline/expected counts are not substituted for an executed result.

## WebDAV Production Loader

| Required case | MP4 | HEVC/MKV |
| --- | --- | --- |
| Real Network page/list flow | NOT RUN | NOT RUN |
| Metadata/duration/dimensions | NOT RUN | NOT RUN |
| Thumbnail and engine-routing log | NOT RUN | NOT RUN |
| New persistent WebP | NOT RUN | NOT RUN |
| Reopen/cache hit | NOT RUN | NOT RUN |
| activeSources=0 / no crash | NOT RUN | NOT RUN |

Production NetworkMediaLoader overall: **NOT RUN**. No Phase2 comparison harness or old cached HAP was used as a substitute for this production-flow test.

## Thumbnail Fallback / Unavailable

- Natural fixture triggering FFmpeg failure with successful System fallback: NOT RUN.
- FFmpeg frame → common WebP → persisted cache: NOT RUN.
- System fallback `thumbnailEngine=system` / persisted WebP / cleanup: NOT RUN.
- Both engines unavailable/corrupt case, usable list, retained metadata, invalid thumbnail absence, bounded retry/backoff and resource release: NOT RUN.
- No production source was patched to force a failure or alter test expectations.

## Cache Compatibility

Existing metadata-only cache, existing WebP, legacy JPEG reads, new WebP-only writes, source+plan key, and JPEG-fallback absence: **NOT RUN**. Cache regression scripts later in the verifier were not reached. No new cache compatibility claim is made from prior Phase2 evidence.

## Cancellation / Refresh / 20-cycle Lifecycle

- Navigate-away, refresh, cancel/re-enter while real WebDAV analysis is active: NOT RUN.
- Old-generation metadata/thumbnail rejection and stale-row checks: NOT RUN.
- Production fallback-after-cancel / final activeSources: NOT RUN.
- 20-cycle directory open/preview/leave/reopen: NOT RUN, cycles0.
- Crash/ANR, duplicate rows, proxy source growth and cached-frame decode across cycles: NOT RUN.
- Passing pure cancellation cases above prove only their tested deterministic policy/adapter behavior, not production runtime lifecycle.

## HTTP / HLS / DASH / LOCAL_DOCUMENT

- HTTP file-like production-consumer applicability: NOT RUN; build stop occurred before consumer/runtime validation. Existing resolver pure cases ran PASS, including owned HTTP/remote proxy leases and unsafe credential-bearing link rejection.
- HTTP native boundary/real functional probe: NOT RUN.
- HLS/DASH runtime native-attempt audit, existing System playback/probe regression: NOT RUN. Pure thumbnail policy checks PASS; no new manifest-proxy support was added by this test-only run.
- LOCAL_DOCUMENT existing local UI/thumbnail flow: NOT RUN. Pure System-only order PASS; no content-URI/path workaround or source edit made in this run.

## SFTP Semantics

- Media fingerprint no longer supplied as provider host-key fingerprint: **PASS — read-only static check**. `HarmonyAnalysisInputs.ets:26` calls `directory.openSource(source.locator)` with no media/cache fingerprint argument.
- Persisted trust remains owned by server advanced options: **PASS — read-only static check**. `DefaultNetworkStorageProviders.ets:95–99` uses `options.expectedFingerprint || this.server.advancedOptions.sftpFingerprint`; `SftpBrowserService.ets:106–111` retains persisted fingerprint and strict host-key policy.
- SFTP runtime, new SFTP-specific unit execution and optional arm64 open/read: NOT RUN. Static inspection is not reported as an SFTP connection/read success.

## Security

- New log formatter: **PASS — read-only static fields inspection**, `NetworkMediaLoader.ets:265–269` emits only `metadataEngine`, `thumbnailEngine`, `thumbnailPlan` property names. No runtime value-safety claim.
- Existing pure adapter diagnostic-redaction assertions: PASS in 45-case runner.
- Actual Phase3 production log scan for Authorization/Cookie/password/proxy token/full upstream locator/SFTP secret leakage: **NOT RUN**. New production HAP not built/launched; old process logs were not substituted.
- Committed build evidence contains source/checker paths and pure case names only; no credentials, signing material, proxy URL/token or upstream media locator.

## Performance Scope

System-vs-FFmpeg latency, median/p95, CPU/GPU, memory/throughput rankings, power/thermal comparisons and performance-policy judgments: **NOT RUN**. No benchmark NDJSON/report produced. Incidental command/test-runner durations in original stdout are preserved only as original output; no engine timings were collected or compared. Performance remains deferred to arm64 device.

## Failures / Feedback

| Area | Status | Exact evidence | Source/checker change required? |
| --- | --- | --- | --- |
| First default verification gate | FAIL | Coordinator method parameter line87 matches verifier line53 regex; exit1 at line57 | BLOCKED pending ChatGPT review; would require reviewed source or verification-rule change; none applied |
| All subsequent build/runtime gates | NOT RUN | Runbook section20 stop condition | Do not bypass the failing gate |

## Evidence / Decision

Evidence directory: `test-lab/analyzer-policy/phase3/` — exact failing stdout/stderr, command/exit/source SHA, dependency install output, unchanged-source hash audit and exact source/rule context.

**FAIL — BUILD**. The first gate did not pass; Phase3 functional validation is incomplete. Stop condition reached. Report/evidence only committed; no ArkTS/C++/profile/lock/test-expectation modifications, no fixes, no merge. Hand back to ChatGPT architecture review before any further execution.

## Execution ledger

1. Fetched and checked out clean source `72e74d1`; latest test-only runbook read completely.
2. Recorded791 protected file hashes; normal `ohpm install` exit0, tracked lockfiles unchanged.
3. Executed full `verify.ps1`; existing architecture/pure/artifact guard checks passed before static rule failure, exit1. No full-verifier completion marker.
4. Stopped later gates/runtime; inspected original failure and method/regex context read-only. Policy/SFTP/log static observations separated from runtime claims.
5. Protected hash audit after testing: changed0. Only report and sanitized evidence prepared for commit; no source fix or rerun.
