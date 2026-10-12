# Phase 8F simulator media-function checkpoint

REVIEW_RESULT: COMPLETED WITH FAILURES / PARTIAL — DEPENDENCY_BLOCKED ACTUAL INSTALL; REQUIRED X86 ARTIFACT AUDIT FAIL.
STATE: COMPLETED WITH DEPENDENT MEDIA NOT RUN.

- TASK_ID: phase8f-level1-simulator-codec-encode-playback-v2
- REPOSITORY / BRANCH: baozi510/Linkora / feat/playback-capability-phase8
- SOURCE_SHA: 7932941b637b3083c9801181ec95bd202667bd43
- TESTED_DISPATCH_SHA: eb079eb70892fa3f166db3e75309fd4d3f6a9a95
- Superseded unexecuted dispatch: c7668da343d9252031dbf9bfb27e5115f21df29f

## Source and execution route

Fresh independent clone/fetch matched exact dispatch, immediate SOURCE parent and task-only drift. Superseded dispatch-to-SOURCE changed exactly workflow, Master Plan, status and handoff. Current policy/CURRENT sections, simulator profiles, EntryAbility/RuntimeDiagnostics, native FFmpeg decode implementation, existing smoke routes, WebP encoder and approved fixture manifests were read. Earlier architecture readings were revalidated. No production/test/script/config/media/history edits or old stopped task execution.

The user physically stopped Computer Use with Escape and then explicitly directed use of DevEco CLI instead of GUI. No further GUI input was issued. Installed `devecocli` help returned0 and exposes build-and-run with product/module/target selection. The GUI Run was NOT performed; the user's replacement CLI route was performed once from the new clone, with `simulator`, `entry@simulator`, Debug and EntryAbility. No uninstall, skip-build, hot-reload, manual sign-app, old credential/profile operation or duplicate verify build was requested.

Initial HDC list returned0 with no target. One normal existing authorized simulator start through installed CLI returned0. Subsequent HDC list/uname/API queries returned0 with exactly one actual x86_64/API26 target. No reset/wipe/config/license change or second start. Existing pinned x86 FFmpeg dependency archives/headers were read and copied only into the new clone's ignored prebuilt dependency directory; pinned commit/ABI manifest and four archive hashes checked, no dependency rebuild or old HAP reused. Approved playback MP4 actual bytes/hash matched the existing corpus record. The fixed FFmpeg smoke requires separate 10-second MP4/HEVC MKV fixtures; their expected historical directory was absent, not replaced with incompatible media. No owned HTTP server/reverse route was started.

## One CLI run: compilation succeeded, install failed

- Run UTC: 2026-10-12T14:45:40.2299252Z to 2026-10-12T14:47:23.2272343Z.
- Original CLI wrapper exit: **1**. One run/build workflow; CLI performed its normal ohpm install and Hvigor pipeline.
- Hvigor reported **BUILD SUCCESSFUL in 43 s 337 ms**, then **Build completed successfully**. The nested build numeric exit was not independently captured; compilation success is the original tool's reported semantic result, not complete artifact acceptance.
- Actual installer: **failed to install bundle**, **code:9568332**, **install sign info inconsistent**. No successful install/start of this source was observed. This is not a new keystore-open or historical 11014003 error. No signer retry, app removal, second run/build or dependent runtime test followed.
- BUILD_COUNT=1 scoped simulator Debug workflow; ARM64/default/Release compile requests=0. Manual SIGN_APP_COUNT=0; keystore probes=0. The build pipeline's normal SignHap task is not a manual SDK sign-app invocation.
- New sole HAP: 62,525,910 bytes, SHA256 `07D55AFF91F72F129D06F5741A0A57E54912001DF20627BAD6D6CBE208274A4C`; retained privately.

ACTUAL_FIRST_BLOCKER: DEPENDENCY_BLOCKED — ACTUAL INSTALL (9568332).

The existing read-only `check-ffmpeg-artifact.cjs` was invoked once on that fresh HAP for x86_64. It returned **1**, with **Native ELF/ABI mismatch: libs/arm64-v8a/libaki_jsbind.so**. This is a real required artifact failure, not an optional observer error. The compile-success message cannot establish a valid x86 package; presence of a prebuilt ARM64 library does not establish an ARM64 compilation or hardware validation. No audit modification, recheck, workaround or rebuild occurred. Exact packaging cause is not established by this checkpoint.

Private original stream SHA256: CLI stdout `979E3743C1C69043EF88CB080C4EC59EC7144FEB9AAE56F90EBA0148D90091A2`; CLI stderr `56BB54CE42CE557EAD5A62E5894612F3B8D60B5FDC418F82048C27BB5620AB75`; artifact-audit stdout `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`; audit stderr `63F66438867C2A133FFA9F7ADCF9C70586E6B67C960A38B1D09A288210E4B6A7`. These hashes describe locally retained originals, not publicly replayable raw logs or binary evidence.

After the stopped run, the user supplied a separate IDE deployment log: `entry-default-unsigned.hap` rejected with 9568347, `install parse native so failed`, and an explicit device/C++ ABI mismatch. This is USER-REPORTED evidence, not another executor run. Read-only inspection found all nine native entries in the existing default HAP have ELF machine183 (AArch64); the current default profiles specify arm64-v8a. The fresh CLI simulator HAP has one x86_64 entry, `liblinkora_ffmpeg.so` (machine62), plus four machine183 ARM64 entries: `libaki_jsbind.so`, `libc++_shared.so`, `libmpv.so`, and `libmpv_wrapper.so`. No extraction, mutation, reinstall or build followed. Thus the user's default-target error and the executor's 9568332 signature-consistency error are distinct; the simulator package also demonstrably violates the repository's sole-x86-library acceptance boundary. The entry manifest retains the real MPV dependency and declares a simulator stub substitution, but effective dependency substitution/packaging mechanics are not proven by the declaration or static checker. No keystore-unavailable inference is made from either installer result.

## Independent function outcomes

| Field/case | New executions | Result |
| --- | ---: | --- |
| X86_ACTUAL_TARGET | One normal start, then one target verification | PASS: actual x86_64/API26 connected |
| NORMAL_IDE_RUN_STATUS | GUI Run 0; user-authorized CLI Run 1 | CLI FAIL at install; compiler reported success; required artifact FAIL |
| APP_FUNCTIONAL_ENTRY_STATUS | 0 current-source installed invocations | BLOCKED / NOT RUN |
| A: FFMPEG_PROBE | 0 | NOT RUN — shared install/artifact prerequisites blocked |
| A: FFMPEG_REAL_FRAME_DECODE | 0 | NOT RUN; decoded RGBA bytes/time/content NOT PROVEN |
| A: FFMPEG_CANCEL_RESOURCES | 0 | NOT RUN / NOT PROVEN |
| B: WEBP_IMAGE_ENCODER | 0 | NOT RUN — no installed callable current-source invocation; existing AnalyzerIntegrationSmoke contains WebP signature checks, but no new encode/redecode/dimension result |
| VIDEO_AUDIO_ENCODER_NOT_IMPLEMENTED | 0 | NOT IMPLEMENTED / NOT IN SCOPE; WebP is image encoding |
| C: SYSTEM_MP4_PLAY_SEEK_PAUSE | 0 | NOT RUN; prepared/play/position/pause/seek/release NOT PROVEN |
| D: SYSTEM_HLS_PENDING_CANCEL_NATIVE_RELEASE | 0 | NOT RUN / NOT PROVEN |
| D: EARLY_AND_20S_CLEANUP | 0 | NOT RUN / NOT PROVEN; no normal native resource zeros claimed |
| D: DISTINCT_MP4_RECOVERY | 0 | NOT RUN — release and cleanup prerequisite unproven |
| E: MPV_SIMULATOR_STUB | 0 | NOT SUPPORTED / NOT RUN: existing simulator unavailable boundary, not real MPV decode |
| UI visual/layout/screenshot acceptance | 0 | NOT IN SCOPE; IDE navigation was not an app appearance test |

Advanced codec/HDR/DV/audio matrix, ARM64 milestone, real hardware MPV/decoding and performance/power remain DEFERRED/NOT RUN. No newly observed System unsupported codec result exists; no inference about device codec support is made. No frame/probe/encode/player result is inherited from old evidence.

## Privacy, workspace and handoff

Only this authored sanitized new report is authorized. Whole candidate was inspected for credential/profile/raw-output/host/target/device/PID/private-path disclosure. SDK process streams, HAP and private device/endpoint metadata are not published. Staged exact path/mode/blob and fresh dispatch must be checked before ordinary commit/push; final evidence SHA is returned externally after fresh remote fetch/readback. Historical files and failed gates remain unchanged.

CLI ohpm left four lockfiles marked modified in the NEW clone (entry, linkora_ffmpeg, linkora_proxy and root locks); each Git-normalized worktree blob matches HEAD and the semantic diff is empty. They remain unstaged and were not restored because this task gives no explicit normalization allowlist; no locks are included in the evidence commit. The clone is not claimed bytewise clean. No original developer reset/clean/stash/checkout/build or file-write command was issued. Before the user stopped GUI control, DevEco launch restored an existing project window; IDE incidental autosave/global effects were not measured. Exhaustive original-workspace bytewise comparison NOT RUN, so preservation is limited to observed operations.

A guessed optional preparation-script read was missing (enclosing command1), RECORD_ONLY; not executed or retried and not an acceptance gate. Read-only tool discovery/source reads also produced truncated output, followed by bounded relevant reads; no helper was created or changed. Nothing here downgrades the installer or ABI failure. The owned simulator was started once; no app/player/media server/reverse mapping resource was created by the failed install. Simulator remains running for user use; this is not evidence of normal player cleanup.

NEXT_ACTION: GPT should independently review the actual simulator packaging/dependency-target result and installer signature-consistency rejection. Any follow-up must have a distinct meaningful authorization; do not reinstall/rebuild this stopped case, remove existing user app, guess signing credentials, reuse the ABI-failed HAP or relabel it a valid x86 runtime result.
Not checked: actual media-function cases, native cleanup/recovery, effective dependency-substitution mechanics, raw/binary remote replay and original-workspace bytewise preservation. Native entry names and ELF machine headers were read after the failure; this is not runtime or complete dependency-link validation.
