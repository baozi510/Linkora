# FFmpeg Analyzer Production Policy Phase 3 Report

> Status: RUNTIME VALIDATION BLOCKED — LOCAL_DOCUMENT THUMBNAIL ACCEPTANCE; network core and 20-cycle PASS. Prior build/static/pure PASS remains separate.
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Codex role: test/report only; no source fixes.
> Date: 2026-10-06 (Asia/Shanghai).

## Current runtime validation — phase3-runtime-acceptance-1-mate60-webdav (2026-10-06)

**Decision: BLOCKED — LOCAL_DOCUMENT THUMBNAIL ACCEPTANCE.** Network production acceptance passed in the declared scopes; full Phase 3 architecture acceptance is not claimed pending the local-thumbnail ruling.

- Implementation source: `44d0f62816b73ebd3bab8069be5b74f51e2c6999`.
- Reviewed runtime source: `4ced68f1b5cae7000ce9a24183d4a1d1b1c747a8`; actual tested HEAD: `30c19502aa06e82b4fe75624c9f0d817fd36eb6d`.
- Repository/branch: `baozi510/Linkora`, `feat/ffmpeg-analyzer-policy-phase3`; isolated checkout `D:/Linkora-runtime-phase3`.
- Fresh fetch/clean-state/ancestor checks pass; runtime-source->HEAD changes only `docs/CODEX_VALIDATION_TASK.md`. All ten required documents completely read, SESSION_HANDOFF CURRENT STATE first.
- Evidence: [runtime-acceptance-1-mate60-webdav-20261006](../test-lab/analyzer-policy/phase3/runtime-acceptance-1-mate60-webdav-20261006/).
- Target: real Mate60, arm64-v8a/aarch64, API 26, HDC 3.2.0f; private device identity omitted.

### Fresh artifact and source provenance

Exactly one normal DevEco bundled `ohpm install` succeeded. Only four task-allowlisted locks acquired CRLF; normalized Git blobs, normalized bytes and line contents equal HEAD. Exact locks restored after strict proof; clean, no reinstall. Generated pinned arm64 FFmpeg inputs were reused as dependency inputs only and freshly checked: four archive hashes/all-member AArch64 checks and exact manifest pin `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`; no old HAP or runtime PASS reused.

A temporary signing-only overlay reused the user's existing local references read-only. Only root `build-profile.json5` changed; canonical comparison proved every non-signing semantic unchanged, material references existed, and default selected the config. Overlay SHA-256: `5143AE29AFDA4A20ECECCDD7495E1B1759FD40A77A0312BBCFD63F97E04E9F6C`; no raw signing diff/material/secret path published.

Actual build: DevEco `tools/hvigor/bin/hvigorw.bat assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon`, once, exit 0 (UTC 08:04:03–08:05:40). Fresh `entry-default-signed.hap`, 64,492,731 bytes, SHA-256 **`A6141D058B29A569546D53A34876C8C25F469561D89ED1DF638788D7A1E574C4`**. Existing checker on that exact signed HAP passed: exactly nine native libraries, all AArch64; individual native hashes/ELF machine 183 recorded. Bundle `com.linkora.player`, version `0.1.0`. Signing overlay restored to HEAD before runtime cases, checkout clean. Explicit `hdc install -r <exact hashed HAP>` succeeded; no uninstall or app-data reset. EntryAbility launched and process Hilog readable.

No `verify.ps1`, simulator verifier, Hypium or green build matrix rerun. Reviewed 3g build/static/pure evidence `e95feef35fa2541322216f9ce9336da3cad9060f` remains distinct historical acceptance, not fresh runtime execution.

### Human-directed fixture environment and preflight

The user paused initial form automation before a media case was executed, then explicitly supplied a replacement HTTPS WebDAV and authorized SSH fixture preparation under a media directory. This overrides only the task's prepared local endpoint, not source/build/permissions/test assertions or stop conditions. Original developer workspace and pre-existing media/server entries were preserved.

A new isolated child directory holds separate MP4, MKV, corrupt and cancellation folders. MP4/MKV/corrupt hashes match the controlled synthetic corpus; cancellation copy is identical to MP4. Normal TLS validation remained enabled. Authenticated PROPFIND returned 207; Range GET returned 206. No claim is made that the external account itself is read-only; test clients used read operations only, with authorized filesystem fixture creation via SSH. Full endpoint, credentials and SSH/device identities are withheld.

The human saved the test server using the normal app form and confirmed browse; independent SDK UI capture showed all four folders on the freshly installed app. App-side transport preflight PASS. Earlier interrupted/unsaved form activity and one coordinate click on a changed screen executed no media case and supply no PASS. Subsequent actions used fresh UI layouts. UI-helper target/encoding issues before actions/cycles were retained locally and did not cause a source/expectation change or erase an application gate failure.

### Runtime results

| Case | Result | Fresh evidence/limits |
| --- | --- | --- |
| R01 MP4 cold | PASS | Controlled new server/path; UI 0:20/720P and test-pattern thumbnail; safe log metadataEngine=system, thumbnailEngine=ffmpeg, plan 4000:480:270:80:1; persisted WebP 7,102 bytes, decoded 480x270 |
| R02 MP4 reopen | PASS | Correct metadata/preview, same persistent size+mtime, no new analysis completion observed |
| R03 HEVC/AAC MKV cold + reopen | PASS | UI 0:20/720P, FFmpeg thumbnail log, plan 4004:480:270:80:1; persisted WebP 7,000 bytes, decoded 480x270; reopen same size+mtime |
| R05 corrupt/both unavailable | PASS | Usable 37-byte file row, correct placeholder, no invalid thumbnail/new JPEG; three rapid view rebindings within 30-second backoff produced no new System failure event; list responsive |
| R06 cancel/refresh/stale generation | PASS in observed behavior | Rapid cold entry/Back left parent with only four folders and no new thumbnail; rapid leave/re-enter/pull refresh then single correct preview, no late visible fallback/stale row/crash. Native fallback-start trace unavailable; refresh was not proved before analysis completion, that subcase NOT RUN |
| R07 lifecycle | PASS, 20/20 | Exactly twenty fresh open-server/open-MP4/stable-preview/leave-folder/leave-page cycles; metadata correct, one media row, rendered test-pattern pixels, no late row after leave; same process, no observed crash/ANR; cache remained usable and unchanged |
| R10 LOCAL_DOCUMENT | BLOCKED for thumbnail acceptance | System DocumentViewPicker selected the controlled MP4; import and 0:20/720P metadata PASS; normal local playback rendered the fixture, showed 1280x720, and completed at 0:20. System metadata FileDescriptor API observed. List thumbnail remains placeholder; see ruling request below |

Direct production proxy counters: **NOT RUN — NO PRODUCTION DIAGNOSTIC ENDPOINT**, as explicitly permitted by this task. No instrumentation/reflection or independent smoke counter substituted. Cleanup conclusions use real UI/lifecycle/process/cache evidence and retain this visibility limit.

Optional/unavailable: natural FFmpeg->System successful-thumbnail fallback NOT RUN (no safe natural fixture); HLS/DASH NOT RUN (no prepared streaming fixture); target-native ADVANCED NOT RUN (no existing authorized diagnostic entry); SFTP NOT RUN (no prepared app-side credential/trust fixture); legacy JPEG compatibility NOT RUN (no safe existing JPEG fixture). No benchmark/performance rankings collected.

### Cache/metadata evidence and local-thumbnail ruling request

Actual module cache is `<context.cacheDir>/network-thumbnails/<test-server>/<key>.webp`; physical inspection resolved the **entry module** cache directory. An earlier app-level cache-path probe was incorrect and is not used as a cache verdict. Current test cache ended with three WebPs (MP4, MKV, cancellation copy), no corrupt thumbnail. MP4 file size+mtime remained unchanged after twenty cycles; JPEG counts in inspected current/compatibility areas were zero. WebP file hashes/decode dimensions are published, raw private app data is not.

The app RDB uses `encrypt: true`. Stock readonly sqlite reported `file is not a database`; this is an observer limitation, not proof of corruption. No dump/decryption bypass. Available metadata is verified through normal page reopen/UI; exact RDB fields were not independently extracted.

The controlled local document is imported and plays normally, but its list image remains a placeholder. Read-only `LocalMediaThumbnailLoader.fetch()` queries PhotoAccessHelper assets by URI and returns null for unavailable assets; it has no DocumentViewPicker frame-extraction fallback. That file is unchanged at the dispatched implementation. This supports an existing document-thumbnail limitation and does **not** establish a new Phase 3 regression. Because the runtime manual requires existing System/local thumbnail behavior to remain functional, Codex leaves the local-thumbnail acceptance unresolved rather than silently relaxing that criterion or calling the placeholder a generated thumbnail. GPT must decide whether this existing limitation is outside the exact smoke contract, requires an explicit task clarification, or warrants a source fix and fresh dispatch. No local/native-path workaround, source fix, expectation change or rerun after this ruling request.

### Integrity, security and handoff

All 2,204 pre-recorded tracked regular files remain byte-identical before report publication, three Gitlinks pinned; checkout clean after overlay restore. Original dirty `D:/Linkora` stays on main with the same HEAD/status/diff hashes before/after, including read-only signing access. No production/test/task/profile/manifest/CMake/semantic-lock change is committed.

Evidence value scan finds no provided passwords/private endpoint/SSH host/device ID or signing material. Raw private layouts, phone screenshots/status bars, full Hilog, signing diff, keys, signed HAP and app database remain local/ignored. Published routing logs contain the safe engine/plan fields; selected native System lifecycle lines are sanitized. Incidental command timestamps are not performance measurements.

Only this report and the new evidence directory are authorized outputs. Commit/push without force or merge; re-fetch and verify remote evidence containment before handoff. Return the remotely visible evidence SHA separately; the commit cannot contain its own SHA. Final decision remains **BLOCKED — LOCAL_DOCUMENT THUMBNAIL ACCEPTANCE**, with remote/network results preserved for review. Do not merge or begin another phase.

## GPT review after phase3-rerun-3g

Review date: 2026-10-05.

Independent decision:

- There is no failed build/static/pure gate in the fresh 3g evidence.
- The typed `HarmonyAnalysisInputs` correction is validated by successful ArkTS compilation twice, zero `arkts-limited-throw` matches, and the existing cleanup/cancellation regression coverage.
- Both prescribed default verifiers pass around the simulator verifier, with no manual package reinstall between simulator and immediate default.
- Hypium is 209/209 PASS in both default runs.
- Required HAR/HAP builds and exact-nine AArch64 ABI audits pass in both default runs; simulator whitelist/ABI also passes.
- Desktop Loader/cache/lifecycle, MPV mapping, policy suites and supplemental ADVANCED/error-boundary checks pass in their declared scopes.
- Protected-file, EOL, submodule and security audits support the run's integrity.

This is sufficient to mark **Phase 3 build/static/pure acceptance PASS**.

It is **not sufficient for full production runtime/architecture acceptance**. The repository runbook explicitly requires real production Loader/coordinator and media cases where a target is available, and this run had `hdc list targets = [Empty]` both before and after testing. Runtime cycles were zero.

No production source/test/build correction is justified by this evidence.

The next action is an environment gate, not another build rerun: obtain a connected HarmonyOS target and a deployable test setup with the required media fixtures, then dispatch a runtime-focused validation task. Until those prerequisites exist, the fixed Codex task must remain non-READY so Codex does not repeatedly reproduce the same environment block.

The current 3g evidence below remains authoritative for build/static/pure acceptance.

## GPT runtime-readiness review — 2026-10-06

The environment is now sufficient to dispatch a targeted Phase 3 production runtime validation.

Reviewed facts:

- a real Mate60 ARM64 target is connected and HDC/Hilog access works;
- the clean runtime checkout is isolated from the dirty developer workspace;
- required MP4/MKV/corrupt fixtures are prepared with local hashes;
- an isolated authenticated read-only WebDAV fixture service is reachable from the target through HDC reverse port forwarding;
- device-side authentication/DAV listing has been confirmed;
- DevEco development signing is available, but the already-installed Linkora package has unknown source provenance.

Artifact-provenance ruling:

- the existing installed app must not be used for acceptance;
- the runtime task must build a fresh signed default/debug arm64 HAP from the dispatched checkout;
- a local uncommitted `build-profile.json5` signing-only overlay is permitted under the strict manual rules;
- the signed HAP hash and explicit install action establish the artifact link;
- the signing overlay must be restored and the checkout clean before evidence publication.

Cleanup-observability ruling:

- `NetworkFileProxy.diagnostics()` exists but the current production app exposes no external path to the shared proxy instance;
- Phase 3 runtime validation must not add instrumentation only for counters;
- direct `activeSources/activeClients` is therefore optional/NOT RUN when no existing endpoint is available;
- cleanup remains a mandatory behavioral requirement through cancellation/stale UI, leave/re-enter, corrupt-media recovery, 20-cycle stability, cache usability and crash/ANR evidence.

This readiness review does not itself execute any runtime acceptance case and does not alter the prior 3g PASS/BLOCKED evidence.

## Latest reviewed build/static validation — phase3-rerun-3g-typed-analysis-error

This section preserves the reviewed 3g build/static run. It supplies no freshly executed runtime PASS for the Mate60 round above. All following review/validation sections are historical and provide no PASS for 3g.

- Repository/branch: `baozi510/Linkora`, `feat/ffmpeg-analyzer-policy-phase3`.
- Validation source SHA: `44d0f62816b73ebd3bab8069be5b74f51e2c6999`.
- Actual checkout SHA: `d27845a7dfe26f074756fd8ce76c561b0ecdc952`.
- Fresh independent clone: `D:/Linkora-validation-phase3-3g-20261005`, origin `https://github.com/baozi510/Linkora.git`.
- Fresh evidence: [rerun-3g-typed-analysis-error-20261005](../test-lab/analyzer-policy/phase3/rerun-3g-typed-analysis-error-20261005/).
- Fresh fetch, branch/clean-state check and source ancestor check pass; source-to-HEAD drift is exactly the permitted `docs/CODEX_VALIDATION_TASK.md`. All nine required documents completely read in dispatch order, SESSION_HANDOFF CURRENT STATE first (`required-reading.json`).
- Original dirty `D:/Linkora` stays on main at `ef6ee820a6d010f4ee63a1c0a14c646a717eaa17`. Before/after status SHA256 `648A0D596918685CDA16A5E9CA8102F289C5C21D4838C4646C54240652512DE4` and tracked binary-diff SHA256 `2F10CDD611132E2170F8466E5CBB3E136A44BFB06F0312A01E48DB73FEEBC9E2` match. No write/stash/reset/clean/restore/checkout there (`user-workspace-proof.json`).

### Commands, dependency inputs and strict EOL recovery

Preparation and execution used only the new clone; captures initially lived in ignored `artifacts/phase3-rerun-3g`.

| Command/check | Exit | Fresh result |
| --- | --- | --- |
| Exact-branch independent `git clone --single-branch --branch feat/ffmpeg-analyzer-policy-phase3 https://github.com/baozi510/Linkora.git D:\Linkora-validation-phase3-3g-20261005` | 0 | New clean checkout |
| `git fetch origin feat/ffmpeg-analyzer-policy-phase3` | 0 | Dispatch SHA above |
| `git merge-base --is-ancestor 44d0f62816b73ebd3bab8069be5b74f51e2c6999 HEAD` | 0 | Source ancestor |
| `git diff --name-only 44d0f62816b73ebd3bab8069be5b74f51e2c6999..HEAD` | 0 | Task file only |
| `git submodule update --init --recursive` | 0 | Pinned native Gitlinks initialized |
| `node --version`; `ohpm --version` | 0 | `v24.14.1`; `26.0.0.630` |
| Normal `ohpm install` | 0 | Exactly once; four EOL-only lock changes |
| Initial strict proof, `git diff --exit-code -- <allowed locks>`, exact affected-lock restore | 0 | All proofs pass; clean, no reinstall |
| `pwsh -NoProfile -File scripts/verify.ps1` | 0 | First complete unmodified default invocation |
| `pwsh -NoProfile -File scripts/verify-simulator.ps1` | 0 | Exactly once; automatic default dependency restore completes |
| Post-simulator strict proof and exact affected-lock restore | 0 | Same proven EOL-only case; clean; no manual install |
| Immediate `pwsh -NoProfile -File scripts/verify.ps1` | 0 | Exactly once after simulator; no manual ohpm between |
| Bundled Node `artifacts/phase3-rerun-3g/functional-check.cjs` | 0 | Supplemental read-only desktop checks 10/10 |
| SDK `hdc list targets`, initial/final | 0 | Both `[Empty]` |
| Protected/submodule audit | 0 | 1,997 regular files unchanged; three Gitlinks clean/pinned |

PowerShell `7.6.6`; DevEco bundled Node/ohpm directories prepended to process PATH. Official scripts manage SDK/Java. No dependency flags, gate substitution, source/test edits or retries. The two default invocations are the exact prescribed sequence, not retries of a failed gate.

Only generated FFmpeg dependency inputs were reused from `D:/Linkora-validation/third_party/ffmpeg/prebuilt`. Both ABI manifests freshly match pin `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, ABI, four libraries and disabled programs/encoders/muxers/hwaccels. Eight archive hashes and all-member ELF machine checks pass (AArch64/X86-64). Provenance/manifests are captured. This is dependency reuse, not fresh bootstrap builds; no old HAP/HAR or old test results were reused.

Both the initial install and the official simulator script's automatic `ohpm install` rewrite only `entry/oh-package-lock.json5`, `linkora_ffmpeg/oh-package-lock.json5`, `linkora_proxy/oh-package-lock.json5`, `oh-package-lock.json5`. In each occurrence every normalized Git blob equals HEAD, CRLF→LF worktree bytes equal raw HEAD bytes, line contents match, EOL is `i/lf w/crlf attr/text eol=lf`, no additional protected byte changes, and semantic diff exit is 0. Thus dependency/version/checksum/graph/comment/content are unchanged. Restore occurs only after all proofs; exact affected paths return clean. No semantic lock edit/commit or manual reinstall. Post-simulator recovery takes place after the official script completed its own checks and automatic restoration, so no official check is bypassed. Initial proof is in `eol-proof.json`/`eol-restore.json`; second proof under `post-simulator-eol/`. Its installCount=1 describes the official automatic restore invocation, distinct from the single initial normal install.

### Fresh complete build gates

| Gate | First default | Immediate default | Scope |
| --- | --- | --- | --- |
| Architecture boundaries/fixtures | PASS, 5/5 | PASS, 5/5 | Fresh markers and zero failures |
| Simulator static isolation | PASS | PASS | Shared product parity guard |
| FFmpeg pure suite | PASS, 15/15 | PASS, 15/15 | Desktop pure |
| Analyzer adapter/policy pure suite | PASS, 45/45 | PASS, 45/45 | Desktop pure |
| Native artifact fixtures | PASS, 17/17 | PASS, 17/17 | Synthetic fixtures |
| ArkUI guard/persistence | PASS | PASS | Desktop SQLite; injected rollback failures expected |
| HTTP range/System probe harness | PASS | PASS | Four normal completion markers |
| Whole Loader/cache/lifecycle harness | PASS | PASS | Both normal completion markers; mocked coordinator/image/native boundaries |
| MPV event mapping | PASS, 5/5 | PASS, 5/5 | Desktop mocks |
| Actual Hvigor ArkTS unit compilation | PASS | PASS | `UnitTestArkTS` completed |
| Actual Hypium execution | PASS, 209/209 | PASS, 209/209 | Failure 0, Error 0, Ignore 0; separate raw results |
| `arkts-limited-throw` regression | PASS | PASS | Zero matches in fresh stderr; compilation succeeds |
| Full final completion marker | PASS | PASS | Verifier exit 0, original marker present |

| Artifact/check | First Debug | First Release | Immediate Debug | Immediate Release |
| --- | --- | --- | --- | --- |
| linkora_core default HAR | PASS | PASS | PASS | PASS |
| linkora_proxy default HAR | PASS | PASS | PASS | PASS |
| linkora_media_probe default HAR | PASS | PASS | PASS | PASS |
| linkora_ffmpeg default HAR | PASS | PASS | PASS | PASS |
| entry default arm64 HAP | PASS | PASS | PASS | PASS |
| Actual exact-nine AArch64 native ABI audit | PASS | PASS | PASS | PASS |

Simulator Debug HAP: PASS. Multi-target `assembleHapSeq`, actual whitelist/ABI audit and automatic default dependency restoration pass. Exactly one x86_64 `liblinkora_ffmpeg.so`; no MPV/native-storage/unknown SOs. Simulator Release was not requested/executed. Four default HAP audit markers each confirm nine AArch64 libraries: `libaki_jsbind.so`, `libc++_shared.so`, `liblinkora_ffmpeg.so`, `liblinkora_smb.so`, `liblinkora_sftp.so`, `liblinkora_ftp.so`, `liblinkora_nfs.so`, `libmpv.so`, `libmpv_wrapper.so`. Final default/simulator native entry hashes and ELF machine values (183/62) are captured in `final-artifact-native-inventory.json`; initial Debug/Release HAP hashes are captured separately. Warnings remain in original logs; successful builds are unsigned and do not prove install/runtime.

### Cleanup, wrapper and policy functional evidence

The full sequential Loader harness passes freshly twice through real source factory/server titleLabel, serial/coalesced loading, cache/legacy JPEG migration/WebP/refresh, cancellation and stale decode, deadline/cancel partial rejection, late native setup cleanup serialization and reader closure, SFTP trust checks, missing/rejected WebP encoder without JPEG fallback, four complete-cache thumbnail-only retry rows retaining `[12000,1920,1080]` and persistent metadata, both complete/partial incomplete-cache refresh rows, timed retry, image-only completion, server deletion cleanup and UI/preview tail. All three temporary probe wrappers forward source/headers/options and preserve their injected behavior. These are completed desktop assertions; mocked System engine logs/synthetic pixels do not prove actual FFmpeg/WebP runtime.

Fresh source assertions require cleanup settlement before typed `operation.failure(...RESOLVE_FAILED)` and forbid raw `throw error`. Compilation now succeeds. Supplemental read-only execution of unchanged `AnalysisOperation.failure` freshly verifies existing AnalysisError object identity, generic provider failure→RESOLVE_FAILED, and cancellation precedence→CANCELLED. Combined with the existing cleanup wait/late-setup harness assertions, no tested error/cleanup contract regression is observed. Actual HarmonyAnalysisInputs native open-failure/cancellation remains target runtime NOT RUN.

The 45 adapter/policy cases freshly cover LIST System COMPLETE/no FFmpeg, partial fallback/no merge, DETAIL unusable fallback, DETAIL usable PARTIAL retained, cancellation without later fallback, adapter completeness/error/lease closure and local/playlist order. Supplemental `functional-check.cjs` executes the unchanged production PolicyMediaProbe for actual ADVANCED COMPLETE/PARTIAL/UNAVAILABLE with synthetic adapters, asserts exact result identity/call counts/no merge, and verifies ADVANCED cancellation starts no fallback. It also verifies single-System metadata/thumbnail orders for LOCAL_DOCUMENT/HLS/DASH. Supplemental result: 10/10 PASS (three ADVANCED outcomes, cancellation, three error-boundary cases, three System-only cases). It reuses the unchanged repository pure loader; it changes no existing script, expectation or production file. It is reproducible evidence and is not counted as additional Hypium or native tests.

FFmpeg-first remote thumbnail order and raw RGBA adapter/common WebP wiring are covered by fresh policy/adapter tests and read-only source review. The real coordinator's FFmpeg frame→ImagePacker→persistent WebP, natural FFmpeg failure→System success, and both actual engines unavailable are NOT RUN. Desktop mocked encoder/failure cases are not substituted for those runtime checks.

Fresh static/mocked SFTP ownership checks pass: analysis supplies an empty per-open override rather than media fingerprint; persisted trust is `NetworkServerEntry.advancedOptions.sftpFingerprint` via provider/browser. No native SFTP connection/open/read claim. HTTP resolver safe-input/owned proxy-lease assertions pass; production UI consumer applicability is not established, so no NOT APPLICABLE shortcut.

### Runtime limitation, integrity, security and final decision

Initial and final SDK HDC inventory are `[Empty]`; no running Emulator.exe process is observed. The checked common local environment paths supply no connected HarmonyOS target; an unrelated Android AVD is not a HarmonyOS runtime. Committed product signingConfigs are empty; no signing/build configuration was changed. No target/service/HAP was installed or launched. These facts limit runtime evidence; they do not undo the fresh build PASS results or prove a production defect.

All required target production cases are BLOCKED/NOT RUN: Network page/list→real Loader/coordinator; WebDAV H.264/AAC MP4 and HEVC/MKV metadata/dimensions and engine logs; real FFmpeg-first raw frame/common WebP persistence/cache reopen; natural thumbnail fallback; both engines unavailable/no invalid image/useful metadata/bounded retry; runtime legacy/WebP/metadata-only cache compatibility; navigate-away/refresh/stale generation; actual proxy/source cleanup; 20-cycle lifecycle (runtime cycles 0); HTTP production consumer/native boundary; HLS/DASH/LOCAL_DOCUMENT user flows; actual ADVANCED native probe; optional arm64 SFTP and real SMB/FTP/NFS. No old HAP/process/test evidence substitutes for these items.

Protected audit confirms all 1,997 tracked regular files excluding report/phase3 evidence byte-identical, three Gitlinks pinned/clean, and original dirty main snapshots unchanged. Production/tests/expectations/task/build profiles/manifests/CMake/semantic locks remain untouched.

Fresh evidence was scanned/reviewed for Authorization/Cookie values, credentials/passwords, proxy tokens, sensitive upstream URLs/paths and private-key/signing material. Matches are public dependency URLs, case/source identifiers and committed synthetic mocks (including literal `password: 'secret'` in the source context), not live secrets. No private signing/key file content is collected. Loader desktop log contains only metadataEngine/thumbnailEngine/thumbnailPlan; actual production log security is NOT RUN. No x86 engine rankings, p50/p95, throughput, CPU/GPU/memory/power/thermal measurements or conclusions. Original build/test durations are incidental runner output only.

**Final decision: BLOCKED — TEST ENVIRONMENT.** Fresh build chain and desktop functional checks PASS; Phase 3 production runtime/architecture acceptance is not established. No failed gate, patch, bypass, merge or next-phase work. Return to GPT to review the complete fresh evidence and determine target runtime provisioning/next task.

Only this report and the new evidence directory are committed. Fetch before push and reject unexpected protected remote drift, normal push to the exact task branch, fetch again and verify evidence commit remote containment. Return the remotely visible SHA afterward; no self-referential SHA is embedded. Publication failure is `BLOCKED — EVIDENCE NOT PUSHED`.

## Historical GPT review after phase3-rerun-3f ArkTS compile stop

Review date: 2026-10-05.

Ruling:

- The run freshly proves the previously blocked desktop Loader/cache/lifecycle harness and MPV mapping now pass.
- The new stop is a real production ArkTS compilation failure, not a desktop fixture failure or missing target.
- `HarmonyAnalysisInputs.openRemote()` must retain the late native setup-settlement wait before propagating an open failure.
- Raw `throw error` is invalid because ArkTS limits thrown values to supported Error types.
- The repository already has the appropriate typed boundary: `AnalysisOperation.failure(error as Object, fallback)`.
- The source is corrected to await `setupSettled` and then throw `operation.failure(error as Object, AnalysisErrorCode.RESOLVE_FAILED)`.
- This preserves cancellation as `CANCELLED`, preserves an existing `AnalysisError`, and maps other provider/open failures to `RESOLVE_FAILED`.
- The desktop harness now statically guards against raw arbitrary rethrow and requires the typed mapping after the cleanup wait.
- No analyzer routing, storage trust, playback routing, WebP/cache policy, benchmark policy or Direct I/O behavior is changed.
- Hypium execution, HAR/HAP packaging, ABI audits, simulator and production runtime remain NOT RUN until a fresh validation proceeds past compilation.

The failed 3f run below remains historical evidence and is not relabeled PASS.

## Historical validation — phase3-rerun-3f-probe-wrapper-forwarding

This section preserves the 3f run and supplies no PASS evidence for current 3g.

- Repository/branch: `baozi510/Linkora`, `feat/ffmpeg-analyzer-policy-phase3`.
- Validation source SHA: `0d87488dc92f3cd8bc77319ec61197520695597e`.
- Actual checkout SHA: `24812a98fd1a01d6f7a1cfee18843ceb783cd382`.
- Independent clean clone: `D:/Linkora-validation-phase3-3f-20261005`, origin `https://github.com/baozi510/Linkora.git`.
- Fresh evidence: [rerun-3f-probe-wrapper-forwarding-20261005](../test-lab/analyzer-policy/phase3/rerun-3f-probe-wrapper-forwarding-20261005/).
- Source ancestor check exit 0; source-to-HEAD drift exactly `docs/CODEX_VALIDATION_TASK.md`; fetched remote/branch/initial clean state match (`start-state.json`, `source-drift.txt`). All nine required documents completely reread in dispatch order, SESSION_HANDOFF CURRENT STATE first.
- Original dirty `D:/Linkora` remained on `main`, HEAD `ef6ee820a6d010f4ee63a1c0a14c646a717eaa17`. Before/after status SHA256 `648A0D596918685CDA16A5E9CA8102F289C5C21D4838C4646C54240652512DE4` and tracked binary-diff SHA256 `2F10CDD611132E2170F8466E5CBB3E136A44BFB06F0312A01E48DB73FEEBC9E2` match (`user-workspace-proof.json`). No file write, stash/reset/clean/restore/checkout there.

### Commands, dependencies and EOL proof

All preparation/test mutations used the new clone. Captures initially went to ignored `artifacts/phase3-rerun-3f`; the fresh evidence directory was created after STOP.

| Command/check | Exit | Fresh result |
| --- | --- | --- |
| Exact-branch independent `git clone --single-branch --branch feat/ffmpeg-analyzer-policy-phase3 https://github.com/baozi510/Linkora.git D:\Linkora-validation-phase3-3f-20261005` | 0 | New clean checkout |
| `git fetch origin feat/ffmpeg-analyzer-policy-phase3` | 0 | Dispatch HEAD above |
| `git status --porcelain=v1` before install/before verifier | 0 | Empty |
| `git merge-base --is-ancestor 0d87488dc92f3cd8bc77319ec61197520695597e HEAD` | 0 | Source ancestor |
| `git diff --name-only 0d87488dc92f3cd8bc77319ec61197520695597e..HEAD` | 0 | Task file only |
| `git submodule update --init --recursive` | 0 | Native Gitlinks initialized at recorded pins |
| `node --version`; `ohpm --version` | 0 | `v24.14.1`; `26.0.0.630` |
| `ohpm install` | 0 | Exactly once; four EOL-only rewritten locks |
| `git ls-files --eol -- <four allowed locks>` | 0 | All `i/lf w/crlf attr/text eol=lf` |
| `git diff --exit-code -- <four allowed locks>` | 0 | No normalized content delta |
| `git restore --source=HEAD --worktree -- <four affected locks>` | 0 | After all section 5 proofs; clean, no reinstall |
| `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File scripts/verify.ps1` | 1 | Full unmodified verifier exactly once; STOP |
| SDK `hdc list targets` | 0 | `[Empty]`; no target started |
| Protected/submodule audit after STOP | 0 | 1,997 regular files unchanged; pins/worktrees clean |

Fresh environment: PowerShell `7.6.6`, bundled Node/ohpm above, DevEco tools directories prepended to process PATH. The official verifier sets its own SDK/Java environment. HDC executable: `C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe`. No resolution flags/test substitutions were applied.

Generated FFmpeg dependency inputs only were reused from `D:/Linkora-validation/third_party/ffmpeg/prebuilt`. Both ABI manifests were freshly verified against pin `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, ABI, four libraries and disabled programs/encoders/muxers/hwaccels. Eight archive hashes and all-member ELF machine checks are in `dependency-inputs.json`; manifests in `dependency-manifests.txt`. AArch64/X86-64 archive input checks are not fresh FFmpeg bootstrap builds, application builds or final ABI audits. No old application binary/test result was reused.

Install affected only `entry/oh-package-lock.json5`, `linkora_ffmpeg/oh-package-lock.json5`, `linkora_proxy/oh-package-lock.json5`, `oh-package-lock.json5`. No other tracked path/protected byte changed. Every normalized worktree blob equals HEAD; raw worktree bytes normalized only CRLF→LF equal raw HEAD bytes, line contents equal, EOL attributes match. This proves no dependency/version/checksum/graph/comment/content delta. `eol-proof.json` retains raw hashes/blob IDs; `lockfile-diff.txt` retains the empty content diff and warnings. After all proofs, only those exact files were restored. `eol-restore.json` records exit 0, empty status and install count 1. Restored locks are not committed.

### Fresh gates and regression contracts

| Gate/check | Result | Scope/evidence |
| --- | --- | --- |
| Architecture boundaries | PASS | Fresh completion marker |
| Architecture fixtures | PASS | 5/5; failures 0 |
| Simulator product static isolation | PASS | Static parity/isolation marker; no simulator build |
| FFmpeg pure suite | PASS | 15/15 |
| Analyzer adapter/policy pure suite | PASS | 45/45 |
| Native artifact guard fixtures | PASS | 17/17; synthetic fixtures only |
| ArkUI guard/persistence | PASS | Reached persistence; desktop SQLite completion marker |
| HTTP range/System probe | PASS | Four fresh harness PASS markers |
| Whole network-media Loader/cache/lifecycle harness | PASS | Both normal completion markers at stdout lines 229–230 |
| MPV event mapping | PASS | 5/5; failures 0; desktop mocks |
| Actual Hvigor `test` compilation | FAIL | ArkTS `10605087`, `arkts-limited-throw` at `HarmonyAnalysisInputs.ets:34:7` |
| Actual Hypium case execution | NOT RUN | Compilation stopped; executed count 0, result file absent |
| Full default verifier/final marker | FAIL | Exit 1 at `verify.ps1:84`; final marker absent |
| Simulator/immediate default verifier | NOT RUN | Mandatory default STOP |

The complete Loader harness freshly reached all sequential assertions, not just earlier sections: server `titleLabel()`/real factory; serial/coalesced loading; cache identity/legacy JPEG migration/WebP/refresh; consumer cancellation/stale decode; deadline/cancel partial-result rejection; late setup cleanup serialization and reader closure; SFTP ownership static/mocked checks; missing/rejected WebP encoder without JPEG writes; four complete-cache retry rows (`missing`, `corrupt`, `unexpected-dimensions`, `incomplete-dimensions`) asserting thumbnail-only mode, unchanged `[12000,1920,1080]` and persistent metadata; both incomplete-cache refresh rows asserting `both` mode and persistent complete/partial refreshed values; timed retry preserving cached metadata; image-only completion; failed/retried server deletion cleanup; UI/preview boundary/lifecycle tail.

`reviewed-contract-context.txt` preserves numbered assertions and all three wrappers. Each now forwards source/headers/options while retaining its injected partial/result behavior, and each was reached in the successful harness. This combines fresh source inspection and existing functional assertions; no extra argument-identity instrumentation was added. Coordinator/image/native adapters in this desktop harness are mocked. Its System engine log values and synthetic image bytes do not prove real FFmpeg routing/WebP encoding or production runtime cleanup.

The 45 pure cases freshly pass LIST COMPLETE/no FFmpeg, LIST partial fallback/no merge, DETAIL unusable fallback, DETAIL usable PARTIAL/no merge, cancellation without later fallback and local/playlist policy order. Actual ADVANCED COMPLETE/PARTIAL/unusable end-to-end execution remains NOT RUN; DETAIL is not relabeled ADVANCED. Functional HTTP timing-shape assertions are not performance comparisons.

### Exact compile stop and supported assessment

Nested failing invocation: `hvigorw.bat test --mode module -p module=entry@default -p product=default --no-daemon`, launched by the unmodified verifier. `default-stderr.txt` records compiler diagnostic `10605087`: `"throw" statements cannot accept values of arbitrary types (arkts-limited-throw)` at `entry/src/main/ets/analysis/HarmonyAnalysisInputs.ets:34:7`, followed by `COMPILE RESULT:FAIL {ERROR:2 WARN:299}`, build failure and `Unit-test compilation failed.` at verifier line 84. The summary reports two errors; the named source diagnostic displayed is the arbitrary-type throw restriction. Warnings are retained without treating them as the stop cause.

The source at lines 27–34 awaits `directory.openSource(source.locator, '', setupObserver)`, catches `error`, awaits `setupSettled.catch(() => {})`, then rethrows the unconstrained caught value with `throw error`. The compiler directly rejects that rethrow. This is an actual production ArkTS compilation failure, not the earlier desktop wrapper assertion or an unavailable device. The existing cleanup wait/error contract needs independent source review; no cast/replacement/error-mapping fix was attempted. `failure-source-context.txt` preserves the actual lines and caller references. No standalone reproducer, instrumentation, retry or gate bypass was run.

Native build tasks ran as prerequisites of the failed unit-test compilation, including entry and FFmpeg native compilation. This does not establish successful HAR/HAP packaging, final native whitelist/ABI audit or Hypium execution. Fresh isolated Hypium result path `entry/.test/default/intermediates/test/coverage_data/test_result.txt` is absent (`hypium-result-state.json`).

### Build/runtime exclusions, integrity and decision

| Artifact | Debug | Release |
| --- | --- | --- |
| linkora_core default HAR | NOT RUN | NOT RUN |
| linkora_proxy default HAR | NOT RUN | NOT RUN |
| linkora_media_probe default HAR | NOT RUN | NOT RUN |
| linkora_ffmpeg default HAR | NOT RUN | NOT RUN |
| entry default arm64 HAP | NOT RUN | NOT RUN |
| Actual exact-nine AArch64 native set/ABI audit | NOT RUN | NOT RUN |
| Simulator x86_64 HAP/native whitelist/ABI audit | NOT RUN | NOT RUN |

All production/runtime runbook cases are NOT RUN after STOP: real Network page/list -> Loader/coordinator; WebDAV H.264/AAC MP4 and HEVC/MKV; duration/dimensions/metadata and thumbnail engine identities; FFmpeg-first frame/common WebP/cache persistence and reopen; natural System thumbnail fallback; both engines unavailable/no invalid image/useful metadata/bounded retry; production legacy/cache compatibility; navigate-away/refresh/stale generation; actual proxy/source cleanup; 20-cycle lifecycle (runtime cycles 0); HTTP production consumer applicability/native boundary; HLS/DASH/LOCAL_DOCUMENT System-only production flows; native WebDAV/SMB/SFTP/FTP/NFS I/O. No UI/runtime consumer is deemed NOT APPLICABLE without assessment. HDC is empty; no target/service launched or new HAP installed. Device availability did not cause the compile error.

Protected audit: all 1,997 tracked regular files excluding report/phase3 evidence remain byte-identical, including production/tests/task/build/profiles/manifests/CMake and restored locks. Three pinned Gitlinks retain clean worktrees. Original dirty main snapshots match. No protected delta is committed.

Fresh evidence/logs were scanned and reviewed for Authorization/Cookie values, credentials/passwords, proxy tokens, sensitive full upstream URLs/paths and signing/private-key material. Matches contain source identifiers, paths/hashes, public submodule URLs and committed synthetic mock values, not real secrets. No signing material or real token/credential found. Loader mocked log only emits metadataEngine/thumbnailEngine/thumbnailPlan; production runtime log security is NOT RUN. No x86 performance ranking/p50/p95/throughput/CPU/GPU/memory/power/thermal analysis collected; incidental build/test durations are preserved original output only.

**Final decision: FAIL — BUILD.** Wrapper/Loader desktop regressions now pass freshly; default acceptance stops at the production ArkTS rethrow compilation restriction. No architecture acceptance, fix, retry, merge or next-phase work.

Commit only this report and the new sanitized evidence directory. Fetch before push and reject unexpected protected remote drift, push without force to the exact task branch, fetch again and prove evidence commit remote containment. Return the remotely visible evidence SHA after verification; a commit cannot include its own SHA. Push failure is `BLOCKED — EVIDENCE NOT PUSHED` while preserving the build failure.

## Historical GPT review after phase3-rerun-3e wrapper-forwarding stop

Review date: 2026-10-05.

Ruling:

- The run correctly stopped at the first failing assertion and did not patch or retry it.
- The coordinator mock computes `metadataComplete` from complete hints and supplies `mode: 'thumbnail'` to `Probe.inspect`.
- The complete-cache retry wrapper accepted no arguments and invoked `normalInspect.call(this)`; the original Probe therefore received its default empty options object and recorded `both`.
- This fully explains the observed `actual 'both', expected 'thumbnail'` without requiring any production routing change.
- The same dropped-argument pattern existed in the deadline/cancel partial wrapper and timed retry wrapper. Those older assertions could pass while not exercising the complete caller options/callback contract.
- All three wrappers are corrected to transparently forward `source, headers, options` while retaining only their intended injected behavior.
- The strict `thumbnail` mode assertion, metadata immutability assertions, timeout/cancellation assertions and later lifecycle assertions are not weakened.
- No production Loader/coordinator/analyzer source, policy, playback behavior, WebP behavior or performance policy changes are justified by this evidence.
- All later gates from the stopped run remain NOT RUN and require a fresh run.

The failed 3e run below remains historical evidence and is not relabeled PASS.

## Historical validation — phase3-rerun-3e-thumbnail-metadata-separation

This section preserves phase3-rerun-3e and supplies no PASS evidence for the current phase3-rerun-3f task.

- Repository/branch: `baozi510/Linkora`, `feat/ffmpeg-analyzer-policy-phase3`.
- Validation source SHA: `198854ed2e6c14378e692f86852a78656d0aebe8`.
- Actual checkout SHA: `18a143fcf27b4db1c1d5d0ed57a1b31c052b083c`.
- Independent clean clone: `D:/Linkora-validation-phase3-3e-20261005`, public origin `https://github.com/baozi510/Linkora.git`.
- Fresh evidence: [rerun-3e-thumbnail-metadata-separation-20261005](../test-lab/analyzer-policy/phase3/rerun-3e-thumbnail-metadata-separation-20261005/).
- Source is an ancestor of HEAD; source-to-HEAD drift is exactly `docs/CODEX_VALIDATION_TASK.md`. Branch, remote and initial empty status are recorded in `start-state.json`. All nine required documents were completely read in dispatch order, SESSION_HANDOFF CURRENT STATE first.
- Original dirty `D:/Linkora` remains on `main`, HEAD `ef6ee820a6d010f4ee63a1c0a14c646a717eaa17`. Before/after status SHA256 `648A0D596918685CDA16A5E9CA8102F289C5C21D4838C4646C54240652512DE4` and tracked binary-diff SHA256 `2F10CDD611132E2170F8466E5CBB3E136A44BFB06F0312A01E48DB73FEEBC9E2` match (`user-workspace-proof.json`). No file write, stash/reset/clean/restore/checkout was performed there.

### Commands and preparation

All mutation/test commands used the new isolated clone. Initial captures used ignored `artifacts/phase3-rerun-3e`; final evidence was created after STOP.

| Command/check | Exit | Fresh result |
| --- | --- | --- |
| `git clone --single-branch --branch feat/ffmpeg-analyzer-policy-phase3 https://github.com/baozi510/Linkora.git D:\Linkora-validation-phase3-3e-20261005` | 0 | Independent clone |
| `git fetch origin feat/ffmpeg-analyzer-policy-phase3` | 0 | Latest dispatch HEAD above |
| `git status --porcelain=v1` before install/verifier | 0 | Empty at both checkpoints |
| `git merge-base --is-ancestor 198854ed2e6c14378e692f86852a78656d0aebe8 HEAD` | 0 | Source ancestor |
| `git diff --name-only 198854ed2e6c14378e692f86852a78656d0aebe8..HEAD` | 0 | Task file only |
| `git submodule update --init --recursive` | 0 | Recorded native pins initialized |
| `node --version`; `ohpm --version` | 0 | `v24.14.1`; `26.0.0.630` |
| `ohpm install` | 0 | Exactly once; four EOL-only lock changes |
| `git ls-files --eol -- <four allowed locks>` | 0 | All `i/lf w/crlf attr/text eol=lf` |
| `git diff --exit-code -- <four allowed locks>` | 0 | No normalized content delta |
| `git restore --source=HEAD --worktree -- <four affected locks>` | 0 | Section 5 authorized restore after all proofs |
| `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File scripts/verify.ps1` | 1 | Full unmodified verifier exactly once; STOP |
| SDK `hdc list targets` | 0 | `[Empty]`; no target started |
| Protected-file/submodule audit | 0 | 1,997 regular files unchanged; submodule worktrees clean |

Fresh environment: PowerShell `7.6.6`, DevEco bundled Node/ohpm above. Process PATH prepended DevEco `tools/node` and `tools/ohpm/bin`. No dependency flags or test substitutions. HDC used `C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe`.

Generated FFmpeg dependency inputs alone were reused from `D:/Linkora-validation/third_party/ffmpeg/prebuilt` into the new clone's ignored prebuilt directory. Both manifests were freshly checked for source `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, exact ABI/libraries and disabled programs/encoders/muxers/hwaccels. Eight archive SHA256s and all-member ELF machine checks are recorded in `dependency-inputs.json`; full manifests in `dependency-manifests.txt`. All arm64 archive members are AArch64, all x86 archive members X86-64. This is dependency-cache verification, not a fresh bootstrap or application build. No old HAP/HAR/test result was reused. Native Gitlinks were freshly initialized and separately audited.

### Strict EOL proof and integrity

Only `entry/oh-package-lock.json5`, `linkora_ffmpeg/oh-package-lock.json5`, `linkora_proxy/oh-package-lock.json5`, `oh-package-lock.json5` changed during installation. No extra tracked path or protected byte changed. For each, normalized worktree Git blob equals HEAD blob; raw UTF-8 worktree bytes with only CRLF-to-LF normalization exactly equal raw HEAD bytes; line contents equal; EOL attributes match. Thus there is no dependency/version/checksum/graph/comment/content delta. Raw hashes/blob IDs and proof are in `eol-proof.json`; the empty semantic diff/warnings are in `lockfile-diff.txt`.

Only after all proofs succeeded were these exact affected files restored from HEAD. `eol-restore.json` records exit 0, empty post-restore status and install count 1. No reinstall followed. After the stopped verifier, all 1,997 protected tracked regular files excluding the authorized report/phase3 evidence remained byte-identical. Submodule revisions stayed pinned and worktrees clean. Production, scripts/expectations, task, build profiles/manifests/CMake and semantic locks were untouched. Restored locks are not committed.

### Fresh gates and Loader scope

| Gate/check | Result | Evidence scope |
| --- | --- | --- |
| Architecture boundaries | PASS | Fresh completion marker |
| Architecture fixtures | PASS | 5/5, failures 0 |
| Simulator static isolation | PASS | Static parity marker; no simulator build |
| FFmpeg pure suite | PASS | 15/15 |
| Analyzer adapter/policy pure suite | PASS | 45/45 |
| Native artifact guard fixtures | PASS | 17/17; synthetic fixture audit only |
| ArkUI migration/static guard | PASS | Verifier proceeded into persistence |
| Persistence | PASS | Desktop SQLite completion marker; injected rollback errors expected |
| HTTP range/System probe | PASS | Four fresh harness PASS markers |
| Server fixture/real source factory; serial/coalesced loading | PASS | Reached sequential assertions through line 430; line 281 calls=1 passed |
| Early cache/legacy migration/refresh/generation cancellation | PASS | Reached desktop assertions; not production runtime acceptance |
| Late native setup cleanup; cancelled late partial rejection; reader closure | PASS | Assertions at 350–430 completed, including opened=closed |
| SFTP trust ownership | PASS | Harness static/mocked checks 393–412 passed; no native SFTP runtime |
| Missing/rejected WebP encoder never writes JPEG fallback | PASS | Desktop mock assertions 413–430 completed |
| Complete-cache missing-thumbnail retry mode | FAIL | Line 449: actual `both`, expected `thumbnail` |
| Complete-cache metadata immutability/persistence for this retry table | NOT RUN | First row stops before lines 450–454 |
| Corrupt/stray-dimension retry rows; incomplete-cache refresh cases | NOT RUN | Later rows not reached |
| Later timeout retry/image-only/server deletion/UI tail | NOT RUN | First failure precedes these assertions |
| Whole network-media cache/Loader/lifecycle harness | FAIL | Both normal completion markers absent |
| Full default verifier | FAIL | Exit 1 at `verify.ps1:77`, final marker absent |
| MPV event mapping; actual Hvigor Hypium | NOT RUN | Subsequent commands not reached; executed Hypium count 0 |
| Simulator; immediate post-simulator default | NOT RUN | Mandatory default STOP |

Partial Loader PASS entries describe freshly reached sequential desktop assertions only. The coordinator and image encoder are mocked; System engine log values are not production FFmpeg routing evidence. Whole-harness acceptance remains FAIL.

The 45 pure cases freshly cover LIST COMPLETE/no FFmpeg, LIST partial fallback/no merge, DETAIL unusable fallback, DETAIL usable PARTIAL/no merge, cancellation without later fallback, adapter completeness/order, local/playlist System-only policy. Actual ADVANCED COMPLETE/PARTIAL/unusable probe execution is NOT RUN; DETAIL is not relabeled ADVANCED. Existing HTTP timing-shape assertions are functional contracts, not rankings.

### Exact stop and read-only assessment

First failing nested command: DevEco bundled Node running `scripts/check-network-media-list.cjs`. Original stderr records `AssertionError [ERR_ASSERTION]: complete cached metadata uses thumbnail-only retry: missing` at `check-network-media-list.cjs:449:12`; actual `both`, expected `thumbnail`. `default-result.json` records actual verifier exit 1 and invocation count 1. Redirected PowerShell source-line echo contains encoding replacement characters; numbered source excerpts supply readable context without rewriting raw output.

Read-only tracing supports a test-wrapper argument-forwarding defect: the complete-cache retry wrapper at line 442 declares no parameters and calls `normalInspect.call(this)` with no arguments. The original `Probe.inspect` at line 60 defaults `options = {}`, then records `options.mode || 'both'` at line 62. Consequently that recorded mode is `both` even though the mock coordinator computes `thumbnail` for complete hints at lines 137–138 and supplies it in the options object at lines 140–153. The wrapper also prevents the original probe from seeing the thumbnail-only callback guard. This explains the observed assertion without proving that the real production coordinator selected metadata refresh.

This is a source-supported assessment, not an instrumented reproduction. No wrapper patch, mode override, expectation change, standalone rerun, source fix or gate bypass was applied. The production coordinator remains mocked in this harness. Independent GPT review is required; metadata immutability and later new refresh cases remain unproven because execution stopped before them.

### Build and production/runtime exclusions

| Artifact | Debug | Release |
| --- | --- | --- |
| linkora_core default HAR | NOT RUN | NOT RUN |
| linkora_proxy default HAR | NOT RUN | NOT RUN |
| linkora_media_probe default HAR | NOT RUN | NOT RUN |
| linkora_ffmpeg default HAR | NOT RUN | NOT RUN |
| entry default arm64 HAP | NOT RUN | NOT RUN |
| Actual exact-nine AArch64 native set/ABI audit | NOT RUN | NOT RUN |
| Simulator x86_64 HAP/native whitelist/ABI audit | NOT RUN | NOT RUN |

All production runtime runbook cases are NOT RUN after STOP: Network page/list -> real Loader/coordinator; WebDAV H.264/AAC MP4 and HEVC/MKV; duration/dimensions/engine logs; FFmpeg-first raw frame -> common WebP encoder/cache; natural FFmpeg-to-System thumbnail fallback; both engines unavailable/no invalid image; useful metadata/ bounded retry; production cache reopen/legacy JPEG reads; navigate-away/refresh/stale-generation rejection; actual proxy/source cleanup; 20-cycle lifecycle (runtime cycles 0); HTTP production consumer applicability/native boundary; HLS/DASH and LOCAL_DOCUMENT System-only production flows. No runtime consumer is classified NOT APPLICABLE without assessment. Real WebDAV/SMB/SFTP/FTP/NFS native behavior is NOT RUN. No new HAP was built/installed/launched. Empty HDC inventory did not cause this desktop failure.

### Security, decision and publication

Fresh logs/evidence were scanned and reviewed for Authorization/Cookie values, credentials/passwords, proxy tokens, sensitive upstream URLs/paths and signing/private-key material. Matches are source identifiers/hashes/local paths, public submodule URLs and synthetic loopback/fixture values; no real secret or signing material was found. The reached mocked Loader analysis log contains only metadataEngine/thumbnailEngine/thumbnailPlan. Production runtime log security is NOT RUN. No latency/median/p95/throughput/CPU/GPU/memory/power/thermal ranking collected or interpreted; incidental runner durations are not benchmarks.

**Final decision: FAIL — NETWORK MEDIA LOADER.** The full default verifier stopped at the desktop complete-cache retry mode assertion. This is not evidence of a real production routing defect or a successful application build. Phase 3 architecture acceptance remains unready. Return to GPT review; no fix, retry, merge or next-phase work.

Only this report and the new sanitized evidence directory are committed. Fetch remote before push and reject unexpected protected drift; push `HEAD:refs/heads/feat/ffmpeg-analyzer-policy-phase3` without force; fetch again and prove evidence commit containment. Return the remotely visible SHA after verification (the commit cannot include its own SHA). If push fails, handoff is `BLOCKED — EVIDENCE NOT PUSHED` while preserving this test failure.

## Historical GPT review after phase3-rerun-3d thumbnail-retry stop

Review date: 2026-10-05.

Ruling:

- The run correctly proved the prior server-fixture fix and advanced the network-media harness.
- The failing corrupt-thumbnail row seeds complete cached metadata `[12000, 1920, 1080]` but expected a thumbnail retry to replace duration with `9000`.
- That expectation reflects the older coupled `NetworkMediaProbe` implementation, whose THUMBNAIL result was still fed through Loader `updateInfo()`.
- Phase 3 intentionally separates metadata analysis from thumbnail extraction. Current production `NetworkMediaAnalysisCoordinator` runs LIST metadata probing only when duration/width/height hints are incomplete. With complete hints, thumbnail extraction does not update metadata.
- Therefore the observed `[12000, 1920, 1080]` is consistent with the intended Phase 3 contract, not evidence of a production metadata regression.
- Simply changing one expected number would lose useful coverage. The desktop regression is restructured so complete-cache thumbnail retries assert thumbnail-only mode and unchanged metadata, while separate incomplete-cache cases assert metadata refresh and persistence.
- No production Loader/coordinator/analyzer behavior, playback routing, WebP policy, benchmark policy or Direct I/O design is changed.
- All gates after the stopped network-media harness remain NOT RUN and require a fresh run.

The failed run below remains historical evidence and is not relabeled PASS.

## Historical validation — phase3-rerun-3d-server-fixture

This section preserves phase3-rerun-3d and supplies no PASS evidence for the current phase3-rerun-3e task.

- Repository/branch: `baozi510/Linkora`, `feat/ffmpeg-analyzer-policy-phase3`.
- Validation source SHA: `cd12a3869db8a8dbe84730c6f8a118faf73f33e0`.
- Actual checkout SHA: `a517f01d9ea84c7505d61052a320ac18fb1c059c`.
- Independent clean clone: `D:/Linkora-validation-phase3-3d-20261005`, public origin `https://github.com/baozi510/Linkora.git`.
- Fresh evidence: [rerun-3d-server-fixture-20261005](../test-lab/analyzer-policy/phase3/rerun-3d-server-fixture-20261005/).
- Source is an ancestor of HEAD. Source-to-HEAD diff is exactly `docs/CODEX_VALIDATION_TASK.md`, the sole allowed pre-test drift. Initial branch/remote/clean state are in `start-state.json` and `source-drift.txt`. All nine required documents were completely reread in dispatch order, SESSION_HANDOFF CURRENT STATE first.
- Original dirty `D:/Linkora` workspace remains on `main`, HEAD `ef6ee820a6d010f4ee63a1c0a14c646a717eaa17`. Before/after status SHA256 `648A0D596918685CDA16A5E9CA8102F289C5C21D4838C4646C54240652512DE4` and tracked binary-diff SHA256 `2F10CDD611132E2170F8466E5CBB3E136A44BFB06F0312A01E48DB73FEEBC9E2` match. `user-workspace-proof.json` records these read-only snapshots. No file write, stash/reset/clean/restore/checkout was performed there.

### Commands, environment and dependency preparation

Commands below used the new isolated clone. Initial captures used ignored `artifacts/phase3-rerun-3d`; the final evidence directory was created only after STOP.

| Command/check | Exit | Fresh result |
| --- | --- | --- |
| `git clone --single-branch --branch feat/ffmpeg-analyzer-policy-phase3 https://github.com/baozi510/Linkora.git D:\Linkora-validation-phase3-3d-20261005` | 0 | Independent clone |
| `git fetch origin feat/ffmpeg-analyzer-policy-phase3` | 0 | HEAD matches current remote dispatch SHA |
| `git status --porcelain=v1` before install | 0 | Empty |
| `git merge-base --is-ancestor cd12a3869db8a8dbe84730c6f8a118faf73f33e0 HEAD` | 0 | Source safety check passes |
| `git diff --name-only cd12a3869db8a8dbe84730c6f8a118faf73f33e0..HEAD` | 0 | Only task file |
| `git submodule update --init --recursive` | 0 | Pinned native dependencies initialized |
| `node --version`; `ohpm --version` | 0 | `v24.14.1`; `26.0.0.630` |
| `ohpm install` | 0 | Executed once; four EOL-only lockfile changes |
| `git ls-files --eol -- entry/oh-package-lock.json5 linkora_ffmpeg/oh-package-lock.json5 linkora_proxy/oh-package-lock.json5 oh-package-lock.json5` | 0 | All `i/lf w/crlf attr/text eol=lf` |
| `git diff --exit-code -- entry/oh-package-lock.json5 linkora_ffmpeg/oh-package-lock.json5 linkora_proxy/oh-package-lock.json5 oh-package-lock.json5` | 0 | No normalized content delta |
| `git restore --source=HEAD --worktree -- entry/oh-package-lock.json5 linkora_ffmpeg/oh-package-lock.json5 linkora_proxy/oh-package-lock.json5 oh-package-lock.json5` | 0 | Authorized only after all section 5 proofs passed |
| `git status --porcelain=v1` after restore / before verifier | 0 | Empty; no second install |
| `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File scripts/verify.ps1` | 1 | Full unmodified verifier invoked exactly once; STOP |
| SDK `hdc list targets` | 0 | `[Empty]`; no target started |
| Protected-file/submodule audit after stop | 0 | 1,997 regular files unchanged; submodule worktrees clean |

Fresh tool versions: PowerShell `7.6.6`, DevEco bundled Node/ohpm above. Process PATH prepended `C:\Program Files\Huawei\DevEco Studio\tools\node` and `tools\ohpm\bin`. No resolution flags or test substitutions were used. HDC is `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe`.

Dependency cache reuse only: generated FFmpeg headers/static archives were copied from `D:/Linkora-validation/third_party/ffmpeg/prebuilt` into the new clone's ignored prebuilt directory. Both manifests were freshly checked for source pin `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, matching ABI, four required libraries and disabled programs/encoders/muxers/hwaccels. Eight SHA256s and all-member ELF machine inspections are recorded in `dependency-inputs.json`; manifests are in `dependency-manifests.txt`. These prove dependency-input checks, not a fresh bootstrap/HAR/HAP build or acceptance of historical test results. Native Gitlinks were freshly initialized at their recorded pins. No old application binary or old PASS was reused.

### EOL proof, restore and protected audit

Exactly the four listed lockfiles changed; no other tracked path or protected byte changed during install. Each HEAD blob exists, each `git hash-object --path=<path> <path>` equals `git rev-parse HEAD:<path>`, CRLF-to-LF normalized worktree bytes exactly equal raw HEAD bytes, and line contents match. Consequently no dependency/version/checksum/graph/comment/content delta exists. `eol-proof.json` preserves raw SHA256s, blob IDs, byte/line equality and EOL attributes; `lockfile-diff.txt` preserves the empty semantic diff and normalization warnings.

Section 5 restore was applied only after every proof succeeded. `eol-restore.json` records exact paths/command, exit 0 and clean status. All 1,997 protected tracked regular files excluding report/phase3 evidence are byte-identical after the verifier, including the restored locks and untouched task/test/production/build files. Gitlink revisions and clean submodule status are separately recorded. No semantic lockfile change or protected-file delta is committed.

### Fresh gates and required Loader regressions

| Gate/check | Result | Scope/evidence |
| --- | --- | --- |
| Architecture boundaries | PASS | Fresh completion marker |
| Architecture fixtures | PASS | 5/5; failures 0 |
| Simulator static product isolation | PASS | Static parity marker; no simulator build |
| FFmpeg pure tests | PASS | 15/15 |
| Analyzer adapter/policy pure tests | PASS | 45/45 |
| Native artifact guard fixtures | PASS | 17/17; synthetic fixture audit only |
| ArkUI migration/static guard | PASS | Verifier entered subsequent persistence command |
| Persistence | PASS | Desktop SQLite completion marker; injected rollback failures expected |
| HTTP range/System probe | PASS | Four fresh harness PASS markers |
| Corrected server fixture / `calls === 1` | PASS | Passed line 281 and reached line 447; real factory remains in harness |
| Serial/coalesced loading and early metadata/cache/legacy migration | PASS within reached desktop assertions | Assertions before line 447 returned normally; not overall cache acceptance |
| Cancellation/stale results / cancelled late partial | PASS within desktop harness | Reached assertions at lines 350–370 and later failure |
| Queued job waits for late native setup cleanup | PASS within desktop harness | Lines 382–383; native-reader late-handle close assertion also reached |
| Opened readers/sources close | PASS within completed desktop phases | Equality assertions at lines 354 and 430 passed; no final runtime cleanup claim |
| SFTP trust ownership | PASS within harness/static checks | Empty analysis override/no media fingerprint and setup wait checks at 403–409 passed; mocked protocol trust checks passed; no native SFTP runtime |
| No WebP-to-JPEG fallback for missing/rejected encoder | PASS within desktop mocks | Lines 410–429 reached; no real ImagePacker/FFmpeg runtime claim |
| Corrupt-thumbnail retry retains metadata | FAIL | At line 447: actual `[12000,1920,1080]`, expected `[9000,1920,1080]` |
| Entire media cache/Loader/lifecycle harness | FAIL | Both normal completion markers absent |
| Full default verifier | FAIL | Exit 1 at `verify.ps1:77`; final marker absent |
| MPV mapping / actual Hvigor Hypium | NOT RUN | Subsequent commands not reached; Hypium executed count 0 |
| Simulator / immediate default verifier | NOT RUN | Default STOP condition |

These partial desktop PASS entries are freshly executed sequential assertions before the first failure, not standalone reruns or production-device tests. The harness coordinator is mocked, so its `Network media analysis` output with System engines is not production FFmpeg routing evidence. Its normal completion and UI lifecycle tail remain unexecuted.

The 45 pure cases freshly cover LIST COMPLETE/no FFmpeg, LIST partial fallback/no merge, DETAIL unusable fallback, DETAIL usable partial/no merge, cancellation without later fallback, and adapter completeness/order contracts. Actual ADVANCED COMPLETE/PARTIAL/unusable end-to-end execution remains NOT RUN; DETAIL is not relabeled ADVANCED. HTTP timing-shape assertions remain functional coverage, not performance rankings.

### Exact failure and read-only root-cause assessment

First failing nested command: DevEco bundled Node running `scripts/check-network-media-list.cjs`. `default-stderr.txt` records `AssertionError [ERR_ASSERTION]: thumbnail retry preserves previously known fields: corrupt` at `check-network-media-list.cjs:447:12`; actual duration 12000, expected 9000, dimensions 1920x1080 unchanged. `default-result.json` records verifier command, checkout, timestamps and exit 1. Original redirected stderr contains replacement characters in PowerShell's source-line echo; separate numbered excerpts provide readable source context without rewriting raw output.

The retry table at lines 433–438 seeds complete cache metadata `[12000,1920,1080]` for every row. The `corrupt` row supplies invalid cached image bytes, injects probe result `[9000,0,0]`, and expects duration to change to 9000. Loader retains the complete cached metadata as hints at lines 140–142 and passes them to the mocked coordinator at lines 217–221. That mock explicitly selects thumbnail-only mode when all hints are positive (137–138), and then chooses `durationHintMs` rather than the probe-returned duration (158). Thus it returns 12000 to Loader, matching the observed result.

The real production coordinator similarly initializes from complete hints and only runs metadata probe if duration or dimensions are missing (85–109); thumbnail extraction does not replace these metadata values. This supports a possible stale regression expectation versus the thumbnail-only coordinator contract, requiring independent review. Because this failing harness uses a mocked coordinator, the result does not establish a real production-runtime metadata defect. No modified-run reproduction, instrumentation, expectation change or fix was applied. Do not weaken the assertion without reviewing the intended contract.

The `missing` retry row passed before the `corrupt` row failed. Its persistent check passed. The `corrupt` persistent assertion at 449, later dimension/incomplete-dimension retry rows, timed retry, image-only publication, server-deletion cleanup and UI/preview tail are all NOT RUN. Final readers/source closure for those unexecuted phases is unknown. The entire gate remains FAIL regardless of earlier passed assertions.

### Build and functional/runtime exclusions

| Artifact | Debug | Release |
| --- | --- | --- |
| linkora_core default HAR | NOT RUN | NOT RUN |
| linkora_proxy default HAR | NOT RUN | NOT RUN |
| linkora_media_probe default HAR | NOT RUN | NOT RUN |
| linkora_ffmpeg default HAR | NOT RUN | NOT RUN |
| entry default arm64 HAP | NOT RUN | NOT RUN |
| Actual exact-nine AArch64 native-library/ABI audit | NOT RUN | NOT RUN |
| entry simulator x86_64 HAP/native whitelist/ABI audit | NOT RUN | NOT RUN |

All production/runtime runbook cases are NOT RUN after the default STOP: real Network page/list -> Loader -> coordinator; WebDAV H.264/AAC MP4 and HEVC/MKV; production duration/dimensions/engine logs; FFmpeg-first thumbnail/raw frame -> common WebP/cache; natural FFmpeg-to-System thumbnail fallback; both engines unavailable/no invalid image; retained metadata/bounded retry; production cache reopen/legacy JPEG compatibility; navigate-away/refresh/stale-generation rejection; actual proxy/source cleanup; 20-cycle lifecycle (executed runtime cycles 0); HLS/DASH and LOCAL_DOCUMENT System-only production flows; real HTTP production-consumer applicability/resolver/native boundary. No runtime consumer was judged NOT APPLICABLE without assessment. SFTP/WebDAV/SMB/FTP/NFS native protocol behavior is NOT RUN. No new HAP installed/launched; no target or unrelated service/workspace altered. Empty HDC inventory did not cause this desktop failure.

### Security, decision and remote handoff

Fresh evidence/logs were scanned and reviewed for Authorization/Cookie values, passwords/private credentials, proxy tokens, sensitive full upstream URLs/paths and signing/private-key material. Source identifiers, public submodule URLs, local paths/hashes and synthetic loopback fixtures are preserved; no secret value/signing material was found. The reached mocked Loader log lines contain only `metadataEngine`, `thumbnailEngine`, `thumbnailPlan`; real production runtime log security remains NOT RUN. No System-vs-FFmpeg latency/throughput/CPU/GPU/memory/power/thermal ranking collected or interpreted. Incidental original test durations are not benchmarks.

**Final decision: FAIL — NETWORK MEDIA LOADER.** The full default gate stopped at a desktop corrupt-thumbnail retry contract assertion. Phase 3 architecture acceptance remains unready; no production-runtime defect or build success is inferred. Stop for GPT review without any source/test/build/expectation fix, merge or next-phase work.

Commit only this report and the new sanitized evidence subdirectory. Fetch before publication to ensure no unexpected source/test/build drift; push `HEAD:refs/heads/feat/ffmpeg-analyzer-policy-phase3` without force; fetch again and confirm remote containment of the evidence commit. Return that remotely visible SHA to the review conversation. The commit cannot include its own SHA. If publication fails, handoff status is `BLOCKED — EVIDENCE NOT PUSHED`, with local SHA and this preserved failure. No restored lockfile, production/test/build/task-file delta is committed.

## Historical GPT review after phase3-rerun-3c network-media-loader stop

Review date: 2026-10-05.

Ruling:

- The run correctly applied the approved EOL-only self-heal and returned the isolated validation checkout to clean state before the verifier.
- The old target-alias failure is resolved: the desktop harness reached Loader assertions.
- The failing `calls === 1` assertion is explained by a stale test fixture, not by proven production analyzer behavior.
- Production `NetworkMediaSourceFactory.fromEntry()` calls `server.titleLabel()`.
- Real `NetworkServerEntry` implements `titleLabel()`.
- The desktop harness fixture only provided `id`, `updatedAt` and `protocol`, so Loader failed before `analysis.inspect()`; Loader's catch converted the malformed fixture exception into the observed null path and probe count 0.
- The appropriate correction is to add `titleLabel: () => 'test'` to that minimal fixture while retaining the real `NetworkMediaSourceFactory` call and the existing probe-count expectation.
- No production ArkTS/C/C++ source, analyzer routing, playback routing, WebP policy, performance policy or Direct I/O design is changed by this review.
- All later build/simulator/runtime gates from the stopped run remain NOT RUN and must be executed fresh.

The failed run below remains historical evidence and is not relabeled PASS.

## Historical validation — phase3-rerun-3c-eol-self-heal

This section preserves the historical phase3-rerun-3c result and supplies no PASS evidence for phase3-rerun-3d.

- Repository/branch: `baozi510/Linkora`, `feat/ffmpeg-analyzer-policy-phase3`.
- Implementation source SHA: `15db3f8a3e87f75edc209c1919f944f39c0b9fcb`.
- Actual validation checkout SHA: `70f26f8f20086c8fee849170f2e2858dee324028`.
- Independent clean clone: `D:/Linkora-validation-phase3-3c-20261005`; origin `https://github.com/baozi510/Linkora.git`.
- Fresh evidence: [rerun-3c-eol-self-heal-20261005](../test-lab/analyzer-policy/phase3/rerun-3c-eol-self-heal-20261005/).
- The source is an ancestor of HEAD. Every intervening path is in the dispatch's operational allowlist; exact paths are in `source-drift.txt`. All nine required documents were read completely in order, SESSION_HANDOFF CURRENT STATE first.
- Original dirty workspace `D:/Linkora` was left untouched on `main`, HEAD `ef6ee820a6d010f4ee63a1c0a14c646a717eaa17`. Before/after porcelain-status digest is `648A0D596918685CDA16A5E9CA8102F289C5C21D4838C4646C54240652512DE4`; tracked binary-diff digest is `2F10CDD611132E2170F8466E5CBB3E136A44BFB06F0312A01E48DB73FEEBC9E2`. Matching snapshots are in `user-workspace-proof.json`. No stash/reset/clean/restore/checkout or file write was performed there.

### Commands, environment and dependency preparation

All mutation/build commands below used the isolated clone. Capture files were initially placed in ignored `artifacts/phase3-rerun-3c`, so the validation checkout was clean before install and before the full verifier.

| Command/check | Exit | Result |
| --- | --- | --- |
| `git clone --single-branch --branch feat/ffmpeg-analyzer-policy-phase3 https://github.com/baozi510/Linkora.git D:\Linkora-validation-phase3-3c-20261005` | 0 | Independent validation clone |
| `git fetch origin feat/ffmpeg-analyzer-policy-phase3` | 0 | Retrieved current remote HEAD above; latest READY dispatch read |
| `git status --porcelain=v1` | 0 | Empty before dependency installation |
| `git merge-base --is-ancestor 15db3f8a3e87f75edc209c1919f944f39c0b9fcb HEAD` | 0 | Source safety check passed |
| `git diff --name-only 15db3f8a3e87f75edc209c1919f944f39c0b9fcb..HEAD` | 0 | Only allowed operational paths |
| `git submodule update --init --recursive` | 0 | Pinned native submodules initialized; `submodule-init.txt` |
| `node --version`; `ohpm --version` | 0 | Node `v24.14.1`; ohpm `26.0.0.630` |
| `ohpm install` | 0 | Installed once; only four allowlisted lockfiles rewritten to CRLF |
| `git diff --exit-code -- entry/oh-package-lock.json5 linkora_ffmpeg/oh-package-lock.json5 linkora_proxy/oh-package-lock.json5 oh-package-lock.json5` | 0 | No normalized content delta |
| `git ls-files --eol -- <the four paths above>` | 0 | Every file: `i/lf w/crlf attr/text eol=lf` |
| `git restore --source=HEAD --worktree -- <the four paths above>` | 0 | Authorized restore only after all section 5 proofs passed |
| `git status --porcelain=v1` immediately after restore | 0 | Empty; no second install |
| `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File scripts/verify.ps1` | 1 | Complete, unmodified default verifier invoked once; mandatory STOP |
| SDK `hdc list targets` | 0 | `[Empty]`; no simulator/device started |
| Post-stop protected-file/submodule audit | 0 | 1,997 tracked regular files byte-identical; submodules clean |

PowerShell is `7.6.6`. The process PATH prepended DevEco's `C:\Program Files\Huawei\DevEco Studio\tools\node` and `tools\ohpm\bin`; no package-manager resolution flag, source patch, test substitution or gate bypass was used. HDC executable is `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe`.

Generated FFmpeg headers/static archives were copied as ignored dependency inputs from the existing local dependency cache at `D:/Linkora-validation/third_party/ffmpeg/prebuilt`. Both cached manifests were freshly checked for FFmpeg pin `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, matching ABI, and disabled programs/encoders/muxers/hwaccels. Eight archive SHA256s and all-member ELF machine checks are recorded in `dependency-inputs.json`: AArch64 for arm64-v8a and x86-64 for x86_64. This is dependency reuse, not a fresh FFmpeg bootstrap build or HAP/HAR/native-output audit; no historical test result or generated application binary was accepted as this run's evidence. The public Git submodules were freshly initialized at the pinned revisions in `submodules-before.txt`.

### Strict EOL-only proof and authorized self-heal

The four affected paths are exactly `entry/oh-package-lock.json5`, `linkora_ffmpeg/oh-package-lock.json5`, `linkora_proxy/oh-package-lock.json5` and `oh-package-lock.json5`. No extra tracked file changed. For each path, its HEAD blob exists, `git hash-object --path=<path> <path>` equals `git rev-parse HEAD:<path>`, raw worktree bytes normalized only by CRLF-to-LF are byte-identical to the raw HEAD blob, and line contents are equal. This establishes no dependency/version/checksum/graph/comment/content change. Raw HEAD/worktree SHA256s, normalized blob IDs and EOL attributes are preserved in `eol-proof.json`; the empty Git diff and its CRLF warning are in `lockfile-diff.txt`.

Only after those proofs passed, section 5's authorized restore was executed in this isolated clone. `eol-restore.json` records exact paths/command, exit 0 and empty post-restore status. `protected-audit.json` and before/after CSVs confirm all 1,997 protected tracked regular files have their original bytes after the gate; initialized Gitlinks are recorded separately and their worktrees are clean. Restored lockfiles are not included in the report/evidence commit. No semantic lockfile change was made or committed.

### Fresh gate results

| Gate | Current-run result | Scope/evidence |
| --- | --- | --- |
| Architecture boundary checks | PASS | Fresh completion marker |
| Architecture guard fixtures | PASS | 5/5; failures 0 |
| Simulator product static isolation | PASS | Fresh parity/isolation marker; no simulator build implied |
| FFmpeg pure suite | PASS | 15/15 |
| Analyzer adapter/policy pure suite | PASS | 45/45 |
| Native artifact guard fixtures | PASS | 17/17; synthetic fixtures, not actual HAP ABI verification |
| ArkUI migration/static guard | PASS | Verifier passed the static check and entered persistence |
| Persistence regression | PASS | Desktop SQLite completion marker; injected rollback errors are expected |
| HTTP range/System probe regression | PASS | Four harness PASS markers, including stalled cleanup watchdog |
| Network media list/cache/lifecycle regression | FAIL | Assertion at `check-network-media-list.cjs:281`: actual 0, expected 1; normal completion absent |
| Target alias regression | PASS within desktop module-loading scope | Harness reaches `check()` and Loader assertion; old `entry/AnalysisComposition` import error does not recur |
| Full default verifier/final marker | FAIL | Exit 1 at `verify.ps1:77`; no final completion marker |
| MPV event-mapping regression | NOT RUN | Next command after failed gate |
| Actual Hvigor Hypium | NOT RUN | Executed count 0; `hvigor test` was not reached |
| Simulator verifier/immediate default | NOT RUN | Mandatory default-gate stop condition |

The 45-case pure run freshly exercises LIST COMPLETE without FFmpeg, LIST partial fallback without merging, DETAIL unusable fallback, DETAIL usable PARTIAL without System merge, and cancellation without starting fallback. It also covers adapter completeness for LIST/DETAIL/ADVANCED. These are pure harness observations; DETAIL is not relabeled as actual ADVANCED execution. ADVANCED end-to-end routing remains NOT RUN. The HTTP harness's timing-shape regression is functional contract coverage only; no engine performance comparison or ranking was collected or interpreted.

### Exact failure and supported root-cause assessment

`default-stderr.txt` records `AssertionError [ERR_ASSERTION]`, `0 !== 1`, at `scripts/check-network-media-list.cjs:281:38`, followed by `Network media list/cache regression checks failed.` at `scripts/verify.ps1:77`. `default-result.json` records the command and exit 1; stdout/stderr are preserved separately. Some PowerShell source-line echo in redirected stderr contains encoding replacement characters; clean numbered source context is provided separately, without rewriting the captured log.

Read-only tracing identifies a fixture/API mismatch that explains the assertion: the script's server at line 219 is `{ id: 1, updatedAt: 2, protocol: 'smb' }`, with no `titleLabel()` method. The real `NetworkMediaSourceFactory.fromEntry` calls `server.titleLabel()` at line 15. Loader `run()` calls that factory at line 215 before `analysis.inspect`; its catch at line 274 suppresses the exception and resolves null. Probe `inspect` increments `calls` only at harness line 61, so it is not reached for this fixture. The real `NetworkServerEntry` defines `titleLabel()` at line 135. This supports a desktop test-fixture incompatibility, not an established production-device defect. The discarded TypeError itself was not logged; this assessment is source tracing, not a modified-run reproduction. Numbered excerpts are in `failure-source-context.txt`.

The gate was not rerun after failure. No fixture, source, expectation or build-profile fix was made. Later Loader assertions for late native setup cleanup, cancelled partial publication and reader/source closure were not reached. Passing earlier cache assertions does not make the overall list/cache/lifecycle gate PASS.

### Build, functional and runtime scope after STOP

| Artifact | Debug | Release |
| --- | --- | --- |
| linkora_core default HAR | NOT RUN | NOT RUN |
| linkora_proxy default HAR | NOT RUN | NOT RUN |
| linkora_media_probe default HAR | NOT RUN | NOT RUN |
| linkora_ffmpeg default HAR | NOT RUN | NOT RUN |
| entry default arm64 HAP | NOT RUN | NOT RUN |
| Actual exact-nine AArch64 production native-library/ABI audit | NOT RUN | NOT RUN |
| entry simulator x86_64 HAP/native whitelist and ABI audit | NOT RUN | NOT RUN |

All runbook runtime cases are NOT RUN because the prerequisite default gate failed: production Network page/list -> Loader -> coordinator; WebDAV H.264/AAC MP4 and HEVC/MKV; production duration/width/height and engine logs; FFmpeg-first thumbnail/raw-frame/common-WebP persistence; natural System thumbnail fallback; both engines unavailable/no invalid image; useful metadata when thumbnail fails; cache reopen/legacy compatibility in production; navigate-away/refresh/stale-generation rejection; proxy/source cleanup; and the 20-cycle lifecycle (executed runtime cycles 0). HLS/DASH/LOCAL_DOCUMENT System-only functional flows and production HTTP-consumer applicability are NOT RUN. No new HAP was built, installed or launched. Empty HDC inventory is an observed environment limit, but did not cause this desktop gate failure.

Post-stop read-only static observations: `HarmonyAnalysisInputs` passes an empty per-open trust override, never `MediaSource.fingerprint`, and retains the `setupSettled` wait; `SftpBrowserService.trustedFingerprint` falls back to `NetworkServerEntry.advancedOptions.sftpFingerprint`. Static source observations do not establish runtime SFTP trust/cleanup PASS. SFTP runtime ownership and WebDAV/SMB/FTP/NFS behavior are NOT RUN. The source diff confirms no non-operational branch drift, not protocol runtime correctness.

Production log formatting statically exposes only `metadataEngine`, `thumbnailEngine` and `thumbnailPlan` in the Loader analysis log. Actual production runtime log security is NOT RUN. Fresh evidence was reviewed for Authorization/Cookie values, passwords/private credentials, proxy tokens, sensitive full upstream URLs/paths and signing material. It includes public repository IDs, local environment paths, hashes, synthetic test context and captured functional-test output; no secret value/signing material was found. No System-vs-FFmpeg performance or x86 performance-policy conclusion is made. Benchmarking remains excluded.

### Decision and mandatory remote handoff

**Final decision: FAIL — NETWORK MEDIA LOADER.** The full default verifier is blocked by the desktop Loader fixture assertion. Phase 3 architecture acceptance is not ready; production runtime/build correctness remains unestablished. Return this evidence for reviewed test-infrastructure handling; do not repair the stopped gate, merge or start the next phase.

Only this report and the fresh evidence subdirectory are authorized for the evidence commit. No production/test/build/profile/manifest/CMake/semantic-lockfile/task-file delta is included. Publication uses `git push origin HEAD:refs/heads/feat/ffmpeg-analyzer-policy-phase3` without force, after fetching and checking allowed remote drift. A subsequent fetch and `git merge-base --is-ancestor <evidence SHA> origin/feat/ffmpeg-analyzer-policy-phase3` must prove remote containment. The evidence commit's SHA and observed remote visibility will be returned after those commands succeed; its own SHA cannot be embedded in itself. If push fails, handoff status is `BLOCKED — EVIDENCE NOT PUSHED` with the local SHA; the test failure remains recorded.

## Historical review — phase3-rerun-3b environment block

Review date: 2026-10-05.

Ruling:

- The Codex stop was correct under the task wording active during that run.
- The uploaded evidence proves the four lockfiles changed only by LF→CRLF worktree encoding: each `normalizedWorktreeBlob` exactly equals its corresponding HEAD blob and line content is equal.
- `.gitattributes` already declares `*.json5 text eol=lf`; no repository line-ending policy change is required.
- This is not evidence of a dependency graph/content change, production analyzer defect, build failure, or runtime failure.
- Future validation tasks may explicitly allow Codex to restore only these four lockfiles from HEAD inside an isolated validation checkout after re-proving the same normalized equality and confirming no other tracked path changed.
- That cleanup must be recorded as evidence and must not be committed. Any normalized-content mismatch remains an immediate STOP.
- No Phase 3 production source, analyzer routing, playback routing, benchmark policy, or Direct I/O implementation changes are justified by this run.

The blocked result below remains historical evidence. It is not converted into PASS. A fresh run must begin from the current READY validation task.

## Validation evidence — phase3-rerun-3b-isolated-checkout

This section preserves the historical phase3-rerun-3b result. It supplies no PASS evidence for the current phase3-rerun-3c task.

- Repository: `baozi510/Linkora`.
- Branch: `feat/ffmpeg-analyzer-policy-phase3`.
- Implementation source SHA: `15db3f8a3e87f75edc209c1919f944f39c0b9fcb`.
- Actual validation checkout SHA: `b5c53c01ee158d1374b71130f6ce910da1fddcaa`.
- Isolated independent clone: `D:/Linkora-validation-phase3-20261005`; origin is `https://github.com/baozi510/Linkora.git`.
- Evidence: `test-lab/analyzer-policy/phase3/rerun-3b-isolated-20261005/`.
- Original dirty workspace `D:/Linkora` remains on `main`, HEAD `ef6ee820a6d010f4ee63a1c0a14c646a717eaa17`. Its status and binary-diff SHA256 digests match before/after. No stash/reset/clean/checkout or file write was performed there.
- All nine required documents were read completely in the dispatched order, with SESSION_HANDOFF CURRENT STATE first.

### Fresh commands and results

| Command / check | Exit code | Fresh result |
| --- | --- | --- |
| `git fetch --no-tags https://github.com/baozi510/Linkora.git feat/ffmpeg-analyzer-policy-phase3` in original repository | 0 | Retrieved current dispatch only; no checkout performed |
| `git clone --single-branch --branch feat/ffmpeg-analyzer-policy-phase3 https://github.com/baozi510/Linkora.git D:\Linkora-validation-phase3-20261005` | 0 | Created independent validation clone |
| `git fetch origin feat/ffmpeg-analyzer-policy-phase3` in clone | 0 | HEAD and remote branch both equal the validation SHA above |
| `git status --porcelain=v1` before evidence/dependency installation | 0 | PASS; empty output |
| `git merge-base --is-ancestor 15db3f8a3e87f75edc209c1919f944f39c0b9fcb HEAD` | 0 | PASS; implementation source is an ancestor |
| `git diff --name-only 15db3f8a3e87f75edc209c1919f944f39c0b9fcb..HEAD` | 0 | PASS; exactly `docs/AI_WORKFLOW.md` and `docs/CODEX_VALIDATION_TASK.md` |
| `ohpm --version`; `node --version` with DevEco tool directories prepended to process PATH | 0 | ohpm `26.0.0.630`, Node `v24.14.1` |
| `hdc list targets` using installed SDK executable | 0 | `[Empty]`; no simulator/device started |
| `ohpm install` in validation clone | 0 | Install succeeded; four tracked lockfiles subsequently reported modified |
| `git diff --exit-code -- '*oh-package-lock.json5'` | 0 | No normalized Git-content change; this does not establish byte preservation or clean status |
| `git ls-files --eol '*oh-package-lock.json5'` | 0 | All four index blobs LF, worktree files CRLF, attribute `text eol=lf` |

Installation used process PATH prefixes `C:\Program Files\Huawei\DevEco Studio\tools\node` and `C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin`. No package-resolution flags, test substitutions, source patches or gate bypasses were used. PowerShell version freshly observed: `7.6.6`. HDC executable: `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe`.

### Stop evidence and assessment

Normal `ohpm install` changed the bytes of these four protected files:

- `entry/oh-package-lock.json5`;
- `linkora_ffmpeg/oh-package-lock.json5`;
- `linkora_proxy/oh-package-lock.json5`;
- `oh-package-lock.json5`.

For every file, line-content comparison is equal and Git-normalized worktree blob equals the HEAD blob. The fresh evidence therefore confirms LF-to-CRLF rewriting only, with no dependency graph/content change. SHA256 before/after values are different, and `git status --porcelain=v1` reports all four files as modified. Exact hashes/blob IDs and EOL attributes are in `lockfile-eol-drift.json` and `lockfile-eol.txt`.

The task requires a clean validation checkout, unchanged tracked lockfiles after dependency resolution, and forbids lockfile edits. On that conservative reading, the prerequisite cannot be reported PASS despite the empty normalized Git diff. Execution stopped before `scripts/verify.ps1`. No manual EOL normalization, restore, index refresh to conceal status, new checkout workaround, verifier retry or package-manager patch was performed. The decision is an environment/prerequisite block, not a failed default verifier, production analyzer defect or dependency-content mismatch. Resolution of this package-manager/EOL prerequisite needs a reviewed workflow clarification or environment correction before a new run.

Protected audit: 1,997 tracked regular files were hashed before and after installation, excluding the authorized report and phase3 evidence. 1,993 files are byte-identical; only the four installer-rewritten lockfiles differ. Three Gitlink entries were recorded separately rather than hashed as files. An initial attempt to hash those directories produced access errors; the baseline was corrected before installation to cover regular files and record Gitlinks separately. No production/test/build file was manually edited. No source/test/profile/lockfile content is staged or committed by this report.

### Unexecuted gates and cases

| Required item | Current-run result |
| --- | --- |
| Fresh full default `./scripts/verify.ps1` | NOT RUN; dependency/clean-checkout prerequisite blocked |
| Architecture boundaries and guard fixtures | NOT RUN |
| Simulator product static isolation | NOT RUN |
| FFmpeg pure tests; analyzer adapter/policy pure tests | NOT RUN |
| Native artifact guard fixtures | NOT RUN |
| ArkUI migration/static guard; persistence regressions | NOT RUN |
| HTTP range/System probe regressions | NOT RUN |
| Network media list/cache/lifecycle normal completion, late native cleanup serialization, cancelled-result rejection and reader closure | NOT RUN |
| MPV event-mapping regressions | NOT RUN |
| Actual Hvigor Hypium execution and test count | NOT RUN; executed count 0 |
| Debug/Release HAR for core/proxy/media_probe/ffmpeg | NOT RUN for every module/mode |
| Debug/Release default HAP and exact-nine AArch64 native/ABI audit | NOT RUN for both modes |
| Default verifier final completion marker | NOT RUN |
| Simulator verification, x86 whitelist/ABI audit and dependency restoration | NOT RUN |
| Immediate post-simulator default verification | NOT RUN; no simulator gate executed |
| LIST COMPLETE/incomplete fallback; DETAIL and ADVANCED COMPLETE/PARTIAL/unusable; non-merging and cancel policy | NOT RUN; no DETAIL evidence relabeled ADVANCED |
| FFmpeg-first thumbnail, common WebP persistence, natural System fallback and both-engines-unavailable behavior | NOT RUN |
| WebDAV H.264/AAC MP4 and HEVC/AAC MKV production Network-page/loader/coordinator flow | NOT RUN |
| Production metadata/thumbnail engine logs, cache reopen and legacy cache compatibility | NOT RUN |
| Navigate-away/refresh/stale-generation rejection, proxy/source cleanup and 20-cycle lifecycle | NOT RUN; runtime cycles 0 |
| HTTP production-consumer applicability, HLS/DASH System-only and LOCAL_DOCUMENT functional flow | NOT RUN; applicability not established |
| SFTP host-key ownership regression and WebDAV/SMB/FTP/NFS behavior | NOT RUN; no fresh source/runtime result claimed |
| Production log security audit | NOT RUN; no new HAP built/installed/launched |
| Performance comparison/benchmark/ranking | NOT RUN; prohibited this round |

No runtime fixture/service was started and no target installed or launched. Device-dependent acceptance is unavailable in the observed empty HDC inventory, but that did not cause the lockfile prerequisite block. Uninitialized native Gitlinks and generated FFmpeg prebuilts were not provisioned or assessed for build readiness after the stop.

Evidence is checked for Authorization/Cookie values, passwords/private credentials, proxy tokens and sensitive upstream URLs/paths before commit. It contains only command results, repository paths, public Git repository identifiers, hashes and environment metadata. No signing material, credential or raw private URL is included. No performance data was collected or interpreted; the install duration in original output is incidental command output.

**Final decision: BLOCKED — TEST ENVIRONMENT.** No Phase 3 architecture acceptance claim. Publish only the authorized report/evidence under the updated remote-handoff requirement; do not merge or begin another phase.

### Remote handoff of the preserved run — 2026-10-05

The latest task was freshly fetched and read completely at remote SHA `5aa9ddc39901be8ebaf72c7607fb3e1ad974f1ce`, including sections 12 and 13. It retains the same task ID/source and adds mandatory push/fetch verification. The only changes from the actual tested checkout SHA are the two allowed operational documents. This handoff is not a new test run: `ohpm install`, default verifier, simulator verifier and runtime cases were not rerun, and the actual validation SHA above remains unchanged.

Original local evidence commit: `34e203a537c842e76cb90f2c018c8b003c463e77`. Its report/evidence worktree diff is empty; all 14 evidence Git blobs are preserved unchanged during import. The original validation checkout, including the four installer-rewritten lockfiles, was not reset, normalized, rebased or otherwise overwritten.

Publication uses a new clean independent clone at `D:/Linkora-phase3-handoff-20261005`, initially at the remote SHA above. Only the authorized report/evidence delta from the original local commit is imported with `git cherry-pick --no-commit`; no branch merge or protected-file delta is included. Original run evidence remains in its fresh per-run subdirectory. Additional handoff provenance and blob-identity evidence are under `test-lab/analyzer-policy/phase3/remote-handoff-20261005/`.

The handoff commit is sent using `git push origin HEAD:refs/heads/feat/ffmpeg-analyzer-policy-phase3` without force. After push, `git fetch origin feat/ffmpeg-analyzer-policy-phase3` and `git merge-base --is-ancestor HEAD origin/feat/ffmpeg-analyzer-policy-phase3` must establish remote containment before completion is reported. The resulting commit SHA and observed remote verification are returned in the final handoff message; the evidence commit cannot contain its own SHA. If publication fails, the handoff status is `BLOCKED — EVIDENCE NOT PUSHED` while the preserved test result remains `BLOCKED — TEST ENVIRONMENT`.

## Historical validation and review — not current-run evidence


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
