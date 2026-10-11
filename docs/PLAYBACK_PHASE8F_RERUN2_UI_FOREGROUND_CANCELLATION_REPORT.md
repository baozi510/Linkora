# Phase 8F Rerun 2 — UI foreground and cancellation validation

**REVIEW_RESULT: FAIL — REQUIRED TEST GATE. STATE: STOPPED.**

The new private signing-material membership helper threw an unhandled AssertionError before simulator build, signing/install, foreground/UI preflight or any official media open. Its comparison incorrectly included the explanatory label returned by `bm get -u`. A read-only examination of the already captured output confirms the isolated identifier is in the existing legal profile. This is a validation-helper defect, not an established signature/profile, startup, playback or cancellation production defect. The failed helper was neither changed nor rerun, and its original false result remains false.

- Repository / branch: `baozi510/Linkora` / `feat/playback-capability-phase8`
- TASK_ID: `phase8f-sim-rerun2-ui-foreground-gated-cancellation`
- SOURCE_SHA: `867907df5ab768c5127a707d2076fd8d619a3fbf`
- TESTED_DISPATCH_SHA: `148de8f4cfd7c382aa403fb4e1b17d3a4171f850`
- Unchanged production playback fix: `8174e6e4f0214958fb83fef46e92170c4c10263a`
- Historical Rerun 1 evidence: `4d59195f6fa3502b60f5f53ed60d5407be700510`; not reexecuted.
- Date: 2026-10-11, Asia/Shanghai.
- Evidence: `test-lab/playback/phase8f-rerun2-ui-foreground-cancel-recovery-20261011/`.

The task file remains READY and unchanged as required. STOPPED describes this execution, not an unauthorized edit of the dispatch. The evidence commit's complete SHA is supplied in the chat handoff after normal push and fresh remote verification; this report does not attempt a self-referential commit SHA.

## Fresh source and environment

A new independent GitHub clone was created outside the original workspace, followed by a fresh branch fetch. Remote HEAD exactly equaled the supplied dispatch. The previous evidence is an ancestor of SOURCE, SOURCE is an ancestor of dispatch, and source-to-dispatch drift is exclusively `docs/CODEX_VALIDATION_TASK.md`. Adaptive/System blobs exactly match the unchanged production fix. Required current workflow/master/architecture/current-state sections, complete task, historical reports/evidence, declared entry/bundle, playback source and lifecycle diff were inspected; revision/blob/hash provenance is retained. Historical results supply context only.

Three submodules were freshly initialized normally from authentic upstream GitHub origins at the committed pins: libnfs `cee4ca723e081e6a18f51b838690a4c21e14bb2c`, libsmb2 `b3d560c02fb1268320d2fd1c17fe841b0d93b85f`, framework `7d726d145d678aa7f5a7df3b9e7ee3dbce6ea1bf`. No local source fallback or TLS/Git-safety weakening. Only pinned FFmpeg dependency inputs were copied: all eight archive hashes and every member ABI were freshly checked against committed provenance. No old HAP, test executable or test result was copied.

One initial normal `ohpm install` returned0. Exactly the four authorized locks received independent raw-byte/Git-normalized-blob/exact CRLF-to-LF equality and unchanged semantics proof before isolated restore. All other tracked bytes were unchanged, and the checkout became fully clean. The simulator verifier and its finally install never ran; a second EOL proof is therefore NOT APPLICABLE, not invented.

## Actual build and STOP sequence

| Gate | Fresh result |
| --- | --- |
| Source/ancestry/dispatch/drift/submodule gates | PASS |
| Initial install / four-lock EOL proof | PASS |
| First default `verify.ps1` | PASS, actual exit0 |
| First default Hypium | 210 run / 210 PASS / 0 Failure / 0 Error / 0 Ignore; separate original retained |
| First default other gates | Architecture5, FFmpeg15/15, Analysis46/46, artifact17, MPV mapping7, Debug/Release HAR/HAP and two exact-nine ARM64 ABI audits |
| New signing membership helper | FAIL, unhandled AssertionError; no retry |
| `verify-simulator.ps1` | NOT RUN |
| Simulator-finally EOL proof | NOT APPLICABLE, no simulator install occurred |
| Final default `verify.ps1` | NOT RUN |
| Fresh simulator artifact / signing / signed ABI audit / replace-install | NOT RUN |

The helper ran during the already executing first default verifier. It failed at08:08:59UTC; that verifier subsequently finished at08:09:33UTC. No subsequent verifier was launched. By the owned-process containment check, the runner had already completed, so no build process or application process was stopped. This scheduling detail is retained rather than implying the complete required default→simulator→default chain passed.

The exact failed statement was the conjunction of bundle match, material presence and whole-stdout membership. The stored `simulatorListedInExistingProfile=false` remains untouched. `target-udid.stdout.sanitized.txt` preserves the label followed by the redacted identifier; `stop-diagnosis.json` separately records the post-stop token membership diagnostic as true. This diagnostic does not replace the helper result or authorize continuation.

**Exit-capture limitation:** Python's unhandled AssertionError implies child exit1, but the original orchestration did not independently save that numeric child exit. A following log read in the same PowerShell invocation yielded outer wrapper exit0. This outer0 is explicitly not helper success. The traceback is a copied tool console transcript, not claimed byte-identical original stderr. Device-query commands did retain their actual HDC process exits and original byte hashes. No failed command exit was patched or a second helper executed to obtain green evidence.

## Foreground and playback boundaries

The existing HDC target was present; installed HDC3.2.0f and API26/x86_64 identity were read. No emulator launch/reset/profile change occurred. Installed help was inspected: this installation rejects `aa --help` as a command and `dumpLayout -h` as an option despite HDC transport exit0. These discovery outputs remain published, and supported `aa help`, `aa start -h`, AbilityManager/WindowManager help and `uitest help` establish available forms. No invalid syntax was treated as successful application observation.

A finite non-invasive foreground plan was predeclared before any owned app start: at most one ordinary EntryAbility start, <=30s/six read-only samples, independent ability/window ownership, sequential bundle/window layout and matching screenshots, two stable samples, and strict STOP on failed required commands. **The actual foreground/UI collector was not invoked.** No app start, layout collection, screenshot, UI input, preference action, fixture server, reverse mapping, HTTP row or official media open occurred in this task. Presence of the pre-existing application PID is not foreground or rendered-UI proof.

| Official scenario | Opens | Result |
| --- | ---: | --- |
| Healthy H264/AAC MP4, positive progress | 0 | NOT RUN |
| HLS H264/AAC | 0 | NOT RUN |
| HLS HEVC/AAC | 0 | NOT RUN |
| MKV FFV1/FLAC | 0 | NOT RUN |
| Separate pending-HLS cancellation / actual native release / early and >20s normal resource samples | 0 | NOT RUN / NOT PROVEN |
| Independent recovered MP4 | 0 | NOT RUN / NOT PROVEN |

The attempt ledger is intentionally empty. The four retained fixture classes/ten files were reviewed in committed truth; no fresh local/WebDAV wholeGET/Range/ffprobe or target-route PASS is claimed. Neither the new positive-progress runtime observer nor old `>=800ms` helper was invoked; no pure selfcheck PASS is invented. There are no position pairs, native first-frame/pixel/native-GET evidence, cancellation object correlations or recovery observations in this execution.

## Cleanup, preservation and review action

No owned server/mapping/HTTP row existed to remove, and no preference existed to restore. Read-only cleanup found mapping list empty and host19084 listener count0. The pre-existing installed app had0 matching PlayerDistributedService entries and0 matching audio renderer entries. These observations are not release/cancellation proof, native-instance counts or audibility. Surface count and original Auto preference are NOT PROVEN because no app UI was collected or settings inspected. No app force-stop, uninstall, wipe, emulator reset or unrelated service/mapping removal occurred.

The audit covers all3036 pre-existing regular files in the isolated clone, exact submodule state, original workspace regular-file bytes/HEAD/status and protected Git blobs. Production, tests/assertions/scripts/config/media, task and all old evidence remain unchanged. New output is confined to the authorized report and evidence directory. Full build warnings and counters are retained;25 public sanitized gzip pairs have exact decompression/SHA256 proof and private-original provenance. HAP/media/keys/profiles/credentials/raw device identifiers/PIDs/user host paths, raw screenshots and full hilog are not published. No quota was queried.

**NEXT_ACTION:** GPT independently review this validation-helper parsing error and missing original child-exit capture, then issue a new distinct READY task before another fresh build/install/UI/playback execution. No production patch is warranted by this STOP. The Adaptive pending-candidate release fix remains runtime UNVALIDATED. No physical ARM64, real MPV, hardware decode, Mate60, HDR/DV, advanced audio or comprehensive format acceptance occurred.
