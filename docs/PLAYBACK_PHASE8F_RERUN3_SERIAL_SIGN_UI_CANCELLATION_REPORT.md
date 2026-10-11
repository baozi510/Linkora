# Phase 8F Rerun 3 — Serial signing, UI and cancellation validation

**REVIEW_RESULT: FAIL — REQUIRED TEST GATE. STATE: STOPPED.**

A PowerShell progress-observation command exited **1** while the final default verifier was still in flight. It tried to read `default-final-result.json` before that file existed, using `Get-Content -ErrorAction SilentlyContinue`. This suppressed the missing-file text but did not make the process exit successful. The actual numeric process exit1 is retained from the exec tool result; it is not inferred from a traceback or overridden with outer0. Under this task's any-child-nonzero STOP rule, no live signing/profile query, installation, foreground/UI preflight or official playback was performed afterward. The failed observation was not repeated or edited to produce green evidence.

This is a validation orchestration defect, not a production/player/profile or codec defect. The new parser selfchecks and three fresh verifier invocations individually passed. The final verifier was already running before the STOP and naturally completed afterward; its PASS does not override the failed observation or make the whole task PASS.

- TASK_ID: `phase8f-sim-rerun3-serial-sign-ui-cancel`
- REPOSITORY / BRANCH: `baozi510/Linkora` / `feat/playback-capability-phase8`
- SOURCE_SHA: `bfd34a33a36772077538c7c57527e30f23689a95`
- TESTED_DISPATCH_SHA: `026559e1975b44d00096d0fdccef7d164d0df049`
- Unchanged production fix: `8174e6e4f0214958fb83fef46e92170c4c10263a`
- Historical stopped Rerun2 evidence: `1999b761563902a19a163f7123524190ba9be95b`, immutable and not reexecuted.
- Date: 2026-10-11, Asia/Shanghai.
- Evidence directory: `test-lab/playback/phase8f-rerun3-serial-sign-ui-cancel-20261011/`.

The remote evidence commit SHA is provided in the chat handoff only after normal push/fresh-fetch verification, avoiding a self-referential SHA. The dispatched task file remains READY and unchanged; STOPPED is the result of this execution.

## Source, context and isolation

Fresh independent GitHub clone and fresh fetch matched the exact full dispatch. Rerun2 evidence is an ancestor of SOURCE, SOURCE an ancestor of dispatch, and SOURCE→dispatch drift is exactly `docs/CODEX_VALIDATION_TASK.md`. Adaptive/System blobs match8174. Latest CURRENT status/handoff and complete task were read; historical reports/source already fully read in this same session were revalidated against exact unchanged Git blobs. New Rerun2 helper source/error/provenance was read only. Relevant unchanged PlaybackEngine tests and MPV mapping tests were inspected. Required-reading metadata records revision/blob/scope and installed API26 declaration provenance. The original workspace and historical test outputs were not used as new PASS.

All three submodules were freshly initialized normally from authentic upstream GitHub at exact committed pins; no TLS/Git-safety bypass or local repository fallback. Eight retained pinned FFmpeg dependency archives were freshly checked for exact hash/manifest/member ABI, used only as dependency inputs. No previous HAP/test executable/result was copied. All new private scripts live outside the tracked checkout; no production/existing test/script/config/media or old evidence was changed. The private environment document was only read locally and was not published, quoted or hashed into public identifiers.

The previous scheduled check was paused before its due time when the user required immediate execution, preventing overlapping execution. No new task was delayed awaiting that timer.

## Parser and actual serial build stages

The new PRIVATE `id_parser.py` accepts only the already observed exact two-line shape: recognized label, then one standalone64-hex identifier. It strips surrounding line whitespace, never guesses the last token, concatenates stderr, changes case or uses substring membership. Extra text, blank/malformed output and multiple IDs are rejected. Same-line and bare positive formats were not demonstrated by installed output and are explicitly NOT APPLICABLE; synthetic negative tests reject them. Ten new pure selfchecks all passed with saved helper child returncode0 and exact source hash. The historical whole-stdout comparison remains FAIL and its old helper was not invoked or patched.

**Live `bm get -u` query/profile membership was NOT RUN.** Synthetic checks do not validate real device signing membership, legal installation or UI readiness.

| Required stage | Actual saved child code | Result |
| --- | ---: | --- |
| New parser pure selfchecks | 0 | PASS,10 synthetic checks |
| Fresh source protection/submodules/dependency inputs/baseline | 0 each | PASS |
| One initial normal ohpm install | 0 | PASS |
| Initial four-lock EOL proof/isolated restore | 0 | PASS, exact normalized bytes/Git blob/semantics; no other tracked drift |
| First default verifier | 0 | PASS, fresh Hypium210/210,0 Failure/Error/Ignore |
| Simulator verifier and ordinary finally dependency install | 0 | PASS, parity/isolation/audio metadata static guard, only x86 liblinkora_ffmpeg.so native whitelist |
| Independent post-simulator four-lock EOL proof/restore | 0 | PASS, checkout clean |
| Final default verifier | 0 | PASS, fresh independent Hypium210/210; natural completion after observation STOP |
| Separate PowerShell progress observation | **1**, observed exec result | **FAIL / STOP** |
| Live signing/parser/profile gate, signed artifact/ABI/replace-install | — | NOT RUN |
| Actual foreground/window/layout/screenshot gate | — | NOT RUN |

Each default independently includes architecture fixtures5, FFmpeg15/15, Analysis46/46, artifact fixtures17, MPV mapping fixtures7, Debug/Release HAR/HAP and two exact-nine ARM64 audits. Both Hypium originals were separately retained. Simulator successfully restored the real default dependency graph in finally; the subsequent default build individually verified production packaging.

Core scheduled gates were serialized, with saved UTC start/end and child numeric codes before the next start: first default14:42:44.596→14:47:33.562UTC; simulator subsequently finished14:48:55.950UTC; post-simulator EOL finished14:48:58.561UTC; final default then finished14:51:58.184UTC. The extra controller-side progress observation was outside that safe capture wrapper and ran during the final verifier. It reintroduced an in-flight observer/read race despite the required gates themselves being ordered. This exception is explicitly recorded, not hidden as an optional successful operation.

The simulator unsigned HAP is freshly hashed as a build artifact only. It was never signed/installed, and its checksum cannot imply runtime acceptance.

## STOP provenance and missing evidence

`progress-monitor-stop.json` records actual exec process exit1 and the command's purpose/cause. The tool console result showed successful simulator output and the initial EOL-proof lines, but no final result file, then process exit1. `progress-monitor-console.sanitized.txt` is explicitly a copied console description/subset, **not** byte-identical original stdout/stderr. The original progress command's precise UTC start/end and separate raw stderr were not independently captured. The missing-file text was originally suppressed by `-ErrorAction SilentlyContinue`; it is not reconstructed as an invented stderr or traceback. These are additional capture limitations of the orchestration path.

No second invocation recovered its returncode or turned it green. The final default verifier's separately captured process0/original logs/Hypium were retained as an already-running stage's natural completion, not a post-STOP new gate. No process force termination occurred. There was no production patch, helper repair followed by continuation or reexecution of old tasks.

| Official scenario | New opens | Result |
| --- | ---: | --- |
| Healthy System MP4 / positive delta>0ms | 0 | NOT RUN |
| HLS H264/AAC | 0 | NOT RUN |
| HLS HEVC/AAC | 0 | NOT RUN |
| FFV1/FLAC | 0 | NOT RUN |
| Separate native PREPARING cancellation / actual release / early and >20s normal zero resources | 0 | NOT RUN / NOT PROVEN |
| Independent recovered MP4 | 0 | NOT RUN / NOT PROVEN |

The official ledger is intentionally empty. No new target media request, native frame, pixel sample, UI position pair or release identity is invented. Fresh fixture local/WebDAV/host-byte/native-route tests are NOT RUN. Old ≥800ms helpers and prior positive+766/raw false are untouched. There is no new playback, cancellation or codec regression established.

## Cleanup, security and owner action

No app start, sign/install, UI input, backend preference, HTTP row, server or reverse mapping was created in this execution. Their removal/restoration is NOT APPLICABLE. Read-only cleanup's HDC target listing returned `[Empty]` with its own process0; no target was guessed, booted, reset or restarted after STOP. App player/audio/surface counts are NOT PROVEN, not fabricated0. Original Auto is NOT PROVEN and unchanged by this task. Host19084 listener count0 was separately read. No force-stop, uninstall, wipe, private profile change or unrelated process/service cleanup occurred.

Protection covers3105 pre-existing regular files and3108 initial Git-tree entries, original workspace HEAD/status/regular bytes and exact submodule pins. Publication is only this authorized new report and evidence directory. There are33 actual sanitized readable/gzip pairs with private-original hashes and exact public decompression proofs; complete build warnings/results are preserved. No private device identifiers/PIDs/user paths/signing/profile/credentials/HAP/media/screenshots or full hilog are published. No quota/usage query occurred.

**NEXT_ACTION:** GPT independently review the failed progress-observation process and its missing capture wrapper/timing. A new distinct READY task should prohibit reading completion-only result files before a stage finishes and route any progress observation through a method that retains its actual exit and treats absent completion metadata without a failing operation. Do not retry this stopped task/helper or overwrite its evidence. No production fix is warranted by this orchestration failure. Pending-candidate native release and recovery remain runtime UNVALIDATED; no physical ARM64, real MPV, hardware decode, HDR/DV, advanced audio or broad format acceptance was performed.
