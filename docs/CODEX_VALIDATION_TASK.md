# Codex Task — Verify Real Simulator Dependency Split, ABI and Functional Media via CLI

> STATE: READY
> TASK_ID: phase8f-level1-cli-mpv-target-split-abi-gated-media-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — DEPENDENCY/ABI GATES BEFORE INSTALL
> SOURCE_SHA: 3cdf0d4606c83c0fe2b9c759da84c9de5636d647
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> PREVIOUS_DIAGNOSIS: phase8f-level0-simulator-abi-dependency-install-identity-diagnosis-v1 — COMPLETED
> PREVIOUS_DIAGNOSIS_REPORT: ef204701e010382a5d5822645d913cc3be9e435f
> MODE: CLI ONLY — NO DESKTOP GUI, NO IDE/GUI LAUNCH, NO COMPUTER USE
> USER_GOAL: ACTUAL X86 SIMULATOR FFMPEG DECODING / WEBP IMAGE ENCODING / SYSTEM PLAYBACK
> MAX_DEPENDENCY_INSTALL: 1 EXPLICIT OHPM INSTALL --pf
> MAX_SCOPED_SIMULATOR_DEBUG_BUILD: 1
> MAX_NATIVE_HAP_AUDIT: 1
> MAX_INSTALL: 1, ONLY AFTER CLEAN X86 ABI AND BUNDLE ID PASS
> MAX_MANUAL_SIGN_APP / OLD_KEYSTORE_PROBE: 0
> NO_DEFAULT_ARM64/RELEASE_BUILD; NO SIMULATOR WIPE OR OLD APP UNINSTALL
> UI_LAYOUT/PIXEL_SCREENSHOT_ACCEPTANCE: OUT OF SCOPE

## 0. Critical distinction to maintain

There is ONE Linkora product source tree with TWO native **target-specific dependency sets**. Default real handset: ARM64 `linkora_ffmpeg` and full native `@mpv-ohos/mpv-arkts@1.0.0`; x86_64/API26 simulator: x86 FFmpeg and only a **compile-only fail-closed MPV stub**, with real System AVPlayer. Previous V2 mistakenly packaged ARM64 `libaki_jsbind.so`, `libc++_shared.so`, `libmpv.so`, `libmpv_wrapper.so` inside its x86 HAP, failing `check-ffmpeg-artifact.cjs` and later install `9568332`. User separately tried an ARM64 default HAP and received `9568347`; these are distinct failures. No prior task has recent real decoded-frame/WebP/System playback PASS. No old HAP reuse.

GPT has changed SOURCE_SHA config from the previous report:
- root `oh-package.json5` parameterFile -> `./oh-package-default-params.json5`;
- `oh-package-default-params.json5` sets `dependencies.mpv=1.0.0` for ARM64/default;
- `oh-package-simulator-params.json5` sets `dependencies.mpv=./entry/simulator-stubs/mpv-arkts` relative to root parameter file;
- `entry/oh-package.json5` uses `@param:dependencies.mpv` and removes the former unconsumed `simulatorTargetDependencies`;
- `build-profile.json5` sets only simulator product bundleName `com.linkora.player.simulator`; default/AppScope remain `com.linkora.player`;
- `scripts/check-simulator-product.cjs` now checks actual two parameter targets and can inspect a **supplied real generated simulator** lock via `--simulator-lock <path>` (without this, it explicitly says effective resolution NOT VERIFIED).

Official specifications: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hmos-oh-package-json5 ; https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hmos-ohpm-install ; https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-hvigor-commandline ; https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hmos-hvigor-build-profile-app . The installed DevEco CLI `devecocli run` help did NOT expose parameterFile forwarding: **DO NOT use devecocli run without proven parameter propagation**. Use actual supported pure CLI `ohpm install --pf` then direct Hvigor `-p parameterFile` as appropriate. Do not open desktop GUI.

## 1. Source integrity and prerequisite checks — no extra builds

1. Fresh-fetch latest remote and bind exact SOURCE and task dispatch full40. Require SOURCE direct parent of dispatch, only `docs/CODEX_VALIDATION_TASK.md` drift. Previous report `ef204701e010382a5d5822645d913cc3be9e435f`->SOURCE diff must be precisely: `oh-package.json5`, `entry/oh-package.json5`, `build-profile.json5`, `oh-package-default-params.json5`, `oh-package-simulator-params.json5`, `scripts/check-simulator-product.cjs`, `docs/IMPLEMENTATION_STATUS.md`, `docs/SESSION_HANDOFF.md`. Validate exact version-controlled code and source identity; no accidental build of the old dispatch. No production/target edit by executor.
2. Work only in a new isolated clone. NEVER open or mutate original possibly dirty `D:/Linkora`, prior stopped clones/private evidence worktrees, original caches, keystores, IDE project/state, signing profiles or installed existing `com.linkora.player`. No reset, stash, clean, force remove, uninstall, wipe, emulator reprovision. CLI target read-only check for already user-authorized x86_64/API26; if unavailable, at most one normal existing simulator CLI start, no settings changes. If no target, mark simulator-dependent operations NOT RUN.
3. Check existing x86 FFmpeg pinned prebuilt inputs and approved fixture/route without regenerating all 59 cases. If missing and safe prior private pinned prebuilt cannot be accessed lawfully without touching protected checkout, block dependent build. No import or use of old invalid HAP. No manual signing or old credential work.

## 2. One effective dependency selection proof, before compilation

1. In isolated clone only, execute one explicitly parameterized official `ohpm install --pf oh-package-simulator-params.json5` using normal environment/working directory; do not also perform unparameterized `ohpm install` or `update`/individual-package install. The root project parameterFile must already exist; keep default parameter file pointing to REAL 1.0.0 and simulator alternate only via explicit flag.
2. Inspect **ACTUAL generated** entry simulator effective lock/dependency map and resolved MPV package path; root/entry lockfile variations are tool-generated and may differ. Require exactly one `@mpv-ohos/mpv-arkts` chosen from the local `entry/simulator-stubs/mpv-arkts`, with NO remote real HAR. Check the stub's manifest and module entry; do not rely on the source's `@param` declaration alone, or on old checked-in default lock. If necessary use the source checker with `--simulator-lock` pointing to the genuine generated simulator dependency lock. If metadata semantics differ, independently inspect actual resolved package under isolated `oh_modules`/generated target context. **STOP before build** if target resolution is REAL MPV, UNKNOWN, conflicting or missing; report exact dependency failure, NO guessing/second install.
3. Keep any tool-created lockfile changes only in scratch clone. Never manually edit or fake generated lockfiles, and never publish raw machine/private paths. Do not invoke a separate static-check helper that would itself rebuild or install.

## 3. One source-aligned CLI build; strict native ABI audit; then at most one safe install

1. If only the LOCAL MPV stub is proven, use an actual supported direct Hvigor CLI command. It must explicitly include `-p parameterFile=oh-package-simulator-params.json5`, `-p product=simulator`, and the correct `entry@simulator` module/target and Debug mode; select appropriate advertised assemble task/--mode correctly. Capture the actual command/child exits without credential-bearing argv. **ONE** scoped Debug build max. No separate default/ARM64/Release build, no devecocli automatic hidden second ohpm build, no duplicate verify.ps1/verify-simulator.ps1.
2. Independently identify the new HAP that matches THIS source/target. Read-only inspect embedded bundle identifier and relevant signatures (only categorical metadata, never copy private material), require `com.linkora.player.simulator`. Run the existing required x86_64 audit **ONCE**, `scripts/check-ffmpeg-artifact.cjs <actual-new-HAP> x86_64`. Strict PASS requires exit0, exactly approved `libs/x86_64/liblinkora_ffmpeg.so` (ELF machine62), and no ARM64 `libs/arm64-v8a` or real MPV/AKI/C++ native libraries. A mere BUILD SUCCESSFUL string is NOT HAP PASS. If build/ABI/package-ID check fails, INSTALL=NOT RUN, media all NOT RUN — no duplicate build or monkey-patching archive.
3. ONLY after matching x86 HAP ABI and identity PASS, permit ONE legal non-destructive standard HDC/Bundle Manager CLI installation for the NEW separate simulator identity. Do not uninstall/replace pre-existing user `com.linkora.player`; do not reset/clear data, bypass signature integrity or invoke manual old `sign-app`. If install fails capture actual exact code and classify (new simulator identity may still have a separate install issue; do not infer fixed signing). No retry, no signing credential probe. If install works, use CLI to start relevant existing Linkora Ability/functional diagnostic hooks; no GUI launch or layout inspection.
4. An unsupported CLI or missing capability must be honestly `DEPENDENCY_BLOCKED — CLI/TOOLCHAIN`, not an invented PASS. No new custom test instrumentation or production modifications in this validation task.

## 4. After install ONLY: prioritize real media function, not interface

Only if working functional route exists: run representative already authorized native **FFmpeg probe + actual RGBA decoded frame** (probe result != decode PASS), native cancel/timeouts/source resources if existing bounded smoke harness; **WebP image** encoding actual output/signature/redecode only if existing callable harness, otherwise NOT RUN; real System AVPlayer H.264/AAC MP4 prepare/play/positive position, pause/seek/release; HLS H264 PREPARING cancellation correlated real native release, early 3–5s and >20s resource cleanup; distinct MP4 recovery **ONLY** after HLS clean cancellation. Independence/one attempt per case; shared install failure blocks all. No full 59-case regeneration, screenshots, visual UI quality gates or real MPV/ARM64 hardware/capability claims. Only proven runtime observations may be PASS.

## 5. Lean public evidence and owner handoff

Only one new public sanitized report path:
```text
docs/PLAYBACK_PHASE8F_CLI_TARGET_SPLIT_ABI_MEDIA_REPORT.md
```
Provide source/dispatch full40, exact counts for dependency install/build/audit/install/media, effective stub proof vs unknown, actual output bundle ID/FFmpeg native ELF audit, runtime case outcomes and source/status distinctions. Private HAP/files, passwords, sign profiles, certificate fingerprint, device ID, raw stdout/stderr, source filesystem paths, private URL, media or screenshots must stay private. Candidate-wide semantic scrub; stage exactly one report in isolated clone, verify staged paths/modes/blob, parent dispatch, single ordinary push and fresh-fetch/readback. If publication blocked, do not re-run previous build/install/decoder just to publish. Historical STOP/FAIL immutable.

Final result must explicitly show `STATE / TASK_ID / SOURCE_SHA / DISPATCH_SHA / EFFECTIVE_MPV_STUB_RESOLVED / SOURCE_ALIGNED_BUILD / X86_HAP_ABI_AUDIT / SIMULATOR_BUNDLE_ID / INSTALL / FFMPEG_PROBE / REAL_DECODE / WEBP_ENCODE / SYSTEM_MP4 / HLS_CANCEL_RELEASE_AND_20S / RECOVERY / GUI=0 / MANUAL_SIGN_APP=0 / ORIGINAL_WORKSPACE_LIMITS / REMOTE_EVIDENCE_SHA_OR_NONE / NEXT_ACTION`. No completed V1/V2/diagnosis ID replay and no autonomous repair/push of production files.
