# Codex Task — Simulator Codec Decode, Supported Encoding and Playback Functional Checkpoint

> STATE: READY
> TASK_ID: phase8f-level1-simulator-codec-encode-playback-v2
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — MEDIA FUNCTION FIRST / NO UI TESTS
> SOURCE_SHA: 7932941b637b3083c9801181ec95bd202667bd43
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> SUPERSEDED_UNEXECUTED_READY_TASK_ID: phase8f-level1-normal-deveco-simulator-run-v1
> SUPERSEDED_UNEXECUTED_DISPATCH_SHA: c7668da343d9252031dbf9bfb27e5115f21df29f
> USER_GOAL: SIMULATOR CODEC/DECODER, ACTUAL SUPPORTED ENCODING AND PLAYBACK FUNCTIONS
> UI_LAYOUT_SCREENSHOTS_VISUAL_ACCEPTANCE: NOT REQUIRED / NOT IN SCOPE
> NORMAL_ENTRY: DEVECO STUDIO RUN, simulator PRODUCT, entry@simulator TARGET
> MAX_NEW_SCOPED_X86_DEBUG_COMPILES: 1
> MANUAL_SIGN_APP / OLD_KEYSTORE_PROBES: 0
> FULL_ARM64_OR_RELEASE_BUILDS: 0
> MPV_REAL_NATIVE_DECODING_ON_SIMULATOR: NOT SUPPORTED / NOT RUN

## 0. Goal and new execution priority

**User correction:** the goal is functional codec/decoder, encoding and media playback testing. Do NOT spend time validating page layout, screenshots, player skin, full-screen mode or UI pixel/color ROI. Unlike the replaced previous READY task, **a Linkora-owned visual window, visible color, screenshot, UI tree and screenshot metadata are NOT functional acceptance gates**. Installing and starting app or existing callable simulator diagnostics may still be technically necessary to execute runtime media APIs. Check real process/Ability and diagnostic/event/native observations only as needed to prove the functional cases; a merely installed package or launcher does NOT make any decoder/encoder/playback claim PASS.

The previous `phase8f-level1-normal-deveco-simulator-run-v1` was READY but had no reported execution. This new distinct task SUPERSEDES it, without relabeling its untouched ID FAIL/STOP/PASS. Historical manual signer failure `11014003`, inaccessible keystore and older V4 CLOSED task remain immutable, but manual keystore is NOT a precondition of ordinary DevEco simulator Run.

Actual repo feature inventory (read directly before execution):
- `entry/src/main/ets/playback/SystemPlaybackPort.ets`: real simulator System AVPlayer playback decoder.
- `linkora_ffmpeg/src/main/cpp/analysis.cpp`: x86 FFmpeg probe + real `avcodec_send_packet`/`avcodec_receive_frame` decode and `sws_scale` RGBA output. Existing `entry/src/simulator/ets/diagnostics/FfmpegRuntimeSmoke.ets` can invoke native probe/frame/cancel/timeout, wired by `entry/src/simulator/RuntimeDiagnostics.ets` from a controlled `Want` parameter `linkoraFfmpegSmoke` (existing allowed endpoint pattern). Do not publish endpoint, fixture host or media.
- `entry/src/main/ets/services/SystemWebPEncoder.ets`: existing ImageKit ImagePacker **WebP image** encoder; **not** H.264/HEVC/AAC video/audio transcoder.
- `MpvPlaybackPort` native capability on simulator is stub/unavailable; no genuine MPV decoder/codec PASS is possible here.

Keep decoder, metadata probe, image encode and player outcomes distinct. Nothing here asserts video/audio encoding is implemented. If the user later wants video/audio transcoding, that needs source work, not a fabricated PASS from decoder probe or fixture creation.

## 1. Cheap source/environment prerequisite and maximum one ordinary Run

1. Fresh-fetch exact branch, verify `STATE READY` and new ID. Current dispatch must have immediate parent SOURCE_SHA `7932941b637b3083c9801181ec95bd202667bd43` and change **only** `docs/CODEX_VALIDATION_TASK.md`. Prior dispatch `c7668da343d9252031dbf9bfb27e5115f21df29f`→SOURCE must change exactly `docs/AI_WORKFLOW.md`, `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/SESSION_HANDOFF.md`. Check protected original/old stopped user workspaces remain untouched; use fresh isolated checkout, no reset/clean/stash/build of original `D:/Linkora`. Read current architecture/workflow/status and actual source files above, simulator build profiles, `RuntimeDiagnostics`/EntryAbility and authorized fixture manifest.
2. Cheap read-only actual HDC target check **x86_64/API26** first; no `-config`, undocumented emulator JSON parsing, instance reset or wipe. If absent, at most one normal supported start of existing authorized simulator; if still unavailable `DEPENDENCY_BLOCKED — SIMULATOR`, build0 and all runtime `NOT RUN`, but preserve offline source inventory/report. Check existing fixture bytes and allowed route before media tests, no 59-case matrix regeneration, no new services/ports except a narrowly scoped owned route actually required and permitted by previous fixture approval.
3. Select `simulator` product / `entry@simulator` in **normal DevEco Studio Run** from isolated project, invoke once, at most ONE necessary scoped x86 Debug compile to make artifact correspond to current source. Do NOT separately run `scripts/verify-simulator.ps1`, `scripts/verify.ps1`, default ARM64/triple builds or previous failed SDK `sign-app`, no keystore queries/old password/profile import. If IDE Run can't be safely controlled, `DEPENDENCY_BLOCKED — IDE RUN CONTROL`; no new invented signing dependency. If build fails, record exact error as BUILD FAIL and dependent cases NOT RUN; if actual install fails, record actual install error and dependent cases NOT RUN, not an automatic old-keystore assumption. No repeated builds to make a gate green.
4. Confirm lawful installed/started current-source Linkora app/Ability or existing authorized callable simulator functional diagnostic entry, **without inspecting UI visuals**. `RuntimeDiagnostics` may technically run after `loadContent`; do not test page appearance. No custom instrumentation or production code edits just to fake a functional invocation; if no functional entry is callable, record `DEPENDENCY_BLOCKED — FUNCTIONAL ENTRY` for dependent cases, avoid UI-only troubleshooting loops.

## 2. Targeted media-function cases — independent, source-backed

**Case A — Native FFmpeg decode (priority):** use existing authorized FFmpeg simulator diagnostics/controlled locally owned fixture, preferably H.264/AAC MP4 plus existing HEVC MKV if both already available. Verify actual encoded stream/container metadata (e.g. codec H264, AAC, duration/dimensions) **separately** from `extractFrame` returning decoded RGBA bytes with valid width/height, `width*height*4` buffer size, frame timestamp/target relationship and repeatable content check if already implemented. A simple `probe` is `PROBE PASS`, never a `DECODE PASS`. If old `FfmpegRuntimeSmoke` safe route is available, use its native timeout/cancel and ensure observed zero proxy active sources and no stale output, each as separate observations. Do not invent FFmpeg H.264 encoding support. One bounded run of relevant existing smoke cases only; no new full test matrix. If a pre-existing runner includes additional cases in the same single invocation, report their outcomes as observed, without multiplying runs.

**Case B — Existing image encoding:** only if an existing safe app/harness invocation of `SystemWebPEncoder.encodeRaw` or `encode` is actually available, verify a valid RGBA frame encodes to nonempty `image/webp` bytes, correct signature/container and expected dimensions when decoded by a real supported image decoder, and quality/input bounds if supported. Record `ENCODE IMAGE/WEBP PASS/FAIL`, not video encoding. If no safe existing callable route, state `NOT RUN — NO EXISTING ENCODER FUNCTIONAL HARNESS`; do not build new instrumentation or force a new UI path. Video/audio transcoding: `NOT IMPLEMENTED / NOT IN SCOPE`, not `FAIL` of WebP.

**Case C — System player functional playback:** one controlled H.264/AAC MP4 through real System AVPlayer. Check actual media prepared/playing, codec/error code, monotonic or positive playback position, pause/resume and one seek completion/position (if accessible via existing functional instrumentation), and bounded normal release. First-render native event or decoder frame bytes can help but do **not** demand screenshot/color ROI or UI-layout checks. No claim of real playback based solely on a manual `play()` invocation or mocked event. If the existing app only exposes this operation via a basic user action, you may trigger that action strictly as a functional driver; do not assess UI appearance.

**Case D — System HLS PREPARING cancel and conditional recovery:** if existing approved HLS H264 fixture is reachable, one prepare-start followed by normal leave strictly while pending, correlate System AVPlayer candidate release and suppressed stale prepared/play/Auto fallback. Collect native app-associated audio/surface/service resource snapshots early ~3–5sec and >20sec without force-stop. Failure/unknown native state cannot become cleanup PASS. If normal pending release AND cleanup are proven, perform one *distinct* healthy MP4 real-play recovery, with new true native playing/position. Healthy MP4 failure does not suppress independent HLS test if app state is safe; failed HLS release blocks only dependent recovery. No retrials to green a case.

**Case E — Capability limits as facts:** the simulator System AVPlayer's reported unsupported codec is `SIMULATOR SYSTEM UNSUPPORTED`, not proof MPV/ARM64 hardware lacks that codec. Simulator MPV boundary is stub. FFmpeg parser/probe != successful decode, and ImageKit WebP encode != FFmpeg video/audio encode. Advanced HEVC/AV1/FFV1/HDR/DV/audio-format matrix, physical MPV/native and complete x86/ARM64 performance/power are **DEFERRED/NOT RUN** unless same existing safe short fixture execution directly produces isolated evidence; do not regenerate all 59 fixtures or force test all codecs in this checkpoint.

Scope each failure: A/B/C independently runnable if installed functional entry is valid; D needs its fixture route; recovery depends on D release. Optional diagnostics failures RECORD_ONLY if unrelated. Critical media assertion FAIL is NOT silently waived; other safe independent cases continue once. If no real decoder frame/position/release evidence, mark case NOT PROVEN even when IDE Run succeeds.

## 3. Lean evidence and publication

Only one NEW authorized sanitized report:
```text
docs/PLAYBACK_PHASE8F_SIMULATOR_MEDIA_FUNCTION_REPORT.md
```

Fields: `REVIEW_RESULT / STATE / TASK_ID / SOURCE_SHA / TESTED_DISPATCH_SHA / X86_ACTUAL_TARGET / NORMAL_IDE_RUN_STATUS / BUILD_COUNT / SIGN_APP_COUNT=0 / APP_FUNCTIONAL_ENTRY_STATUS / FFMPEG_PROBE / FFMPEG_REAL_FRAME_DECODE / FFMPEG_CANCEL_RESOURCES / WEBP_IMAGE_ENCODER / VIDEO_AUDIO_ENCODER_NOT_IMPLEMENTED / SYSTEM_MP4_PLAY_SEEK_PAUSE / SYSTEM_HLS_PENDING_CANCEL_NATIVE_RELEASE / EARLY_AND_20S_CLEANUP / DISTINCT_MP4_RECOVERY / MPV_SIMULATOR_STUB / DEFERRED_CASES / ACTUAL_FIRST_BLOCKER / REQUIRED_PROVENANCE / EVIDENCE_SHA_OR_NONE / NEXT_ACTION`. Every media case must show count and `PASS/FAIL/BLOCKED/UNSUPPORTED/NOT RUN/NOT PROVEN` without extrapolation. No UI aesthetic/layout/screenshot results. Original SDK child stdout/stderr, screenshots, media, HAP, passwords, profile material, target/instance IDs, local machine paths, private URLs/PIDs must stay private.

Direct semantic candidate-wide privacy check, stage ONLY exact one report path, read actual staged name/mode/blobs, confirm remote HEAD equals this exact new dispatch before ONE ordinary commit/push, fresh-fetch and confirm evidence HEAD parent/diff/readback. If publication fails, preserve locally observed statuses; do not replay build/codec tests to repair packaging. Preserve old Rerun4 STOP evidence and private workspaces. No helper/progress/inventory/gzip scripts or repeated reports.

This task is complete even if some cases `NOT RUN`; no fake PASS, no hand-waved unsupported features, no self-dispatch of an identical task. Real ARM64/HDR/MPV and device acceptance belongs to Level2/3 milestones. Return concise final verdict and link evidence when safely published.
