# CLI target split: effective MPV dependency verified, native input blocked

STATE: COMPLETED WITH DEPENDENCY BLOCK — PINNED X86 FFMPEG INPUT UNAVAILABLE IN AUTHORIZED ISOLATED SCOPE.
TASK_ID: phase8f-level1-cli-mpv-target-split-abi-gated-media-v1
SOURCE_SHA: 3cdf0d4606c83c0fe2b9c759da84c9de5636d647
DISPATCH_SHA: c2ec84d8f3708d264bb86a11bc0faa410a19f0b7
PREVIOUS_DIAGNOSIS_REPORT: ef204701e010382a5d5822645d913cc3be9e435f
REVIEW_RESULT: EFFECTIVE LOCAL MPV STUB RESOLUTION PASS; NO BUILD/HAP/INSTALL/RUNTIME PASS.

## Source and cheap preflight

New isolated clone completed0 before subsequent fetch0. Local/remote HEAD matched dispatch, direct parent SOURCE, task-only drift. Previous diagnosis report..SOURCE changed exactly the eight declared config/checker/status/handoff paths. Initial checkout clean; no AGENTS found in tracked inventory. Full task, changed configuration and checker read; full workflow and Master Plan readings revalidated unchanged blobs; complete current status/handoff sections read. No original developer/stopped checkout, historical private log/HAP, signing facility or GUI operation.

Exactly one existing connected target: HDC list0, uname0=x86_64, API query0=26. No emulator startup/reset/settings change. Source keeps default ARM64 real MPV parameters; simulator uses the local compile-only stub parameters and separate product bundleName. These declarations do not by themselves prove a built package.

## One explicit dependency install and actual resolution proof

Official installed OHPM executed once from scratch project root: `ohpm install --pf oh-package-simulator-params.json5`.
UTC: 2026-10-12T15:45:33.4513707Z to 2026-10-12T15:45:34.5056776Z. Original native exit0, enclosing exit0; tool reports install completed. No unparameterized or second dependency install, update, sync or package repair.

Actual generated `entry/oh-package-lock.json5` has exactly one MPV record: package name `@mpv-ohos/mpv-arkts`, version1.0.0, `registryType=local`, `resolved=simulator-stubs/mpv-arkts`. Its specifier changed from the checked-in remote1.0.0 record to the local stub; remote HAR resolution/integrity was removed. No remote real MPV record remains in this actual entry lock. There is no invented target-specific lock or dependencyMap: this invocation updated the normal entry lock, which is the genuine selected-context result.

The installed entry MPV module is a junction whose fully resolved target equals THIS scratch source's `entry/simulator-stubs/mpv-arkts`. Installed manifest and Index.ets bytes match the versioned local stub. Manifest SHA256 `3D80AEE92062F97FF5748A776A8285E881D220261A8E0F8260F1AF3FD22E187C`; entry SHA256 `025D8EEAAFCFAF6B47F9D751649B933E6CEA52DB091BDF0AF3470496A9577028` (source Git blob `77554f68d2327b414046c53ee17abb75d25aa7a8`). Package manifest identifies the compile-only simulator stub and contains no native dependency declaration.

Existing `scripts/check-simulator-product.cjs --simulator-lock entry/oh-package-lock.json5` executed once using installed SDK Node, exit0: source and supplied resolved lock checks passed; HAP ABI audit still required. This is effective dependency resolution proof, not a native package or runtime result.

Locally retained private stream hashes: OHPM stdout SHA256 `64F4FA8572F922D60D076E521B9C2AC9580958A32EA0BA3F8556ED9F9E540FEF`, stderr `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`; resolved-lock-check stdout `1E71C4C0F6D7661AAB137EFA11F99BD5C14FFFBB5FB91396E909CDFC25B864D0`, stderr the same empty-stream hash. Actual generated entry lock byte SHA256 `7EC53812CBF0D994C4F81B209DF88F5E7C249D8DBAFEEF6A4CBDD9AE3A422766`. Raw files are PRIVATE; hashes do not make them remotely replayable.

## Build prerequisite unavailable; no build attempt

The scratch clone has no required `third_party/ffmpeg/prebuilt/x86_64` input. Current CMake explicitly requires its pinned manifest for FFmpeg commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`, x86_64 ABI, four headers and avformat/avcodec/avutil/swscale static archives. No host FFmpeg binaries or unbound libraries can substitute. No bootstrap/native dependency compilation was authorized or attempted.

The task explicitly prohibits opening the original developer project and prior stopped/private evidence checkouts. Earlier successful input checks do not grant current access to those protected directories. A bounded separate host FFmpeg-directory inventory found no matching manifest/static archive; it was not a dependency rebuild or proof that all local disks lack inputs (optional rg no-match exit1, RECORD_ONLY, not retried).

Asked only for an independent existing input directory. User replied that it should previously have been in the project or another branch; no independent path or explicit permission to open protected inputs was supplied. Following that steering, one remote branch fetch and read-only tree inspection checked all 20 current remote branch tips: zero tracked pinned-prefix/four FFmpeg static-archive matches. Current `.gitignore` explicitly excludes FFmpeg source/build/prebuilt outputs. This supports Git-unavailable inputs at those tips, not exhaustive all-history/all-local-path absence. No branch checkout, original workspace read, old artifact reuse or file regeneration followed.

ACTUAL_BLOCKER: DEPENDENCY_BLOCKED — REQUIRED PINNED X86 NATIVE INPUT NOT AVAILABLE IN THE AUTHORIZED SCRATCH SCOPE. Build stopped before invocation; this is NOT a compiler failure or a new HAP ABI failure. Effective stub proof remains PASS independently. Fixed FFmpeg smoke fixture manifest read; actual fixture bytes/route were not accessed or started once native build prerequisite was unavailable. No inherited fixture/runtime PASS.

## Outcomes and counts

| Field | Result |
| --- | --- |
| EFFECTIVE_MPV_STUB_RESOLVED | PASS — generated local lock, canonical installed junction and matching manifest/entry bytes; existing checker0 |
| SOURCE_ALIGNED_BUILD | NOT RUN — native input prerequisite blocked; builds0 |
| X86_HAP_ABI_AUDIT | NOT RUN — no fresh HAP; native HAP audits0 |
| SIMULATOR_BUNDLE_ID | SOURCE CONFIG ONLY: com.linkora.player.simulator; embedded fresh HAP identity NOT PROVEN |
| INSTALL | NOT RUN, installs0; no fresh install/signature error |
| FFMPEG_PROBE / REAL_DECODE | NOT RUN / NOT PROVEN |
| WEBP_ENCODE | NOT RUN; no output/redecode evidence |
| SYSTEM_MP4 | NOT RUN; prepare/play/position/pause/seek/release not proven |
| HLS_CANCEL_RELEASE_AND_20S / RECOVERY | NOT RUN / NOT PROVEN |
| GUI / MANUAL_SIGN_APP / KEYSTORE_PROBE | 0 / 0 / 0 |
| DEPENDENCY_INSTALL / SOURCE+LOCK_CHECK / BUILD / HAP_AUDIT / APP_INSTALL | 1 / 1 / 0 / 0 / 0 |

No emulator startup, default/ARM64/Release build, FFmpeg rebuild, reinstall, uninstall, force-stop, wipe/reset/clear-data, signing/profile changes, media server/rport, screenshot or new instrumentation. MPV simulator stub is unavailable; no true MPV decode or ARM64/device/advanced codec/performance claim. Historical V2 9568332/ABI failure and user default9568347 remain unchanged and were not reproduced here.

## Workspace, publication and next action

Tool-created lock changes remain only in this new scratch clone: entry has the genuine remote-to-local semantic dependency change; three other locks are marked modified with no semantic diff reported by Git. No manual lock editing/restoration or lock publication. Checkout is NOT claimed clean after dependency install. Source/config/scripts/history untouched by executor. Original-workspace operation limit honored; exhaustive original bytewise snapshot NOT RUN.

Only this new sanitized report is authorized; candidate-wide review excludes private paths, target/user IDs, raw logs/URLs, signing metadata and binary/media files. Stage exactly this regular text report; ordinary commit/push plus fresh remote parent/path/blob/readback verification required. REMOTE_EVIDENCE_SHA is supplied externally after verification.

NEXT_ACTION: owner provides an existing independently accessible pinned x86 FFmpeg input directory or explicitly authorizes a narrowly bounded read-only copy from its known protected location in a distinct follow-up task. Do not recompile FFmpeg, guess paths, rerun this completed ID or repeat dependency diagnosis. After source/input binding, next meaningful checkpoint is at most one direct parameterized Hvigor simulator build, strict new x86 HAP audit and embedded bundle ID gate before any non-destructive install/media test.
