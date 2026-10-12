# Codex Task — CLI-Only Build and Normal App Open on x86 Simulator (HAR Stub Repair)

> STATE: CLOSED — NORMAL SIMULATOR ABILITY OPEN PASS, MEDIA NOT RUN
> COMPLETED_EVIDENCE_SHA: 4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88
> RETEST_SAME_ID: NOT AUTHORIZED
> TASK_ID: phase8f-level1-cli-har-stub-prebuild-and-app-open-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — BUILD/ABI/INSTALL/ABILITY OPEN CHECKPOINT
> SOURCE_SHA: 56a8ba073267305e7ecb950fd2576f94e31fbb76
> ALLOWED_DISPATCH_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> OLD_AUTONOMOUS_TASK: phase8f-cli-autonomous-simulator-build-repair-and-media-v1 — SUPERSEDED (NO EXECUTION ON ITS OWN ID)
> PRIOR_COMPLETED_REPORT: c5d79b27c8462b8f7e1c5ca44c45d5714ae66b28
> USER_DIRECT_SMOKE: ONE CLI BUILD FROM OLD CHECKOUT FAILED 00306060 (NO NEW REPORT/DISPATCH)
> MODE: CLI ONLY — NO GUI, DESKTOP IDE, COMPUTER USE, SCREENSHOT OR LAYOUT TEST
> USER_GOAL_THIS_CHECKPOINT: SOURCE-ALIGNED APP CAN NORMALLY OPEN VIA CLI ON X86_64/API26 SIMULATOR
> MAX_SCOPED_X86_SIM_DEBUG_BUILD: 3 — ONLY AFTER DISTINCT CONCRETE SCRATCH REPAIRS
> MAX_OHPM_INSTALL: 2 — EXPLICIT SIMULATOR PARAM FILE; SECOND ONLY IF REPAIR REQUIRES IT
> MAX_SAFE_INSTALL: 1 — ONLY AFTER REAL X86 ABI AND BUNDLE-ID AUDIT PASS
> MAX_NORMAL_APP_OPEN: 1 — ONLY AFTER SUCCESSFUL INSTALL
> MANUAL_SIGN_APP / KEYSTORE PROBE / OLD PROFILE / DEVICE WIPE / EXISTING APP UNINSTALL: 0
> DEFAULT_ARM64/RELEASE BUILD: 0
> MEDIA / FFMPEG PROBE / VIDEO FRAME / WEBP / MP4 / HLS TESTS: 0 (NEXT CHECKPOINT)

## Closure notice — completed; next task follows six-step bounded-autonomy workflow

**This exact prior ID is CLOSED, not executable again.** Independently reviewed evidence at `4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88` (only new report `docs/PLAYBACK_PHASE8F_CLI_HAR_STUB_PREBUILD_APP_OPEN_REPORT.md`) records source-bound x86 simulator build/HAP ABI/CLI install/EntryAbility foreground **PASS**. It deliberately did not execute FFmpeg/WebP/MP4/HLS media functions. GPT accepts only that narrow Ability-open milestone.

The latest owner direction authorizes Codex to autonomously test, troubleshoot and fix bounded build/media failures in a NEW isolated scratch clone. The canonical six-step policy and **stop-after-two-concrete-repairs / no identical retry / stop if unsolvable** gates are in `docs/AI_WORKFLOW.md`. New source-bound media task has a DIFFERENT ID and budget. Do not use this historical dispatch to restart work or infer media PASS.

## 0. Separate execution provenance and actual newly observed failure

The user separately authorized a CLI-only normal app-open smoke from fixed older checkout `c5d79b27c8462b8f7e1c5ca44c45d5714ae66b28`. That is NOT this task and did not create any GitHub evidence report. Authorized local directory read/copied four pinned x86 FFmpeg static inputs into a NEW scratch clone and verified originals/copies. Explicit `ohpm install --pf oh-package-simulator-params.json5` succeeded and actually resolved local MPV stub. Then one genuine `hvigorw assembleHapSeq --mode project -p module=entry@simulator -p product=simulator -p buildMode=debug -p parameterFile=oh-package-simulator-params.json5 --no-daemon` reported `00306060 Specification Limit Violation` at Hvigor PreBuild: unable to get `@mpv-ohos/mpv-arkts` version/name from local stub package. Wrapper child1; build FAIL. It was *not* an input-unavailable, SDK parameter-forwarding, package ABI, signed HAP install, old keystore, or device/runtime failure: NO HAP/install/Ability was attempted. Direct original command forwarded `-p parameterFile` into nested tasks. Do not misclassify.

GPT independently verified current GitHub configuration and compared it with the official HarmonyOS source HAR module structure: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/ide-hvigor-build-har-V5 and project module registration https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hmos-hvigor-build-profile-app . Previously `entry/simulator-stubs/mpv-arkts` contained only `Index.ets` and `oh-package.json5`; missing `build-profile.json5`, `hvigorfile.ts` and `src/main/module.json5`. New SOURCE_SHA fills them in, registers `mpv_simulator_stub` in root `build-profile.json5` only under simulator product, adds modelVersion/empty dependencies to existing `@mpv-ohos/mpv-arkts` manifest, and strengthens `scripts/check-simulator-product.cjs`. **This is a source-level hypothesis to test, not a proven 00306060 fix or a compiler PASS.** Genuine production ARM64 MPV version1.0.0 remains selected by default params, simulator by `oh-package-simulator-params.json5` local Stub.

The previous README/current task `phase8f-cli-autonomous-simulator-build-repair-and-media-v1` is explicitly SUPERSEDED in SOURCE, not runnable and not automatically failed. This new task binds one NEW SHA and focuses on normal CLI Ability OPEN **before** any media tests.

## 1. Bind exact NEW source; input permission is no longer a blocker

1. Fresh fetch. Require dispatch commit direct parent SOURCE_SHA `56a8ba073267305e7ecb950fd2576f94e31fbb76`; SOURCE..dispatch only `docs/CODEX_VALIDATION_TASK.md`. Prior dispatch `c78bb62da04a536026833f49f86663a0208c24b8`..SOURCE is exactly **9 files**: `build-profile.json5`; `entry/simulator-stubs/mpv-arkts/{oh-package.json5,build-profile.json5,hvigorfile.ts,src/main/module.json5}`; `scripts/check-simulator-product.cjs`; `docs/{IMPLEMENTATION_STATUS.md,SESSION_HANDOFF.md,CODEX_VALIDATION_TASK.md}`. Check original official CLI error appears only in the separately user-reported smoke, not this code's executed runtime history. Preserve previous reports verbatim.
2. Fresh isolated scratch checkout, original possibly dirty `D:/Linkora` only for **read-only explicitly approved native inputs**, never checkout/reset/stash/clean/build/copy-back. READ ONLY the exact pinned existing `third_party/ffmpeg/prebuilt/x86_64` subtree and strictly relevant installed toolchain docs/helpers. Canonical manifest: FFmpeg n8.1.3 commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, triple x86_64-linux-ohos and four headers. Static archives SHA256:
   - avformat `697CD7D4861418A1091421337B48D6E1DE255F8EE9341005A44DA7AD7EA1AED1`;
   - avcodec `9DDD5CE0292E4E372263029DE6AACB00BF8BE5BCED86AF1D989B52D927DD4170`;
   - avutil `074AE78E9D6C1BFD9FDAE7A161409F48EABA39D1D979B973C3CA233BA24DBB2A`;
   - swscale `452F0BB617EEC5C8A9CE0872AE28B478AE74828A04725971823EB283328D74C9`.
   Verify originals by read/hash and COPY only manifest/includes/four `.a` to fresh isolated ignored x86 prebuilt prefix, then verify copied bytes. No ARM64 libs, HAPs, credential-related files or private logs. Prior checks showed these inputs exist; do not repeat broad disk/remote branch searches or rebuild FFmpeg.
3. Existing CLI/HDC connected simulator x86_64/API26 cheap checks, at most one ordinary non-destructive start if absent. No GUI, IDE, per-process monitor, signature/license key, reset, uninstall, same-bundle app removal or configuration changes. `simulator` product bundleName is `com.linkora.player.simulator`; default app remains `com.linkora.player`.

## 2. Codex can repair errors in SCRATCH without stopping at every compiler failure

Codex has user-granted autonomy to inspect SDK CLI/help/toolchain paths, generated locks and Hvigor PreBuild diagnostic output (PRIVATE), and edit **scratch only** `build-profile.json5`, simulator stub module files, build/ohpm parameter config, checker, narrowly related ArkTS imports and CMake when an actual error supports the change. Do NOT edit originals or overwrite production/default ARM64 MPV, patch a failed HAP ZIP to conceal ABI violations, weaken build checks, bypass signing, or reset unrelated applications. Up to **THREE distinct** direct simulator builds, first after actual source-verified OHPM resolution, next only after a justified specific repair. No identical retry loop, no separate full default/release/verify builds.

1. In fresh scratch run one explicit `ohpm install --pf oh-package-simulator-params.json5` (no plain install). Confirm actual generated entry lock has ONE LOCAL stub entry and junction to scratch `entry/simulator-stubs/mpv-arkts`; compare package `name/version`, confirm new HAR module/config registration matches canonical source. Run static checker with actual generated simulator lock; static PASS is NOT PreBuild PASS.
2. Discover exact documented direct Hvigor `assembleHap` or `assembleHapSeq` invocation supported by installed toolchain; pass `-p parameterFile=oh-package-simulator-params.json5`, simulator product, `entry@simulator`, Debug. No devecocli GUI or unsupported implicit parameter forwarding. Count actual build child exit and capture exact FAILED stage. First check whether the newly completed HAR manifest and module registration resolve original 00306060. If not, inspect full relevant private PreBuild diagnostic, effective manifest path/junction and official package schema, fix smallest scratch issue; do not assume it's just `name/version` missing. User already permitted self-repair. An unsuccessful first build plus a justified modified second build is allowed; three is max, not goal.
3. **For tracked source changes needed beyond committed SOURCE**, Codex may propose and test them in scratch. Push only a separate `codex/phase8f-har-stub-prebuild-repair-v1` CANDIDATE branch from this dispatch if safe, with code-only reviewed diff and concrete commit SHA; never merge/force push/directly edit the feature branch production source. Actual HAP testing must bind its real candidate SHA. If no new tracked change needed, no candidate branch is required. Do not stage ohpm generated lock/ignored prebuilt paths or private compiler logs.
4. When build succeeds create/read ONLY fresh current-source `entry@simulator` HAP, verify embedded `com.linkora.player.simulator`, invoke the existing `scripts/check-ffmpeg-artifact.cjs <new-hap> x86_64`. Its exit MUST be0: only approved `liblinkora_ffmpeg.so` with ELF machine62 and NO ARM64 `libmpv/libmpv_wrapper/libaki_jsbind/libc++_shared` in HAP. Do not install a build that merely prints BUILD SUCCESSFUL but has foreign ABI or failed audit. If another packing problem surfaces, Codex may repair in scratch and use remaining distinct-build budget; if impossible mark blocker, installs0.

## 3. Only after ABI and bundle name PASS: one nondestructive install and normal app OPEN

- At most ONE CLI install of newly built, source-aligned audited HAP to already authorized simulator under **new** `com.linkora.player.simulator` identity. Never uninstall/clear the existing `com.linkora.player` or other user's app, no signature bypass, keystore/password/old signer tool, global IDE settings or device wipe. If native installer fails, capture exact error **as NEW evidence** (not inherited old 9568332) and STOP dependent ability start.
- After successful install, one normal CLI `EntryAbility` launch. Verify native bundle/process/Ability resumed or started without fatal error using bounded CLI diagnostics; **no screenshot, layout, pixels, UI polish or GUI interactions**. The checkpoint answers `CAN OPEN NORMALLY = YES/NO/NOT PROVEN`, not codec/performance PASS. Do not run FFMPEG smoke, WebP encoder, actual MP4/HLS, network server, media fixture matrix, or >20s resource tests in this task. They belong to the next authorized functional checkpoint when basic source-aligned app OPEN is proven.
- A genuine BUILD/ABI/INSTALL failure remains FAILED with all downstream gates NOT RUN. If an unrelated optional helper is missing, RECORD_ONLY and continue safe independent checks without repeating.

## 4. Single compact evidence with source-bound truth

Only new authorized public result (if successful ordinary publication feasible):
`docs/PLAYBACK_PHASE8F_CLI_HAR_STUB_PREBUILD_APP_OPEN_REPORT.md`

Report full40 SOURCE/DISPATCH SHA; confirmed original and copied FFmpeg archive hashes (no private paths), generated local MPV resolution, specific PreBuild 00306060 status `FIXED/REMAINS/NOT RUN`, exact build attempts and grounded small scratch repairs, candidate branch SHA if any, new HAP x86 ABI audit exit, HAP embedded bundle identity, actual install exit/error, Ability start CLI evidence/result, protected-original read-only scope, no UI/media, no password/signing. All actual artifacts and raw process streams private. Never publish device ID, local user/machine paths, private HAP/media/screenshots, secrets/profiles, signing certificate fingerprint, auth tokens or raw user app inventory.

Stage ONLY one new report in a clean isolated repository based on exact dispatch; user original and all stopped previous checkout untouched. Verify remote branch still dispatch before report-only normal no-force push, fresh-fetch and independently verify exactly one-parent one-path report and remote readback. If candidate source branch was pushed separately, report its SHA. If publication fails, keep truthful local result; DO NOT re-run build or installation for reporting.

Final summary: `STATE / TASK_ID / SOURCE_SHA / DISPATCH_SHA / INPUT_COPY_VERIFIED / MPV_LOCAL_STUB_LOCK / HAR_PREBUILD_00306060 / BUILD_COUNTS / SCRATCH_FIXES / CANDIDATE_SHA_OR_NONE / NEW_HAP_X86_ABI_AUDIT / EMBEDDED_BUNDLE_ID / CLI_INSTALL / ABILITY_OPEN_NORMAL / GUI0 / SIGN_APP0 / OLD_KEYSTORE0 / MEDIA_NOT_RUN / USER_ORIGINAL_READ_ONLY / REMOTE_REPORT_SHA_OR_NONE / NEXT_ACTION`.

Never claim simulator-open PASS without an actual installed current-source Ability. On a clean app-open result, prioritize a subsequent separate decoder/encoding/playback checkpoint.
