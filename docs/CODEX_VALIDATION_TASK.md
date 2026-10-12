# Codex Task — CLI-Only Simulator Native Packaging and Installed Identity Diagnosis

> STATE: READY
> TASK_ID: phase8f-level0-simulator-abi-dependency-install-identity-diagnosis-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_0_DEPENDENCY_DIAGNOSIS — READ-ONLY CLI / NO BUILD
> SOURCE_SHA: 3ee01e2b8c3fd85960e9f857a1efc6452b81ee2b
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> COMPLETED_PREVIOUS_TASK: phase8f-level1-simulator-codec-encode-playback-v2
> PREVIOUS_EVIDENCE_SHA: 5cd9166f725be3418545a0ef2ea2277390d4bd83
> KNOWN_PREVIOUS_ERRORS: ACTUAL INSTALL 9568332; REQUIRED X86 HAP AUDIT EXIT1 (AARCH64 MPV/AKI/CXX LIBS)
> USER_REPORTED_OTHER_ERROR: DEFAULT ARM64 HAP TO X86 SIMULATOR 9568347 (NOT EXECUTOR RUN)
> EXECUTION_MODE: CLI ONLY — NO IDE WINDOW / GUI / COMPUTER USE
> MAX_BUILD/INSTALL/SIGN/KEYSTORE_OPERATIONS: ZERO
> MAX_APP_UNINSTALL/RESET/CLEAR_DATA/PROFILE_CHANGES: ZERO
> NEXT_OWNER: GPT MAKES MINIMAL SOURCE/CONFIG PATCH AFTER GROUNDED DIAGNOSIS

## 0. Only the two specific observed blockers matter

User prioritizes functioning native codec/decoder/encoding/playback on simulator, NOT GUI or extra reports. In V2 a user-authorized CLI Run used x86_64/API26, one simulator Debug build reported BUILD SUCCESSFUL; final CLI wrapper exited1 at genuine native installer error `9568332 install sign info inconsistent`. An independent required existing x86 audit returned1; actual private HAP locally inspected had x86_64 `liblinkora_ffmpeg.so` but **AARCH64** `libaki_jsbind.so`, `libc++_shared.so`, `libmpv.so`, `libmpv_wrapper.so`. Other user-supplied default ARM64 HAP failed with `9568347`, a different package/error. All real FFmpeg decoder, WebP image encoder, System MP4/HLS playback tests **NOT RUN**. Prior executor ID is completed; do not run it again or repackage/reinstall its invalid HAP.

GPT independently read `entry/oh-package.json5`: real `@mpv-ohos/mpv-arkts:1.0.0` is an unconditional dependency; `simulatorTargetDependencies` asserts a stub but the checked-in `entry/oh-package-lock.json5` resolves the remote native HAR. `scripts/check-simulator-product.cjs` verifies only existence of the stub declaration; real simulator HAP did not honor it. Do **not** claim the exact Hvigor/ohpm causal mechanism is proven before checking effective target dependency configuration. Official ohpm docs describe per-target generated `dependencyMap.json5` and optional `ohpm install --target_path` mechanics: https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hmos-ohpm-install . Official Huawei 9568332 guidance describes existing same-bundle app/retained data with incompatible signature OR multi-package sign mismatch: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/bm-tool-V5 . Neither automatically implies incorrect keystore password, permission to remove an installed app, or an installable x86 HAP.

**This is a single targeted, low-cost read-only causal diagnosis** which should enable GPT to make a concrete minimal config fix. DO NOT spend time on old credential probes, helper scripts, FFmpeg media generation, UI inspection, packaging reruns or repeating V2. Zero compiler executions.

## 1. Source binding and protected workspaces

- Fresh GitHub fetch/checkout ONLY in a new isolated clean worktree. Verify dispatch full40 SHA direct parent SOURCE_SHA `3ee01e2b8c3fd85960e9f857a1efc6452b81ee2b`; SOURCE..dispatch exactly `docs/CODEX_VALIDATION_TASK.md`. Previous evidence `5cd9166f725be3418545a0ef2ea2277390d4bd83` must be SOURCE's immediate parent, with exactly two review docs changed. Read full current workflow/plan/status/handoff and full this task.
- Do not operate on original potentially dirty `D:/Linkora`, stopped private evidence checkouts or the old V2 failed HAP. No reset/clean/stash/checkout/build in protected locations. Keep private logs, package bytes, signing material, user/device IDs and paths private; no final exhaustive original bytewise snapshot claim unless actually performed.
- Read only real `build-profile.json5`, `entry/build-profile.json5`, `entry/oh-package.json5`, `entry/oh-package-lock.json5`, project root `oh-package.json5`, `hvigorfile.ts`, `entry/hvigorfile.ts`, `entry/simulator-stubs/mpv-arkts/oh-package.json5`, `scripts/check-simulator-product.cjs` and `scripts/check-ffmpeg-artifact.cjs`. Confirm current production/ABI paths before any assertion.
- No GUI/Desktop/IDE application launch, clicks, PowerShell GUI automation or debug window interactions. Use installed CLI `-h`/read-only subcommands only, and avoid command lines with secrets, tokens, keystore references.

## 2. Identify real MPV dependency resolution — no builds or package modifications

- Record exact **source** relationship: production `entry.dependencies['@mpv-ohos/mpv-arkts']`, simulator stub and `simulatorTargetDependencies` field, original checked-in remote HAR lock resolution, x86 FFmpeg target declaration. Compare them with publicly documented **supported** target-specific ohpm dependency configuration. Distinguish documented support from invented property names.
- Check only if already present in NEW scratch clone (or safe newly generated metadata under its own isolated path from a completely read-only CLI tool) any generated Hvigor `dependencyMap.json5`, target-specific `oh-package*.json5` and target lockfile. If not present, mark `NOT PRESENT`; do not run `ohpm install`, `--target_path` install, `hvigor --sync`, a rebuild or reinstall to manufacture them. CLI help/version listings permitted **without invoking build or dependency installs**. Do not read private old stopped worktree merely to find these caches.
- Provide an actionable minimal safe target split proposal for GPT: keep **real ARM64 MPV package** for `default`; use existing **compile-only MPV stub** for `simulator`, backed by an actually supported per-target dependency mechanism. Specify which exact files/keys would need change and what proof is still missing. If toolchain behavior cannot be established without a build, `MECHANISM UNCONFIRMED`, not source/capability PASS. Don't edit `oh-package`, lockfiles or static checker yourself.
- Independently state the mandatory next package gate: newly created x86_64 simulator HAP MUST contain `liblinkora_ffmpeg.so` with machine62 and NO `libs/arm64-v8a/` or any real MPV/AKI/CXX foreign-ABI lib; package audit exit0 is required BEFORE installing/testing media. No rechecking or repairing previous invalid HAP.

## 3. Diagnose installer sign identity conflict WITHOUT mutation

- Use only a **single** safe read-only currently connected simulator status check when accessible. Check x86_64/API26 without changing emulator lifecycle/config. Read-only CLI package metadata/status inspection for existing `com.linkora.player` if supported, and compare **categorically** with the reported new product/bundle identity; safely classify `SAME_BUNDLE_PREEXISTS / NOT_INSTALLED / RETAINED_IDENTITY_OR_UNKNOWN`. Never output device identifiers, signed cert fingerprints, profile keys or installed user-app metadata to public report. Do not inspect old passwords, invoke sign-app/keytool, export certificates or reset/modify profiles.
- Isolate 9568332 from ABI failure: whether existing same bundle app's signature collision is demonstrable, whether multiple packaged artifacts are plausible or UNKNOWN, and whether a **supported distinct simulator-only product bundleName** is a safe non-destructive next proposal while default production identity remains unchanged. Official product `bundleName` selection is per-product, but existing `scripts/check-simulator-product.cjs` currently asserts simulator shares production identity; GPT must review/update that guard intentionally IF such a change is chosen, not quietly bypass it. Do not change bundle ID or signing yourself. Do not uninstall, update, force-replace, clear app data, reset/wipe emulator or run an install probe.
- If CLI metadata access is denied/unavailable, mark that dimension `UNKNOWN`, continue dependency source inspection; no global STOP. Don't claim the old error is caused by a particular keystore or package until supported.

## 4. One precise owner-facing report, no repeat loops

One NEW sanitized public report file, when ordinary safe publication is possible:
```text
docs/PLAYBACK_PHASE8F_SIMULATOR_ABI_AND_INSTALL_IDENTITY_DIAGNOSIS.md
```
Keep under ~120 lines; report: task/source/dispatch SHA, checked actual source file/blobs and lock resolution, target-specific dependency mechanism `PROVEN/NOT PROVEN`, exact official documentation links where used, true previous x86 ABI failure/native inventory as `LOCALLY REPORTED`, read-only current app identity status `KNOWN/UNKNOWN`, distinct 9568332/9568347 errors, minimal exact recommended config changes **proposal only**, execution counts all ZERO, and next owner action. All old actual playback media `NOT RUN` without inheriting PASS.

Inspect whole public candidate for raw private local paths/logs/HAP/media/URLs/credentials, account/signing identity, device target IDs, user installed-app inventories; stage ONLY this one file, check staged path/mode/blob; single ordinary commit/push with parent dispatch if unchanged; fresh fetch verify report and HEAD. If publication blocked preserve local findings and report no evidence commit, do not rerun any diagnostics or tests.

Failure handling: `RECORD_ONLY` optional metadata tool absence, `DEPENDENCY_BLOCKED` only the dependent fact, `GLOBAL_SAFETY_STOP` actual unauthorized worktree mutation/privacy exposure. Do not turn failure of optional source lookup into task abort or repeat it. No new HAP, build, sign, simulator startup, install, playback, optional FFmpeg smoke or screenshot. No reopening the prior completed task.

Required final fields: `STATE / TASK_ID / SOURCE_SHA / DISPATCH_SHA / REVIEW_RESULT / EFFECTIVE_MPV_DEPENDENCY_FINDING / SIMULATOR_BUNDLE_IDENTITY_FINDING / PROPOSED_MINIMAL_SOURCE_CHANGE / BUILDS=0 / SIGNS=0 / INSTALLS=0 / MEDIA=NOT RUN / GUI=0 / REPORT_SHA_OR_NONE / NEXT_ACTION`. After this one diagnosis GPT independently reads GitHub and makes the actual minimal supported change; avoid another cycle of identical diagnosis.
