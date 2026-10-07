# Playback Phase 8B Capability Report

> Status: BLOCKED — VALIDATION ENVIRONMENT (EOL RECOVERY NOT DISPATCHED)
> Branch: `feat/playback-capability-phase8`
> Date: 2026-10-07

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
