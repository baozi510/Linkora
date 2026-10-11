# Codex Validation Task

> State: READY
> Task ID: phase8f-sim-rerun2-ui-foreground-gated-cancellation
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation SOURCE_SHA: `867907df5ab768c5127a707d2076fd8d619a3fbf`
> Unchanged production playback fix: `8174e6e4f0214958fb83fef46e92170c4c10263a`
> Previous completed preflight evidence: `4d59195f6fa3502b60f5f53ed60d5407be700510`
> Role: FRESH BUILD / SIMULATOR ENVIRONMENT-FOREGROUND PREFLIGHT / BOUNDED NATIVE PLAYBACK-CANCELLATION / EVIDENCE / REPORT ONLY

## 0. Owner decision: new task, no previous task retry

**This task is NEW; the completed ID `phase8f-sim-rerun1-positive-progress-cancel-recovery` MUST NOT be re-executed.** Its genuine `FAIL — REQUIRED TEST GATE` was accepted on independent remote evidence: new screenshot/layout preflight asserted and exited1 **before any official media opened**, the PNG (1256×2760) displayed **system Launcher**, and app-scoped layout had **zero visible Linkora nodes**. Although ordinary signed install/aa start command was accepted and a later app process PID existed, **foreground/window/rendered ArkUI was NOT PROVEN**. App startup failure versus foreground management versus UI collector applicability remains UNRESOLVED. No production/codec/candidate bug was established by that preflight.

The private positive-progress collector was predeclared and passed 6 **pure** selfchecks but had **zero runtime invocations**; old >=800ms helper wasn't invoked and its previous +766ms/false/AssertionError remains immutable. Old Phase8E pending preparation cancellation cleanup failed; Phase8F and Rerun1 did **not** validate the new Adaptive pending-candidate ownership/release correction.

**GPT correction this time is TASK/VALIDATION ENVIRONMENT ONLY; no production code change.** Exact production source blobs in `AdaptivePlaybackPort.ets` and `SystemPlaybackPort.ets` remain those in `8174e6e4f0214958fb83fef46e92170c4c10263a`. System prepared-state safety gate (native Promise + true prepared notification/state, bounded20s), existing forced-System HLS routing, player Auto preference/logic, media tests/policies, sources and configurations stay unchanged. Codex **must not edit** source, fixtures, scripts, tracked tests or expectations.

**Mandatory new control:** an explicit **bounded UIAbility / foreground / window / app-scoped layout readiness preflight**, performed *before* instrumentation assertion or any fixture open, after fresh signed install. Read installed command help, identify exact declared `EntryAbility` and installed bundle, issue one ordinary targeted start, then gather a time-bounded series of read-only foreground/window observations. Only after a visible matching Linkora window is established may the task run a **sequential** (not concurrent first-read) Linkora app-scoped layout and screenshot preflight. Success is **not** implied by PID, HDC exit0, installer installSuccess or valid screenshot dimensions. If readiness does not establish: STOP with evidence and **zero official playback opens**; no restart/reset/UI trick/decoder source patch or replay of prior failing helper.

No physical ARM64 device currently available: simulator first plus fresh full ARM64 build. MPV stub in simulator is not real MPV. No Mate60/HDR/DV/encoded audio/FFmpeg ARM64 runtime/performance certification; no Auto policy, Direct I/O, thumbnails Issue#17, display modes, media-track codec handling implementation.

## 1. Exact branch, checkout and protected path gates

1. Fresh-fetch `baozi510/Linkora` branch `feat/playback-capability-phase8`. Verify current task READY, exact ID, source SHA `867907df5ab768c5127a707d2076fd8d619a3fbf`, and actual fetched full dispatch SHA. Evidence `4d59195f6fa3502b60f5f53ed60d5407be700510` must be ancestor of source; source ancestor of dispatch.
2. `git diff --name-only 867907df5ab768c5127a707d2076fd8d619a3fbf..HEAD` must list **only** `docs/CODEX_VALIDATION_TASK.md`. Any other drift => STOP `BLOCKED — SOURCE DRIFT`. Verify exact Adaptive/System source blobs unchanged from source commit `8174e6e4f0214958fb83fef46e92170c4c10263a`.
3. Distinct clean isolated clone/worktree only. Do not stash/reset/clean/check out over user dirty `D:/Linkora`. Normal fresh pinned submodules at three exact tracked Git object SHAs and verified authentic upstream origins; do not disable TLS or Git safety to recover optional fetch. No old HAP/test PASS/test executable copied into new proof.
4. Codex handles BUILD / TEST / INSTRUMENTED READ-ONLY OBSERVATION / REPORT ONLY. Production source changes, test policy, app code/hooks, test scripts/expectations, profiles, media, package/native version, lock semantics, runtime player policy and signing bypass are **forbidden**. On defect stop and return to GPT. Do not query quota, poll chat, or promise background work.

## 2. REQUIRED_READING: complete current and historical source

Read and record Git revision/blob or precise provenance, distinguishing CURRENT vs historical:
- `docs/AI_WORKFLOW.md`; `docs/MASTER_IMPLEMENTATION_PLAN.md`; `docs/ARCHITECTURE_TARGET.md`; `docs/ARCHITECTURE_MIGRATION.md`.
- Latest CURRENT sections of `docs/IMPLEMENTATION_STATUS.md`, `docs/SESSION_HANDOFF.md`, and this **entire** `docs/CODEX_VALIDATION_TASK.md`.
- `docs/PLAYBACK_PHASE8F_RERUN1_POSITIVE_PROGRESS_CANCELLATION_REPORT.md`; `test-lab/playback/phase8f-rerun1-positive-progress-cancel-recovery-20261008/{preflight-stop-diagnosis.json,runtime-preflight-result.json,instrumentation-helper-source.sanitized.txt,instrument-preflight-console.sanitized.txt,task-result.json,emulator-start.json,source-state.json,independent-collector-provenance.json,independent-collector-source.sanitized.txt,cleanup.json}`. Do not execute any of those failed task scripts; read for diagnosis only.
- `docs/PLAYBACK_PHASE8F_PENDING_CANDIDATE_CANCELLATION_REPORT.md` and its original `healthy-control.json`, `healthy-run.stderr.sanitized.txt`, `native-readiness-timeline.json` for old threshold FAIL; `docs/PLAYBACK_PHASE8E_SYSTEM_READINESS_VALIDATION_REPORT.md` and its original pending-preparation `leave-during-prepare.json` and lifecycle diagnosis.
- `docs/PLAYBACK_PHASE8D_SIMULATOR_RERUN1_REPORT.md`, `docs/PLAYBACK_PHASE8D_SIMULATOR_INVESTIGATION_REPORT.md`, `docs/PLAYBACK_PHASE8B_REPORT.md`, the tracked simulator runbook and committed controlled media-corpus truth; `docs/PLAYBACK_NATIVE_CAPABILITY_AUDIT_REPORT.md` for static-only Phase8C scope.
- `entry/src/main/module.json5` (module `entry`, `mainElement: EntryAbility`, exported `EntryAbility`); `entry/src/main/ets/entryability/EntryAbility.ets` (asynchronous `windowStage.loadContent('pages/Index')`); `entry/src/main/ets/pages/Index.ets` (grounded initial page content); `AppScope/app.json5` for **actual bundle ID**, and the installed signed package entry/module info.
- `entry/src/main/ets/playback/{AdaptivePlaybackPort,SystemPlaybackPort,MpvPlaybackPort,NetworkPlaybackSourceResolver}.ets`, `entry/src/main/ets/pages/PlayerPage.ets`, `linkora_core/src/main/ets/playback/{PlaybackEngine,PlaybackPort,PlaybackModels,PlaybackBackend}.ets`; review previous GPT lifecycle source diff `68452df5486cf568da66a5c52352841cb7e64c5f..8174e6e4f0214958fb83fef46e92170c4c10263a`.
- Installed API26 `AVPlayer.prepare/state/stateChange/release` declarations, installed HDC3.2.0f / `aa` / `hidumper` / `uitest dumpLayout` help and official OpenHarmony docs. Note UITest `dumpLayout -b <bundleName>` and `-w <windowId>` are distinct target selectors; check *installed syntax* rather than invent flags.
- Four retained fixture classes / ten files: healthy H264/AAC MP4, HLS H264/AAC and HEVC/AAC both manifests+3 segments each, and MKV FFV1/FLAC. Confirm actual corpus truth.

## 3. Fresh install, EOL-only normalization, strict builds and signed HAP

Run **one initial normal** `ohpm install`; simulator verification's built-in finally install is permitted. Before restoring any locally mutated tracked file, separately prove Git-normalized worktree blob and exact CRLF→LF bytes equal HEAD, semantic versions/checksums/comments/graph unchanged, no other tracked bytes changed, and full clean isolated checkout after restoring **only** these four explicitly authorized lockfiles:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

Do independent fresh proofs after initial install and after simulator finally dependency install. Any semantically changed lock/other path or dirty checkout => STOP `BLOCKED — VALIDATION ENVIRONMENT`. Do not repeat normal install to recover.

Full fresh commands in **exact order**:

```powershell
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Both default invocations: independently retained original Hypium outputs/counts, architecture fixtures, FFmpeg/Analysis suites, artifact fixtures, MPV mapping, Debug/Release HAR/HAP, **two exact-nine AArch64 artifact/native ABI audits per invocation**. Simulator: parity/isolation, static audio-metadata guard, x86 FFmpeg-only library whitelist, correct x86 ABI. The second default verifies final restoration of real production MPV/native packages. Any actual gate failure STOP, no simulator playback; never inherit old 210 PASS or old HAP.

Sign only the actual newly built simulator HAP using installed legal SDK sign tool and unchanged appropriate simulator-permitted profile, if required; never disable signature/permission checks. Run ABI whitelist audit with installed CLI's required **positional `x86_64`**, not previously rejected `--abi=x86_64`. Save artifact signed SHA/size; explicit replace-install with verified installSuccess (HDC transport exit0 alone isn't proof); app data retained, no uninstall/wipe. No HAP/keys/profiles published.

Emulator target if absent: allow **only normal launch of existing permitted x86_64 API26 simulator instance** after observing installed emulator help and accepted agreement, retaining current image/profile/data. Do NOT create a new image, reset, downgrade, disable TLS, clear data or stop unrelated user instances. Verify actual exact HDC target/API/ABI before install. Record whether boot required (and headless mode if used). Simulator transport readiness does not mean application UI ready.

## 4. NEW MANDATORY stage: finite foreground/UIAbility/layout readiness

**This section must fully pass before running UI-input/media helper, creating HTTP row, starting fixture server, creating rport or issuing official media opens.** It is a fresh setup preflight, not a retry/override of Rerun1's failed helper.

A. **Predeclare a non-invasive PRIVATE preflight collector and finite stop rules before launching any app UI.** Allowed: installed HDC/aa/hidumper/uitest read-only calls; private local scripts for timestamped command/result capture, ordinary UI screenshots, and targeted tree parsing. Forbidden: changing production/test/build content, injecting tracing hooks, persistent ArkUI debug/testmode setting, app reconfiguration, arbitrary HOME/BACK click to force foreground, startup argument hacks, emulator image reset/upgrade, suppressing failed command exits. Keep a sanitized copy/source hash and accurate original return codes. If a predeclared command itself throws/asserts/exits1, **STRICT STOP**, never call it optional or rerun it to turn red green.

B. Verify `module.json5` expected `entry/EntryAbility` and `AppScope/app.json5` actual bundle against installed fresh signed HAP. Read installed `hdc shell aa --help` / `aa start` help and AbilityManager/WindowManager/hidumper help to select **supported** command forms. Confirm target HDC device ID and API26/ABI, private ID redacted. Capture pre-start foreground app/window (whether Launcher) and app process/ability state separately.

C. **Issue at most one explicit normal owned app `EntryAbility` start**, e.g. installed-supported equivalent of `hdc shell aa start -a EntryAbility -b <actual bundle>`. Do not treat command acknowledgement or pid as success. Do not automatically force-stop and relaunch multiple times. If app already genuinely foreground and window/content loaded before command, record and omit unnecessary start; do not invent new launch.

D. **Bounded read-only readiness observation** after that one start: at most **30 seconds**, e.g. six samples spaced ~5 seconds, actual elapsed timestamps. On every sample record independent layers: (1) target present/ID/API, (2) process/ability lifecycle/foreground state from *supported* `hidumper -s AbilityManagerService` / installed equivalent, (3) visible/top foreground WindowManager window owner/bundle/ID/display/IsVisible/IsStartingWindow where supported, and (4) if window owner is target, read-only app target component tree. A PID is insufficient; target foreground/window ownership is mandatory. Do not guess unsupported subcommands or publish private identifiers.
   - Distinguish **target app not launched**, **ability exists but background/launcher top**, **visible app window but no loaded `pages/Index`**, and **app visible but `uitest dumpLayout -b` unexpectedly empty**. These are distinct classification possibilities, not one inferred decoder error.
   - If target foreground not proven by deadline, STOP `BLOCKED — SIMULATOR APP FOREGROUND/STARTUP` or `FAIL — UI READINESS PREFLIGHT` with grounded logs; no official open. The Rerun1 helper is not invoked again. No second app start; make read-only diagnostic captures only **as part of predeclared observation** before the deadline.

E. Only when actual target visible window is confirmed, collect **sequentially**:
   1. supported `uitest dumpLayout -b <actual bundle>` / installed equivalent and optionally `-w <verified target windowId>`; validate exit and nonempty **visible Linkora-app component nodes**, not root attributes, and identify actual app page controls from `Index.ets`;
   2. an ordinary readable screenshot that actually contains matching Linkora UI, not merely a valid 1256×2760 PNG showing Launcher; check screenshot and app tree refer to same foreground window/display and sampled time; 
   3. if one selector returns empty while WindowManager shows target visible, use a predeclared **read-only** alternative `dumpLayout -w` / unscoped whole-tree comparison to diagnose **bundle selector vs window ID/UI-test permission**. This may diagnose, but may NOT transform an empty app view into a PASS without independently proving actual Linkora app nodes and target window identity.
   4. require two stable, timestamped samples that satisfy target-window foreground and nonempty app layout, with no intervening launcher focus; at most 30s total. Capture errors/worker results explicitly rather than claiming they were absent if not observed. No concurrent-first-dump race.

F. The UI gate PASS requires **actual target app foreground+visible window+nonempty Linkora UI nodes+matching screenshot** and no failed required command within the predeclared stage. If any fails: STOP, report exact layer and native/ability/window selected startup errors with honest subset provenance. **Zero official opens**, no arbitrary remediation, no source patch. Passing this stage does NOT yet mean healthy playback PASS.

## 5. Normal owned fixture route + playback evidence, ONLY after §4 PASS

Keep controlled same local+WebDAV fixture corpus; fresh exact hashes/size and local/WebDAV TLS wholeGET/Range206, ffprobe checks already required, but host served-byte and genuine target HTTP route remain separate gates. Check host19084 listener/ownership and current fport/rport list; do not kill unrelated services. Start only retained owned host fixture server 127.0.0.1:19084, verify served exact bytes match committed truth. Create precisely **one** `hdc rport tcp:19084 tcp:19084`, device→host, check actual `[Reverse]`, not `fport`. No changed port, URI, media, profile, signing, backend policy or app code. Healthy unchanged forced System MP4 official open must prove genuine target AVPlayer GET/Range206 correlated with host access; host-only GET cannot substitute.

Predeclare independent PRIVATE read-only playback observer (not prior asserting helper) **before any official open**, preserve source hash and six prior boundary selfchecks but do not treat pure checks as runtime. Old `focus-run.PRIVATE.py >=800ms` historical false/AssertionError unchanged and never invoked as this run's gate. A newly invoked helper/collector nonzero => STOP with raw error; no retry. Healthy official progress criterion: two timestamp-ordered numeric PLAYING UI position samples under an explicitly bounded <=5s window with strictly positive delta `later-earlier>0`, **not >=800ms**. Keep an optional separate `diagnosticAtLeast800ms` but don't alter old raw `positionAdvanced=false`. Require *independently* true native prepared before play/playing, actual OnStartRenderFrameCb, 320x180 video size, colored XComponent pixels, real native target→host GET, and normal leave sampled surface/service/audio0. One official healthy attempt, one official control, no retries to chase threshold.

After healthy A passes perform (each **one official open**; no extra attempts):
1. **HLS H264/AAC:** manifest+three segments GET200, native prepare/state/play timeline; no play while initialized; actual frame callback vs actual independently colored ROI, positive delta/raw progress separately. Bounded HLS format result may be FAIL/NOT PROVEN but no safety regression; don't claim codec/device support.
2. **HLS HEVC/AAC:** independent same; native 5400106 `VID_DEC_ERR` if observed is scoped simulator evidence, not cross-device verdict. If a real source safety regression occurs, STOP.
3. **Mkv FFV1/FLAC:** native prepared/playing, size callback and actual first-frame event vs registration, XComponent ROI, numerical position positive vs optional >=800 diagnostic; black 0x0 is not video PASS or audio-output proof.
4. **Separate cancellation HLS H264:** deliberately leave **during native initialized/JsPrepare, before prepared**. Need timestamped at-leave proof. If preparation wins and no valid preparing hold is witnessed, report NOT PROVEN and STOP; do not retry fixture or insert hooks. Require correlated actual native candidate release/released where observable (same native AVPlayerNapi object ref if safely derivable privately); prevent late synthetic PREPARED/JsPlay/Auto fallback, confirm native release without waiting for 20s timeout. Take early (~3–5s) and late **>20s** normal resource samples: surfaces, app-associated PlayerDistributedService entries, app audio renderers all zero **without force-stop**, with correct metric limits. If anything persists, STOP `FAIL — CANCELLATION CLEANUP REGRESSION`; do not turn forced cleanup into PASS or open recovery.
5. **Distinct recovered MP4:** only after true cancellation normal PASS, one independently new healthy System control with exact native prepared→play, fresh frame callback, actual colored pixels, native GET, strictly positive position, normal zero sampled leave. No forced application restart. Recovery absent if cancellation failed => NOT RUN.

Result boundaries: native callback ≠ rendered visible frame; +progress ≠ video output; app service entries ≠ proven distinct native player instances; audio record ≠ audible sound; System simulator ≠ physical ARM64/Mate60. Keep Phase8B/D/E/F old FAIL/NOT RUN and raw helper results untouched; Phase8C audit static only.

## 6. Cleanup, security, stop conditions

Stop for branch/source drift, build/native ABI/test errors, semantic EOL mismatch, fresh helper nonzero, app foreground/UI readiness not proven within bounded preflight, missing owned route, healthy gate FAIL, inappropriate preprepared play, missing cancellation native release or nonzero resources >20s, late commit, inability to prove safety without hooks or valid cancellation precondition, and any production defect needing GPT fix.

After stop/finish remove **only own** created rport (installed supported `fport rm` syntax) and server/HTTP row; if never created, record NOT APPLICABLE rather than fake restored. Restore Auto/preferences/layout only if actually changed and read the original; don't claim observed original Auto if not observed. No wipe/uninstall/force-stop to get green; if force-stop is needed solely for containment *after* documented FAIL, separately report it without changing verdict or running subsequent recovery. Preserve emulator data and unrelated listeners/mappings/services, fixture corpus, WebDAV data and user's dirty workspace. Sample app player/audio; when layout invalid, **surface0 remains NOT PROVEN**.

PRIVATE signing/HAP/raw screenshot/full hilog/media/credentials/device IDs/PIDs/user-specific host paths remain outside Git. Log actual failed exits/traceback (declare console transcript vs byte-identical original stderr), selected native logs labeled subset/redacted, full sanitized build warnings/test counters, original local provenance hash, gzip decompression/SHA256 pairs. No arbitrary UI script changes to mask red results, no private endpoint release, no quota queries.

## 7. ONLY authorized new evidence/report paths

```text
docs/PLAYBACK_PHASE8F_RERUN2_UI_FOREGROUND_CANCELLATION_REPORT.md
test-lab/playback/phase8f-rerun2-ui-foreground-cancel-recovery-20261011/
```

Suggested: exact source-state/required-reading, original EOL proofs twice, build results/Hypium originals and sanitized logs, signed artifact install/ABI, fixture truth, installed command-help provenance, emulator and app launch lineage, predeclared foreground polling definitions/selected ability/window dumps, bounded timestamped foreground samples, per-selector UI layout results and screenshot private hashes/dimensions, explicit app-readiness verdict, instrumentation preflight, native route proofs, official attempt ledger, healthy six-predicate progress, HLS/FFV1, cancellation/normal cleanup samples, recovery, cleanup/security/log-integrity, protection audit. If preflight fails, later categories are NOT RUN and official attempt ledger intentionally empty; do not fabricate missing files.

**No changes** to old Phase8F Rerun1 report/evidence, any prior phase, production sources/tests/scripts/profiles/media, or `docs/CODEX_VALIDATION_TASK.md` after dispatch.

## 8. Publication and exact verdicts

1. Before push: diff only authorized new report + evidence directory, preexisting tracked blobs/old evidence untouched; original unrelated dirty workspace unchanged.
2. Fresh-fetch remote before push. Stop on unexpected advanced/protected remote edits; normal evidence-only commit/push, no merge/no force. Fresh-fetch and verify full remote evidence SHA/ancestry, all new blob paths/hashes, old protected blob identity and gzip/hash proof; checkout clean. If push can't be confirmed: `BLOCKED — EVIDENCE NOT PUSHED` and report local SHA, not remote success.
3. Select truthful **one primary**:
  - `PASS — ADAPTIVE CANCELLATION AND RECOVERY VALIDATED` only if all fresh builds + §4 UI foreground/layout PASS + independent positive-progress healthy A + two HLS/one FFV1 bounded case collection + single real native-initialized cancellation, correlated native release and early/>20s all normal resources0 without force-stop + distinct healthy recovery. Scoped HLS/FFV1 format FAIL remain explicit, no broad codec acceptance.
  - `FAIL — REQUIRED TEST GATE` for actually failed new required helper/collector/assertion, with original exit and STOP;
  - `BLOCKED — SIMULATOR APP FOREGROUND/STARTUP` if app window/foreground never established by finite deadline;
  - `FAIL — UI READINESS PREFLIGHT` if foreground window exists but app-scoped UI nodes/screenshot cannot be proven;
  - `FAIL — ARM64 BUILD GATE`, `FAIL — SIMULATOR BUILD`, `FAIL — HEALTHY CONTROL`, `FAIL — CANCELLATION CLEANUP REGRESSION`, `FAIL — PLAYBACK SOURCE REGRESSION`, `FAIL — EVIDENCE INCOMPLETE`;
  - `BLOCKED — SOURCE DRIFT`, `BLOCKED — VALIDATION ENVIRONMENT`, `BLOCKED — SIMULATOR ENVIRONMENT`, `BLOCKED — EVIDENCE NOT PUSHED`, or `PENDING — INTERRUPTED` when applicable.
4. Report exact SOURCE_SHA, tested dispatch SHA and fresh remote EVIDENCE_SHA (all forty chars), each actual official attempt and explicit NOT RUN, no reused old PASS, normal Markdown chat handoff. GPT reviews independently; Codex never implements source changes or queries quota.
