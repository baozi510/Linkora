# Native simulator media results and isolated diagnostic candidate

TASK_ID: phase8f-level1-cli-media-all-error-autonomous-repair-v2
SOURCE_SHA: 7f94e2deabe6372c05d46e10883b82e0d3f386b8
DISPATCH_SHA: 03a71c692952ab9e478150072c7099b03eea61ef
RESULT: PARTIAL — real FFmpeg decode, WebP roundtrip, System MP4 controls and FFmpeg cancellation PASS; HLS native cancellation PASS, complete associated-resource cleanup/recovery NOT PROVEN.
CODE_CANDIDATE_SHA: fd8bae5ab1e52c45c8a2e0848156879c66278b40
FIRST_CORE_TESTED_SHA: 928fe777869a8fefbdacad26c52d1d2f91835452

## Source and actual work boundaries

Fresh fetch/clone bound dispatch directly to SOURCE, task-only drift. Prior superseded media-v1 dispatch8ceb7d6505f23f84605379188d88fb3db950ec4c..SOURCE changed only the five workflow/plan/status/handoff/task documents. No product source changed since accepted app-open evidence4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88. Current full task/workflow, changed plan/current status/handoff, architecture boundary and relevant native/encoder/player/diagnostic source were inspected. The v1 task was superseded during initial cloning; only read-only preflight occurred, no functional case/build/install under its ID.

Task paused on account availability before runtime, then resumed at the user's request. Dormant wall time was excluded from the 40-minute ACTIVE budget; known pre-interruption work was about11 minutes and resumed work about21 minutes before handoff. No quota queries. The resumed simulator was offline: one normal start of the already approved x86_64/API26 instance exited0, then one target/architecture/API verification; no instance creation/reset/GUI.

Retained previously installed-source HAP bytes still matched the prior reported digest, and named installed bundle metadata was available. A read-only installed-HAP checksum was denied by the device (transport0, semantic Permission denied); no privilege/signature/sandbox bypass or identical retry. Installed binary fingerprint was not independently obtained. New runtime instrumentation required newly built audited candidates anyway; no old artifact was promoted to changed-code PASS.

## Two bounded instrumentation changes, not product-codec fixes

ALL_ERROR_REPAIR_COUNT: 2, both supported by missing acceptance paths, with no repeated media failure and no exhausted retry loops.

1. **Missing warm diagnostic entry and usable controlled sample → bounded task-only acceptance path.** Existing EntryAbility configured diagnostics only in onCreate, and the host's candidate sample directory was empty; existing FFmpeg smoke also assumes different fixed MP4/MKV/WebDAV fixtures. Added onNewWant dispatch through the existing target diagnostics boundary (default remains no-op), a simulator-only MediaFunctionSmoke, and a task-owned loopback fixture/result service. Host behavior test executed actual transpiled EntryAbility with unavoidable platform-boundary doubles: RED1 for missing warm method, GREEN0 after change. This is host dispatch characterization, not native media proof; platform warm lifecycle was not separately certified. No main/native FFmpeg implementation, SystemWebPEncoder, SystemPlaybackPort or PlaybackEngine logic was changed.
2. **Missing bounded cancellation route → additional independent cases.** Reused/exported the existing simulator stalling source for real FFmpeg I/O cancellation; added controlled HLS segment delay and native pending-release observations. An extra-only mode prevented repeating the already passed decode/WebP/MP4 cases. Second build/install tested these NEW cases, not a identical retry. No HAP editing, waived assertions or manufactured resource counters.

Candidate branch: `codex/phase8f-media-all-error-repair-v2`. Two local code commits, ONE ordinary candidate push, remote fetch verified final SHA and ancestry: finalfd8bae5ab1e52c45c8a2e0848156879c66278b40 → first928fe777869a8fefbdacad26c52d1d2f91835452 → dispatch03a71c692952ab9e478150072c7099b03eea61ef. Exactly six reviewed code/test files, no lock/prebuilt/media/raw log/secret commit. No merge or code push onto feature branch. Core runtime observations belong to the FIRST candidate; only cancellation cases ran on the FINAL candidate. A full core regression on final candidate was NOT RUN.

## Real fixture, compile and install gates

Task-owned synthetic fixture used the approved lavfi testsrc2+sine recipe, no downloaded/private material. Actual host ffprobe: H264 video320×180, AAC audio, duration8000ms; 689981 bytes, SHA256 `BB134EE150847FAF2242176779A1EB8B855956F28F38AA30F3629CE75D5B99F8`. It is a NEW generated controlled fixture, not the old canonical Phase1B fixture hash. HLS segment was remuxed from that same approved source; SHA256 `2F37D35954C486FE184B1C0210F9561BE9A1E9D026BEE41CE175A1E599EBF23D`. No full59-case regeneration. Host generated/decoded fixture facts are not product decoder results.

Only original approved pinned x86 FFmpeg headers/manifest/four archives were read/copied outward, and original/copy digest verification passed. No original workspace writes/build/reset/clean/stash, ARM64 input copying, FFmpeg bootstrap rebuild, credential/old stopped-log access. One explicit parameterized OHPM install exited0; generated local MPV stub check0. Two source-bound simulator Debug builds exited0:

| Build | Tested candidate | UTC start → finish | HAP SHA256 |
| --- | --- | --- | --- |
| 1 | 928fe777869a8fefbdacad26c52d1d2f91835452 | 2026-10-13T04:26:31.2201190Z → 04:27:34.6722564Z | 22D90AB062C49D94FC96907AE85BD2C48C2AC9815FE0349EDFAEE89900FEBF41 |
| 2 | fd8bae5ab1e52c45c8a2e0848156879c66278b40 | 2026-10-13T04:34:16.7090032Z → 04:34:29.5391530Z | D9DAB0B62CA988803D0B9FADAA53BB399F4FBE5DD2237B13B220C2F8252DA69A |

Both fresh HAPs embedded com.linkora.player.simulator, both strict existing x86 ABI audits exited0 (only machine62 liblinkora_ffmpeg.so, no ARM64/MPV/AKI/CXX). Two nondestructive HDC upgrades of this owned simulator identity each exited0 and explicitly reported install success. No production app uninstall/reset/clear-data, old signer/password/keystore or global SDK/IDE change. Each runtime invocation was CLI-only with a private validated controlled endpoint.

## Independent native observations

| Case | Actual attempts | Result / original evidence |
| --- | ---: | --- |
| FFmpeg metadata probe | 1 | PASS: native H264/AAC, 8000ms, 320×180; full container/channel/profile matrix not recorded |
| ACTUAL_FFMPEG_DECODE | 1 | PASS: native extracted RGBA320×180,230400 bytes=width×height×4,time1000ms,pixel hash db2a8c64; probe was not substituted for frame |
| WEBP_ENCODER | 1 | PASS: actual ImagePacker output5008 bytes, RIFF/WEBP signature, real ImageSource/PixelMap decode320×180; no lossless pixel-equality or picture-quality claim |
| MP4_PLAY_PAUSE_SEEK | 1 | PASS: actual SystemPlaybackPort/AVPlayer prepared→playing→paused→playing→released; position1096ms before pause, seekDone2500ms, resumed position assertion beyond seek;46 native receiver images, first-frame event true |
| FFmpeg active cancel | 1 | PASS: genuine proxy read began, native FF_CANCELLED, reads1/closes1, actual proxy activeSources0/activeClients0 after normal release |
| HLS pending native release | 1 | PASS within this scope: initialized, native preparation still pending and not prepared; normal release observed; early3.5s/later>20s states remain initialized/released with no prepared callback |
| HLS audio/surface/service resource zeros | 0 complete scoped measurement | NOT PROVEN: native released state alone cannot establish all associated-resource zeros; late service helper output insufficient for complete early/later ownership attribution |
| Distinct MP4 recovery | 0 | NOT RUN — complete native cleanup prerequisite unproven; no forced-stop cleanup or automatic fallback |

HLS host ledger also records a real segment request followed by socket closure about1410ms later during cancellation. This supports native transport cancellation, not a global audio/surface/resource guarantee. System video output used a real ImageReceiver surface and drained/released images; no screenshots, layout/beauty or desktop GUI actions. MPV native playback remains unavailable on x86 stub; ARM64/device/hardware/HDR/advanced formats/power/stability remain untested.

## Stop, cleanup and publication

FIRST_REAL_BLOCKER: the original onCreate-only diagnostic entry and unavailable owned fixture were addressed. FIRST_UNRESOLVED_BLOCKER / STOP_REASON: complete app-associated HLS audio/surface/service zero-resource attribution was unavailable in this bounded path; recovery remains unsafe to certify. HLS resource/recovery branch STOPPED for GPT decision. Do not reinterpret native release PASS as complete cleanup PASS. No further identical case/build/install; two-install ceiling already used.

COUNTS: repair/instrumentation cycles2; builds2/5; OHPM1/3; owned installs2/2; each attempted independent native case1/2; GUI0; manual signer/keystore0; default ARM64/Release/device builds0. Existing target normal start1. Task-owned loopback service generations2 were each normally shut down; final owned listener count0. No other listener/process/app stopped. App/emulator left for user use. Four tool-generated scratch locks remain unstaged, no source/locks copied back; no claim of final scratch bytewise cleanliness or exhaustive original bytewise snapshot.

Private original evidence SHA256 `9B02A6552D6E965E24D95DA23D1469C02A628641072A7D0B91110B590BF2A53E`, HLS ledger `E44F121A5935B11987D46DAA5EAA9A9289510CDB0AD6846F3D26FABABF4ED2C2`; build stdout hashes `3D9D310BEB468C37E82FDF9BBCE33B28C1D4569293CA48F0117080AE9AA64521` / `229F5D736824E11F4EA35FC644405E171E7EAF89312AA1EF79A832DFA7347A58`. Raw binary/log/endpoint/target/user/process/resource identity data remains private; hashes describe local originals, not remote raw replay. Candidate source and report are publicly reviewable.

One separate clean report checkout at exact dispatch; only this new report authorized. Whole candidate manually inspected for private field/path/URL/token/signing/raw inventory disclosures before report-only ordinary commit/push and fresh remote parent/path/mode/blob/full-text verification. REMOTE_EVIDENCE_SHA supplied externally after verification; no code merged into feature branch.
NEXT_OWNER_DECISION: independently review the two candidate commits and source-specific native observations. If complete HLS lifecycle is required, supply/approve a supported per-app native audio/surface/service measurement contract and distinct recovery route in a new task; do not replay this completed ID or treat mock/static/host generation as additional runtime PASS.
