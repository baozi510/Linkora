# Codex Validation Task

> State: READY
> Task ID: phase3-rerun-3b-isolated-checkout
> Repository: `baozi510/Linkora`
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Implementation source SHA: `15db3f8a3e87f75edc209c1919f944f39c0b9fcb`
> Role: TEST / EVIDENCE / REPORT ONLY

## 1. Start rule

This file is the only current validation dispatch.

Do not rely on any previous Codex conversation.

The user's existing local workspace is **not required** to already be on the validation branch or be clean.

If the current workspace is on another branch (for example `main`) or contains uncommitted work:

- do **not** stash it;
- do **not** reset it;
- do **not** clean it;
- do **not** checkout another branch over it;
- leave it completely untouched.

Instead, create or reuse a **separate isolated validation clone/worktree** and perform all validation there.

If an existing validation checkout is itself dirty, do not destroy its work. Create another clean isolated validation checkout.

In the isolated validation checkout:

1. fetch the repository;
2. check out the remote branch `feat/ffmpeg-analyzer-policy-phase3`;
3. confirm the isolated checkout's `git status` is clean;
4. record the actual validation checkout HEAD;
5. confirm `15db3f8a3e87f75edc209c1919f944f39c0b9fcb` is an ancestor of that HEAD;
6. run:

```powershell
git diff --name-only 15db3f8a3e87f75edc209c1919f944f39c0b9fcb..HEAD
```

The only permitted changed paths after the implementation source SHA are:

```text
docs/AI_WORKFLOW.md
docs/CODEX_VALIDATION_TASK.md
```

No other path is allowed.

If any production source, test script, build profile, lockfile, report, evidence or unrelated document changed after the implementation source SHA, **STOP** and report the mismatch. Do not guess which revision to test.

The validation checkout HEAD may therefore contain docs-only workflow/dispatch commits ahead of the implementation source SHA. Record both the implementation source SHA and actual validation checkout SHA in the final report.

Do not modify this task file.

Important distinction:

- dirty/unrelated **user workspace** -> preserve it and use an isolated validation checkout;
- dirty **validation checkout** -> do not test there; create another clean validation checkout or stop if that is impossible;
- source/HEAD mismatch beyond the explicitly allowed docs-only paths -> STOP.

## 2. Required reading

Read completely, in this order:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md`
6. `docs/SESSION_HANDOFF.md` — CURRENT STATE first
7. `docs/CODEX_VALIDATION_TASK.md`
8. `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`
9. `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

Historical validation results are history only. Do not reuse an older PASS for an item not executed in this round.

## 3. What changed since the previous failed rerun

The previous Codex rerun stopped because the desktop `check-network-media-list.cjs` VM tried to resolve the Harmony target alias `entry/AnalysisComposition` as a root file.

ChatGPT review made three relevant corrections:

1. The desktop Loader/cache harness now mocks `NetworkMediaAnalysisCoordinator` at the Loader boundary instead of loading target-specific analyzer composition/NAPI code.
2. `HarmonyAnalysisInputs.openRemote()` again captures the remote native setup-settlement promise and awaits late setup cleanup on failure, preserving the pre-Phase-3 queue/lifecycle guarantee.
3. Timeout/cancellation regression semantics now require that a cancelled analysis cannot publish a late partial result.

SFTP trust semantics remain:

- `MediaSource.fingerprint` is media/cache identity only;
- the per-open SFTP fingerprint override is empty;
- persisted SFTP host-key trust remains owned by `NetworkServerEntry.advancedOptions.sftpFingerprint`.

No System/FFmpeg performance policy, playback routing, field merger or Direct I/O change was made.

## 4. Codex permissions

Allowed:

- create/reuse a separate isolated validation clone/worktree without modifying the user's unrelated dirty workspace;
- run builds/tests;
- install/run the supported simulator or device when required by the Phase 3 runbook;
- collect sanitized evidence;
- update `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`;
- add/update evidence only under `test-lab/analyzer-policy/phase3/`.

Forbidden:

- ArkTS/C/C++ production edits;
- test-script or test-expectation edits;
- build-profile/lockfile edits;
- architecture changes;
- bypassing a failed gate;
- changing playback/analyzer policy;
- modifying `docs/CODEX_VALIDATION_TASK.md`;
- merging branches.

If a source/test-infrastructure change is required, stop and return evidence to GPT.

## 5. Fresh default gate

Use a clean validation checkout.

Run normal dependency resolution:

```powershell
ohpm install
```

Confirm tracked lockfiles remain unchanged.

Then run the full default verifier exactly as the project requires:

```powershell
./scripts/verify.ps1
```

Do not substitute individual commands for this gate.

Record fresh results for:

- architecture boundary checks;
- architecture guard fixtures;
- simulator product static isolation;
- FFmpeg pure suite;
- analyzer adapter/policy pure suite;
- native artifact guard fixtures;
- ArkUI migration/static guard;
- persistence regression;
- HTTP range/System probe regression;
- network media list/cache/lifecycle regression;
- MPV adapter event-mapping regression;
- actual Hvigor Hypium execution and exact test count;
- Debug/Release HAR builds;
- Debug/Release default HAP builds;
- exact production AArch64 native-library/ABI audit;
- final verifier completion marker.

Specific regression requirements introduced by this review:

- `check-network-media-list.cjs` must reach its normal completion marker instead of failing module resolution;
- the queued Loader job must not advance while a failed native setup is still completing late cleanup;
- a cancelled analysis must not publish a late partial metadata result;
- all opened test sources/readers must still close;
- the media/cache fingerprint must not be used as an SFTP host-key override.

If the full default verifier fails, apply the stop condition in section 11.

## 6. Simulator -> immediate default isolation gate

Only after the fresh default verifier fully passes:

```powershell
./scripts/verify-simulator.ps1
```

Verify the simulator artifact rules from the existing runbook.

Immediately after simulator verification, **without a manual `ohpm install`**, run:

```powershell
./scripts/verify.ps1
```

The immediate default verification must pass and restore/retain the production dependency/native set correctly.

If either gate fails, stop.

## 7. Phase 3 functional policy

After the build gates pass, execute every achievable case in:

`docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`

At minimum preserve fresh evidence for:

### Probe policy

- LIST System COMPLETE -> no FFmpeg invocation;
- LIST System incomplete/unusable -> FFmpeg controlled fallback;
- DETAIL FFmpeg COMPLETE -> FFmpeg result;
- DETAIL usable FFmpeg PARTIAL -> keep FFmpeg partial, no System merge;
- DETAIL FFmpeg unusable -> System fallback;
- ADVANCED follows the same functional contract;
- cancellation must not start a later fallback engine;
- no field merger.

Do not relabel DETAIL coverage as ADVANCED coverage when ADVANCED execution was not actually run.

### Thumbnail policy

For resolvable file-like remote media:

- FFmpeg thumbnail first;
- FFmpeg raw frame -> common WebP encoder/cache;
- natural FFmpeg failure -> existing System thumbnail fallback;
- both engines unavailable/fail -> no invalid image persisted;
- metadata must remain useful when thumbnail generation fails where the production contract allows it.

HLS / DASH / LOCAL_DOCUMENT remain System-only.

### SFTP regression

Confirm:

- no `MediaSource.fingerprint` -> SFTP host-key use;
- persisted SFTP trust is still read from `NetworkServerEntry.advancedOptions.sftpFingerprint`;
- WebDAV/SMB/FTP/NFS behavior is not changed by this fix.

## 8. Production flow/runtime

Use the real production Network page/list -> `NetworkMediaLoader` -> `NetworkMediaAnalysisCoordinator` path where the runbook/environment makes it available.

Required production cases remain those in the Phase 3 runbook, including:

- WebDAV H.264/AAC MP4;
- WebDAV HEVC/MKV;
- metadata engine result;
- thumbnail engine result;
- new WebP persistence;
- cache reopen;
- cancellation/refresh/stale-result rejection;
- proxy/source cleanup;
- natural thumbnail fallback;
- both-thumbnail-engines-unavailable behavior;
- 20-cycle lifecycle.

If no suitable simulator/device is available, report affected runtime items as BLOCKED or NOT RUN according to the runbook. Do not promote static/pure tests into runtime PASS.

Do not start/modify unrelated user environments or services merely to manufacture a PASS.

## 9. Security

Inspect fresh logs/evidence for accidental exposure of:

- Authorization;
- Cookie;
- password/private credential;
- proxy token;
- sensitive full upstream URL/path.

The new production analysis log should expose only safe analysis diagnostics such as:

- metadataEngine;
- thumbnailEngine;
- thumbnailPlan.

Do not commit signing material, credentials, private URLs or raw secrets.

## 10. Performance exclusion

This round is functional validation only.

Do not collect or interpret System-vs-FFmpeg:

- latency ranking;
- median/p95;
- throughput ranking;
- CPU/GPU ranking;
- memory-efficiency ranking;
- power;
- thermal.

Performance policy remains deferred to a real arm64 device.

Incidental command durations are not benchmark evidence.

## 11. Stop conditions

Stop immediately and write evidence if any of these occurs:

- `scripts/verify.ps1` fails;
- simulator verification fails;
- immediate post-simulator default verification fails;
- a policy/fallback order violates the Phase 3 contract;
- cancellation starts/publishes work from a later/stale generation;
- common WebP encoding/fallback behavior regresses;
- production NetworkMediaLoader/cache behavior regresses;
- a source/test-infrastructure modification would be required;
- branch/source safety checks in section 1 do not match.

Do not fix the failure.

## 12. Report and evidence

Remote handoff requirement: the final report/evidence commit must be pushed to the task branch and verified visible remotely before the run is considered complete.

Update:

`docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

Store fresh sanitized evidence under a new subdirectory of:

`test-lab/analyzer-policy/phase3/`

The report must record:

- task ID;
- implementation source SHA `15db3f8a3e87f75edc209c1919f944f39c0b9fcb`;
- actual validation checkout SHA;
- isolated validation checkout path/worktree identity;
- confirmation that any unrelated dirty user workspace was left untouched;
- exact commands;
- exit codes;
- actual Hypium count if executed;
- build/artifact results;
- functional/runtime results;
- environment/device availability;
- failures and root-cause assessment when supported;
- items NOT RUN / NOT APPLICABLE / BLOCKED;
- confirmation that protected production/test/build files were not modified.

Only actually executed items may be PASS.

## 13. Final decision

Use one of these conclusions:

- `READY FOR PHASE 3 ARCHITECTURE ACCEPTANCE` — only if all required and achievable Phase 3 gates/cases pass and no required acceptance evidence is missing;
- `FAIL — BUILD`;
- `FAIL — POLICY`;
- `FAIL — NETWORK MEDIA LOADER`;
- `FAIL — THUMBNAIL PIPELINE`;
- `FAIL — CANCELLATION/CLEANUP`;
- `BLOCKED — TEST ENVIRONMENT`;
- another precise FAIL/BLOCKED category justified by evidence.

Do not merge and do not begin the next implementation phase.

After the test commands finish, the round is not handed off until the evidence is remotely visible.

You must:

1. commit only the authorized report/evidence changes;
2. push that commit to `feat/ffmpeg-analyzer-policy-phase3`;
3. fetch the remote branch and verify the pushed commit is contained in the remote branch;
4. report the pushed evidence commit SHA.

If push fails or is unavailable, conclude `BLOCKED — EVIDENCE NOT PUSHED`, preserve the local evidence commit SHA, and do not claim that GPT can review the run.

Only after the evidence commit is visible remotely should you stop and return the result to GPT.
