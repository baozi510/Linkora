# Linkora Player Architecture — Implementation Status

## CURRENT EXECUTION SUMMARY — 2026-10-08 (Phase 8F helper-gate stop independently reviewed; new progress-contract task pending)

**Repo / branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Owner review:** `ACCEPTED — FAIL — REQUIRED TEST GATE` for executed and remotely published `phase8f-sim-adaptive-pending-candidate-cancel-recovery` at evidence `202fdab4f77365bd62ec60fe5af2c2fb9cc9364c`. Actual source `8174e6e4f0214958fb83fef46e92170c4c10263a`, dispatch `616e0ed6ddb838edb2b7cc50dcd88fff1193f46f`. One authorized new report and evidence commit, 85 paths; source→dispatch drift task-only; no protected source/tests/media/history drift. **This task is complete as a STOP; never repeat its task ID.**

- Fresh normal install and both 4-lock independently verified EOL-only restore operations, default → simulator → immediate default build gates PASS. Both original Hypium outputs 210/210, two exact-nine AArch64 native ABI audits per default, x86 simulator FFmpeg-only whitelist, legally signed and installed fresh HAP. No real ARM64 runtime.
- One fresh healthy MP4 official open only: real device→host reverse port19084 and AVPlayer GET/Range206; native initialized→prepared→play→playing, actual first-frame callback, native video size320×180, independently sampled XComponent test-color pixels, positions161→927ms (**positive +766ms**), and normal sampled surface/service/audio cleanup0. No playback production failure established.
- **Exact stop:** old private focus-run helper evaluated `positionAdvanced = (delta >= 800ms)`, yielding `false`, original `BOUNDED FAIL / UNRESOLVED`, and `AssertionError`/exit1. It was a **real failed helper/test gate** and remains FAILED. However this task's written healthy-progress criterion is **monotonic positive (>0ms)**, which fresh +766ms meets. Do not change old helper/raw Boolean/test expectation, infer player regression from 34ms shortfall, or claim the existing helper PASS.
- **NOT RUN:** both HLS format checks, FFV1 representative, pending HLS cancellation, and distinct post-cancel healthy recovery. Adaptive pending-candidate ownership fix from source `8174e6e4f0214958fb83fef46e92170c4c10263a` compiled, but **has not received any actual cancellation/recovery runtime validation**. This review makes **no** new production patch and no codec/device outcome judgment.
- One preliminary signed native ABI CLI `--abi=x86_64` was rejected (expects positional `x86_64`); the unchanged exact signed HAP subsequently passed the correctly invoked strict audit. Do not conceal rejected setup invocation or claim repeat build/sign/install/media attempt. Original 23 sanitized gzip integrity reports and protected 2872 old regular blobs remain evidence; logs are sanitized subsets where designated and full private screenshot/hilog/HAP unavailable for independent replay.
- **Next owner decision:** use a NEW distinct READY task with a **preauthorized independent fresh private non-invasive runtime observer/collector** for the healthy System control, while preserving the old private helper's `>=800ms` raw output/threshold semantics. The healthy task gate is: valid native prepared-before-play, playing, real first-frame callback AND independent colored pixels, matching target HTTP route, **two correctly ordered position samples with strict delta >0ms**, and zero sampled clean leave. Require a bounded declared observation window; do not change repo tests or historical helper, reinterpret an invoked failed gate as PASS, retry an official failed case, or broaden compatibility acceptance. If old helper is invoked and exits nonzero, record and STOP; do not silently ignore it.
- If new independent healthy observation gate passes, freshly run HLS H264/HEVC, one FFV1 representative, one pending-HLS cancellation **with native release and zero app-matching service/audio records without force-stop**, then and only then distinct recovery MP4. Fresh builds are required anew, no inherited earlier PASS. Existing 8B/8D/8E FAIL/NOT RUN immutable, Phase 8C native-first 39-feature static audit scoped, simulator MPV stub ≠ real MPV and simulator ≠ Mate60.

Previous Phase 8E current execution summary below is now **historical**.

---


## HISTORICAL EXECUTION SUMMARY — 2026-10-08 (Phase 8E failure reviewed; ownership correction awaiting validation)

**Repository/branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Owner ruling:** `ACCEPTED — FAIL — SYSTEM PREPARED-STATE GUARD REGRESSION`, task `phase8e-sim-system-prepared-state-gate`, tested source `68452df5486cf568da66a5c52352841cb7e64c5f`, dispatch `ff5917e912c310d52fda747b2a8089109a170954`, remotely reviewed evidence `e99ad8928811d394e65efb1ca31d77fb1c885c72`. Its 99 changed files are entirely one authorized report and new evidence directory, no production/test/historical changes. This task is closed as FAIL; never rerun under old ID.

Fresh default→simulator→default PASS: two independent Hypium 210/210; each default had two exact-nine AArch64 ABI audits; one legal signed x86 HAP/whitelist/replace-install/coldlaunch; valid 19084 reverse target route. Exactly five new opens, zero retry: healthy H.264 MP4 PASS with visible pixels; HLS H.264 native prepared→play, first-frame callback but late colored video NOT independently proven (335ms positive, raw>=800 false); HLS HEVC native 5400106 decoder-type bounded simulator error; FFV1 size0x0/black ROI/no actual frame submission (positive 768ms, raw>=800 false); separate HLS cancellation while initialized/JsPrepare.

**Cancellation failure:** after leave, sampled app-matching PlayerDistributedService entries2 persisted >20s, later audio renderer records1; normal cleanup FAIL. These are service/renderer records, not asserted unique AVPlayer instance counts or audible sound. Only forced owned-app stop plus coldlaunch (no media) cleared samples, which cannot be called release PASS. Post-cancel healthy recovery was NOT RUN. Native excerpts selected after-minus-before; complete private hilog and screenshots unavailable for independent replay. Five opens observed, no synthetic PREPARED/timer-clear direct telemetry.

**Confirmed source ownership bug:** Adaptive candidate only lived in local `prepareBackend` variable and committed before being assigned to `this.backend`; release saw null during async prepare, so new System reject-on-release could not execute. Stale commit possible after cancellation. **GPT correction in this review/implementation commit, VALIDATION NOT RUN:** `AdaptivePlaybackPort` owns pending candidate through native preparation, releases it before source lease on page leave, checks release after resolver/factory/prepare awaits and prevents fallback/late commit/synthetic PREPARED. Error path avoids duplicate release ownership. `SystemPlaybackPort` release additionally rejects pending initialization and ignores initialized notifications after release. System prepared-state confirmation and 20s timeout remain unchanged. No decoder, Auto, UI, test or fixture alterations.

**Next:** distinct Phase 8F Codex validation task from exact review source SHA: fresh build chain and simulator forced System health/HLS/cancellation+healthy recovery, candidate lifecycle proof. Any remaining native service/audio records beyond bound are FAIL; forced cleanup never passes. Preserve old Phase8B/D/E results, hardware/codec capability classifications, real MPV/ARM64/HDR/audio NOT PROVEN. Do not query quota.

The preceding Phase 8D/8E summaries below remain historical, not current instructions.

---


## HISTORICAL EXECUTION SUMMARY — 2026-10-08 (Phase 8D-SIM Rerun 1 independently reviewed; System ready gate pending validation)

**Active branch:** `feat/playback-capability-phase8`.

**Review decision:** **ACCEPTED — FOCUSED SYSTEM SIMULATOR INVESTIGATION COLLECTED** at evidence `9c4f6ded7cc86afad1052eb448ce3172b3232db6`. This is **collection-only** and is not a playback PASS for six historical formats, not a platform-wide codec diagnosis, and not ARM64/Mate60 acceptance.

- Task `phase8d-sim-rerun1-hdc-rport-six-case`; tested source `c0d37ef9aaeba31c512743fe704e8d91ba1c0c48`, dispatch `a8ad55081c54630e3602b71f9fe9415cc092e1ab`. The evidence commit is one ahead of dispatch with 87 authorized files, no protected edits. Task is already executed; **never rerun it under the old ID**.
- Fresh default → simulator → default build suite PASS. Actual two Hypium outputs 210/210; each default run two exact-nine ARM64 artifact/ABI audits, x86 simulator FFmpeg-only library whitelist, valid signed simulator HAP installed. Four Windows locks had two fresh EOL-only proofs. Submodule pins were verified; extra recursive fetch TLS problem did not alter pins/policies.
- Fresh reverse HDC 19084 mapping had actual `[Reverse]` proof and device→host requests. One healthy native System H.264/AAC MP4 official open: Range206, prepared/playing, 320×180 callback, actual first-frame callback **and separate colored pixel proof**, progress 144→977 ms; clean leave. Six targets each independently opened **once**, all six scoped **BOUNDED FAIL/UNRESOLVED**, not format PASS.
- HLS H.264/AAC and HLS HEVC/AAC: each manifest+three segments GET200; native initialized → prepare invocation → about 2s wait → play called while **still initialized**, without prior prepared notification; native invalid-state rejection and UI LNK-PLAY-006. Not a proven 404/auth/route failure; decoder unsupported or whether SDK/native prepare incorrectly resolves is **not proven**.
- Four simulator legacy video samples (FFV1/ProRes/Theora/WMV): native prepared+playing and exact `videoSizeChange(0,0)`, no actual first-frame callback; correct XComponent geometry, independently captured black ROI after overlay, no capture errors. Position increased by **701/676/750/724ms** respectively but old host helper's **>=800ms** Boolean remains `false`. Monotonic progress is not pixel proof, black in sampled windows is not permanent/all-device unsupported, and audio playback/output is not proved.
- Cleanup: original Auto restored, only owned reverse and temporary row removed, owned server stopped, seven sampled leave checks zero; protected history untouched. 25 sanitized gzip integrity reports present; selected hilog excerpts are **after-minus-before subsets/redacted**, not full native logs. Neither full private screenshots nor full raw hilog are published; publicly readable metadata supports the bounded verdicts.
- **Architecture decision and production correction (this review commit, not yet tested):** `SystemPlaybackPort.prepare()` must not resolve the app-level PREPARED contract from `AVPlayer.prepare()` Promise alone. Add a **bounded, state-confirmed readiness gate**: require both Promise fulfillment **and** native `stateChange('prepared')` and current native `player.state === 'prepared'`; otherwise fail with timeout/error/release, without calling play while initialized. This is a correctness guard, **not** an HLS codec fix or promise of eventual prepared. Existing System/MPV selection, Auto fallback, SDK config, media, UI and other contracts remain unchanged. New production change **VALIDATION NOT RUN**; Codex must perform fresh compile/simulator and regression evidence.
- Preserve Phase 8B six historical FAIL, Phase 8D first-round BLOCKED and seven NOT RUN, and this round six bounded FAIL. Phase 8C 39-feature native-first static audit accepted within scope; future feature implementation/real MPV/ARM64 runtime/display/audio/HDR still separate.
- **Next:** publish a **distinct** READY Codex validation dispatch from this source/review commit, focused on state-confirmed System readiness, HLS two cases, healthy control, timeout/cancellation and a legacy video representative as non-playback-PASS guard. Do not reuse old PASS as new PASS. No device available; do not change Auto/Direct I/O/UI/media.

The previous 2026-10-08 Phase 8D environment summary below is historical, not the current new source state.

---


## HISTORICAL EXECUTION SUMMARY — 2026-10-08 (Phase 8D-SIM stopped and independently reviewed)

**Branch:** `feat/playback-capability-phase8`. **Current owner ruling:** `BLOCKED — SIMULATOR ENVIRONMENT` for completed Phase 8D-SIM attempt `phase8d-sim-system-hls-first-frame-root-cause`; **not** a functional investigation PASS, hardware claim or identified production defect.

- Tested source: `e19123a0e110cebb479d24dbdf72d6d3c9169a5b`; tested dispatch: `0a5e1af4be94a2528dcbc968f42f1883d9c22c3b`; remotely published evidence: `391d56e4c0b36f19d4a52f8d77a4adab2db87b8b`.
- Three append-only evidence commits: `d572bcfd22fb69b165ec68dd72136feadcebe965`, `78f915471a9d152832aaffaac0b0c43b20ebcf2b`, `391d56e4c0b36f19d4a52f8d77a4adab2db87b8b`. Source-dispatch drift was task-only; dispatch-evidence change set is 56 paths, all in one authorized report/new evidence directory. No old report/evidence or production code modified.
- Fresh default → simulator → immediate default build gates PASS: both independent Hypium outputs 210/210, each default invocation two exact-nine AArch64 native artifact audits, x86 simulator contains FFmpeg only. Exact fresh signed simulator HAP built, ABI-checked, installed and launched. This gate evidence belongs **only to the stopped round** and cannot be inherited as fresh PASS in another round.
- User-owned controlled fixture input preflight: seven planned media inputs and thirteen source/manifest/segment files, host/local and authenticated TLS WebDAV/hash/Range/ffprobe evidence matched committed corpus truth. Media retained unchanged. Target loopback HTTP path **not proven** because forwarding failed.
- **Precise blocker:** owned host fixture server was already listening on TCP19084; orchestration mistakenly attempted `hdc fport tcp:19084 tcp:19084` for a device→host input route. Installed HDC3.2.0f help distinguishes `fport localnode remotenode` (host→device) from `rport remotenode localnode` (device→host). Actual error: `[Fail]TCP Port listen failed at 19084`. Direction mismatch is confirmed; exact listener/collision owner was not independently established. STOP was honored; no subsequent `rport` retry or official playback occurred. Forward mapping was empty before and after.
- **Actual playback coverage:** healthy System H.264 control NOT RUN, two HLS FAIL-cause investigations NOT RUN, four legacy format first-frame investigations NOT RUN: official attempts = 0. Historical two HLS initialization FAIL and four first-frame-evidence FAIL remain immutable/UNRESOLVED, not overwritten. Build PASS ≠ investigation PASS; no decoder or player failure inferred.
- Owned host server stopped, no new forward retained, preferences not changed; sampled surfaces/service entries/audio renderers zero. Private credentials, signing, identifiers, device media/HAP/screenshots absent from published report. The prior dirty `D:/Linkora` and 2630 old tracked blobs are reported preserved.
- **Decision:** no production source patch, no codec/profile fallback change, no UI or performance research. Issue a **distinct new task** to normalize the simulator fixture route with `hdc rport tcp:19084 tcp:19084` only after owned host listener/port preflight and then perform the same seven scoped fresh runtime checks. No task text in chat substitutes for the new separately committed `docs/CODEX_VALIDATION_TASK.md`. Fresh builds/evidence required anew.

**Existing accepted boundaries unchanged:** Phase 3 production analysis ACCEPTED; Phase 7A real ARM64 measurement baseline ACCEPTED but not global policy; Phase 8A playback foundation ACCEPTED but not full codec/output; Phase 8B-SIM functional preflight ACCEPTED; Phase 8C native-first audit ACCEPTED for audit/evidence scope only (39 static feature rows, runtime/device acceptance pending). Simulator System ≠ Mate60, MPV simulator stub ≠ real MPV, x86 FFmpeg ≠ ARM64 runtime.

The previous 2026-10-08 Phase 8C execution summary below is retained as **historical**. Its next-action instruction is superseded by the separate new task dispatch.

---


## HISTORICAL EXECUTION SUMMARY — 2026-10-08 (Phase 8C independently accepted)

**Active repository/branch:** `baozi510/Linkora` / `feat/playback-capability-phase8`.

**Review ruling:** **ACCEPTED — PHASE 8C NATIVE-FIRST PLAYBACK CAPABILITY AUDIT EVIDENCE.** This accepts the collection and bounded analysis, **not** the 39 features as runtime PASS, not a codec/container/output capability certification, and not a real-MPV/ARM64 device gate.

- Audited implementation source: `99ab47020f81391b7640d44c58ccb719491b4106`.
- Audited dispatch HEAD: `e835a3567132c9f496d0c79f3c1eab88f1916774`.
- Remotely reviewed evidence commit: `9cd0db4b4719409de942892790de71f0ae015823`.
- Task: `phase8c-sim-native-first-capability-audit`, **executed and reviewed; do not rerun it even if the historical task file still says READY**.
- Matrix: exact 39 unique seed IDs; System 14 static NATIVE_VERIFIED / 10 NATIVE_PARTIAL / 14 public-AVPlayer-API26-scoped NATIVE_ABSENT / 1 DEVICE_CONFIRMATION_REQUIRED; MPV 37 DEVICE_CONFIRMATION_REQUIRED / 1 passthrough NATIVE_PARTIAL / 1 platform media-session NOT_APPLICABLE. All normalized contracts remain `DEFER_TO_GPT`; 38 audit-specific device follow-up groups.
- Fresh evidence: default → simulator → final default completed; two real captured Hypium 210/210 outputs, production AArch64 artifact/ABI checks, simulator x86 package isolation; single-dispatch AudioMetadataSmoke emitted four fixture records plus one summary (five events). MP3/FLAC PASS; TrueHD/WavPack bounded 23002 FAIL; raw four-fixture summary remains FAIL (2 PASS, 2 FAIL). Normal forced-System H.264/AAC simulator smoke observed visible frame pixels and 1614→3701 ms with sampled clean leave.
- Pinned wrapper is `@mpv-ohos/mpv-arkts@1.0.0`; its exposed generic native property/command/observer API was checked against the distributed declarations and compiled bytecode. Embedded mpv identity `v0.41.0-dev-g6edeee00a` / FFmpeg `n8.0` does not prove a reproducible, unmodified native build.
- **Acceptance limits:** installed SDK/static semantics do not imply runtime support. Simulator System results do not transfer to Mate60. Simulator MPV is a stub. x86 FFmpeg results do not transfer to ARM64 runtime. Real-MPV rendering, HDR/HLG/DV, encoded passthrough, device-specific codec/audio routes and hardware output remain unproven/device-gated.
- **Semantic findings for GPT implementation planning:** System speed request/effective-rate mismatch; MPV `demuxer-cache-time` cache-end versus duration mismatch and numeric precision; seekDone/restart request-correlation limits; first-frame signal versus visible-frame proof; System display default/viewport ownership; System track observers absent from adapter; MPV OHOS HDR metadata is not hardware output acceptance and audio-spdif option is not encoded OHAudio passthrough. These findings do **not** change existing production source/contract/Auto policy in Phase 8C.
- **Historical outcomes preserved:** Phase 8B six simulator FAIL observations (two HLS initialize and four first-frame-evidence gaps), previous audio seven-event diagnostic and original 2/2 FAIL summary, other prior raw FAIL/NOT RUN remain unchanged.

**Next distinct validation scope:** focused Phase 8D-SIM investigation of the six historical System simulator observations using unchanged production playback, with independent new evidence and no historical reclassification. Use only a newly published, separate READY dispatch in `docs/CODEX_VALIDATION_TASK.md`. Native-first capability contract/adapter implementation and real-device batch remain separate owner decisions.

**Previously accepted boundaries:** Phase 3 production analyzer policy ACCEPTED; Phase 7A real-arm64 measurement baseline ACCEPTED only for its measured fixtures; Phase 8A playback foundation ACCEPTED (not full codec/output); Phase 8B-SIM functional preflight ACCEPTED at `dcb34487e2043ba37f763c2ee50f4e040b597fbd`.

The 2026-10-06 execution summary below is retained for provenance; its prior "current branch" and "next action" are historical.

---


## HISTORICAL EXECUTION SUMMARY — 2026-10-06

Project-wide technical baseline: `docs/MASTER_IMPLEMENTATION_PLAN.md`.

Operational GPT/Codex workflow: `docs/AI_WORKFLOW.md`.

Current branch: `feat/ffmpeg-analyzer-policy-phase3`.

Phase 3 implementation source:

`44d0f62816b73ebd3bab8069be5b74f51e2c6999`

Reviewed build/static evidence:

`e95feef35fa2541322216f9ce9336da3cad9060f`

Reviewed Mate60 runtime evidence:

`bf99989fff7cbcf17e2410e5df5258a586f12e6f`

### Acceptance status

**FFmpeg Analyzer Production Policy Phase 3: ACCEPTED.**

Build/static/pure acceptance:

- default -> simulator -> immediate-default PASS;
- ArkTS compilation PASS;
- Hypium 209/209 PASS twice;
- Debug/Release HAR/HAP and exact-nine AArch64 audits PASS;
- Loader/cache/lifecycle and policy pure suites PASS.

Production runtime acceptance on Mate60:

- exact-source signed default/debug arm64 HAP provenance established;
- app-side authenticated WebDAV preflight PASS;
- H.264/AAC MP4 cold + reopen PASS;
- HEVC/AAC MKV cold + reopen PASS;
- FFmpeg-first remote WebP thumbnail generation PASS;
- corrupt/both-thumbnail-unavailable behavior PASS;
- observed cancellation/refresh/stale-generation behavior PASS within naturally exercisable scope;
- production lifecycle 20/20 PASS;
- no observed crash/ANR or accumulating stale rows;
- direct proxy counters NOT RUN because no production diagnostic endpoint exists, as allowed by the reviewed contract;
- natural FFmpeg->System successful fallback NOT RUN because no safe natural fixture exists;
- HLS/DASH target smoke NOT RUN because no prepared streaming fixture exists; their System-only policy remains covered by fresh 3g pure evidence.

### R10 local-document ruling

The Mate60 run proved DocumentViewPicker import, 20 s / 720P metadata, 1280x720 playback and completion.

The list thumbnail remained a placeholder because `LocalMediaThumbnailLoader` only resolves `PhotoAsset` thumbnails and has no DocumentViewPicker frame-extraction fallback.

Independent review confirmed that loader is byte-identical from at least `15db3f8a3e87f75edc209c1919f944f39c0b9fcb` through the accepted Phase 3 implementation and current evidence.

Therefore the placeholder is a **pre-existing document-thumbnail limitation, not a Phase 3 regression**. R10 is accepted for Phase 3 because local import/metadata/playback remain functional, LOCAL_DOCUMENT stays System-only, and no content-URI/native-path workaround was introduced.

No production source change or rerun is required for this ruling.

### Current architecture action

**Phase 8A playback functional foundation: ACCEPTED. Phase 8B simulator functional preflight: ACCEPTED. Device-only backend/hardware acceptance is batched; while no device is available, mainline continues with native-first playback capability audit and other simulator-testable work.**

Phase 7A Analysis Benchmark baseline is ACCEPTED.

This stage adds measurement infrastructure only:

- target-side debug benchmark runner using the accepted System/FFmpeg adapters;
- real MediaProxy HTTP Range counting;
- adapter prepare/probe timing;
- NDJSON schema and summary tooling;
- stable Phase 7 benchmark manual.

`ProductionMediaAnalysisPolicy` remains unchanged until benchmark evidence is reviewed.

The first validation attempt exposed a desktop pure-harness/platform-clock boundary defect. GPT corrected it by injecting the clock into the adapters and supplying the real monotonic HarmonyOS clock from target-specific AnalysisComposition.

The corrected rerun passed the full build chain and collected 240 real-Mate60 WebDAV records. GPT independently accepted the baseline at evidence commit `92017b8fd95cb944c03a30c2eb909cd8ad70dff5`.

The baseline shows meaningful System-vs-FFmpeg differences, especially thumbnail latency/upstream bytes, but only for H.264/AAC MP4 and HEVC/AAC MKV. Production analysis routing remains unchanged because two cases are insufficient for a global policy rewrite.

Broader codec/container/audio coverage will not reopen the accepted Analysis phase. It is now part of the shared Media Capability Corpus and will be exercised during Playback/Advanced AV validation with Analyzer and Playback results recorded independently.

Phase 8A first validates that the current real-arm64 playback foundation itself is trustworthy: System/MPV forced modes, Auto selection/fallback boundary, surface lifecycle, remote MediaProxy playback, seek/EOF/release, and bounded negative behavior. The first device run exposed MPV unified-state/EOF/surface-unit defects; GPT corrected them. Rerun 1 then passed P01-P05, System/MKV observation, corrupt-MPV recovery, 20/20 MPV lifecycle and background/foreground on the real Mate60. That run also exposed a PlayerPage fullscreen overflow, which is retained as a real but non-blocking UI/layout issue. Phase 8A is accepted on playback-function evidence. The next mainline step is Phase 8B media capability coverage using the shared Tier A/B/C corpus.


This file is the current execution status for the architecture migration.

## Completed in code

### Phase 0 — Repository audit

Completed.

Artifacts:

- ARCHITECTURE_CURRENT.md
- ARCHITECTURE_TARGET.md
- ARCHITECTURE_MIGRATION.md
- MIGRATION_CALLSITES.md

### Phase 1 — Contracts and adapters

Completed in code.

Includes:

- MediaInfo / track models
- StorageProvider
- RandomAccessSource
- IMediaProbe contracts
- thumbnail contracts
- playback backend contracts
- MediaSource remote identity fields

### Phase 2 — Storage provider productionization

Completed in code.

Production directory access now resolves through provider registry.

Adapters exist for:

- WebDAV
- SMB
- SFTP
- FTP
- NFS

Existing protocol implementations are reused.

### Phase 3 — System analysis split

Completed in code.

Separated:

- SystemMediaProbe
- SystemThumbnailExtractor

NetworkMediaProbe remains a compatibility facade and preserves one-extractor behavior for BOTH mode.

### Phase 4 — WebP thumbnail pipeline

Completed in code.

Current target policy:

- short video: 20%
- normal video: min(10%, 60 seconds)
- 480 x 270 bounding box
- preserve aspect ratio
- WebP quality 80
- algorithmVersion in cache identity
- no new JPEG generation

### Phase 5 — shared MediaProxy

Completed in code.

Includes:

- RandomAccessSource-first registration
- shared production proxy
- Range transport
- diagnostics
- bytes-read and request counters

### Phase 6 — dual playback foundation

Completed in code and build-verified on the validation branch. Device runtime is still not verified.

Includes:

- @mpv-ohos/mpv-arkts 1.0.0 dependency
- MpvPlaybackPort
- SystemPlaybackPort as PlaybackBackend
- AdaptivePlaybackPort
- Auto/System/MPV preference
- remote playback through RandomAccessSource -> MediaProxy
- network browser creates REMOTE_FILE MediaSource
- progressive-download path retained only for compatibility

### Phase 7 — playback contract enrichment

Completed in code and build/unit-regression verified. Device runtime is still not verified.

Includes:

- SEEKING
- seek complete
- surface size
- tracks
- video color/HDR metadata
- backend identity
- buffered duration

## Blocked / not complete

### FFmpeg media analysis

**ACCEPTED THROUGH PHASE 3 PRODUCTION FUNCTIONAL POLICY.**

Accepted implementation includes:

- FFmpeg 8.1.3 pinned to commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`;
- native `linkora_ffmpeg` module;
- System and FFmpeg probe adapters;
- FFmpeg thumbnail extraction;
- protocol-agnostic analysis input resolver;
- shared MediaProxy remote input;
- production LIST / DETAIL / ADVANCED routing policy;
- FFmpeg-first remote thumbnail policy with System fallback;
- common WebP encoding/cache path;
- cancellation and lifecycle handling;
- SFTP trust-ownership correction;
- real Mate60 remote MP4/MKV runtime acceptance.

Latest reviewed runtime evidence:

`bf99989fff7cbcf17e2410e5df5258a586f12e6f`

Known non-blocking limitation:

- DocumentViewPicker local-document list thumbnail may remain a placeholder because the pre-existing local thumbnail loader only resolves PhotoAsset-backed URIs.

This limitation is outside the Phase 3 remote analyzer production-policy scope and must not be misreported as an FFmpeg analyzer regression.

### Analysis benchmark: System vs FFmpeg

**NEXT ANALYZER PHASE — READY TO PLAN ON REAL ARM64 HARDWARE.**

Phase 3 production functional policy is accepted. Performance-based routing remains intentionally deferred.

The benchmark format and test procedure are defined in `test-lab/benchmark` and `TEST_MANUAL.md`. Before execution, GPT must review the current benchmark assets against the accepted Phase 3 architecture and dispatch a dedicated benchmark task.

Do not derive final routing policy from x86/simulator data.

### Playback benchmark: System vs MPV

READY TO RUN, but requires:

- ohpm install
- DevEco/Hvigor arm64 build
- target HarmonyOS device
- fixed media corpus

No benchmark-derived Auto policy should be merged before this test.

### Advanced AV validation

REQUIRES TARGET DEVICE.

Pending validation:

- HDR10
- HLG
- Dolby Vision profiles
- native Dolby Vision output
- DTS
- DTS-HD MA
- TrueHD
- Atmos behavior
- DTS:X behavior
- Audio Vivid
- ASS
- PGS
- hardware decode fallback
- HDMI/audio passthrough if target hardware supports it

### Direct I/O

NOT IMPLEMENTED by design.

Do not implement OH_AVDataSource / AVIOContext / libmpv stream callbacks until benchmark data proves localhost MediaProxy is a bottleneck.

## Mandatory next steps outside this environment

1. On `test/simulator-validation`, run `ohpm install` and Project Sync.
2. Run `scripts/verify.ps1` to prove default arm64 behavior still passes.
3. Run `scripts/check-simulator-product.cjs`.
4. Run `scripts/verify-simulator.ps1`.
5. Install `com.linkora.player.simulator` on the x86_64 emulator.
6. Execute `docs/SIMULATOR_TEST_MANUAL.md` and fill `docs/SIMULATOR_VALIDATION_REPORT.md`.
7. Run `scripts/ffmpeg/fetch-source.ps1`.
8. Build FFmpeg for x86_64 and arm64-v8a using `docs/FFMPEG_BOOTSTRAP.md`.
9. If both FFmpeg builds succeed, return for architecture review before wiring `FFmpegMediaProbe`.
10. After simulator evidence is reviewed, continue the arm64 device manual for real MPV/native/HDR/audio validation.
11. Collect benchmark data before tuning `PlaybackBackendSelector`.
12. Do not implement direct I/O until MediaProxy benchmark evidence justifies it.


### Phase-2 analyzer integration goals

Current branch: `feat/ffmpeg-analyzer-integration-phase2`

Validated prerequisites:

- FFmpeg 8.1.3 dual-ABI bootstrap;
- real x86 NAPI probe/frame runtime;
- WebDAV -> MediaProxy -> FFmpeg runtime;
- timeout/cancel/concurrency/lifecycle smoke;
- arm64 Debug/Release build;
- simulator/default dependency restoration hardening.

Current work:

- formal `IMediaProbe` adapters for System and FFmpeg;
- formal FFmpeg `IThumbnailExtractor` adapter;
- protocol-agnostic analysis input resolver;
- simulator functional comparison matrix with field completeness/correctness/error/cleanup and remote access-semantics diagnostics. Performance comparison is deferred to real arm64 device testing.

Production NetworkMediaLoader behavior remains unchanged until policy review.


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


### Phase 3 — FFmpeg analyzer production functional policy

**ACCEPTED — BUILD/STATIC/PURE + MATE60 PRODUCTION RUNTIME.**

Reviewed evidence:

- build/static/pure: `e95feef35fa2541322216f9ce9336da3cad9060f`;
- Mate60 runtime: `bf99989fff7cbcf17e2410e5df5258a586f12e6f`.

No Phase 3 rerun is pending.

Current branch:

`feat/ffmpeg-analyzer-policy-phase3`

Implemented:

- `ProductionMediaAnalysisPolicy`;
- `PolicyMediaProbe` with non-merging one-step fallback;
- production `NetworkMediaAnalysisCoordinator`;
- FFmpeg-first remote thumbnail extraction with existing System fallback;
- raw RGBA -> existing WebP encoder bridge;
- `NetworkMediaLoader` production routing through the coordinator;
- cancellation generation guards;
- SFTP media-fingerprint/host-key semantic correction;
- policy unit tests.

Functional routing:

- LIST: System first, FFmpeg fallback for file-like sources;
- DETAIL/ADVANCED: FFmpeg first, System fallback only if FFmpeg is unusable;
- HLS/DASH/LOCAL_DOCUMENT: System-only policy;
- thumbnail: FFmpeg first for file-like remote sources, System fallback.

No field merger is implemented.
No performance-based policy is implemented.
Playback routing is unchanged.

Validation owner: Codex, report-only.
Source fixes remain owned by ChatGPT.
