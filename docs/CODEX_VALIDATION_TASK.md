# Codex Task — CLI-Only Autonomous Simulator Build Repair and Media Function Checkpoint

> STATE: READY
> TASK_ID: phase8f-cli-autonomous-simulator-build-repair-and-media-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — BOUNDED AUTONOMOUS BUILD REPAIR
> SOURCE_SHA: c5d79b27c8462b8f7e1c5ca44c45d5714ae66b28
> ALLOWED_DISPATCH_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> PREVIOUS_COMPLETED_TASK: phase8f-level1-cli-mpv-target-split-abi-gated-media-v1
> PREVIOUS_COMPLETED_REPORT: c5d79b27c8462b8f7e1c5ca44c45d5714ae66b28
> MODE: CLI ONLY — NO GUI / DESKTOP IDE OR COMPUTER USE
> NEW_OWNER_PERMISSION: READ-ONLY RELEVANT DIRECTORIES + COPY PINNED NATIVE INPUT TO ISOLATED SCRATCH + SELF-REPAIR COMPILATION/PACKAGING THERE
> MAX_SCOPED_SIMULATOR_DEBUG_BUILDS: 3, ONLY FOR DISTINCT ROOT CAUSES AND REAL REPAIRS
> MAX_OHPM_PARAMETERIZED_INSTALLS: 2, ONLY IF A CLEAN OR REPAIRED SCRATCH TARGET NEEDS THEM
> MAX_SUCCESSFUL_ABI-GATED_INSTALL_ATTEMPTS: 1
> OLD_KEYSTORE_OR_MANUAL_SIGN_APP_OPERATIONS: 0
> ORIGINAL_PROJECT_WRITE/RESET/CLEAN/STASH/BUILD: 0
> EXISTING_SIMULATOR_APP_UNINSTALL/CLEAR_DATA/WIPE/RESET: 0
> UI_VISUAL_LAYOUT_TESTS: 0
> NEXT_OWNER: GPT REVIEWS ANY CANDIDATE SOURCE PATCH; NO UNSUPERVISED MERGE TO FEATURE BRANCH

## 0. Explicit expanded authorization — this is NOT another read-only task

The user now explicitly authorizes Codex to **inspect necessary local directories, work through compilation errors and independently attempt bounded fixes**. A separate after-report user-authorized read-only inspection found both `x86_64` and `arm64-v8a` pinned native FFmpeg prebuilt directories in the existing original project; this new finding did NOT change the prior completed task or its GitHub report. The x86_64 tag is `n8.1.3`, FFmpeg commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, triple `x86_64-linux-ohos`, required four headers are present, and archived SHA256 hashes were reported:
- avformat: `697CD7D4861418A1091421337B48D6E1DE255F8EE9341005A44DA7AD7EA1AED1`
- avcodec: `9DDD5CE0292E4E372263029DE6AACB00BF8BE5BCED86AF1D989B52D927DD4170`
- avutil: `074AE78E9D6C1BFD9FDAE7A161409F48EABA39D1D979B973C3CA233BA24DBB2A`
- swscale: `452F0BB617EEC5C8A9CE0872AE28B478AE74828A04725971823EB283328D74C9`

These are **user-reported/previously locally verified native inputs**, not new remotely replayed binary proof and not a build PASS. Their absence in a freshly cloned Git checkout is expected because `third_party/ffmpeg/prebuilt/` is Git-ignored. Windows-host `ffmpeg.exe`, `ffplay.exe`, `ffprobe.exe` are not substitute OHOS libraries.

**Codex may now find and READ ONLY the specific existing native input prefix** `third_party/ffmpeg/prebuilt/x86_64` under the user's existing original project (and the analogous ARM64 manifest for target differentiation if necessary), plus necessary SDK/CLI/toolchain directories, relevant build caches, package lock/manifests, and new scratch build outputs. Do not treat directory access as permission to read arbitrary private files, other user projects, credential/profiles/keystores or historical stopped-task logs. Do not disclose full local paths or private filenames in public evidence. No mutation of any original project file, ignored prebuilt, old clone or user application is authorized.

The prior task independently PROVED local simulator MPV Stub resolution via a parameterized `ohpm install --pf oh-package-simulator-params.json5`, generated entry lock `registryType=local`, and canonical installed stub module bytes, with actual checker exit0. Do NOT repeat that old task to change its result. This new task must establish an actual source-aligned x86_64 simulator HAP and run media functions, not another general diagnosis.

## 1. Bind source/target and stage verified FFmpeg inputs

1. Fresh-fetch GitHub and verify dispatch is exactly the direct child of SOURCE_SHA, task-only diff, old completed report unchanged. Preserve branch/history and use a **new isolated scratch clone** for all builds and edits. Inspect real `AGENTS.md`/local project instructions if present before editing. No DevEco GUI start, no desktop computer use.
2. In the *explicitly newly authorized* original-project pinned FFmpeg prebuilt directory perform bounded read-only listing and read/hash checks of manifest, four required headers `libavformat/avformat.h`, `libavcodec/avcodec.h`, `libavutil/avutil.h`, `libswscale/swscale.h`, and four x86 archive files. Verify version, commit, x86 ABI/triple and their exact four SHA256 hashes above. Inspect only relevant native inputs; no global disk scan or credential access. A missing file may prompt one bounded directory search for the actual pinned prefix without modifying the original. **Never copy real ARM64 libraries into simulator scratch**.
3. Copy ONLY validated `x86_64` manifest, `include/` and `lib/libavformat.a`, `libavcodec.a`, `libavutil.a`, `libswscale.a` from this source into the new scratch ignored `third_party/ffmpeg/prebuilt/x86_64`. Recheck copied bytes against reported hashes and required header/manifest content. Don't copy old HAPs, private logs or build caches; copy inputs, not output artifacts. If original contents unexpectedly fail validation, diagnose precisely; may attempt a supported *scratch-only* x86 dependency regeneration from the exact pinned source with present SDK inputs if technically needed and safe, but no network/credential bypass or host FFmpeg substitution. Such an exceptional rebuild is separately counted and must not alter the original.
4. Check already-running authorized simulator via CLI x86_64/API26. At most one ordinary CLI start of the existing simulator if absent; no emulator wipe/reconfigure. Confirm exact simulator parameter `oh-package-simulator-params.json5`, separate bundle identity `com.linkora.player.simulator`; `default` real ARM64 MPV remains untouched.

## 2. Give Codex independent repair authority INSIDE scratch only

- Codex **may change local source, build profiles, dependency parameters, CMake, manifest, scripts, ArkTS typing, or packaging configuration** in the isolated scratch checkout when a real compiler/resolution/ABI issue indicates a concrete fix. It may inspect necessary non-secret native toolchain directories and sanitized compiler logs. Each patch must be small, justified by the actual error and followed by a targeted static check or bounded build. Do not change app behavior unrelated to media/build, credentials, production signing, SDK global settings, AppScope default identity or actual original user workspace.
- First prepare simulator OHPM dependencies with **explicit** `ohpm install --pf oh-package-simulator-params.json5` only if scratch is not already correctly prepared. Require genuine generated MPV local stub resolution (not just existence of the `@param` reference) and keep real MPV 1.0.0 for default. An optional second parameterized ohpm install is allowed **only after a justified scratch dependency/config fix**, never to blindly rerun an identical command. No `devecocli run` with unproven parameter forwarding.
- Invoke direct supported **CLI Hvigor** with `-p parameterFile=oh-package-simulator-params.json5`, `-p product=simulator`, correct `entry@simulator` and Debug scope. Up to **THREE** actual x86 simulator build invocations TOTAL (ideally ONE): one baseline plus at most two after **materially different, concrete local repairs**. Not three tries of the same failure. No global default/ARM64/Release compile, no repeated full verify cycle, no build-after-every-edit habit. If a build fails, Codex may inspect the error and fix the scratch source rather than requesting new permission for every compilation issue.
- After any successful build, inspect fresh HAP source/target identity and run `scripts/check-ffmpeg-artifact.cjs` for x86_64; it MUST return0 and show only allowed machine62 x86 native FFmpeg, **ZERO** AArch64/MPV/AKI/C++ libraries. Effective generated MPV stub must remain proven. If the HAP fails, trace packaging to its real dependency/cause, patch scratch if feasible, then spend the next authorized build budget. Do not mask checker findings, repack a bad HAP, or install any ABI-invalid HAP. Embedded package ID must be `com.linkora.player.simulator` before install; a source-only bundleName is insufficient.
- For **any necessary patch to tracked production/build files**, keep candidate changes in a **separate isolated branch** based on this task dispatch, with clear git diff, no generated lock/prebuilt binaries, no secrets. Codex MAY create a conventional candidate commit and push a separate `codex/phase8f-simulator-build-repair-v1` branch ONLY if its remote head can be safely bound to dispatch and its paths are reviewed. **Do not force-push, merge, PR-auto-merge or directly push patched production/config files onto `feat/playback-capability-phase8`**. Provide candidate branch SHA and precise diff to GPT for independent owner review. If remote candidate push is unsafe/unavailable, retain diff in scratch and summarize it in the report; do not abandon safe locally validated progress.
- Compilation repairs that alter a source hash MUST bind new HAP/build evidence to the actual candidate patch SHA, not falsely to dispatch source. Nothing from a previous invalid HAP, older unsigned HAP or other task is reused as a proven current result. Stop when the build budget is exhausted; present the exact remaining compiler/packager blocker rather than looping.

## 3. Only after a valid HAP: one non-destructive install, then media functionality

- If AND ONLY IF actual generated stub resolution PASS + x86 ELF/ABI audit exit0 + embedded simulator bundle identity PASS, allow ONE normal native CLI install of THIS candidate HAP into the already authorized simulator. Do not uninstall or replace original `com.linkora.player` package, wipe/reset, clear app data, disable signature checks, search private signing keys or run manual `sign-app`. If install returns `9568332` or any other error, capture actual code once and mark dependent runtime `NOT RUN`; Codex may reason about installer cause but must not retry install or perform destructive signature work without further owner consent.
- If install succeeds and an existing callable diagnostics/Ability route works, test bounded **real** native FFmpeg probe and decoded RGBA frame (probe != decode), optional WebP image encoding through the existing functional route, System AVPlayer H.264/AAC MP4 actual prepared/PLAYING/position/pause/seek, System HLS H264 PREPARING cancel/normal native release and early plus >20s resource cleanup, with recovered MP4 only if cleanup positively proven. One attempt per independent case; unrelated fixture/harness absence is its own BLOCKED/NOT RUN, not a reason to fabricate PASS or create UI tests. No broad 59-case matrix, no UI screenshot/skin/layout assertions. MPV simulator is intentionally Stub, real ARM64 MPV remains untested.

## 4. Minimal reviewable evidence, never rewrite historical task

New report permitted on existing feature branch if source branch still equals this dispatch:
`docs/PLAYBACK_PHASE8F_CLI_AUTONOMOUS_SIMULATOR_BUILD_REPORT.md`

Report task/dispatch full40, cloned source, validated copied FFmpeg input names/version/SHAs (no absolute paths), genuine generated local MPV lock, up to three distinct build attempts/errors/patches, final HAP ABI/bundle ID, source-aligned SHA, actual native install and each media case status, remote candidate branch SHA if applicable, and truthful remaining blockers. No device/user IDs, old HAP, private logs/media/screen captures, certificates, keystores, PIDs, private host paths or credentials in public report. Stage only this new report on unchanged task dispatch, one ordinary no-force commit/push, fresh-fetch one-parent/report-only identity; patch commits belong ONLY on separate candidate branch. No changing historical report or rewriting old COMPLETED task data. Publication failures do not authorize recompilation or rerunning playback.

Required final summary: `STATE / TASK_ID / SOURCE_SHA / DISPATCH_SHA / VERIFIED_X86_INPUT / COPIED_TO_SCRATCH / RESOLVED_LOCAL_MPV / BUILDS_USED_AND_ERRORS / SCRATCH_REPAIRS / CANDIDATE_BRANCH_SHA_OR_NONE / X86_HAP_ABI_AUDIT / EMBEDDED_SIMULATOR_BUNDLE_NAME / INSTALL_RESULT / FFMPEG_PROBE_AND_REAL_FRAME_DECODE / WEBP_ENCODE / SYSTEM_MP4 / HLS_CANCEL_RELEASE_20S / MP4_RECOVERY / GUI=0 / MANUAL_SIGN_APP=0 / ORIGINAL_USER_WORKSPACE_READ_ONLY / REMOTE_EVIDENCE_SHA_OR_NONE / NEXT_ACTION`.

**Success means actual native function evidence, not merely a green build.** A completed task with a truthful blocker and bounded attempted repairs is valid; no same-ID rerun, no credential guessing, no workspace or simulator-data destruction.
