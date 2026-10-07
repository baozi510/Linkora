# Playback Phase 8B Capability Report

> Status: BLOCKED — RUNNER INSTRUMENTATION GAP (AUDIO-ONLY METADATA)
> Branch: `feat/playback-capability-phase8`
> Date: 2026-10-07

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
