# Playback Phase 8B Capability Report

> Status: ACCEPTED — PHASE 8B SIMULATOR FUNCTIONAL PREFLIGHT. Device-only capability remains batched.
> Branch: `feat/playback-capability-phase8`
> Date: 2026-10-08

## GPT acceptance of focused simulator closure — 2026-10-08

Reviewed evidence commit:

`dcb34487e2043ba37f763c2ee50f4e040b597fbd`

Ruling:

**ACCEPTED — PHASE 8B SIMULATOR FUNCTIONAL PREFLIGHT.**

- mandatory MP3 and FLAC audio-only FFmpeg DETAIL metadata passed through the real REMOTE_FILE/resolver/MediaProxy/FfmpegMediaProbeAdapter path;
- TrueHD and WavPack returned bounded x86 `FF_OPEN_FAILED / 23002` and remain optional x86 capability observations;
- zero emitted active sources and normal post-diagnostic System playback were demonstrated;
- prior 59-case System matrix, MPV-stub control flow, x86-video representatives and stress evidence remain correctly attributed to `4e3ff969...`;
- the 15-item device backlog is genuinely target/backend/hardware dependent;
- the six simulator-continuable items are correctly retained for software-side work.

The seven raw audio events are not seven executions. They are four detailed fixture records, two redundant post-assertion failure notes and one summary. The redundant failure-note behavior is a diagnostic schema issue only and is corrected in the next source so future runs emit one case verdict per fixture.

No simulator observation is promoted to Mate60/real-MPV product capability.

**Phase 8B-SIM is complete.**


## Current focused closure — 2026-10-08

**PASS — PHASE 8B SIMULATOR FUNCTIONAL PREFLIGHT COLLECTED.**

Task: `phase8b-sim-rerun-2-audio-metadata-and-device-backlog`.

Validation source: `1c02e84f7afdc938de2b2723bae07c5869e560f1`; actual tested dispatch HEAD: `5b528e5e7a6ec3338435ec765b380e50182800a7`.

Evidence: `test-lab/playback/phase8b-simulator-audio-closure-20261008/`.

This focused run closes the audio-only instrumentation gap. The 59-case System matrix, nine x86 FFmpeg video representatives and stress/recovery results remain attributable to prior evidence `4e3ff969b3d1bc785d8c3e20c245ba2408e5b6e6`; they were not repeated or relabeled as new execution. The six historical System FAIL observations retain their simulator-only scope.

### Fresh source and build proof

The fresh isolated checkout matched repository/branch/READY task/dispatch HEAD. Prior evidence is an ancestor of source, source is an ancestor of HEAD, and source-to-HEAD drift is exactly `docs/CODEX_VALIDATION_TASK.md`. Three pinned submodules were initialized at their committed revisions. Required reading and read-only correction review are recorded with exact file hashes; unchanged previously read sections were checked against Git history. Production analysis policy and Phase 7 benchmark semantics are unchanged.

Exactly one initial normal `ohpm install` succeeded. Its four allowlisted lockfiles received fresh Git-normalized blob, exact CRLF-to-LF byte, line-content and full tracked-byte proofs before isolated restore. The simulator verifier's normal internal finally install received its own fresh proof/restore. No reinstall repaired a failure; no semantic dependency change occurred.

Fresh default → simulator → immediate default all passed. Each default invocation passed architecture fixtures 5, FFmpeg pure 15/15, analysis pure 46/46, artifact fixtures 17, MPV mapping 7 and Hypium **210 PASS / 0 Failure / 0 Error / 0 Ignore**. Debug/Release HARs for four modules and HAPs passed; each default invocation produced two exact-nine AArch64 audits. Both Hypium original files were preserved separately before overwrite. Simulator parity/isolation and the new audio metadata guard passed; its artifact contains only real x86_64 `liblinkora_ffmpeg.so`, with no real MPV or production native-storage library. Eight reused FFmpeg dependency archives were freshly hashed and all ELF members audited; no old app artifact or test result was reused.

Target: x86_64, API 26, OpenHarmony 7.0.0.105, HDC 3.2.0f; bundle `com.linkora.player`, debug 0.1.0.

Fresh unsigned HAP SHA-256: `E35BA74D53335CE851C9AD726EAEFD6FF16DCADAB72A311A5FABAA4D7E353244` (25,087,171 bytes). Its normal replace-install was rejected solely by signature enforcement, code 9568332; HDC transport exit 0 was not mistaken for installation success. The existing authorized profile was freshly checked to include this simulator. The accepted unchanged SDK signing procedure signed that exact input without changing source, profiles, dependency/ABI resolution or signature/permission checks. Signed native audit, explicit replace-install and cold launch passed; app data was retained.

Installed signed HAP SHA-256: `C9A27B313E6B3466DEFEB99900B4745EE2D8BECE5666A186705E4F6BBAFA6A2E` (25,281,141 bytes).

### Audio-only real x86 FFmpeg metadata

All four retained owned fixture files were independently fresh-hashed against committed prior truth, re-probed with host ffprobe, and whole-GET/Range 206/PROPFIND 207 checked through authenticated WebDAV with TLS verification enabled. The persisted owned WebDAV profile was present uniquely. The private loopback config endpoint contains no credential values; the actual diagnostic made one config GET and seven evidence POSTs after its single cold dispatch. Independent app hilog records exactly match the POST records. No audio case was retried.

The unchanged diagnostic exercises REMOTE_FILE → NetworkDirectoryService/resolver → shared NetworkFileProxy → real FfmpegMediaProbeAdapter, requesting DETAIL metadata only.

| Case | Actual metadata verdict | Code | Container / duration | Tracks / codec / channels / sample rate | Proxy bytes / reads / Range | Final activeSources |
| --- | --- | ---: | --- | --- | --- | ---: |
| audio-mp3 | PASS, complete | 0 | mp3 / 3000 ms | 0 video, 1 audio / mp3 / 1 / 48000 Hz | 48813 / 1 / 1 | 0 |
| audio-flac | PASS, complete | 0 | flac / 3000 ms | 0 video, 1 audio / flac / 1 / 48000 Hz | 47895 / 1 / 1 | 0 |
| audio-truehd | bounded FAIL, unavailable | 23002 | empty / 0 ms | 0 video, 0 audio; unavailable values remain empty/zero | 103200 / 1 / 1 | 0 |
| audio-wavpack | bounded FAIL, unavailable | 23002 | empty / 0 ms | 0 video, 0 audio; unavailable values remain empty/zero | 76831 / 1 / 1 | 0 |

TrueHD/WavPack `OPEN_FAILED / FF_OPEN_FAILED` are x86 capability observations permitted by this task, not MP3/FLAC failure or infrastructure failure. No ARM64 or playback/output compatibility conclusion follows from these metadata results.

**Raw summary remains FAIL: total 4, passed 2, failed 2.** The preserved NDJSON has four detailed case records, two additional post-assertion notes (`FAILED / 21007`, one for each optional failed case) and one summary: seven events in total, not seven independent samples. The additional notes follow the diagnostic's post-emit assertion/outer catch. They do not replace the detailed native 23002 errors or represent extra runs. The required MP3/FLAC gate passed; the task's final classification follows its explicit mandatory/optional rule. Failure-note schema clarity is retained in the simulator backlog for owner review.

The diagnostic asserts zero activeSources after probe.close and before final proxy.close; every detailed row is emitted only after that assertion. It separately emits final activeSources=0 for all four cases. The intermediate numeric snapshot is not separately exposed, so no independent pre-close telemetry file is invented. The proxy is closed unconditionally in finally. No thumbnail/frame request, output or fabricated video dimensions occurred in the audio diagnostic. Proxy counters are functional observations, not speed or efficiency comparisons; these short controlled files may be read in full.

### Ordinary runtime regression and cleanup

After the audio diagnostic, the app was cold-launched normally without any diagnostic parameter. The original Auto preference was recorded, then forced System was verified before one owned 20-second H.264/AAC MP4 open. Its WebDAV bytes were freshly hashed against retained controlled truth.

The normal player reached PLAYING; native XComponent screenshots show the real controlled multicolor frame (six RGB samples and image digests are published, private screenshots are retained locally). Two playing snapshots and the exact progress-slider observations demonstrate **168 ms → 17,848 ms**. App audio renderer state was RUNNING. One leave produced zero sampled XComponent, app player service entries and app audio renderer. Service entry matches are not advertised as independent instance counts. No crash/ANR was observed within this focused run; comprehensive leak freedom is not claimed.

Ignored host orchestration encountered output-encoding/localized-label/navigation checks. They were corrected before dependent operations or resumed the same already-open player; no source, expected verdict or completed case was patched/retried. The first playing observation survived its output-encoding exception and remains in the evidence. An optional shell curl preflight found the utility absent; this was not mislabeled a network-route failure. Actual diagnostic GET/POST delivery supplies route proof.

Original Auto was restored. The owned config server was stopped; no HDC forward was created. The valid owned WebDAV profile and all owned remote media remain for future tests as instructed. No unrelated data or the user's existing workspace was changed.

### Work that can continue and device boundary

`device-required-backlog.json` classifies 15 actual backend/hardware acceptance groups with reasons, existing proof limits and a next-device gate: real ARM64 MPV load/matrix, ARM64 FFmpeg runtime, target System codecs, hardware decode, HDR10, HLG, DV, advanced audio/output/passthrough/routes, performance/power/thermal, real native storage, GPU/surface and exact real-backend/device display behavior.

`simulator-continuable-backlog.json` distinguishes six remaining simulator/software gaps: the six System observations, audio diagnostic failure-note contract, exact runtime fallback/stale-callback telemetry, broader persistence/catalog validation, additional controlled network negative integration, and native-first unified capability research/design. Already-collected baseline playback/recovery/matrix/stress is explicitly excluded from invented pending work. Actual real-MPV rendering/output belongs to the device backlog; source/SDK research and shared contracts can proceed without a device.

**No real-device test was started.** No policy tuning, Direct I/O, display-mode UI, thumbnail research or Phase 7 reopening occurred. Only this report and the new dispatched evidence directory are authorized for publication; source/test/task/profile/manifest/lockfile/policy bytes and old evidence are protected. Build originals are compressed with exact decompression/hash proof; private endpoints/paths/aliases, credentials, identifiers, signing material, media/HAP and screenshots are excluded. Completion additionally requires normal push and fresh remote containment proof.


## GPT independent review of simulator rerun 1 — 2026-10-08

Reviewed remote evidence commit:

`4e3ff969b3d1bc785d8c3e20c245ba2408e5b6e6`

Ruling:

**VALID SIMULATOR PREFLIGHT EVIDENCE WITH ONE TEST-INSTRUMENTATION GAP.**

### System simulator matrix

The 59 System rows are internally consistent:

- 39 PASS;
- 14 SYSTEM_SIMULATOR_UNSUPPORTED;
- 6 bounded FAIL observations;
- no TIMEOUT / NOT_RUN.

The six FAIL rows are not one category:

1. `hls-h264-aac` and `hls-hevc-aac` failed before prepare/play with `LNK-PLAY-006`. These remain simulator-System HLS failure observations. They do not establish Mate60 behavior.
2. `mkv-ffv1-flac`, `mov-prores-pcm`, `ogv-theora-vorbis`, and `wmv-wmv2-wma` reached PLAYING and advanced position, but the required real-frame observation was not established. Their FAIL verdict is valid under the dispatched evidence rule, but it must not be interpreted as proven permanent black video, decoder failure, or layout failure.

None of these bounded simulator capability observations is by itself a production-infrastructure blocker.

### x86 FFmpeg video

The explicit-engine production adapter/input path produced complete records for the nine requested video representatives. Eight common cases succeeded; RV20 produced bounded `FF_OPEN_FAILED / 23002`.

This is useful x86 functional evidence only and does not reopen Phase 7 performance policy.

### Audio-only gap

The prior runner choice genuinely cannot satisfy the dispatched audio-only requirement without falsifying video assumptions:

- `AnalysisBenchmarkRunner` requires positive expected video dimensions;
- its execution loop unconditionally invokes thumbnail extraction;
- `AnalyzerIntegrationSmoke` is video/thumbnail oriented;
- `FfmpegRuntimeSmoke` has fixed video assertions.

The correct repair is **not** to give audio fake dimensions and **not** to ask an audio file for a thumbnail.

A new simulator-only `AudioMetadataSmoke` now exercises:

```text
controlled WebDAV fixture
-> NetworkDirectoryService / REMOTE_FILE
-> MediaAnalysisInputResolver
-> NetworkFileProxy
-> FfmpegMediaProbeAdapter
-> ProbeRequirement.DETAIL
```

It asserts:

- usable metadata;
- duration > 0;
- zero video tracks;
- at least one audio track;
- expected codec;
- positive channels/sample rate;
- bounded cleanup / zero active proxy sources.

The diagnostic contains no thumbnail/frame extraction path.

A simulator static guard enforces that boundary and is executed by `verify-simulator.ps1`.

No production analysis policy, benchmark semantics, thumbnail policy or playback code changed.

### Next step

Run one focused fresh simulator closure on this exact source:

- normal EOL-safe dependency setup;
- fresh default ARM64 build gate;
- fresh simulator build/isolation gate;
- install/launch exact simulator artifact;
- run audio-only FFmpeg metadata on controlled MP3, FLAC, TrueHD and WavPack fixtures;
- one known-good normal System H.264 smoke after diagnostic startup;
- clean release/security/protected audit.

The historical 59-case System matrix and stress evidence remain attributable to the prior source; they do not need repetition because this correction changes only simulator diagnostic/test infrastructure.


## Current rerun result — Phase 8B simulator functional preflight

Task: `phase8b-sim-rerun-1-eol-recovery`, READY dispatch tested at `d360055bd30bb670fc7f1e44f7f4f37e2bf564bf`.

Validation source: `cd5b1d98baba8b80f6910d040cf43c36f1a9ab71`; prior blocked evidence: `a6058b0a79516e334a342680b557552f7a7ceae1`.

New evidence: `test-lab/playback/phase8b-simulator-functional-preflight-rerun1-20261007/`.

Execution began 2026-10-07 and finished on 2026-10-08 Asia/Shanghai. The dispatched evidence directory retains its specified date.

**The EOL blocker is resolved under the new dispatch. Fresh build gates and all available simulator functional checks were executed. Overall acceptance remains BLOCKED because the mandatory audio-only FFmpeg metadata probe cannot be invoked through the unchanged existing runner without violating this task's audio-thumbnail boundary.**

### Source and build provenance

- Fresh isolated checkout; exact dispatch HEAD, repository/branch, pinned submodules and clean initial state verified. Prior evidence and accepted Phase 8A are ancestors of validation source. Source-to-HEAD drift is only `docs/CODEX_VALIDATION_TASK.md`.
- Fourteen required-reading entries were fully read in this session. Twelve unchanged files were byte-checked against that reading; updated task/report were read completely. No historical test PASS was inherited.
- One normal initial `ohpm install`. The four allowlisted lockfiles were freshly proven Git-blob/normalized-byte/line-content equivalent, with no other tracked-byte change, then restored only in this checkout. The simulator verifier's normal finally install received a separate fresh proof/restore. Both returned completely clean.
- Fresh default → simulator → immediate default completed successfully. Each default invocation passed architecture fixtures 5/5, FFmpeg pure 15/15, analysis pure 46/46, artifact fixtures 17/17, MPV mapping 7/7 and Hypium 210/210 (zero failure/error/ignore). Debug/Release HARs for four modules and both HAPs passed; each default invocation produced two exact-nine AArch64 audits.
- Simulator HAP passed parity/isolation and its exact native audit: only real x86_64 `liblinkora_ffmpeg.so`; no real MPV/wrapper or production native storage libraries. The final default gates confirm dependency restoration.
- First Hypium counts were read fresh before the simulator. Its original test-result location was later overwritten by the second invocation; evidence explicitly distinguishes the observed first counts from the preserved second raw file.

Target: x86_64, OpenHarmony 7.0.0.105, API 26, HDC 3.2.0f, bundle `com.linkora.player`, version 0.1.0/debug. No physical-device runtime is claimed.

The unsigned fresh HAP was rejected with install code 9568332 despite HDC exit 0. Existing signed profile/material included this simulator. The unchanged SDK signing utility signed that exact artifact without modifying build profiles or disabling signature/permission checks. Signed native audit and normal replace-install/cold launch passed; no uninstall/data clear occurred.

- Unsigned input SHA-256: `2312D22C30B06C66170AD51FAF2819A2263911F2B4F4C40095592763931707D0`.
- Installed signed SHA-256: `F1DA592C90C29CABBE5710DB69A8E1D7721842EA4114B24E244F854B4C18D644`.

### Controlled corpus and System matrix

Both repository corpus scripts ran fresh. Independent truth covers exactly 59 unique cases: 56 files and three streams. All 74 files including manifests/segments/init were freshly hashed and checked through controlled HTTP; the user-authorized WebDAV copy was independently TLS/whole-GET hash/Range 206/PROPFIND 207 checked. Generated media is not committed. The remote owned directory and auxiliary fixture remain for future testing as the user requested; existing media was not overwritten.

System simulator result:

| Verdict | Cases |
| --- | ---: |
| PASS | 39 |
| SYSTEM_SIMULATOR_UNSUPPORTED | 14 |
| FAIL (bounded observation; cause/platform independence not established) | 6 |
| TIMEOUT / NOT_RUN | 0 |

All 59 rows are unique and separately retained. Audio rows have null first-frame claims. Every case's sampled leave checks showed no surface, app audio renderer or app player entries remaining. This does not prove unexposed proxy counters or comprehensive memory leak freedom.

The six FAIL observations remain FAIL: H.264 HLS and HEVC HLS returned LNK-PLAY-006 before playback; MKV/FFV1, MOV/ProRes, OGV/Theora and WMV/WMV2 advanced playback position but the required real video frame was not captured/established. The latter four are **first-frame evidence failures, not proof of permanent black video or a production layout defect**. No completed failed corpus case was retried to replace its verdict. These observations do not establish Mate60 capability or a platform-independent production defect.

Three initial cases used authenticated WebDAV/MediaProxy. Remaining cases used the ordinary StreamPage with literal paths to the byte-identical controlled HTTP corpus. The unchanged browser suffix filter prevented AC-3 from reaching AVPlayer; that ingestion attempt was not mislabeled codec UNSUPPORTED. No suffix rules were changed.

One orchestration mistake appended a new URL to the prior URL, causing native HTTP 404/5411007 during the first attempted AIFF operation. That **invalid input observation remains retained separately** and is not a codec verdict. Native select-all replacement and exact widget-value validation were added before further openings; the first correct AIFF fixture operation passed. Additional UI selection/keyboard pauses occurred before opening fixtures and did not repeat completed codec cases.

### MPV unavailable boundary and ordinary function

| Check | Actual fresh result |
| --- | --- |
| Forced MPV: MP4/H.264 and MKV/H.264 | Bounded failure; no System player/audio committed; clean leave |
| Next forced System case after stub failures | Actual playback recovered |
| Auto MKV MPV-first representative | Final System playback/real frame; committed playing snapshot had no candidate error; clean leave |
| Player open/leave | 20/20, real frames, clean release |
| Background/foreground | 10/10, paused session and same process preserved |
| Auto MPV-first stub fallback cycles | 10/10, final System/real frame, clean leave |
| Authenticated WebDAV → shared MediaProxy → System | Real 20 s H.264 playback; paused 50%/90% seeks observed at 10.033 s/18.033 s; resumed progress; clean leave |
| Controlled pending-prepare cancellation | Leave bounded and clean |
| Controlled missing-file failure / explicit one retry | Bounded errors; next valid System playback/real frame recovered |
| Stale/error protection | No stale error in next valid playing snapshots; deterministic fresh gates cover event ordering; exhaustive runtime callback injection NOT RUN |

At-most-one Auto fallback follows the unchanged audited Adaptive code and fresh Hypium, corroborated by the final runtime System session. **No standalone runtime MPV-constructor/fallback counter exists; exact callback-count telemetry is NOT PROVEN.** Stub tests are not real MPV codec/runtime evidence.

### Real x86_64 FFmpeg function and required gap

The existing explicit-engine runner exercised nine video representatives through the authenticated shared production WebDAV/MediaProxy input: MP4/H.264, MP4/HEVC, MKV/H.264, MKV/HEVC, WebM/VP9, TS/H.264, AVI/MPEG-4 Part 2, VOB/MPEG-2 and RM/RV20.

Its valid video configuration used zero warmups and the unchanged runner's minimum five repetitions. The 270 complete, unique records contain 135 System and 135 FFmpeg observations. This is functional collection only; it does not reopen Phase 7, rank speed, tune policy or imply ARM64 runtime PASS. The eight common FFmpeg cases succeeded; RV20 returned numeric 23002 (`FF_OPEN_FAILED`) with unavailable metadata/frame results, bounded and without crash. The raw unavailable samples and the System-side failed/partial results are retained.

**Mandatory audio-only FFmpeg metadata: NOT RUN.** `AnalysisBenchmarkRunner.parseConfig` requires positive video width/height and its loop unconditionally calls thumbnail. `AnalyzerIntegrationSmoke` also unconditionally attempts fixture thumbnails; `FfmpegRuntimeSmoke` asserts fixed video characteristics. Supplying fake video dimensions, changing runner expectations or intentionally thumbnailing audio would violate the task. No source/test/runner change or Kit shim was made to conceal this gap.

The five controlled schema/summarizer checks passed: 59 unique IDs; duplicate backend/case rejected; invalid verdict rejected; unexpected case rejected; missing row detected; complete **synthetic schema-only** official shape requires 118 records. Synthetic controls are explicitly labeled and make no MPV capability claim. Simulator rows remain separate from that official real-device schema.

### Integrity, cleanup and handoff

The original user workspace and historical blocked evidence are preserved. Production source, scripts/expectations, task, policies, profiles, manifests and semantic lockfiles remain unchanged. Only this report and the dispatched new evidence directory are committed. Original build/corpus logs are compressed with decompression/hash proof; readable copies normalize whitespace/encoding only. Signing secrets, target identifiers, private endpoints/paths, credentials, proxy tokens, HAP/media and native screenshots are excluded from publication.

Initial Auto and list-view preferences were restored; the temporary local stream link was removed. The valid owned WebDAV profile and remote test fixtures are retained for later use. Final sampled surface/player/audio release checks are zero. Owned local fixture/config services and forwards are cleaned up; unrelated services/data are preserved.

**Primary classification: BLOCKED — RUNNER INSTRUMENTATION GAP (AUDIO-ONLY METADATA).** Available simulator function/data collection is complete, but full task PASS is not claimed. GPT should independently review the six System observations, RV20 result and the mandatory audio entry-point gap, then decide whether to supply an exact-source audio-safe diagnostic rerun or dispatch the later real-device gate. Real MPV, ARM64 FFmpeg runtime, device-specific System/hardware codecs, HDR/DV, advanced audio output, native storage and performance remain DEVICE REQUIRED / NOT RUN.

## Historical blocked attempt and owner review

## Accepted prerequisite

Phase 8A playback functional foundation is accepted from Mate60 evidence:

`e894775c0bc81b39a6217a0a0516cec46158b82b`

Fullscreen/player-layout refinement is non-blocking UI work and is not part of this phase.

## Phase 8B purpose

Execute the 59-case permanent compatibility corpus against forced System and forced MPV and produce a structured 118-record capability matrix.

This phase measures compatibility/function only.

No performance, Auto policy, UI scaling-mode or advanced-AV conclusion is authorized.


## Execution strategy update — 2026-10-07

The previously dispatched immediate Mate60 118-record matrix is superseded before execution.

New order:

1. simulator functional/corpus preflight;
2. continue mainline functional work using simulator-first validation;
3. keep default ARM64 build/link/artifact gates green continuously;
4. batch real MPV, ARM64 FFmpeg runtime, device-specific System codec and advanced native/hardware capability into later real-device acceptance gates.

Simulator results are platform observations, not final product codec capability.

Real MPV remains unavailable in simulator because the simulator target intentionally uses the MPV package stub. The stub is useful for candidate/fallback/error-boundary behavior only.

The x86_64 `linkora_ffmpeg` module is real native FFmpeg and can be functionally exercised in simulator; ARM64 runtime correctness remains a later device gate.

## Fresh simulator-preflight attempt — 2026-10-07

Task: `phase8b-sim-functional-corpus-preflight`, dispatched READY.

Strategy source: `2dda6ccc84547cf2c3ec65caf5d0b546fac9949c`.

Actual checkout/attempted revision: `7b931ca84b88327e647eae37aa974c1f0d928c1b`.

Evidence: `test-lab/playback/phase8b-simulator-functional-preflight-20261007/`.

### Freshly established facts

- Remote HEAD exactly matched the dispatch. A fresh isolated clone was initially clean.
- Accepted Phase 8A evidence is an ancestor of strategy source; strategy source is an ancestor of checkout HEAD. The only source-to-HEAD difference is `docs/CODEX_VALIDATION_TASK.md`.
- Three pinned submodules were freshly initialized and checked at the committed revisions.
- All fourteen required-reading entries were read. Historical evidence was not reused as fresh PASS.
- Read-only strategy inspection confirms default ARM64, simulator x86_64, shared Adaptive playback and HTTP/WebDAV, package-boundary MPV stub, and normal default `ohpm install` in the simulator verifier's finally path. Packaging/runtime assertions remain NOT RUN.
- Reused FFmpeg dependency inputs only: all eight static archives were freshly hashed and every archive member's ELF machine checked against its ABI. No old application artifact or test result was reused.
- Exactly one normal `ohpm install` completed successfully (exit 0; stdout reports 639 ms).

### Stop and strict EOL proof

The installation rewrote these four tracked lockfiles from LF to CRLF:

1. `entry/oh-package-lock.json5`
2. `linkora_ffmpeg/oh-package-lock.json5`
3. `linkora_proxy/oh-package-lock.json5`
4. `oh-package-lock.json5`

For every file, the Git-normalized worktree blob equals HEAD, CRLF-to-LF bytes equal the HEAD blob exactly, and line contents equal HEAD. All other 2,410 tracked regular files remained byte-identical. No dependency version/checksum/graph or other semantic change is observed. `git diff --name-only` is empty, but `git status --porcelain=v1` reports the four files as modified because worktree EOL contradicts the committed `eol=lf` attributes.

The required `docs/AI_WORKFLOW.md` says environment normalization is permitted **"only when the current task explicitly permits it"**, and requires **"every affected path is explicitly allowlisted by the current validation task"**. This current dispatch contains neither an EOL recovery authorization nor an affected-path allowlist. Prior-round permissions were not substituted for the repository task's execution authority.

No restore, reinstall, source/config/test change, gate bypass or retry was performed. Testing stopped before the first ARM64 verifier. This is an environment/dispatch authorization blocker, not an ARM64 compile failure, simulator codec failure, MPV defect or lack-of-device blocker.

### Execution coverage after stop

| Item | Fresh result |
| --- | --- |
| Source safety / required reading | PASS |
| FFmpeg dependency-input ABI/hash audit | PASS, dependency inputs only |
| Normal `ohpm install` | PASS, one invocation |
| Default ARM64 verifier, pure/Hypium suites, Debug/Release HAR/HAP, exact-nine audits | NOT RUN |
| Simulator verifier, HAP/isolation audit, default dependency restoration and final default verifier | NOT RUN |
| Simulator target preflight, fresh install/launch | NOT RUN |
| Corpus generation/fetch, 59-case truth manifest, served-byte verification | NOT RUN |
| Forced System matrix | NOT RUN — 0 cases |
| Forced MPV stub / Auto fallback subset | NOT RUN |
| Real x86 FFmpeg Analyzer/thumbnail subset | NOT RUN |
| Runner/schema/summarizer checks | NOT RUN |
| Recovery, 20 open/leave, 10 background/foreground, 10 fallback, WebDAV/MediaProxy runtime | NOT RUN |
| Real MPV, ARM64 FFmpeg runtime, Mate60 codecs/hardware/HDR/advanced audio/performance | DEVICE REQUIRED / NOT RUN, deferred by task |

### Evidence integrity and handoff

The new evidence includes source/reading provenance, fresh dependency audit, original-byte compressed installation logs with decompression/hash proof, per-file EOL proofs, protected audit, and security review. No generated media, application binaries, credentials, signing material, private screenshot or host endpoint is published.

The user's existing workspace and historical evidence were preserved. Only this report and the authorized new evidence directory are committed; the four EOL-only worktree files are deliberately left un-restored and unstaged for review. The publication audit verifies all protected Git blobs remain unchanged, while explicitly retaining the worktree-byte EOL caveat.

**Primary classification: BLOCKED — VALIDATION ENVIRONMENT (EOL RECOVERY NOT DISPATCHED).**

Next action belongs to GPT: review this proof and, if appropriate, issue a new READY task explicitly permitting the four proven EOL-only paths in an isolated checkout, with a new evidence directory. No production fix is indicated by this attempt. All subsequent build/runtime results must be fresh.


## GPT review of EOL-only blocker — 2026-10-07

Reviewed remote evidence commit:

`a6058b0a79516e334a342680b557552f7a7ceae1`

Ruling:

**VALID VALIDATION-ENVIRONMENT BLOCKER — SAFE EOL-ONLY RECOVERY MAY BE DISPATCHED.**

The blocked run correctly stopped before `verify.ps1`.

The evidence satisfies every technical condition in `docs/AI_WORKFLOW.md` for non-semantic validation-environment normalization:

1. affected paths are exactly known;
2. each worktree file's Git-normalized blob equals `HEAD:<path>`;
3. CRLF-to-LF normalized bytes equal the exact HEAD bytes;
4. line content is identical and no dependency/version/checksum/graph/comment semantics changed;
5. no other tracked regular file changed.

The only failed condition was procedural: the active validation task did not explicitly allowlist the affected paths or authorize the restore.

Therefore no production/source/dependency correction is required.

The next validation dispatch may authorize isolated-checkout EOL-only restoration for exactly:

- `entry/oh-package-lock.json5`
- `linkora_ffmpeg/oh-package-lock.json5`
- `linkora_proxy/oh-package-lock.json5`
- `oh-package-lock.json5`

The authorization is conditional on freshly reproving the same invariants in the new checkout after the new task's single normal `ohpm install`.

If any additional tracked path changes, any normalized blob differs from HEAD, or restore does not return the checkout to clean state, Codex must stop.

The historical blocked evidence directory remains immutable.

No build, simulator, corpus or runtime PASS is inherited from the blocked attempt; all downstream gates remain fresh-required.
