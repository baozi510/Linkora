## CURRENT STATE — 2026-10-13 normal CLI simulator Ability open complete; six-step bounded Codex autonomy

**Latest accepted completed task:** `phase8f-level1-cli-har-stub-prebuild-and-app-open-v1` / report HEAD `4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88`, parent dispatch `b46e115b5712df32a92f0afdd95ce738d096e8ac`, report-only addition `docs/PLAYBACK_PHASE8F_CLI_HAR_STUB_PREBUILD_APP_OPEN_REPORT.md`. Actual x86 simulator Debug CLI build PASS and one clean `libs/x86_64/liblinkora_ffmpeg.so` audit PASS, distinct simulator bundle embedded, nondestructive CLI install PASS, EntryAbility started and app-specific FOREGROUND PASS. No production code changes required. This does NOT validate FFmpeg frame decode, WebP encoding, System MP4 playback or HLS cleanup; those were intentionally NOT RUN. No new raw HAP/log remote reproduction.

**User's new workflow:** GPT creates a source-bound task with target, permitted operations and caps. Codex may inspect authorized relevant native/build directories, copy previously validated FFmpeg x86 manifest/headers/lib into isolated scratch, test, diagnose and repair code or build configuration within that SCRATCH autonomously. Limit default 20 active minutes, three x86 builds only after concrete distinct fixes (first+2), two explicit ohpm --pf operations, one legal non-destructive app install only after native ABI/bundle PASS, one attempt per media case; never identical retry for an unchanged error. If blocked, unfixable or two repairs fail, stop and report `NEEDS GPT DECISION — STOPPED` with observed error, changes and next smallest decision. User original/old worktrees read-only approved subtree only; no default ARM64/GUI/keystore/password/app wipe/uninstall. Source changes candidate on `codex/*`, NOT merged or pushed to feature branch without GPT review. One sanitized public report only.

**Next dispatch:** new Level1 simulator MEDIA FUNCTION task, CLI-only. Prefer existing source-compatible installed `com.linkora.player.simulator` if its identity/provenance is independently confirmed; otherwise one necessary scoped build/ABI gate. Real FFmpeg decoded frame, optional actual WebP image encode, System MP4 play/pause/seek, HLS pending cancel/normal release/early+>20s resources and conditional independent MP4 recovery. No UI visual acceptance and no real simulator MPV native claims. Local media fixtures/diagnostic hook may block cases independently; report genuine observations or STOP. Historical closed IDs remain closed.

Older sections historical.

---

## CURRENT STATE — 2026-10-12 (direct-user CLI build PreBuild 00306060; simulator Stub made full HAR candidate)

**Latest independently confirmed user report:** user-authorized one-off CLI app-open check from OLD fixed checkout `c5d79b27c8462b8f7e1c5ca44c45d5714ae66b28` separately copied four correctly hashed pinned x86 FFmpeg archives, local MPV stub ohpm install PASS, direct Hvigor task forwarding `-p parameterFile=oh-package-simulator-params.json5` PASS. Its only actual build invocation FAILED at PreBuild `00306060 unable to get dependency @mpv-ohos/mpv-arkts version/name at local stub oh-package.json5`, wrapper exit1. No HAP, ABI audit, install, Ability start, media, GUI or keystore check. No new GitHub evidence for this direct-user check; earlier report remains `c5d79b27c8462b8f7e1c5ca44c45d5714ae66b28`.

**GitHub current source correction by GPT:** discovered `entry/simulator-stubs/mpv-arkts` contained ONLY Index.ets and package manifest, lacking standard HAR build-profile/hvigorfile/module descriptor. Added these real HAR structural files plus simulator-only root module registration and additional static checker assertions, with modelVersion and dependencies in stub manifest. `@mpv-ohos/mpv-arkts` package name/version remain unchanged; default 1.0.0 production and `com.linkora.player` untouched. Stub remains fail-closed and no MPV native library on x86 target is allowed. Har module structural missingness is a supported fix candidate, **NOT a guaranteed diagnosis or executed compilation PASS**. Official HAR source module document https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/ide-hvigor-build-har-V5 .

**Next authority:** new separate CLI-only source-bound one-off task after THIS fix commit. Continue existing user permission to ONLY read required original project's pinned FFmpeg input directory and SDK/tool help, copy validated x86 manifest/headers/libs into NEW isolated ignored prebuilt prefix. Codex allowed limited scratch-only repair of actual future compiler errors; no edit original or force push to feature branch, no GUI, signer/old keystore, app uninstall/wipe. Require real local MPV stub resolution, x86 ABI valid + embedded simulator bundle identity BEFORE install. User goal is initial NORMAL CLI Ability start and then decode/encode/playback; no UI visuals. Previous READY Codex autonomous task superseded, do not run both. Current owner source patch has build0 / ABI0 / install0 / media0.

Older sections below historical.

---

## CURRENT STATE — 2026-10-12 Two intended native targets, simulator ABI mixing fix staged as source config (NO RUN)

**Architectural answer:** ONE Linkora shared ArkTS/product source with TWO platform target dependency configurations. `default`: ARM64 native FFmpeg + genuine MPV for real hardware; `simulator`: x86_64 native FFmpeg + actual simulator System AVPlayer + compile-only fail-closed MPV stub. The prior locally reported x86 simulator HAP mistakenly carried FOUR ARM64 MPV/AKI/C++ libs alongside x86 FFmpeg. That is incorrect packaging, NOT evidence the intended two-platform design is wrong. The separate actual CLI installer `9568332` sign-info conflict and user default ARM64 HAP `9568347` ABI rejection must not be conflated with each other or with old keystore password attempts.

**Fresh GitHub owner review:** report `ef204701e010382a5d5822645d913cc3be9e435f`, correct immediate task parent, only one new file; report locally verified source/lock and categorical existing same bundle, NOT effective dependency resolution or cert mismatch. Prior `phase8f-level0-simulator-abi-dependency-install-identity-diagnosis-v1` is completed READ-ONLY, do not run it again.

**GPT patch:** owner chooses documented parameterized OHPM dependency selection. Root `oh-package.json5` default parameterFile to `./oh-package-default-params.json5` (real MPV 1.0.0), `entry/oh-package.json5` MPV dependency `@param:dependencies.mpv`; separate `oh-package-simulator-params.json5` local stub path under root. Removes `simulatorTargetDependencies` unsupported/unconsumed field. Sets simulator ONLY product bundleName `com.linkora.player.simulator`, preserves default/AppScope `com.linkora.player` and default actual native MPV. `scripts/check-simulator-product.cjs` source guard checks the new arrangement and supports `--simulator-lock` required effective local MPV dependency verification. No checked-in auto-generated lock manual tampering. **Not yet proven with ohpm or compiler**; source/config-only. No native/codecs/media PASS.

**NEXT ACTUAL VALIDATION:** One distinct CLI-ONLY task (GUI/IDE 0): in isolated source-compatible checkout, standard ohpm `install --pf oh-package-simulator-params.json5`, inspect actual generated simulator MPV lock before any Hvigor build. Run directly configured Hvigor with `-p parameterFile=oh-package-simulator-params.json5` and exact simulator product/module/Debug (ONE scoped build max), NOT unverified `devecocli run` param forwarding. HAP **must** pass existing x86_64 FFmpeg-only ELF/ABI gate and must embed `com.linkora.player.simulator` before attempting legal non-destructive simulator CLI install. No old signer/password/keystore, no uninstall/clear/reset, no original user workspace/old stopped checkouts. If install works, prioritize real decoded FFmpeg frame, WebP if callable, System MP4 controls/HLS cancellation/cleanup/recovery as safety allows; no UI beauty/layout/screenshot tests. Stop dependent cases on ABI/build/install fail, with exact status and no retries. Release ARM64/real MPV still later Level2/3.

Older sections historical.

---

## CURRENT STATE — 2026-10-12 (V2 CLI x86 HAP invalid; install identity and packaging mechanisms need distinct diagnosis)

**Independently verified GitHub:** evidence HEAD `5cd9166f725be3418545a0ef2ea2277390d4bd83`, parent V2 task dispatch `eb079eb70892fa3f166db3e75309fd4d3f6a9a95`, exactly one new `docs/PLAYBACK_PHASE8F_SIMULATOR_MEDIA_FUNCTION_REPORT.md` (blob `ef4779d61651090b58d5495fc4ab909139cbfa00`). Completed task `phase8f-level1-simulator-codec-encode-playback-v2`: **PARTIAL/DEPENDENCY BLOCK** with real package audit FAIL and installer FAIL; do not replay completed ID. Source review did not reproduce private HAP/log byte findings from GitHub.

**Observed locally reported outcomes:** user-authorized devecocli simulator start1 connected x86_64/API26; one DevEco CLI run wrapper child1 install 9568332, build pipeline verbally reported BUILD SUCCESSFUL but nested build exit not separately captured; manual sign0/password probe0. New HAP reported x86 `liblinkora_ffmpeg.so` plus four ARM64 MPV/AKI/C++ libraries, so x86 ABI checker child1. This is **not** an executable x86 package even though compilation completed. Private unsigned HAP from earlier source and the new ABI-invalid HAP MUST NOT be reused. User separate default ARM64 HAP `9568347` is a different build/profile and error; no UI/media/FFmpeg decoder/WebP encode/MP4/HLS/cleanup recovery executed.

**Diagnosis anchored in GitHub:** `entry/oh-package.json5` has real `@mpv-ohos/mpv-arkts` in unconditional production `dependencies`; `simulatorTargetDependencies` is a separate unsatisfied claim and `entry/oh-package-lock.json5` locks published real MPV HAR; `scripts/check-simulator-product.cjs` checks only presence of that unsupported-by-evidence field and NOT effective resolved MPV. Official ohpm documents Hvigor-generated target dependency maps and `--target_path`; validate CLI outputs before choosing supported fix. `9568332` official description concerns existing app/signature identity conflict or multi-module signature inconsistency, not necessarily an inaccessible keystore. Current AppScope bundleName shared across simulator/default. Never force-uninstall user app, wipe emulator, clear data or alter keys. Consider separate simulator product bundle identity after specific no-mutation read-only diagnosis, with unchanged default identity and only supported product-level config.

**Current direction:** user wants decode, encoding actually implemented (WebP), playback, not UI appearance. Codex next task should do one bounded CLI-only source/installed metadata check; **ZERO builds, IDE GUI, signer, manual profile/key/password probe, installs and media opens**. No repeated failed helpers. GPT owns source/config correction after diagnosis. After verified safe x86-only output and legitimate install, prioritize FFmpeg actual frame buffer decode and System AVPlayer playback/controls/cancellation. Real mpv ARM64 device and hardware codecs remain separately deferred; no false runtime PASS. Preserve all old private STOPPED worktrees and possibly dirty original D:/Linkora; final bytewise snapshot NOT RUN.

Older sections below are historical.

---

## CURRENT STATE — 2026-10-12 Codec/encoding/playback functional checkpoint replaces UI test

**Owner intent:** use simulator for **media-function acceptance**, not visual appearance/UX. Remove screenshot, pixels ROI/color UI/layout and foreground cosmetic gating. A real installed/callable Linkora functional entry remains necessary to run media tests; do not call launcher/process exit a playback PASS.

**Verified source boundary:** x86 `linkora_ffmpeg` probes input/container/encoded stream codec and actually decodes FFmpeg frame buffers to RGBA; existing `FfmpegRuntimeSmoke` under entry simulator diagnostics can test it. Playback uses native System AVPlayer; MPV simulator runtime is unavailable stub. Existing encoding is WebP thumbnail encoding via `SystemWebPEncoder`; no known video/audio FFmpeg transcoding encoder in current source. Do not confuse an input codec named H264/AAC with an actual encoding API. Tests should record probe/real decode/WebP encode/System play separately with accurate `PASS/FAIL/BLOCKED/NOT RUN` and resource cleanup; no 59-case matrix, UI appearance review, video snapshot requirements or raw media disclosure.

**Supersede older READY dispatch:** previous `phase8f-level1-normal-deveco-simulator-run-v1` at `c7668da343d9252031dbf9bfb27e5115f21df29f` is not reported executed. Next dispatch has a new ID and source parent consisting only of four policy/status doc changes. New run uses default DevEco Studio GUI Run in isolated clone, `simulator` product/`entry@simulator`, at most one necessary Debug compile (current source differs from older unsigned HAP), **no old keystore**, no manual `sign-app`, no ARM64/default compile. If GUI/installer unavailable, stop dependent runtime only, record factual failure and continue safe reporting.

**Priority functional probes:** real FFmpeg x86 probe and decode extracted frame with RGBA dimensions/bytes/time, cancellation/timeout, zero active sources where observed; WebP encoded output through existing path if accessible; System H264/AAC MP4 actual play/pause/seek/position; native HLS H264 pending cancellation no leaked candidate/stale fallback, sampled app-associated resources early and >20s; MP4 recovery conditional on successful cleanup. No guessed first-frame pixels, no screenshot, no MPV claim. Keystore remains deferred for device, earlier V3/V4 evidence unchanged, current static fixes only STATIC OK and unbuilt.

**Codex limits:** no production source edits, no extra test runners/harness generation, no repeated compiled builds/fixture regeneration. Exactly one small sanitized remotely reviewed public report if safe. Preserve original possibly dirty workspace and all stopped private evidence. Actual production code and app have NOT been run by this doc change.

Older sections below historical.

---

## CURRENT STATE — 2026-10-12 (Critical correction: normal simulator Run does not require old keystore gate)

**User goal:** run current Linkora in the connected x86_64/API26 simulator through the standard DevEco Studio Run/Debug workflow. Our earlier manual `sign-app` and old keystore precondition was an unnecessary added test-gate for **simulator development**. Huawei official getting-started statement: using emulator/previewer debugging does not need configured signing information; real hardware has its own signed deployment requirements (https://developer.huawei.com/consumer/cn/develop-novice-guide/). Prior V3 native `11014003` reflects failure of extra SDK `sign-app` attempt, not proof DevEco Run cannot work. Old V4 no credential test and old user-reported inaccessible keystore remain true **historical** details; no new password work required.

**Current code:** Level0 PlaybackEngine stale-async fixes static-reviewed and CLOSED; regression tests AUTHORED/NOT RUN. `build-profile.json5` products default+simulator, signingConfigs empty; `entry/build-profile.json5` entry simulator target; SDK x86 native expected FFmpeg analyzer only, no real mpv on simulator. Prior private unsigned x86 HAP built from earlier source must NOT be reused for current source runtime. Explicit user goal now justifies one new scoped simulator Debug build as part of normal IDE Run, if the live source cannot be proven compatible with a previously built artifact.

**NEXT:** one distinct new task-only `LEVEL_1_FUNCTIONAL` dispatch (not rerun previous closed IDs). In an isolated clone, cheap fresh target check, select product `simulator` and target `entry@simulator` in DevEco Studio, invoke normal Run ONCE, no `sign-app`, no old keystore probe, no independent duplicate build. Capture actual install result, foreground Linkora UI/window/pixels, then healthy MP4 and independent HLS H264 PREPARING native cancellation/early+>20s cleanup, distinct recovered MP4 conditional on clean cancellation. If any install fails, record actual native error and no dependent media attempts; never start password guessing or wipe/uninstall user data. Source protections and public privacy still mandatory. Historical STOPs/FAILs unchanged, no new functional PASS claimed by this handoff update. No ARM64 default full build or device hardware.

No production code edits in THIS owner policy change; task dispatch will be separate after review commit. Earlier CURRENT sections below are historical.

---

## CURRENT STATE — 2026-10-12 Level0 stale-async closure accepted; next move is product implementation

**Branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`. Remote static evidence SHA `95ce0319aaa8dbe96e8ee271c3f03c8e806538fe`, one parent `a0f6dfb0b07333222ba9826acf56d0dad6854c8b`, exactly one new `docs/PLAYBACK_PHASE8F_LEVEL0_STALE_OPEN_CATCH_CLOSURE_REVIEW.md`. GPT independently read the published report/source/test and accepts three bounded STATIC OK verdicts closing the two earlier known issues. No new source findings **within that limited scope**; no compiled/tested/runtime PASS.

**Code baseline:** `linkora_core/src/main/ets/playback/PlaybackEngine.ets` source blob `3cb96b50d3d4a10465a2fa11c03a652773c852cc`; `entry/src/test/PlaybackEngine.test.ets` blob `df3857f8b3c388b36638cbc42be5f9f7fc7e3ad6`. Adaptive/System production blobs `1050012dbef214efba5ebccb5571cc9174345c08` / `cc78c2611e8582633f2a67cb323f3072f5d8a31f` unchanged. Static tests authored, **NOT RUN**. Keystore remains UNAVAILABLE, installation/foreground/MP4/HLS native pending cancellation cleanup and recovery all NOT RUN/NOT PROVEN. ARM64/Release/ABI at Level2; genuine device at Level3.

**Dispatch policy:** the completed `phase8f-level0-stale-open-catch-barrier-review-v2` task has been CLOSED in the latest `docs/CODEX_VALIDATION_TASK.md` and is not reusable. Do not run continuous audit/check loops; **no new READY Codex validation task yet**. Next owner action is an actual useful self-contained Level0 product feature implementation, based on current source and plan, without mandatory build after every edit. When needed, GPT creates new source commit then separate task-only dispatch with honest NOT RUN gates. Do not prompt for passwords, touch original dirty workspace/old stopped evidence, rebuild retained unsigned HAP or infer current source runtime from past HAP.

Older sections below historical.

---

## CURRENT STATE — 2026-10-12 reviewed Level0 findings and authored minimal PlaybackEngine correction

**Branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`. Previous remote evidence HEAD before source fix `279fb2216de0e97abec684d82476840826efd05d`, added one remotely inspected static-review report. Old `phase8f-level0-playback-engine-stale-async-review` completed with two source-level findings; historic READY header is superseded by next distinct task-only dispatch, not permission to replay that completed task.

**Fix applied by GPT:** post-await `this.isCurrent(sessionId)` check inside `PlaybackEngine.open` catch before `this.fail`, so old rejected prepare/play after slow release cannot overwrite new playback snapshots. New deferred-prepare-failure/slow-disposal/new-open regression added; deterministic old pending interruption pause rejection test now returns exact deferred Promise and waits for later registered rejection drain. Previous four original race tests preserved. Production source file `linkora_core/src/main/ets/playback/PlaybackEngine.ets`; one test file `entry/src/test/PlaybackEngine.test.ets`. No change to Adaptive/System PlaybackPort source or Native backend.

**No executed result:** build0, tests0, signer0, keystore0, emulator/media0. Static reasoning alone is not PASS for test runtime, native release, actual pixel or recovery. User keystore UNAVAILABLE and deferred; do not return to signing tasks. Old private unsigned HAP hash `DBF39571A1FD594FC8522F5759C678E9A97FA5EF3E3F34EA4615A6707CF9C11E` corresponds to earlier build/source, not new production code. Full ARM64/Release/ABI Level2, hardware Level3.

**Next authority:** after this fix commit, publish one separate `LEVEL_0_FEATURE` Codex narrowly scoped READ-ONLY static verification task for new catch + Promise barrier regression (and source identity). No repeated build, Hypium execution, signing or private credential probes; report independent findings without changing source. Then progress meaningful features; do not infinitely rerun optional helpers or evidence packaging. Preserve user original dirty workspace and all historical stopped data.

Prior sections below historical.

---

## CURRENT STATE — 2026-10-12 Level-0 source fix authored for PlaybackEngine stale operations

**Branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`; previous remote HEAD before this source change `61494cda50fae092647db5133e781d2105063d52`. Keystore is UNAVAILABLE by user report; V4 remains CLOSED, latest independently reviewed V4 evidence `2763174a67da32332754d745a0de174328c7128f`. No keystore checking/retry/new signed HAP or simulator runtime permitted here.

**GPT source work:** only `linkora_core/src/main/ets/playback/PlaybackEngine.ets` and `entry/src/test/PlaybackEngine.test.ets` are production/test diff in the new review commit. Session/port equality now protects old pause/play and interruption async rejections; session identity recheck protects `open()` and `release()` after awaited old-port disposal. Four fake deferred-operation regression cases authored. Existing Adaptive/System production blobs remain `1050012dbef214efba5ebccb5571cc9174345c08` / `cc78c2611e8582633f2a67cb323f3072f5d8a31f`. No actual compile, test or emulator operation was done; don't infer PASS or proven native release. The previously locally verified unsigned HAP belongs to an older source and is NOT source-bound to this new code.

**Immediately follow with new distinct task-only dispatch:** `LEVEL_0_FEATURE`, READ-ONLY Codex static review of stale session/callback isolation and four regression cases with actual source SHA and task-only drift; no build, signing, SDK, simulator, HAP, native artifact, user workspace or historical private logs. If optional tests cannot execute without build, mark NOT RUN. Review should seek concurrent `open`/`release`, async toggle pause rejection, interruption pause rejection, stale callbacks and resource ownership; distinguish source reasoning from runtime evidence. Preserve user workspace untouched. No new test pass claims without execution.

**Later path:** if offline review is clean, return to other feature implementations and defer Level1 installed playback until a legitimate signing route exists. Full ARM64/Release/ABI and real MPV/hardware remain Level2/3; any eventual usable artifact must match current source, not the old unsigned HAP. Older headings are historical.

---

## CURRENT STATE — 2026-10-12 (Keystore unavailable by owner report; runtime deferred; Level-0 development unblocked)

**Repo / branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`. Latest independently reviewed published Phase8F V4 evidence commit: `2763174a67da32332754d745a0de174328c7128f`. Previous current remote closure `3c49bde00a79b099f1d4a2ecd9652cf6a2ef7fc8`, `docs/CODEX_VALIDATION_TASK.md` `CLOSED` and **NO READY execution authorization**.

**User decision:** The existing keystore is **UNAVAILABLE**; defer keystore access/signing until a lawful supported secure method exists. User's statement is a planning/availability status, not evidence of a new failed password test. V4 itself probed0, signed0, built0, opened0. Earlier 11014003 belongs to V3 only. No attempt should be made to obtain passwords, inspect credential stores, export/recreate keys, rerun SDK signing or dispatch credential-check tasks without an actual changed prerequisite. Do not publish secret material or expose credentials in argv/env/shell/log/chat.

**Immediate next meaningful work:** **LEVEL_0_FEATURE** source implementation and architecture review can continue independently. Prioritize actual backend state-machine and PREPARING pending cancellation/ownership/resource-release correctness, UI wiring and error/recovery/fallback contract, or independent browsing/network/cache features after checking real code; targeted pure/unit checks permitted. GPT owns source changes; Codex owns explicitly dispatched validation, not implementation. Do not require every source edit to compile. Unbuilt changes must say `BUILD NOT RUN`, `RUNTIME NOT PROVEN`; no full old three-build verification loop. If a future milestone or native-risk boundary is reached, Level-2 compile/link/ABI must be completed then, not retroactively claimed. Signing-dependent simulator runtime and real-device acceptance are blocked/deferred. **No code edit/test is claimed by this handoff update.**

**Retained private artifact:** previously locally corroborated unsigned x86 Debug HAP SHA256 `DBF39571A1FD594FC8522F5759C678E9A97FA5EF3E3F34EA4615A6707CF9C11E`, not uploaded and not a signed installable artifact. Reconfirm actual bytes and tested production source if future signing becomes authorized; newer production edits invalidate naïve reuse. MP4 actual picture/progress, HLS H264 pending native release and early/>20s cleanup, independent MP4 recovery ALL `NOT RUN / NOT PROVEN`. Old Rerun4 STOPs/privacy findings not rewritten.

**Task policy:** V4 remains CLOSED; DO NOT auto-dispatch V5 to probe the same unavailable keystore. Start a fresh standalone source-level feature change when directed. Any later Codex task is a separate reviewed SHA and task-only dispatch. Documentation-only deferral decision may be committed without changing old CLOSED task or source. GitHub is canonical handoff.

Earlier CURRENT sections below are historical.

---

## CURRENT STATE — 2026-10-12 V4 evidence accepted, secure keystore access NOT PROVEN; no READY retry

**Remote and validation:** GitHub evidence HEAD `2763174a67da32332754d745a0de174328c7128f` contains exactly two new V4 sanitized report/result files and has single parent original V4 dispatch `d719ec7fab3af399f6a3ed6df60a273496d53792`. GPT independently read both complete files. Result `ACCEPTED — DEPENDENCY_BLOCKED — KEYSTORE ACCESS`, task `phase8f-level1-keystore-access-reuse-unsigned-smoke-v4`, `STATE: COMPLETED WITH DEPENDENCY BLOCK`. Public claims of prior unsigned HAP byte integrity and x86 native ABI verification are **locally corroborated**, not independent GPT binary replay; original private file/log bytes were never published.

**Current boundary:** V4 new build0, keystore probes0, signing attempts0, app install0, official opens0. No new SDK `11014003`; that error arose only in previous V3 sign task. User merely asked to proceed, which was not proof of secure keystore access. Secure access channel and keystore-open success NOT PROVEN; prior profile/fixture checks were NOT repeated and cannot stand in for fresh sign/install acceptance. Connected emulator x86_64/API26 in reported read-only check. Normal System HLS PREPARING candidate release/early+>20s cleanup and separate recovery `NOT RUN / NOT PROVEN`. ARM64 and hardware milestones deferred. No product source change warranted.

**Owner next action:** close V4 executable task header as not READY; **do not dispatch another keystore credential inspection** unless the authorized user independently confirms from their trusted existing local signing UI/manager that this keystore can be accessed. The user should share a status ONLY, never a password, key/alias, signing configuration, credential storage path, log, screenshot of secrets or other sensitive data. If no supported safe mechanism can establish access, remain `DEPENDENCY_BLOCKED` and continue other Level0 implementation work rather than repetitive checks/builds. If access is confirmed, owner may separately authorize one new legitimate signing step using previously retained unsigned simulator Debug HAP **only after** confirming actual private SHA256 `DBF39571A1FD594FC8522F5759C678E9A97FA5EF3E3F34EA4615A6707CF9C11E` and source binding again. No repeat build, guessing, unsafe argv/env secret injection, or old failed helper. Historical stopped task findings not rewritten as PASS.

**Repository policy:** signed install/app UI/three focused media cases still NOT RUN, not silently certified. Two public paths and remote commit independently verified, but user original workspace full final bytewise snapshot NOT RUN. The latest `docs/CODEX_VALIDATION_TASK.md` is CLOSED, not a new READY task. Future new dispatch must follow review commit then separate task-only commit after a genuine meaningful prerequisite is resolved.

Older CURRENT sections below are historical.

---

## CURRENT STATE — 2026-10-12 Level1 source-bound x86 build locally PASS; SDK signing keystore access blocked

**Remote verified evidence commit:** `d4905fe4b00f74681e9ff44e0a3102b9679e7ad6`, exact parent prior dispatch `9fc247a5c89173a91e07d1695ae404e70fae82c1`, only the authorized report `docs/PLAYBACK_PHASE8F_LEVEL1_SCOPED_SMOKE_REPORT.md` and `test-lab/playback/phase8f-level1-scoped-smoke-20261012/result.json` were added. GPT independently fetched both and compared them. Private raw build/sign streams NOT available for full independent replay; publicly recorded result is `DEPENDENCY_BLOCKED — SIGNED ARTIFACT`, `COMPLETED WITH FAILURES / PARTIAL`, NOT playable PASS.

**Reported local outcomes:** running API26 x86_64 emulator connected and valid existing fixture/profile membership; optional absent README exit1 `RECORD_ONLY` and did not halt independent stages; exactly ONE scoped simulator Debug build real subprocess0 with FFmpeg-only one-library whitelist, no ARM64/default full build. Sign-app SDK Java/outer exit1 `11014003 / Init keystore failed: keystore password was incorrect`. No signed HAP, no installation/foreground, NO media opens, pending HLS native release-cleanup and recovery NOT RUN / NOT PROVEN. No evidence of product/SDK code defect. Keystore storage opening cannot be inferred from file presence and valid profile membership. Private original logs and signing material kept private; original user workspace reportedly not written, final exhaustive bytewise comparison NOT RUN.

**Next READY separate task to dispatch:** no recompile, no old stopped signing retry. Inspect private existing credential availability using authorized user-owned local facilities, no secret disclosure, guesses, brute-force, profile or keystore regeneration or SDK preference changes. Reuse ONLY if the existing unsigned HAP matches PRIVATE hash `DBF39571A1FD594FC8522F5759C678E9A97FA5EF3E3F34EA4615A6707CF9C11E` AND original dispatch/source/build x86 artifact provenance. One legal successful-credential-dependent sign attempt max; if credential unavailable or opens fail then `DEPENDENCY_BLOCKED — KEYSTORE ACCESS` with all media NOT RUN. If signed source-compatible HAP produced, install and run scoped healthy MP4 + HLS H264 PREPARING cancel independently when app safe; recovered MP4 only after normal native release and early/>20s resource cleanup. Small redacted public report/JSON, exact paths/privacy/remote SHA, no redundant gzip/inventory. Full ARM64/Release/ABI only at Level2 milestone; real hardware Level3. No direct secrets in public logs/chat.

No previous STOP or unsupported product PASS rewritten. Sole execution authority is newest committed `docs/CODEX_VALIDATION_TASK.md`, not this handoff.

Older sections below are historical.

---

## CURRENT STATE — 2026-10-12 Error classification and dependency-scoped continuation

**Repo:** `baozi510/Linkora`, branch `feat/playback-capability-phase8`. Prior dispatch `4e08263fe572ad3caf419c0be741985a2c6f262c` was READY; no new remote evidence from it had been reported when GPT reviewed the current STOP policy. The prior ID must not be executed concurrently with the new dispatch.

**Critical correction:** earlier task text often used unconditional STOP after a helper, prerequisite, actual functional FAIL or evidence push problem. Under newly documented `docs/AI_WORKFLOW.md` rule: nonessential errors are `RECORD_ONLY`; a genuine test failure is `CASE_FAIL`; a missing prerequisite is `DEPENDENCY_BLOCKED` to dependent work; unsafe Git/privacy delivery is `PUBLICATION_BLOCKED` but earlier local observations remain `LOCAL UNREVIEWED`; only genuine source/privacy/user-data or unsafe runtime state is `GLOBAL_SAFETY_STOP`. Each failure retains its true numeric exit and cannot become PASS; no helper/test retries to manufacture success, no full-build rerun triggered by optional tooling.

**Next NEW distinct `LEVEL_1_FUNCTIONAL` task** should establish target/signing/UI cheaply, allow MAX ONE necessary simulator Debug build, then collect healthy MP4 and HLS PREPARING native-cancel evidence as *independent* once-only cases if safe. If cancellation fails or does not prove normal native release and early/>20s resource cleanup, recovery MP4 is `NOT RUN` but other independent results remain. App crash/native state contamination blocks further unsafe opens. A missing emulator blocks only simulator runtime, not independent source reading/report. Brief sanitized result file and report are sufficient; privacy/Git path/remote SHA remain real publication requirements, without a new brittle staging helper. No full default ARM64 cycles or physical-device claims; those are milestone/device gates.

**No historical relabeling:** original Rerun4 STOP and separate publication failures remain immutable and local-only; no Rerun4 remote evidence SHA or simulator cancellation PASS. The developer original workspace and stopped checkout must be protected. Current Codex authority is solely the latest `docs/CODEX_VALIDATION_TASK.md` created after this policy review commit.

---

## CURRENT STATE — 2026-10-12 Phase8F Level1 first attempt stopped on helper hardcoded source path

**GitHub remote check:** HEAD at the reported STOP remained `e605bccf1652f30b9b572e3259ec3f5b0d2c5fe9` on `baozi510/Linkora` / `feat/playback-capability-phase8`, an earlier dispatch and not an evidence SHA. `phase8f-feature-first-targeted-simulator-cancel-smoke` is locally reported STOPPED, unpublished, no local/remote evidence commit. It cannot be silently continued or rerun under the same ID.

**OWNER-INDEPENDENT source tree verification:** `entry/src/main/ets/playback/PlaybackPort.ets` does **not** exist; actual source is `linkora_core/src/main/ets/playback/PlaybackPort.ets`, Git blob `231e49b84dce45b83c472fbed0b258711ce758d5`. PlaybackEngine.ets imports its local PlaybackPort. The private preparation helper hardcoded the nonexistent entry path, reportedly `FileNotFoundError` Python1/outer1; not a product/SDK/HarmonyOS bug. It was neither fixed nor retried under the stopped task.

**Reported separate publication STOP:** only two authorized NEW local output files (report, result.json), `git add` numeric0, but PowerShell extra staged-path validator threw `Unauthorized staged paths` with outer1. The expected/actual pathname arrays and original wrapper full streams/times are NOT independently retained: do not claim unauthorized file staging as fact. The final STOP amendments were not staged, no commit/push. No simulator, legal signing, UI, fixture, builds or official media opens attempted; three functional scenarios NOT RUN and cancellation/recovery NOT PROVEN. Full ARM64/ABI/Release remains DEFERRED to milestone. No full final protected-workspace bytewise comparison was run; historical failed reports and private bytes remain untouched per local handoff, not remotely verified.

**NEXT:** New distinct READY `LEVEL_1_FUNCTIONAL` task may use exact source-verified paths and direct Git inventory instead of invented prep helper; **first** cheap actual emulator/HDC/fixture/signing check, **then at most one scoped simulator Debug build only if needed**, **then** actual MP4 healthy / pending HLS H264 cancellation+normal native release / independent MP4 recovery. Exact one report+one result.json sanitized evidence if possible; stage with explicit `git add --`, check raw staged Git names directly, no new array-comparison PowerShell helper. If an actual necessary Git/security gate fails, STOP honest; never run expensive verification merely because auxiliary publication failed. No old STOP/helper/controller replay, no user workspace mutations, no quota checks. GPT reviews only actual remote SHA.

Earlier CURRENT sections below are historical.

---

## CURRENT STATE — 2026-10-12 Feature-first/test-path change; focused Phase 8F smoke pending

**Repository / branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Approved new rule** in docs/MASTER_IMPLEMENTATION_PLAN.md and docs/AI_WORKFLOW.md replaces per-source ARM64 full-build-always: `LEVEL_0_FEATURE` development without mandatory compilation; `LEVEL_1_FUNCTIONAL` check emulator/target/signing cheap readiness FIRST, then at most one necessary source-aligned simulator Debug build and targeted functional smoke; `LEVEL_2_MILESTONE` full ARM64 Debug/Release/native ABI/link and simulator regressions at cohesive phase/integration gate; `LEVEL_3_DEVICE_BATCH` physical hardware tests. Three full builds are not default. Preserve explicit BUILD NOT RUN, NOT RUN, NOT PROVEN labels. Optional redundant gzip/inventory packaging is not a required gate if essential readable sanitized evidence is complete; any would-be-published material still needs actual privacy/path/safety checks.

**Immediate source boundary:** last confirmed remote HEAD before new review was `eee759ffe99c52dd139b20d4261275f22c23a6f0`, an old publication v3 READY dispatch, not an evidence commit. That unreported READY task will be SUPERSEDED by a new task-only dispatch after this review/policy commit. Do not execute both. Original Rerun4 task `phase8f-sim-rerun4-single-controller-ui-cancel` stopped with local failed emulator JSON inspector, and its local report +109 evidence files were never pushed; v2 publication privacy scanner also stopped. All claims remain local/unreviewed. Previous old task STOP/FAIL records, v2 critical privacy findings, original user workspace and private stopped checkout are immutable; no assumption v3 ever ran. Do NOT try to recover/push prior 110 evidence files without separately proving privacy safe. Do not rerun old controllers/helpers/tests or patch production from tool-failure reports.

**New single READY authority to dispatch:** a different task ID `LEVEL_1_FUNCTIONAL` Phase 8F *three-scenario essential runtime smoke*, preflight actual emulator target and legal signed-install capability before any build; maximum ONE simulator Debug build if required, NO default ARM64/Release/triple build; only healthy MP4 → native pending HLS H264 prepare-cancel/normal early+>20s resource cleanup → independent MP4 recovery after cancel clean. Not HLS HEVC/FFV1/six-case complete gate, and not physical ARM64/MPV HDR/advanced audio validation. If emulator target unavailable, STOP `BLOCKED — ENVIRONMENT` without building. Bounded small sanitized report and decisive evidence, with critical privacy and remote verification but no mandatory 33 gzip pairs/exhaustive packaging scripts. Product runtime errors remain real FAIL and source fixes are GPT-only. Do not replay finished prior IDs. No quotas or chat polling.

**Owner next after remote evidence:** GPT review smallest real functional outcome; continue production feature work or schedule milestone compile when appropriate. If no simulator, continue other nondependent features and resolve target availability as a separate cheap environmental precondition, not endless triple-build reruns.

Older sections below are historical.

---

## CURRENT STATE — 2026-10-12 (publication v2 failed required privacy classifier, remote evidence NONE)

**Repo / branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`. GitHub independently shows HEAD `5d66330f5939480e9ae60988742dd300f60003be` (v2 publication dispatch) with no newer evidence commit.

**Local STOP handoff (NOT independently reviewed remote evidence):** `phase8f-rerun4-evidence-publish-no-retest-v2` failed REQUIRED privacy gate C, actual Python child1 and outer PowerShell1. New broad regex `(?i)[a-z]:[\\/]` can interpret `s:/` in `https://` as a Windows drive path. Nine locally recorded matches span controller-source, fresh-fetch stderr, fresh-submodules stderr, simulator stdout (plain and gz each), and submodules.json. **All exact contexts are UNKNOWN to GPT**, so do not declare no sensitive data. The observed record UTC is not exact subprocess start/end. Earlier source/ancestry and 110 staged public paths are Codex-reported, not remotely replayed. No candidate copy, gzip verification, commit/push, final original-workspace byte comparison, emulator or new media test was performed. Local/remote evidence SHA NONE.

**Rerun4 historical:** separate stopped `phase8f-sim-rerun4-single-controller-ui-cancel`, local claimed three fresh green verifiers but actual PRIVATE inspector list/dict child1, then private controller-state write WinError5 during evidence preparation. Original six official media opens NOT RUN; candidate normal release and recovery NOT PROVEN. No new product issue established; no original STOP is superseded or reclassified as PASS.

**Owner judgment:** Privacy is a CRITICAL publication prerequisite under docs/AI_WORKFLOW.md, not an optional diagnostic. The new regex defect may produce false positives but cannot establish safe publication; preserve failed v2 audit untouched. The next distinct READY task must verify exact nine contexts using a fresh properly delimited drive-path detector and semantic checks; independently review all 110 candidate files and decompressed gz, complete SHA/inventory privacy gates, commit/push only if safe, and fresh-fetch the real evidence SHA. No rerun of old helper/controller/scanner, no builds/SDK/emulator/device/media, no modifying old isolated origin or original user workspace. If genuine secret or unresolved ambiguous hit, STOP BLOCKED — PRIVACY REVIEW without publication. Older tasks and handoff sections are historical.

---

## CURRENT STATE — 2026-10-12 New approved no-retest tooling rule; new publication-only task pending dispatch

**Repo:** `baozi510/Linkora`, branch `feat/playback-capability-phase8`.

**User-approved and now written in docs/AI_WORKFLOW.md:** When an **explicitly predeclared OPTIONAL, noncritical** helper fails, and evidence supports that its failure cannot invalidate any required check or safety/publication gate, record `RECORDED — NONCRITICAL TOOLING ISSUE / NO RETEST`; no old-helper retry, full build cycle, media replay or fresh validation solely for optional helper green status. If effects not established harmless or the stage is required for test validity, preserve FAIL/BLOCKED/NOT PROVEN and do not waive. Cheap prerequisites first; critical privacy, evidence integrity and verified remote push mandatory for independent review. Existing STOPs remain final and immutable.

**Current historical STOP:** Rerun4 original task `phase8f-sim-rerun4-single-controller-ui-cancel` reported local FAIL from metadata inspector JSON list/dict error after independently reported fresh green build stages; evidence publication separately failed on PRIVATE controller-state atomic write WinError5, leaving no evidence SHA. Underlying error cause and read-only effects of emulator -config NOT PROVEN. Signing, installed HAP, app foreground and all six official media opens NOT RUN; cancellation/recovery NOT PROVEN. No new player bug established. Do not re-execute this old task or its failed tools.

**New authority:** Previous publication task `phase8f-rerun4-evidence-publication-recovery-only` (dispatch `135b3b0e6819548ed449a719289b2281b3f07c1a`) is SUPERSEDED. The NEW future distinct READY task in `docs/CODEX_VALIDATION_TASK.md` alone may read/recover, carefully sanitize/audit and publish EXISTING original Rerun4 report plus evidence with a separate clean clone. No new simulator/device/build/playback tests, no touching user original workspace; preserve original stopped checkout and historical failures, and do not fabricate results. Treat unrelated auxiliary publication diagnostics as record-only where preclassified; true privacy/hash/path/commit/push faults remain blockers. GPT reviews only verified new GitHub evidence commit, never this chat narrative alone.

---

## CURRENT STATE — 2026-10-12 Phase 8F Rerun 4 stopped locally; evidence not pushed

**Repo / branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Owner review boundary:** The branch remains at Rerun4 dispatch `f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce`, **not** an Rerun4 evidence SHA. Codex reports `BLOCKED — EVIDENCE NOT PUSHED` and local `FAIL — REQUIRED TEST GATE`. The local report and109 evidence files have not been independently read from GitHub; there is no local evidence commit or remote evidence commit. Do not turn local assertions into GPT-accepted results or treat dispatch SHA as evidence. Completed Rerun4 ID `phase8f-sim-rerun4-single-controller-ui-cancel` is STOPPED and must not run again.

Reported local positives: one PRIVATE blocking controller's synthetic checks; fresh serial default→simulator→default and independent Hypium210/210. Reported test STOP: device list empty, emulator config listed but not running; extra PRIVATE inspector child1 on JSON list/dictionary `AttributeError`; no signing, installed HAP, app UI or any of six official opens. Native cancellation cleanup/recovery NOT RUN/NOT PROVEN; no demonstrated production defect. Actual outer helper full byte-identical stdout/stderr/times not independently retained; `-config` with no args cannot be certified read-only. Reported publication STOP: new audit hit `PermissionError [WinError 5]` writing a PRIVATE controller state file, commit helper exited1; cause not determined, no push, report amended after staging. Private/source/secret protection assertions are awaiting remote evidence.

**Owner decision:** Dispatch a distinct new task to **publish ONLY original authorized local report/evidence** after new independent nonmutating audit/privacy checks in a clean isolated checkout. Do not reuse/retry failed Rerun4 inspector, controller or audit, change original staged workspace, rebuild or test, query quotas, touch production/tests/media/profiles/signature, or boot/reset emulator. Codex must push and verify a new remote evidence SHA before GPT independent review. Rerun3 and older STOP remain historical. New task file is the sole authority; this handoff is not itself executable authorization.

---

# Linkora Session Handoff

## CURRENT STATE — 2026-10-11 Phase 8F Rerun 3 controller observation STOP reviewed

**Repo / branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Owner ruling:** **ACCEPTED — FAIL — REQUIRED TEST GATE** for completed `phase8f-sim-rerun3-serial-sign-ui-cancel`. Tested SOURCE_SHA `bfd34a33a36772077538c7c57527e30f23689a95`, DISPATCH_SHA `026559e1975b44d00096d0fdccef7d164d0df049`, independently reviewed remote evidence `4ef43b09a4e8a05e7021b7734fdfd2ab767bb138`. Evidence-only 98 authorized new report/files. This ID is closed, do not repeat.

Three fresh verifiers independently recorded process0 and proper order: default-first, simulator+finally EOL-only four locks, default-final. Distinct fresh Hypium210/210 and exact-nine AArch64 audits x2 in each default, simulator FFmpeg x86 whitelist PASS. New strict parser 10/10 synthetic tests and own numeric child0 PASS. **Overall task FAIL**: separate PowerShell progress observer ran `Get-Content default-final-result.json -ErrorAction SilentlyContinue` before completion artifact existed, actual exec process **exit1**. Original tool result evidence is not proof its stderr contained text; missing-file errors suppressed. Final verifier independently completed process0 as in-flight stage, cannot override failed observer. `progress-monitor-stop.json` later-recorded timestamp is **not observation start**; exact observation UTC and original bytes missing, so reported overlap not independently timestamp-confirmed. Unwrapped auxiliary command bypassed predeclared controller and violated strict no-extra-process gate.

No live device ID query/profile, signature, signed/installed HAP, UIAbility foreground/window/layout screenshot, corpus route, official MP4/HLS/FFV1/cancellation/recovery. All 6 opens **NOT RUN**. No production/player bug established; pending-candidate release correction from `8174e6e4f0214958fb83fef46e92170c4c10263a` still runtime **UNVALIDATED**. HDC lists `[Empty]`; host listener absent; resource counts/Auto NOT PROVEN. User workspace untouched and prior results immutable, no quota queries.

**Next new READY task:** only a different ID from newest repo `docs/CODEX_VALIDATION_TASK.md`. Add one blocking PRIVATE stage controller handling all process invocation and exit/semantic checks; **no independent monitoring process** or reads of completion-only results while stage RUNNING. The stage controller must wait for actual process completion, then capture child returncode, then atomically write result file and allow subsequent stage. If no progress received, wait within the existing foreground invocation; do not poll through new commands. Evidence must preserve exact UTC and PRIVATE original stdout/stderr for every new command. All gates fresh; only after completed three verifier gates do live legal UDID/profile/sign/install, finite app UI validation, owned media route, healthy real positive progress, HLS/FFV1, actual pending HLS normal native release + early and >20s zero resource, then distinct recovery. A STOP prevents later media and permits no old-task replay/production patch. No quota checks, hardware codec/hdr/audio claims, no touching `D:/Linkora`.

All previous Phase8B–8F reports and STOP evidence immutable. The repo Task, not this conversation, grants test permissions.

Earlier CURRENT sections below are historical.

---


## HISTORICAL STATE — 2026-10-11 Phase 8F Rerun 2 signing preflight STOP reviewed

**Repository / branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Accepted STOP:** `FAIL — REQUIRED TEST GATE` for `phase8f-sim-rerun2-ui-foreground-gated-cancellation`; tested source `867907df5ab768c5127a707d2076fd8d619a3fbf`, dispatch `148de8f4cfd7c382aa403fb4e1b17d3a4171f850`, remote evidence `1999b761563902a19a163f7123524190ba9be95b`. Exactly 69 new authorized evidence/report files, no old evidence/source/test changes. Previous task complete; never rerun under same ID.

Fresh isolated clone with upstream pinned submodules, original install/four-lock EOL normalization PASS, **first default verifier only** PASS with Hypium210/210 and two exact-nine ARM64 ABI audits. `sign-preflight.py` erroneously compared whole **labeled** `bm get -u` stdout to a profile device-id list and asserted on `simulatorListedInExistingProfile=false`; immutable saved original result and exception. Post-stop read-only token membership diagnostic true shows parser mismatch is plausible; profile was not changed. Original Python child numeric exit **NOT independently captured**; outer PowerShell exit0 came after `Get-Content`, so not helper PASS. Signing helper failed while initial verifier still running; verifier independently completed afterward; no simulator/final default/actual HAP/foreground/UI/media tests. **Zero official opens**; candidate lifecycle correction `8174e6e4f0214958fb83fef46e92170c4c10263a` still runtime **NOT PROVEN**. No product defect established.

**Next READY task is distinct**, a serial validation-environment correction, **NOT a production patch**: parse exactly one safe ID from HDC labeled output, pure parser selfchecks and immediate child numeric exit capture, no concurrent verifier/preflight/command wrapper masking. Strict chain: initial install/EOL → first default finish/result → simulator finish/EOL → final default finish/result → new signed HAP/profile/native whitelist/replace-install → app visible foreground, valid window + nonempty Linkora layout + screenshot → controlled route → one healthy native/pixel/positive (>0ms) case → two HLS + one FFV1 → pending HLS cancellation actual release and early/>20s normal zeros without force-stop → separate recovery only after cancel clean. If UI/signing still fails, STOP before all playback; failed helper never retried/bypassed. Old positive766/threshold800false/AssertionError remain immutable. No user workspace modification, device codec/MPV certification or quota query.

History Phase8B/D/E failures and Phase8F original/Rerun1/Rerun2 STOP remain unchanged. Await only newest remote `docs/CODEX_VALIDATION_TASK.md` source+dispatch; Codex test/evidence only, GPT owns independent review.

Previous 2026-10-11 CURRENT state below is historical.

---


## HISTORICAL STATE — 2026-10-11 Phase 8F Rerun 1 startup/UI preflight failure reviewed

**Repo:** `baozi510/Linkora` — **branch:** `feat/playback-capability-phase8`.

**Result:** `ACCEPTED — FAIL — REQUIRED TEST GATE` for *completed* `phase8f-sim-rerun1-positive-progress-cancel-recovery`. Validation source `50eaf6da48f6d0e445676050bde362adfd0b36b6`, dispatch `682e45fa8f222dfb93b2f7d0d596c5db952dd61d`, remote evidence `4d59195f6fa3502b60f5f53ed60d5407be700510`; one append-only 79-file evidence/report commit, no protected changes. Do not execute old ID again.

All fresh ARM64-build/simulator/ABI/Hypium210x2/install gates PASS, ten controlled fixture files match truth, but **zero official fixture opens**. Emulator target initially absent; existing API26 x86 simulator was ordinary data-retaining booted; newly signed HAP installed; app start command accepted. Read-only `instrument-preflight.PRIVATE.py` then failed its assertion/exit1: valid screenshot shows *launcher*, app-scoped UI dump only empty root, no visible Linkora nodes. Later PID exists, but no verified foreground/visible app window or loaded `pages/Index`. The filtered startup log returning zero matches is not proof no startup error. The exact root cause remains **UNRESOLVED** (foreground/startup/window versus dumpLayout capture). No retry/relaunch after failed preflight; no media/route started. All healthy/HLS/FFV1/cancel/recovery NOT RUN. The new independent positive-progress collector's 6 pure selfchecks PASS, runtime collector NOT RUN. Phase8F prior `>=800ms` helper and +766ms/historical assertion unchanged and not called.

No production fix is warranted from these preflight results. Published metadata shows mapping empty/host listener absent, service/audio records0, **surface count NOT PROVEN**, Auto preference was not observed but not changed, no force-stop after STOP or wipe, original user workspace preserved.

**Next:** execute only the NEW separate READY task from newest `docs/CODEX_VALIDATION_TASK.md` based on this docs-only review commit. It must predeclare and use a **finite read-only foreground/UI readiness sequence**: verify installed bundle/EntryAbility, read actual installed HDC/aa/hidumper/uitest help, make one normal explicit target app start in a clean simulator session, poll actual foreground/visible WindowManager/Ability status for bounded time (not PID alone), then collect and cross-check non-empty bundle/window-scoped layout and actual Linkora screenshot **sequentially**. If launcher or blank root remains, STOP truthfully and do not open fixtures, change emulator image, tweak app source or repeat old failed preflight. If valid UI becomes proven, run full fresh route/six-case protocol: positive delta >0 independent native frame/pixels, two HLS, FFV1, one pending candidate leave/native release with early and >20s sampled zeros **without force-stop**, and only then new healthy recovery. Preservation, separate evidence-only push/fetch, source/dispatch SHA discipline and no quota inquiry remain mandatory.

Older state snapshots and Phase8B–8F STOP/results remain immutable. No device/MPV/codec/HDR/audio certification from simulator.

---


## HISTORICAL STATE — 2026-10-08 Phase 8F helper criterion stopped; lifecycle repair still awaiting cancellation validation

**Repository:** `baozi510/Linkora`. **Branch:** `feat/playback-capability-phase8`.

**Reviewed stop:** `ACCEPTED — FAIL — REQUIRED TEST GATE`, Phase 8F `phase8f-sim-adaptive-pending-candidate-cancel-recovery`, source `8174e6e4f0214958fb83fef46e92170c4c10263a`, dispatch `616e0ed6ddb838edb2b7cc50dcd88fff1193f46f`, evidence `202fdab4f77365bd62ec60fe5af2c2fb9cc9364c`. Do NOT rerun previous task ID or rewrite its report.

All full fresh default/sim/default build gates PASS, two independently captured Hypium 210/210, four total exact-nine ARM64 library checks, signed simulator HAP/ABI/replace install and one proper owned `hdc rport tcp:19084 tcp:19084` route. **Only one official MP4 healthy control opened**. Native prepared→play→playing, real callback + colored pixels, position161→927ms, normal clean leave. Original private helper `>=800ms` progress predicate produced `positionAdvanced=false` and AssertionError/exit1 because **+766ms**. Written task required strict positive progress, not >=800ms. Accept the bounded evidence and retain FAIL gate; no established production playback regression.

Both HLS opens, FFV1, pending cancellation and subsequent healthy recovery **NOT RUN**. Therefore new Adaptive `pendingCandidate` release/stale-commit repair from `8174e6e4f0214958fb83fef46e92170c4c10263a` is still **UNVALIDATED in cancellation/recovery runtime**, despite having compiled. No source patch or old-test expectation change is needed from the +766ms sample alone.

**Next dispatch:** NEW distinct task with task-specific fresh private passive observer, without modifying original helper/tests. It must **not invoke the old >=800ms-asserting focus runner as an authoritative gate**. Keep old raw Boolean and original FAIL unchanged; independently predefine monotonic-positive healthy acceptance from two timestamped position samples, native frame and actual pixels/route/clean leave; finite observation window. Any newly invoked old helper nonzero remains STOP, never reinterpret failed gate as PASS. Then HLS/legacy/cancellation tests, and only after normal cleanup (zero service/audio/surface without force-stop) a fresh post-cancel MP4 recovery. Fresh builds and signed simulator HAP mandatory; all historical source and device boundaries preserved.

No physical arm64 device now; x86 FFmpeg result ≠ ARM64 runtime; simulator MPV stub ≠ real MPV; no hardware codec/HDR/DV/passthrough or device-output claims. Existing Phase8B/D/E findings unchanged. Do not query quota or poll under this task; remote new `docs/CODEX_VALIDATION_TASK.md` is sole execution authority.

The prior Phase 8E CURRENT STATE below is historical.

---


## HISTORICAL STATE — 2026-10-08 Phase 8E cancellation FAIL and unvalidated adaptive ownership fix

**Branch:** `feat/playback-capability-phase8`, repository `baozi510/Linkora`.

**Reviewed evidence:** `e99ad8928811d394e65efb1ca31d77fb1c885c72` for completed Phase 8E task `phase8e-sim-system-prepared-state-gate`, source `68452df5486cf568da66a5c52352841cb7e64c5f`, dispatch `ff5917e912c310d52fda747b2a8089109a170954`. Decision `ACCEPTED — FAIL — SYSTEM PREPARED-STATE GUARD REGRESSION`. Never re-execute old task or overwrite old evidence.

Fresh full build/simulator/ABI/signing gates PASS, healthy MP4 native state and pixels PASS. HLS H.264 native prepared before play but late pixels not proven; HLS HEVC simulator native5400106; FFV1 sampled black output/size0x0. Pending HLS leave leaked app-associated service records (>20s entries2) and audio renderer records1. Normal cancellation FAIL; force-stop/coldlaunch cleanup zero is not release PASS; subsequent healthy recovery NOT RUN. Exact native object identity and direct JS promise telemetry NOT PROVEN.

**Production repair committed here but NOT TESTED:** `AdaptivePlaybackPort` explicitly holds pending backend across async prepare, routes leave release to it before disposing source lease, prevents late factory/prepare commit and cancelled Auto fallback. It safely discards source resolver results returned after cancellation and avoids double candidate release. `SystemPlaybackPort` release additionally rejects initialization and ignores late initialized surface binding. Existing native prepared-state confirmation/20s timeout remain. These source changes require a separate new Phase 8F Codex task for fresh ARM64 build/simulator cancellation and post-cancel healthy recovery; no inherited PASS. No codec blacklist, policies, Direct I/O, UI or media edits.

Old Phase8B six FAIL, Phase8D first BLOCKED, Phase8D rerun collection accepted (six bounded FAIL), Phase8C static native audit limits unchanged. MPV stub ≠ real MPV; no physical ARM64 device or hardware/output/HDR/DV validation. Newest `docs/CODEX_VALIDATION_TASK.md` is sole execution authority. No quota checking.

Previous CURRENT sections below are demoted to historical.

---


## HISTORICAL STATE — 2026-10-08 Phase 8D-SIM collection accepted, readiness fix unvalidated

**Repo/branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Accepted collection-only evidence:** Phase 8D-SIM Rerun 1 `9c4f6ded7cc86afad1052eb448ce3172b3232db6`, task `phase8d-sim-rerun1-hdc-rport-six-case`, source `c0d37ef9aaeba31c512743fe704e8d91ba1c0c48`, dispatch `a8ad55081c54630e3602b71f9fe9415cc092e1ab`. Completed; never re-execute that task ID. Remote commit includes only one report + new evidence (87 paths).

Healthy System H.264 control new PASS with exact reverse route, actual native frame callback and independent colored pixels; two HLS failed with native play while initialized despite successful manifest/segment GET200; four legacy native System videos were prepared/playing, size0x0, absent frame callback, sampled black video despite positive +701/+676/+750/+724 ms positions; the raw >=800ms helper Boolean `false` remains immutable. This is scoped simulator evidence, **not** six format playback PASS, device capability, permanent decoder diagnosis or verified audio output. Phase 8B old six FAIL, Phase 8D earlier environment BLOCKED/NOT RUN and all historical metadata FAIL stay intact.

**GPT implementation decision in this review commit:** System `prepare()` may not imply prepared native state from Promise-only completion; gate app-level ready on actual native prepared notification, native state and completion, bound the wait to 20 seconds, abort on error/timeout/release, never call `play()` while initialized. Production source changed in `entry/src/main/ets/playback/SystemPlaybackPort.ets` only; **not yet validated**. This guard may replace invalid-state play with a bounded prepare timeout if the simulator never transitions; it does **not** prove that HLS decodes.

**Next action:** new independently committed READY `docs/CODEX_VALIDATION_TASK.md` task, from this implementation source SHA. Codex test-only; run fresh default/simulator/default, verify exact ABI/signing, controlled reverse host route, actual healthy MP4 and two HLS prepares, validate no early play or fabricated PREPARED, and verify a legacy case (no black→PASS reclassification), cleanup, timeout and leave-cancellation. Stop on build failure, unbounded hang, leaked resources, or regression. Do not query quota. No physical device now; MPV simulator stub, ARM64 FFmpeg runtime/HDR/advanced audio/device-specific capability NOT PROVEN.

The older CURRENT STATE below is historical; newest task and actual remote HEAD win any conflicts.

---


## HISTORICAL STATE — 2026-10-08 Phase 8D-SIM environment stop reviewed

**Repository:** `baozi510/Linkora`. **Branch:** `feat/playback-capability-phase8`.

**Review ruling:** `BLOCKED — SIMULATOR ENVIRONMENT` (truthful Phase 8D-SIM stop accepted as blocker evidence; **no** six-case investigation acceptance). Executed prior task `phase8d-sim-system-hls-first-frame-root-cause`, source `e19123a0e110cebb479d24dbdf72d6d3c9169a5b`, dispatch `0a5e1af4be94a2528dcbc968f42f1883d9c22c3b`, evidence remote `391d56e4c0b36f19d4a52f8d77a4adab2db87b8b`. It is finished and **must not be re-executed**, regardless of old READY state.

Fresh default/simulator/final-default build chain passed with two Hypium 210/210, all AArch64 artifact audits and exact signed x86 simulator HAP. Input proof for seven controlled fixtures and 13 media files passed local/WebDAV hash and ffprobe checks. These are Phase 8D first-attempt-only evidence, **not** fresh next-round PASS.

Setup mistake: host fixture server owned TCP19084; mistakenly used `hdc fport tcp:19084 tcp:19084` (host→device), while planned simulator StreamPage loopback URL needs device→host via `hdc rport tcp:19084 tcp:19084`. Original HDC `[Fail]TCP Port listen failed at 19084`; forwarding list empty before/after. Read-only installed HDC3.2.0f help proves wrong direction but does not identify actual conflicting listener owner. STOP honored: no corrective rport, no official media open, no source/fixture/route bypass.

**Seven fresh runtime checks NOT RUN**: one healthy System MP4 and `hls-h264-aac`, `hls-hevc-aac`, `mkv-ffv1-flac`, `mov-prores-pcm`, `ogv-theora-vorbis`, `wmv-wmv2-wma`. Historical 2 HLS init FAIL + 4 first-frame evidence FAIL remain historical FAIL, unresolved; never silently reclassify. No production patch warranted by this environmental stop.

**Next action:** execute only a **new** READY dispatch in `docs/CODEX_VALIDATION_TASK.md`, with validated owned host HTTP server, **reverse** HDC port mapping, exact target-route probe and strict stop if preflight still fails; then seven fresh scoped simulator checks and honest per-case evidence. Re-run full fresh build chain for that task. Never use fport to evade host port occupancy; don't stop unrelated services or change fixtures. No quota inquiry required or authorized by the new task.

**Architecture/device boundary:** Phase 3, Phase 7A, Phase 8A, Phase 8B-SIM accepted within prior scope. Phase 8C native-first 39-feature audit accepted as static/research evidence only. No physical ARM64 device now; System simulator cannot certify Mate60, simulator MPV is stub, real MPV/HDR/DV/advanced audio/hardware output unproven; x86 FFmpeg isn't ARM64 runtime. Native-first contract/adapter fixes are GPT-owned separately, not authorized for Codex here. Keep old FAIL/NOT RUN/raw summaries/old evidence unchanged and retain user-owned media.

The 2026-10-08 Phase 8C CURRENT STATE below is now **historical context**; when any instruction conflicts, actual Git HEAD and newest dispatch prevail.

---


## HISTORICAL STATE — 2026-10-08, Phase 8C reviewed

Repository: `baozi510/Linkora`

Active branch: `feat/playback-capability-phase8`.

**Current ruling: Phase 8C native-first playback capability audit ACCEPTED for audit/evidence scope only.** Remote evidence `9cd0db4b4719409de942892790de71f0ae015823`, source `99ab47020f81391b7640d44c58ccb719491b4106`, dispatch `e835a3567132c9f496d0c79f3c1eab88f1916774`. Task `phase8c-sim-native-first-capability-audit` has already executed; never dispatch it again merely because its old task file said READY.

The matrix contains exactly 39 unique features; System 14 static NATIVE_VERIFIED, 10 NATIVE_PARTIAL, 14 scoped public-AVPlayer NATIVE_ABSENT, 1 DEVICE_CONFIRMATION_REQUIRED; MPV 37 DEVICE_CONFIRMATION_REQUIRED, 1 NATIVE_PARTIAL (passthrough), 1 NOT_APPLICABLE (platform media-session ownership). All 39 normalized-contract decisions are `DEFER_TO_GPT`; 38 capability-specific real-device follow-up groups remain. `NATIVE_VERIFIED` in this audit denotes static SDK/documentation support unless separately runtime-proven.

**Actual fresh validation:** default ARM64 build/artifact gates → x86 simulator → final default gates PASS, two Hypium 210/210 outputs, one signed simulator install, one audio diagnostic with exactly 5 events, normal System multicolor-frame smoke and sampled clean leave. MP3/FLAC audio metadata PASS; TrueHD/WavPack remain bounded raw FAIL/23002, so audio raw summary remains FAIL (4 total, 2 pass, 2 fail). The historical seven-event diagnostic remains immutable.

**Boundaries:** no physical ARM64 device currently available. Simulator System evidence is not Mate60 evidence; simulator MPV stub cannot validate real mpv; x86 FFmpeg PASS is not ARM64 runtime PASS. MPV package 1.0.0 has generic command/property access; its embedded mpv v0.41.0-dev-g6edeee00a / FFmpeg n8.0 identity does not prove untouched or reproducible binary provenance. No HDR/DV/passthrough/device-specific output claims. Six old System simulator FAIL records (HLS H.264/AAC and HEVC/AAC initialize; FFV1/ProRes/Theora/WMV first-frame evidence) remain FAIL and require a separate focused investigation.

**Next owner action:** launch the distinct focused Phase 8D-SIM investigation only through a new READY `docs/CODEX_VALIDATION_TASK.md` dispatch after the acceptance commit. It is research/simulator evidence for six historic observations, not a repeat of Phase 8C or 59-case Phase 8B matrix. GPT owns native-first contract design, production fixes, and a separate implementation/dispatch round when justified. Device-only real MPV/ARM64/hardware confirmation is batched later.

**Prior accepted baselines:** Phase 3 production analysis ACCEPTED (LIST System-first; DETAIL/ADVANCED FFmpeg-first; no field merge; System-only HLS/DASH/LOCAL_DOCUMENT; FFmpeg remote via shared localhost MediaProxy); Phase 7A real-arm64 measurement baseline ACCEPTED, not global routing; Phase 8A playback foundation ACCEPTED, not codec/output; Phase 8B-SIM accepted at `dcb34487e2043ba37f763c2ee50f4e040b597fbd`.

The former CURRENT STATE below is a **historical snapshot**. Its old branch and next-action instructions must not override this section, actual remote HEAD, the new dispatch or the latest evidence.

---


## HISTORICAL SNAPSHOT — previous CURRENT STATE

Repository: `baozi510/Linkora`

Current branch: `feat/ffmpeg-analyzer-policy-phase3`

Current phase: **Phase 8A playback functional foundation ACCEPTED. Phase 8B simulator functional preflight ACCEPTED at evidence dcb34487e2043ba37f763c2ee50f4e040b597fbd. No physical device is required for current work: continue native-first playback capability audit and other simulator-testable backlog; retain genuine ARM64/real-MPV/hardware items for the batched device gate.**

Implementation source:

`44d0f62816b73ebd3bab8069be5b74f51e2c6999`

Reviewed build/static evidence:

`e95feef35fa2541322216f9ce9336da3cad9060f`

Reviewed Mate60 runtime evidence:

`bf99989fff7cbcf17e2410e5df5258a586f12e6f`

### Phase 3 acceptance ruling

Accepted runtime evidence establishes:

- exact-source signed arm64 artifact provenance;
- real Mate60 deployment;
- authenticated production WebDAV browse;
- MP4 cold/reopen PASS;
- HEVC/MKV cold/reopen PASS;
- FFmpeg-first WebP thumbnails PASS;
- corrupt/both-unavailable behavior PASS;
- observed cancellation/refresh/stale behavior PASS in naturally exercisable scope;
- 20/20 lifecycle PASS;
- no observed crash/ANR or stale-row accumulation.

Direct shared-proxy counters remain NOT RUN because the app exposes no production diagnostic endpoint. That is explicitly non-blocking.

### LOCAL_DOCUMENT clarification

R10 import, metadata and playback all passed.

The DocumentViewPicker item kept a placeholder because the pre-existing `LocalMediaThumbnailLoader` only queries PhotoAsset-backed URIs. Independent review confirmed that file is unchanged from at least `15db3f8a3e87f75edc209c1919f944f39c0b9fcb` through the accepted Phase 3 source.

This is a known local-document thumbnail limitation, not a Phase 3 regression. It does not require a Phase 3 source change or rerun.

### Next action

The first Phase 8A Mate60 run stopped at P02 with a valid MPV foundation failure. P01 System passed; all later cases remain NOT RUN.

GPT independently reviewed evidence commit `08852ccc0ae1806b8270f2a248113eeedd61b5f9` and corrected:

- explicit unified PLAYING/PAUSED state after successful MPV commands;
- EOF terminal-state protection against the wrapper's trailing playing=false;
- vp -> physical-pixel conversion before setting MPV surface size;
- pure MPV event-order regressions.

Rerun 1 evidence at `e894775c0bc81b39a6217a0a0516cec46158b82b` freshly passed P01-P05, System/MKV observation, corrupt-MPV recovery, 20/20 MPV lifecycle and background/foreground on the real Mate60.

The same run found a fullscreen PlayerPage layout overflow. Product scope has since been clarified: Phase 8A is a playback-function gate, while fullscreen visual/layout refinement is non-blocking UI work. That issue is tracked separately and must not stop codec/container/audio capability progress.

Phase 8A is therefore ACCEPTED for playback function.

Next mainline action: prepare and execute Phase 8B using the shared `test-lab/media-compatibility` corpus. Record System and MPV playback capability independently. Analyzer results may be added against the same fixtures where the task explicitly requests them; do not infer Analyzer PASS from Playback PASS.

Playback display modes (fit/contain, fill/crop, stretch, original where supported) are backend capability work; the UI selector is deferred.

After Phase 8A, expand using the shared `test-lab/media-compatibility` corpus and record System/MPV/Analyzer capability independently.

The permanent corpus follows Tier A/B/C rules in `docs/MASTER_IMPLEMENTATION_PLAN.md`: mainstream/core formats are release-gated; legacy/rare formats remain testable but are not all mandatory PASS.

Phase 7A measures System vs FFmpeg explicitly on the same production WebDAV/MediaProxy source path. It does not change production routing.

After the benchmark evidence is pushed, GPT decides whether to expand the corpus/source families or make a narrowly supported policy change. Direct I/O remains deferred unless benchmark evidence identifies MediaProxy as a real bottleneck.

### Durable conversation workflow

Read `docs/AI_WORKFLOW.md`.

New GPT sessions and Codex sessions are intentionally disposable. GitHub is the durable project memory.

For a new GPT session, the user can send only:

`打开 GitHub 仓库 baozi510/Linkora，按照 docs/AI_WORKFLOW.md 的 New GPT Session 流程恢复项目上下文；先审查当前状态，不要直接改代码。`

For a new Codex validation session, the user can send only:

`读取仓库 docs/CODEX_VALIDATION_TASK.md 并严格按其中要求执行本轮测试和取证；不要修改生产源码。`

Every validation round uses the single fixed file `docs/CODEX_VALIDATION_TASK.md`; Git history preserves old tasks.

### Source-of-truth order

1. `docs/MASTER_IMPLEMENTATION_PLAN.md`
2. later explicitly approved architecture decisions
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md`
6. this CURRENT STATE
7. current phase report / validation evidence
8. actual branch/HEAD and affected source

Do not rely on prior chat memory.

### Phase 3 invariants

- LIST: System primary, controlled FFmpeg fallback for resolvable file-like sources.
- DETAIL / ADVANCED: FFmpeg primary, System fallback only when FFmpeg is unusable.
- no System+FFmpeg field merger in Phase 3.
- remote thumbnail: FFmpeg primary + existing System fallback.
- HLS / DASH / LOCAL_DOCUMENT: System-only.
- remote analysis remains RandomAccessSource -> shared MediaProxy -> localhost.
- FFmpeg remains protocol-agnostic.
- WebP/cache/time policy remains unchanged.
- PlaybackBackendSelector and Auto/System/MPV routing remain unchanged.
- performance ranking remains deferred to real arm64 hardware.

### Next action

Use the READY task in `docs/CODEX_VALIDATION_TASK.md` after the validation-dispatch commit is present.

Codex remains test/report-only. Any source/test-infrastructure failure that requires modification returns to GPT.

Performance remains deferred to real arm64 hardware.


# Historical milestones

> The material below is preserved for provenance. It contains earlier "current" statements that may now be stale. For present work, the CURRENT STATE and source-of-truth order above take precedence.

## Purpose

This file is the durable context handoff for a new ChatGPT/Codex session.

If a new session has no prior conversation context, read this file first and then follow the repository documents referenced below.

## Repository

Repository:

`baozi510/Linkora`

Current architecture baseline branch:

`feat/player-architecture-phase8`

Validation branch:

`test/player-architecture-validation`

Do not start new work from `main` until the stacked architecture work is reviewed and merged.

## Current stacked branch/PR chain

```text
main
 ↓
Phase 0  chore/player-architecture-phase0
 ↓
Phase 1  feat/player-architecture-phase1
 ↓
Phase 2  feat/player-architecture-phase2
 ↓
Phase 3  feat/player-architecture-phase3
 ↓
Phase 4  feat/player-architecture-phase4
 ↓
Phase 5  feat/player-architecture-phase5
 ↓
Phase 6  feat/player-architecture-phase6
 ↓
Phase 7  feat/player-architecture-phase7
 ↓
Phase 8  feat/player-architecture-phase8
```

Pull requests:

- PR #1 — Phase 0
- PR #2 — Phase 1
- PR #3 — Phase 2
- PR #4 — Phase 3
- PR #5 — Phase 4
- PR #6 — Phase 5
- PR #7 — Phase 6
- PR #8 — Phase 7
- PR #9 — Phase 8

## Product direction

Linkora is a modular HarmonyOS NEXT network media player.

Primary sources:

- local files;
- WebDAV;
- SMB;
- SFTP;
- FTP;
- NFS;
- future Jellyfin / Emby / Plex integrations.

Playback architecture:

```text
StorageProvider
    ↓
RandomAccessSource
    ↓
MediaSource / MediaProxy
    ↓
AdaptivePlaybackPort
   /                  \
System AVPlayer      MPV
```

Media analysis architecture:

```text
MediaSource
   ↓
MediaProbeService (target)
   ├─ SystemMediaProbe
   └─ FFmpegMediaProbe (blocked)
```

Thumbnail architecture:

```text
metadata
  ↓
ThumbnailTimePolicy
  ↓
thumbnail extractor
  ↓
PixelMap/raw frame
  ↓
WebP encoder
  ↓
thumbnail cache
```

## Non-negotiable architecture rules

1. Protocol/storage code must not know player implementation.
2. Player implementation must not know WebDAV/SMB/SFTP/FTP/NFS implementations.
3. MediaProbe must not know UI.
4. UI must not know FFmpeg internals or concrete player backend internals.
5. Thumbnail extraction, image processing/encoding and cache persistence are separate responsibilities.
6. New remote playback should use RandomAccessSource -> shared MediaProxy -> backend.
7. Do not force all media bytes through ArkTS if a lower-level fast path is later justified, but do not implement direct I/O before benchmark evidence.
8. Auto backend selection must eventually be data driven.
9. Failed backend candidates must not leak events into the committed playback session.
10. Credentials must be referenced through configuration/session identity and never logged in URLs.
11. Newly generated video thumbnails are WebP, not JPEG.
12. Architecture/specification from the latest phase wins when old code conflicts.

## Current thumbnail standard

- short video (<30s): approximately 20%;
- normal video: min(duration * 10%, 60 seconds);
- bounding box 480x270;
- preserve aspect ratio;
- WebP;
- quality 80;
- algorithmVersion participates in cache identity;
- legacy JPEG may be read but new JPEG should not be generated.

## Current network/data rules

Random-access semantics are central.

Important edge cases:

- Range / 206;
- 416;
- unknown length;
- auth expiry;
- ETag / Last-Modified/fingerprint;
- seek cancellation;
- reconnect;
- bounded prefetch;
- no full-file read for a remote seek.

MediaProxy is shared infrastructure and should remain localhost-only with random token URLs.

## Current playback rules

Three user modes:

- Auto;
- System;
- MPV.

Current Auto policy is only a temporary baseline.

Do not treat it as a final ranking.

System is preferred for ordinary native/direct-play cases when it actually works.

MPV is the compatibility path for complex media.

Fallback in Auto is one-shot and occurs around prepare/open, not arbitrary mid-session switching.

Unified state includes:

- IDLE;
- PREPARING;
- READY;
- PLAYING;
- PAUSED;
- SEEKING;
- BUFFERING;
- COMPLETED;
- ERROR;
- RELEASED.

## MPV integration

Current dependency target:

`@mpv-ohos/mpv-arkts@1.0.0`

Current public upstream package is arm64-v8a oriented and declares HarmonyOS compatible SDK 20+.

Linkora currently adapts:

- surface attach/detach;
- surface size;
- open/prepare;
- play/pause;
- seek;
- position/duration;
- buffering;
- EOF;
- tracks;
- video params/color information.

All of this still requires real DevEco/arm64 target validation.

## FFmpeg analyzer status

DEPENDENCY BOOTSTRAP IN PROGRESS.

Pinned source:

- FFmpeg 8.1.3
- n8.1.3
- commit 1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7

The repository now contains reproducible source-fetch and HarmonyOS dual-ABI bootstrap scripts for:

- arm64-v8a
- x86_64

The analyzer itself is still NOT IMPLEMENTED until both ABI builds produce verified libavformat/libavcodec/libavutil/libswscale artifacts.

Never use private libmpv-linked FFmpeg symbols.

Read:

- `docs/FFMPEG_BOOTSTRAP.md`
- `docs/FFMPEG_INTEGRATION_BLOCKER.md`

## Claims that require device evidence

Do not claim these are proven merely from code:

- native HDR output;
- native Dolby Vision output;
- Dolby Vision mode signaling;
- DTS-HD MA passthrough;
- TrueHD passthrough;
- Atmos passthrough/object rendering;
- DTS:X passthrough/object rendering;
- Audio Vivid behavior;
- power efficiency;
- real hardware decode coverage.

## What to read for current status

Read in this order:

1. `docs/IMPLEMENTATION_STATUS.md`
2. `docs/TEST_MANUAL.md`
3. `docs/CODEX_TEST_RUNBOOK.md`
4. `docs/FFMPEG_INTEGRATION_BLOCKER.md`
5. `docs/ARCHITECTURE_TARGET.md`
6. `docs/ARCHITECTURE_MIGRATION.md`
7. latest phase reports

## Current next action

Do not continue feature development first.

Run validation on:

`test/player-architecture-validation`

Follow:

`docs/CODEX_TEST_RUNBOOK.md`

Expected first commands:

```powershell
git fetch --all
git checkout test/player-architecture-validation
git status
ohpm install
./scripts/verify.ps1
```

Then perform target-device smoke tests and write:

`docs/VALIDATION_REPORT.md`

## When to return to architecture/design work

Return with evidence after one of these milestones:

- verify.ps1 fully passes;
- arm64 Debug and Release HAP both build;
- System + MPV + Auto target-device smoke test results exist;
- benchmark data exists;
- an adapter/API mismatch requires redesign;
- FFmpeg dependency artifacts are ready.

The next architecture session should read VALIDATION_REPORT.md first.

## Preferred engineering style

- modular and pluggable;
- small reviewable commits;
- reuse existing protocol/native implementations;
- confirmed facts separated from inference;
- no fake support claims;
- no speculative large refactors when measurement can answer the question;
- errors and logs must not expose credentials;
- preserve rollback paths during migration.

## New-session prompt

A user can start a new assistant session with:

```text
Open GitHub repository baozi510/Linkora.
Read docs/SESSION_HANDOFF.md first, then docs/IMPLEMENTATION_STATUS.md,
docs/VALIDATION_REPORT.md if it exists, docs/TEST_MANUAL.md, and
docs/FFMPEG_INTEGRATION_BLOCKER.md.

Use the latest repository documents as the source of truth.
Continue from the documented current branch/status.
Do not redesign or merge branches until you have reviewed the validation evidence.
```


## Post-validation review update

Architecture review after the first validation pass is complete.

Before any further runtime testing or feature work, read:

`docs/CODEX_POST_VALIDATION_ACTIONS.md`

Current next action is:

1. keep the accepted validation fixes;
2. correct MPV error-log handling;
3. wire surface size from PlayerPage -> PlayerFeatureController -> PlaybackEngine;
4. correct HDR labeling so BT.2020 alone is not treated as HDR;
5. tighten the architecture-boundary scanner;
6. rerun the full verify.ps1;
7. attempt the current HAP on the available x86_64 emulator without production ABI hacks;
8. update VALIDATION_REPORT.md and stop for architecture review.

Do not start FFmpeg or Auto-policy tuning before this review loop is complete.


## ARM64 device validation handoff

The post-validation correction pass has now been architecture-reviewed and accepted at the source/build level.

Current next step requires a real arm64 HarmonyOS device.

Read and follow:

`docs/ARM64_DEVICE_VALIDATION_RUNBOOK.md`

Do not continue simulator-specific production changes. The available x86_64 emulator cannot install the current arm64-v8a HAP.

Do not merge PR #10 until arm64 runtime evidence has been reviewed.


## x86_64 near-production simulator product

Current active simulator branch:

`test/simulator-validation`

It is based on `test/player-architecture-validation` and must not be merged before validation.

The simulator is no longer a System/WebDAV-only product. It intentionally mirrors production business behavior:

- same SettingsPage with Auto/System/MPV
- same NetworkPage with WebDAV/SMB/SFTP/FTP/NFS
- same PlaybackEngine
- same PlaybackBackendSelector
- same AdaptivePlaybackPort
- same NetworkDirectoryService
- same database/config models
- same MediaProxy
- exact same shared HTTP/WebDAV providers

Only the final platform boundaries are replaced:

- real arm64 MPV package -> compile-only x86 simulator MPV replacement
- real SMB/SFTP/FTP/NFS Native storage providers -> explicit simulator unavailable transport provider

This means Auto fallback and native-protocol configuration/error paths can be tested without pretending the real Native implementation ran.

Simulator bundle:

`com.linkora.player`

Read:

- `docs/SIMULATOR_TEST_MANUAL.md`
- `docs/SIMULATOR_VALIDATION_REPORT.md`
- `docs/FFMPEG_BOOTSTRAP.md`

Required order:

1. `./scripts/verify.ps1`
2. `node scripts/check-simulator-product.cjs`
3. `./scripts/verify-simulator.ps1`
4. install the x86_64 simulator HAP
5. execute the near-production simulator manual
6. build pinned FFmpeg for x86_64 and arm64-v8a if the Native SDK is available
7. update reports
8. stop for architecture review

The simulator HAP must never contain real libmpv or production SMB/SFTP/FTP/NFS native libraries.

A future `liblinkora_ffmpeg.so` is the only planned x86 native runtime addition after FFmpeg integration.

Simulator evidence still does not replace ARM64 device validation.


## Simulator validation accepted / FFmpeg Phase 1 authorized

The near-production simulator validation round is architecture-reviewed and accepted.

Accepted tested source SHA from that round:

`04814840403b54d8dd0e0e61798be1fb3f8f8da8`

The simulator branch later added evidence/documentation only.

Confirmed validation highlights:

- default `verify.ps1` PASS;
- Hypium 149/149 PASS;
- default arm64 Debug/Release HAP PASS;
- simulator HAP build/install/launch PASS;
- Auto/System/MPV UI parity preserved;
- WebDAV real shared provider path exercised;
- real MediaProxy random seek evidence collected;
- overlapping seek/buffering bug fixed and regression-tested;
- RepeatItem refresh bug fixed and runtime-tested;
- FFmpeg 8.1.3 bootstrap built for both x86_64 and arm64-v8a;
- static archives audited as X86-64 / AArch64.

Still device-only / not proven:

- real MPV runtime;
- real SMB/SFTP/FTP/NFS native I/O;
- native HDR/Dolby Vision output;
- DTS-HD/TrueHD/Atmos/DTS:X passthrough;
- arm64 hardware decode/power/thermal.

Current implementation branch:

`feat/ffmpeg-media-analysis-phase1`

Read first:

1. `docs/CODEX_FFMPEG_INTEGRATION_RUNBOOK.md`
2. `docs/FFMPEG_PHASE1_REPORT.md`
3. `docs/FFMPEG_BOOTSTRAP.md`
4. `docs/SIMULATOR_VALIDATION_REPORT.md`

Current authorization:

- create dedicated `linkora_ffmpeg` module;
- link the pinned FFmpeg static libraries;
- support x86_64 simulator and arm64-v8a build;
- implement async native metadata probe;
- implement async one-frame RGBA extractor;
- implement cancellation/timeout via AVIOInterruptCB;
- run local + MediaProxy simulator smoke.

Still forbidden before the next architecture review:

- making FFmpeg the production default probe;
- changing IMediaProbe public signature;
- changing Auto/PlaybackBackendSelector;
- System/FFmpeg policy tuning;
- AVIOContext direct callbacks;
- FFmpeg playback backend.


## FFmpeg Phase 1A accepted / Phase 1B runtime required

Phase 1A branch:

`feat/ffmpeg-media-analysis-phase1`

Phase 1A validated source:

`772889a48aabec8d8c427a1222126c1709159ca4`

Accepted Phase 1A results:

- dedicated `linkora_ffmpeg` module exists;
- pinned static FFmpeg linkage is isolated from MPV;
- arm64-v8a native Debug/Release link passes;
- default arm64 HAP Debug/Release passes;
- NAPI work/request/cancel design passed source/unit review;
- Hypium 164/164 passed at the validated source;
- no production analyzer/playback policy was changed.

Phase 1A did **not** execute the x86 simulator native runtime because the previous runbook stop condition fired after arm64 link success. This is not sufficient for analyzer integration.

Current runtime-validation branch:

`test/ffmpeg-media-analysis-phase1b-runtime`

Read:

1. `docs/CODEX_FFMPEG_PHASE1B_RUNTIME_RUNBOOK.md`
2. `docs/FFMPEG_PHASE1B_RUNTIME_REPORT.md`
3. `docs/FFMPEG_PHASE1_REPORT.md`

Phase 1B must attempt real x86:

- HAP packaging/install;
- `liblinkora_ffmpeg.so` load;
- NAPI factory;
- local probe;
- local frame extraction;
- WebDAV -> MediaProxy -> FFmpeg probe/frame;
- real timeout;
- real cancellation;
- concurrency;
- lifecycle cycles.

Still forbidden:

- production FFmpeg routing;
- probe-policy tuning;
- System/FFmpeg merger;
- AVIO direct storage callbacks;
- MPV/Auto changes.


## FFmpeg Phase 1B runtime accepted / build isolation hardening required

Phase 1B runtime validation is accepted.

Validated source:

`d8dad1d757c5b7e6a13b9603d540903aba99567a`

Confirmed:

- real x86 `liblinkora_ffmpeg.so` packaged and loaded;
- real NAPI import/factory/probe/frame/cancel;
- local MP4 and MKV probe;
- software RGBA frame extraction;
- WebDAV -> RandomAccessSource -> MediaProxy -> FFmpeg;
- high-offset Range seek evidence;
- real FF_TIMEOUT through stalling MediaProxy source;
- 10 active FF_CANCELLED cycles;
- concurrency isolation;
- 20 lifecycle cycles;
- final default arm64 Debug/Release builds;
- Hypium 164/164.

One important build-system issue remains before production analyzer routing:

A simulator target dependency resolution previously left the workspace in a state where a subsequent default HAP omitted real MPV until normal `ohpm install` restored the default dependency graph.

Current hardening branch:

`fix/simulator-default-dependency-restore`

Read:

- `docs/CODEX_BUILD_ISOLATION_HARDENING.md`
- `docs/BUILD_ISOLATION_HARDENING_REPORT.md`

This branch:

- makes simulator verification restore the default ohpm dependency graph automatically;
- requires all 9 expected production native libraries in default artifact audits;
- tightens FFmpeg bootstrap manifest checks to exact lines.

Do not start production FFmpeg analyzer routing until this hardening report passes.


## Build isolation hardening accepted / FFmpeg Analyzer Phase 2 active

Build isolation hardening is accepted.

Validated hardening source:

`ce24be1daf12892bfaa028bcd138fca25116a320`

Confirmed:

- two simulator -> immediate default cycles passed with no manual restore;
- one intentional simulator build failure still restored default dependencies automatically;
- default Debug and Release HAPs each contained the required 9 AArch64 native libraries;
- simulator HAP contained only x86_64 `liblinkora_ffmpeg.so`;
- artifact guard fixtures passed;
- exact FFmpeg manifest negative checks passed;
- Hypium 164/164 passed;
- tracked dependency/signing state remained clean.

Current branch:

`feat/ffmpeg-analyzer-integration-phase2`

Read:

1. `docs/CODEX_FFMPEG_ANALYZER_INTEGRATION_PHASE2.md`
2. `docs/FFMPEG_ANALYZER_INTEGRATION_REPORT.md`
3. `docs/FFMPEG_PHASE1B_RUNTIME_REPORT.md`
4. `docs/BUILD_ISOLATION_HARDENING_REPORT.md`

Current authorization:

- implement analysis input resolver;
- implement FFmpeg `IMediaProbe` adapter;
- implement System `IMediaProbe` adapter;
- implement FFmpeg `IThumbnailExtractor` adapter;
- run simulator System-vs-FFmpeg comparison/diagnostic matrix;
- collect completeness, correctness, error/cleanup and remote Range/random-access functional evidence. Performance evidence is deferred to real arm64 device testing.

Still forbidden before the next review:

- switching `NetworkMediaLoader` production results to FFmpeg;
- merging System/FFmpeg fields into cache;
- final analyzer policy;
- default FFmpeg thumbnail routing;
- playback Auto changes;
- AVIOContext direct callbacks;
- FFmpeg playback.

This branch also tightens the default artifact audit to reject unexpected extra arm64 native libraries.


## Performance policy for this phase

Simulator Phase 2 is functional-only.

Do not use x86 simulator data for:

- System-vs-FFmpeg speed ranking;
- median/p95 latency;
- throughput;
- CPU/GPU utilization;
- memory-efficiency ranking;
- power/thermal conclusions;
- final analyzer or playback policy.

Remote byte/range counters may only be used to verify functional random-access behavior and cleanup.

Performance benchmarking and performance-based policy decisions are deferred to real arm64 device testing.


## FFmpeg Analyzer Production Policy Phase 3 — implemented, awaiting test-only validation

Current branch:

`feat/ffmpeg-analyzer-policy-phase3`

Implementation ownership for this phase:

- ChatGPT implements/fixes source;
- Codex tests and reports only;
- Codex must not patch source on validation failures.

Implemented functional policy:

```text
LOCAL_DOCUMENT / HLS / DASH
  -> System-only policy

file-like REMOTE_FILE / HTTP
  LIST
    -> System first
    -> FFmpeg only if System is incomplete/unusable

  DETAIL / ADVANCED
    -> FFmpeg first
    -> System only if FFmpeg is unusable
    -> no field merger

thumbnail
  -> FFmpeg first
  -> existing System thumbnail fallback
  -> common WebP encoder/cache
```

Production `NetworkMediaLoader` now uses `NetworkMediaAnalysisCoordinator`.

Additional lifecycle/security fixes in this phase:

- policy cancellation cannot start a later fallback engine;
- coordinator cancellation cannot continue into thumbnail fallback;
- `MediaSource.fingerprint` is no longer misused as an SFTP host-key fingerprint;
- FFmpeg raw RGBA frames use the existing System WebP encoder;
- no performance-based routing was introduced.

Read for validation:

1. `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`
2. `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

Performance remains deferred to arm64 real-device testing.

If Codex reports a source failure, return to ChatGPT for the fix. Do not let Codex patch the implementation branch.
