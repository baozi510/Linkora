# FFmpeg Analyzer Production Policy Phase 3 Report

> Status: REVIEWED — second rerun stopped at desktop harness alias resolution; harness/lifecycle corrections committed; fresh validation required.
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Codex role: test/report only; no source fixes.
> Date: 2026-10-05 (Asia/Shanghai).


## Architecture review after second validation stop

Review date: 2026-10-05.

Ruling:

- The rerun correctly proved the previous ArkUI guard fix: that gate passed.
- The new failure occurs before Loader/cache assertions because the desktop VM loader does not implement Harmony target alias resolution for `entry/AnalysisComposition`.
- Production `NetworkMediaAnalysisCoordinator` is target-composed by design; changing production imports to satisfy this desktop VM would be the wrong layer.
- `check-network-media-list.cjs` is a Loader/cache/lifecycle regression harness, so it now mocks `NetworkMediaAnalysisCoordinator` at that boundary. Analyzer policy/adapters remain independently exercised by the 45-case pure suite.
- While reviewing the old Loader regression coverage, Phase 3 was found to have dropped the prior `setupSettled` wait when remote opening moved into `HarmonyAnalysisInputs`. The production input adapter now captures `NetworkDirectoryService.openSource(..., setupObserver)` and awaits late native setup cleanup on failure before the loader queue can advance.
- The call passes an explicit empty per-open fingerprint override. It still never passes `MediaSource.fingerprint`; persisted SFTP trust remains in `NetworkServerEntry.advancedOptions.sftpFingerprint`.
- A cancelled coordinator generation must not publish a late partial result. The desktop regression expectation is updated to assert that behavior instead of the old pre-Phase-3 partial-after-timeout behavior.
- No performance policy, playback routing, field merger, Direct I/O, or protocol-specific FFmpeg path was introduced.

All gates after the recorded second stop remain NOT RUN. A fresh validation task is required.


## Post-review rerun — 2026-10-05

Tested source: `81ed0684b273e25afbed056a055ee23aded0b661` on `feat/ffmpeg-analyzer-policy-phase3`, fetched and fast-forwarded to the user-specified reviewed commit. Clean checkout confirmed before dependency install. Original `D:/Linkora` has unrelated uncommitted main changes and is preserved; execution uses `D:/Linkora-validation`.

All seven requested baseline/runbook/report documents were read completely, including SESSION_HANDOFF CURRENT STATE and its approved non-merging Phase 3 interpretation. Historical results below remain historical only.

- Normal `ohpm install`: PASS, exit 0; tracked lockfiles unchanged.
- Fresh full default `scripts/verify.ps1`: FAIL, exit 1 at `scripts/verify.ps1:77`; network-media-list desktop harness fails before Hvigor.
- Simulator/default consecutive verification and all production runtime cases: NOT RUN, runbook section 20 stop condition.
- Initial HDC inventory: `[Empty]`; no emulator/device was started, installed, launched, hidden or closed during this rerun. This did not cause the default gate failure.
- No production, test expectation, profile, lockfile or business-policy edits permitted or applied.
- Fresh evidence: `test-lab/analyzer-policy/phase3/rerun-81ed068/`. Historical first-run evidence is preserved separately and is not reused as rerun PASS.

### Fresh gate results

| Gate | Result | Evidence from this rerun |
| --- | --- | --- |
| Clean checkout / requested source SHA | PASS | Git status empty; HEAD exactly `81ed0684b273e25afbed056a055ee23aded0b661` |
| Normal dependency resolution / tracked locks | PASS | `ohpm install` exit 0; protected audit and Git show no lock changes |
| Architecture boundary checks | PASS | Fresh completion marker |
| Architecture guard fixtures | PASS | 5/5, failure 0 |
| Simulator product static isolation | PASS | Fresh parity/isolation completion marker; no simulator build implied |
| FFmpeg pure tests | PASS | 15/15 |
| Analyzer adapter/policy pure tests | PASS | 45/45; fresh execution, not old results |
| Native artifact guard fixtures | PASS | 17/17; these are fixture tests, not actual HAP audits |
| ArkUI migration/static guard | PASS | Full verifier proceeded into subsequent persistence checks; old callback false positive did not recur |
| Persistence regression | PASS | Desktop SQLite completion marker; injected rollback errors are expected test cases |
| HTTP range / System probe regression harness | PASS | Four existing PASS markers, including stalled cleanup watchdog |
| Network media list/cache regression | FAIL | ENOENT during module load, before `check()` cache/loader assertions |
| MPV event mapping regression | NOT RUN | Next verifier command after failed list/cache gate |
| Actual Hvigor Hypium compilation/execution | NOT RUN | `hvigor test` was not reached; executed Hypium count 0 |
| Full default verifier | FAIL | Exit 1; no overall completion marker |
| Simulator verify / automatic dependency restoration | NOT RUN | Default stop condition |
| Immediate default verify after simulator | NOT RUN | No simulator gate attempted; no intervening manual install |

### Fresh build matrix

| Artifact | Debug | Release |
| --- | --- | --- |
| linkora_core default HAR | NOT RUN | NOT RUN |
| linkora_proxy default HAR | NOT RUN | NOT RUN |
| linkora_media_probe default HAR | NOT RUN | NOT RUN |
| linkora_ffmpeg default HAR | NOT RUN | NOT RUN |
| entry default arm64 HAP | NOT RUN | NOT RUN |
| default exact-nine AArch64 native set / ABI audit | NOT RUN | NOT RUN |
| entry simulator x86_64 HAP / native whitelist audit | NOT RUN | NOT RUN |

No existing generated binary or old Hypium result was accepted as this source's build/runtime evidence.

### Exact new failure / minimal reproduction

Tested source: `81ed0684b273e25afbed056a055ee23aded0b661`.

Actual full command executed in `D:/Linkora-validation`, with DevEco bundled Node on PATH:

```powershell
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File scripts/verify.ps1
```

Actual invocation was captured by the existing ignored `artifacts/build-isolation/run-stage.ps1` wrapper; it launches that unmodified full script with redirected original stdout/stderr. Exit code 1. No Debug checkpoint was reached. UTC timestamps and wrapper details are in the evidence JSON.

The first failing nested command is:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' scripts/check-network-media-list.cjs
```

This is the minimal standalone reproduction command extracted from the actual failing invocation; it was not rerun after the stop condition. The full verifier already executed it once.

Original key error:

```text
Error: ENOENT: no such file or directory, open 'D:\Linkora-validation\entry\AnalysisComposition.ets'
    at Object.readFileSync (node:fs:440:20)
    at load (D:\Linkora-validation\scripts\check-network-media-list.cjs:93:38)
    at D:\Linkora-validation\scripts\check-network-media-list.cjs:97:13
    at D:\Linkora-validation\entry\src\main\ets\analysis\NetworkMediaAnalysisCoordinator.ets:5:31
    at load (D:\Linkora-validation\scripts\check-network-media-list.cjs:96:96)
    at D:\Linkora-validation\scripts\check-network-media-list.cjs:97:13
    at D:\Linkora-validation\entry\src\main\ets\services\NetworkMediaLoader.ets:9:43
    at load (D:\Linkora-validation\scripts\check-network-media-list.cjs:96:96)
    at check (D:\Linkora-validation\scripts\check-network-media-list.cjs:134:34)
Exception: D:\Linkora-validation\scripts\verify.ps1:77
Network media list/cache regression checks failed.
```

Root cause confirmed by read-only source tracing: coordinator source line 17 imports the target-specific alias `entry/AnalysisComposition`. The desktop loader at lines 87–97 checks its `kits` map, appends `.ets`, then reads unmatched non-relative imports directly as filenames. The unchanged harness has no `entry/AnalysisComposition` alias/mock mapping, so it reads the absent root file instead of resolving the target implementation. Both actual files exist at `entry/src/default/AnalysisComposition.ets` and `entry/src/simulator/AnalysisComposition.ets`; their current bytes are identical. VM stack line 5 is a transpiled location, not original ArkTS source line 17.

Classification: FAIL — desktop regression-harness/module-resolution compatibility. This is not an ArkTS compiler failure, native load failure, production runtime failure, or missing SDK/device diagnosis. A reviewed test-harness/source change is required to pass this gate; Codex applied none. No alias shim, new file, mock substitution, test-expectation change, gate bypass or retry was used. Potential later assertions are unknown and must be tested after ChatGPT's reviewed correction.

### Fresh policy coverage / runtime exclusions

The 45-case pure runner freshly passed the seven production-policy cases, including LIST System COMPLETE/no FFmpeg; LIST PARTIAL fallback without merge; DETAIL unusable fallback; DETAIL usable PARTIAL/no merge; cancellation with zero later fallback calls; System-only local/playlist order; and FFmpeg-first file-like DETAIL/ADVANCED order. These are desktop pure tests, not Hvigor Hypium or production UI tests. ADVANCED COMPLETE/PARTIAL/UNAVAILABLE generic execution remains NOT RUN; DETAIL execution is not relabeled ADVANCED evidence.

| Functional area | Result / scope |
| --- | --- |
| WebDAV MP4 production Network page → loader → coordinator flow | NOT RUN |
| WebDAV HEVC/MKV production flow | NOT RUN |
| Production duration/dimensions/metadataEngine/thumbnailEngine | NOT RUN |
| FFmpeg frame → common WebP encoder → persistent cache / reopen | NOT RUN |
| Natural FFmpeg thumbnail failure → real System success | NOT RUN |
| Both thumbnail engines failed / retained metadata / bounded backoff | NOT RUN |
| Legacy JPEG, metadata-only and WebP cache runtime compatibility | NOT RUN; list/cache harness failed before assertions |
| Navigate-away, refresh, generation/stale-result rejection | NOT RUN |
| Production fallback-after-cancel and final activeSources | NOT RUN |
| 20-cycle directory lifecycle | NOT RUN, cycles 0 |
| HTTP production consumer applicability and real resolver/native boundary | NOT RUN |
| HLS/DASH System-only native-attempt runtime audit | NOT RUN; pure policy case PASS only |
| LOCAL_DOCUMENT UI/System thumbnail runtime | NOT RUN; pure order case PASS only |
| SFTP / SMB / FTP / NFS connection/open/read runtime | NOT RUN |
| Production security-log scan | NOT RUN; no fresh HAP installed/launched |
| System / MPV / Auto playback runtime | NOT RUN; outside reached gates |
| Benchmark / performance ranking | NOT RUN, prohibited this round; no NDJSON/report |

MediaProxy diagnostics: real runtime NOT RUN; no activeSources/Range/bytes counters from this rerun. Pure resolver/cleanup assertions passed inside the existing 45-case suite, but do not prove production proxy cleanup.

### Evidence integrity / stop decision

Protected pre/post audit covers 863 tracked source, header, type, package/lock, build-profile, Hvigor, CMake and script files. Changed files: 0. No production edits, test edits, strategy changes, merge or new-stage work.

Raw stdout/stderr, command/exit record, install result, exact numbered failure context and fresh protected hashes are retained in the rerun evidence directory. Evidence is inspected for credential, Authorization/Cookie value, proxy token and sensitive upstream locator leakage before commit. Incidental existing runner durations are original command output only; no System-versus-FFmpeg metrics were collected or compared.

Final rerun decision: FAIL, with later work NOT RUN under runbook section 20. Acceptance is BLOCKED pending ChatGPT review of the new harness failure. **Not READY FOR PHASE 3 ARCHITECTURE ACCEPTANCE.** Only report and sanitized evidence are committed. Stop and await review.

### Historical first execution / architecture ruling

Everything below is preserved history for source `72e74d1` and its architecture review; the current rerun results and stop decision are above. Historical PASS statements are not included in the current rerun's evidence.

Review date: 2026-10-05.

Ruling:

- The Codex run correctly stopped and reported rather than patching source.
- The triggering `onMetadata` text is a service method parameter, not an ArkUI V1 output field.
- The verifier rule itself was over-scoped because it applied the plain `onX/loadX` output-field regex to every `entry/src/main/ets/**/*.ets` file.
- The reviewed fix keeps legacy ArkUI-state scanning across main ArkTS, but scopes the plain output-field regex to `entry/src/main/ets/components` and `entry/src/main/ets/pages`.
- No production analyzer behavior was changed to satisfy the gate.
- SFTP fingerprint ownership was re-reviewed: `HarmonyAnalysisInputs` does not forward media/cache fingerprint; `SftpStorageProvider` / `SftpBrowserService` use persisted `NetworkServerEntry.advancedOptions.sftpFingerprint` when no explicit trusted fingerprint is provided.
- Phase 3 policy remains a functional routing stage. It does not claim benchmark-derived optimality and does not implement a System+FFmpeg field merger.
- Because source/checker changed after the recorded run, all later build/runtime items remain NOT RUN until a fresh validation from the new HEAD completes.

Next acceptance action: rerun this Phase 3 validation manual from a clean checkout of the new branch HEAD. Do not combine old partial results with the new run to manufacture a full PASS.

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
