# Codex Validation Task

> State: READY
> Task ID: phase3-rerun-3c-eol-self-heal
> Repository: `baozi510/Linkora`
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Implementation source SHA: `15db3f8a3e87f75edc209c1919f944f39c0b9fcb`
> Role: TEST / EVIDENCE / REPORT ONLY

## 1. Start rule

This is the only current validation dispatch. Do not rely on any previous Codex conversation.

The user's existing local workspace is not the validation workspace. If it is dirty or on another branch, leave it completely untouched: do not stash, reset, clean, restore, checkout over, or write files there.

Create or reuse a separate isolated validation clone/worktree.

In the isolated validation checkout:

1. fetch `feat/ffmpeg-analyzer-policy-phase3`;
2. check out the current remote branch HEAD;
3. confirm the validation checkout is clean before dependency installation;
4. record the actual validation checkout HEAD;
5. confirm `15db3f8a3e87f75edc209c1919f944f39c0b9fcb` is an ancestor of HEAD;
6. inspect:

```powershell
git diff --name-only 15db3f8a3e87f75edc209c1919f944f39c0b9fcb..HEAD
```

Every path after the implementation source SHA must be inside this allowlist:

```text
docs/AI_WORKFLOW.md
docs/CODEX_VALIDATION_TASK.md
docs/SESSION_HANDOFF.md
docs/IMPLEMENTATION_STATUS.md
docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md
test-lab/analyzer-policy/phase3/**
```

No ArkTS/C/C++, test script, build profile, package manifest, lockfile, CMake/native source, or other unrelated path may differ after the implementation source SHA.

If any non-allowlisted path appears, STOP and report the mismatch.

Record both:

- implementation source SHA;
- actual validation checkout SHA.

Do not modify this task file.

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

Historical failed/blocked runs are evidence only. Never splice their partial PASS items into this run.

## 3. What this rerun is validating

Implementation source remains unchanged at:

`15db3f8a3e87f75edc209c1919f944f39c0b9fcb`

The previous run stopped before `scripts/verify.ps1` because Windows `ohpm install` rewrote exactly four lockfiles from LF to CRLF.

Uploaded evidence proves all four had identical normalized Git blobs/content. GPT reviewed that as non-semantic validation-environment drift.

This rerun must validate the actual Phase 3 source after safely self-healing that exact EOL-only case when it recurs.

Phase 3 production policy remains:

- LIST: System first, FFmpeg controlled fallback for resolvable file-like media;
- DETAIL / ADVANCED: FFmpeg first, System fallback only when FFmpeg is unusable;
- no System+FFmpeg field merger;
- file-like remote thumbnail: FFmpeg first, existing System fallback;
- HLS / DASH / LOCAL_DOCUMENT: System-only;
- no performance-derived routing;
- playback routing unchanged.

## 4. Permissions

Allowed:

- create/reuse an isolated validation clone/worktree;
- run builds/tests;
- install/run the supported simulator/device when required by the runbook;
- collect sanitized evidence;
- update `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`;
- add a new evidence subdirectory under `test-lab/analyzer-policy/phase3/`;
- perform the narrowly defined EOL-only validation-workspace cleanup in section 5.

Forbidden:

- production ArkTS/C/C++ edits;
- test-script/test-expectation edits;
- package manifest/build profile/CMake edits;
- semantic lockfile edits;
- architecture/policy changes;
- bypassing a failed gate;
- modifying `docs/CODEX_VALIDATION_TASK.md`;
- force-pushing or merging.

If a source/test-infrastructure change is required, STOP and return evidence to GPT.

## 5. Dependency installation and EOL-only self-heal

From a clean isolated validation checkout, record pre-install state and run:

```powershell
ohpm install
```

The command itself must succeed.

Then inspect the tracked worktree.

### 5.1 If the checkout remains clean

Proceed directly to section 6.

### 5.2 If the checkout becomes dirty

The only self-healable changed tracked paths are exactly these lockfiles:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

No additional tracked path may be changed.

For each changed allowlisted lockfile, prove all of the following before restoring anything:

1. the HEAD blob exists;
2. the worktree file's Git-normalized blob equals `HEAD:<path>`;
3. CRLF→LF normalized bytes are identical to the HEAD content;
4. line content is equal;
5. there is no dependency/version/checksum/graph/comment/content change;
6. `git diff` has no semantic content delta;
7. EOL inspection is consistent with the known case (repository index LF, worktree CRLF, attribute `text eol=lf`) when the drift manifests.

A valid blob check may use the equivalent of:

```powershell
$headBlob = (git rev-parse "HEAD:<path>").Trim()
$workBlob = (git hash-object --path="<path>" "<path>").Trim()
```

and must establish `$headBlob -eq $workBlob`.

Also preserve evidence equivalent to:

```powershell
git ls-files --eol -- <lockfiles>
git diff --exit-code -- <lockfiles>
```

If **any** normalized blob differs, any semantic content differs, any extra tracked path changed, or the situation cannot be proven to be EOL-only:

**STOP. Do not restore the files.**

If and only if every check passes, Codex is explicitly authorized to restore only the affected allowlisted lockfiles in the isolated validation checkout:

```powershell
git restore --source=HEAD --worktree -- <affected lockfiles>
```

Then verify:

```powershell
git status --porcelain=v1
```

is clean.

Record the EOL drift, proof and restore in this run's evidence.

Do not commit the restored files.

Do not rerun `ohpm install` merely because those EOL-only files were restored; dependency installation already succeeded.

If restore does not return the validation checkout to clean state, STOP.

This permission applies only to the isolated validation checkout, never to the user's unrelated workspace.

## 6. Fresh default gate

After section 5 ends with a clean validation checkout, run the complete default gate:

```powershell
./scripts/verify.ps1
```

Do not substitute individual commands for this gate.

Record fresh results for:

- architecture boundaries;
- architecture guard fixtures;
- simulator product static isolation;
- FFmpeg pure suite and exact count;
- analyzer adapter/policy pure suite and exact count;
- native artifact guard fixtures;
- ArkUI migration/static guard;
- persistence regression;
- HTTP range/System probe regression;
- network media list/cache/lifecycle regression;
- MPV event-mapping regression;
- actual Hvigor Hypium execution and exact count;
- Debug/Release HAR builds;
- Debug/Release default HAP builds;
- exact AArch64 production native-library/ABI audit;
- final verifier completion marker.

Specific regressions that must be exercised by the default gate:

- desktop Loader/cache harness reaches its normal completion marker;
- target-specific `entry/AnalysisComposition` no longer breaks that desktop harness;
- queued Loader job waits for failed native setup's late cleanup;
- cancelled analysis cannot publish late partial metadata;
- opened test readers/sources close;
- media/cache fingerprint is not used as SFTP host-key override.

If `scripts/verify.ps1` fails, STOP and report exact evidence. Do not fix it.

## 7. Simulator -> immediate default isolation gate

Only after section 6 fully passes:

```powershell
./scripts/verify-simulator.ps1
```

Verify the simulator artifact/ABI/native whitelist requirements from the runbook.

Immediately afterward, without a manual `ohpm install`, run:

```powershell
./scripts/verify.ps1
```

The immediate post-simulator default gate must pass.

If simulator verification or the immediate default rerun fails, STOP.

If a dependency-management step inside the official scripts again causes the exact proven LF→CRLF-only lockfile drift, the same section 5 self-heal rule may be applied only after the script finishes and only if the task/runbook does not require inspecting that dirty state as a failure itself. Record it explicitly. Any semantic drift still requires STOP.

## 8. Phase 3 policy validation

After build gates pass, execute every achievable case in `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`.

Fresh evidence must distinguish pure/static/build/runtime scopes.

### Probe policy

Verify:

- LIST System COMPLETE -> no FFmpeg call;
- LIST System incomplete/unusable -> FFmpeg controlled fallback;
- DETAIL FFmpeg COMPLETE -> FFmpeg result;
- DETAIL usable FFmpeg PARTIAL -> keep FFmpeg partial, no System merge;
- DETAIL FFmpeg unusable -> System fallback;
- ADVANCED contract with actual ADVANCED execution where available;
- cancellation does not start a later fallback;
- no field merger.

Do not relabel DETAIL evidence as ADVANCED execution.

### Thumbnail policy

For resolvable file-like remote media verify, where environment permits:

- FFmpeg thumbnail first;
- FFmpeg raw frame -> common WebP encoder/cache;
- natural FFmpeg failure -> existing System fallback;
- both engines unavailable/fail -> no invalid image persisted;
- metadata remains useful when thumbnail generation fails according to contract.

HLS / DASH / LOCAL_DOCUMENT remain System-only.

### SFTP ownership

Verify:

- `MediaSource.fingerprint` is never used as SFTP host-key fingerprint;
- the analysis open path leaves the per-open SFTP trust override empty;
- persisted trust remains `NetworkServerEntry.advancedOptions.sftpFingerprint`;
- WebDAV/SMB/FTP/NFS are not semantically changed by this correction.

## 9. Production flow/runtime

Use the real production Network page/list -> `NetworkMediaLoader` -> `NetworkMediaAnalysisCoordinator` path where the environment permits.

Required cases remain the Phase 3 runbook cases, including:

- WebDAV H.264/AAC MP4;
- WebDAV HEVC/MKV;
- duration/width/height;
- `metadataEngine`;
- `thumbnailEngine`;
- WebP persistence;
- cache reopen;
- natural thumbnail fallback;
- both-thumbnail-engines-unavailable behavior;
- navigate-away/refresh/stale-generation rejection;
- proxy/source cleanup;
- 20-cycle lifecycle;
- HLS/DASH System-only;
- LOCAL_DOCUMENT System-only.

If a required simulator/device is genuinely unavailable, classify affected runtime items as BLOCKED or NOT RUN exactly as the runbook defines. Do not promote pure/static evidence into runtime PASS.

Do not alter unrelated local services/workspaces just to manufacture runtime evidence.

## 10. Security

Inspect fresh committed evidence/logs for leakage of:

- Authorization;
- Cookie;
- passwords/private credentials;
- proxy token;
- sensitive full upstream URL/path;
- signing material.

Production analysis logs should expose only safe analysis fields such as:

- `metadataEngine`;
- `thumbnailEngine`;
- `thumbnailPlan`.

Sanitize evidence before commit.

## 11. Performance exclusion

This is functional validation only.

Do not collect or interpret System-vs-FFmpeg:

- median/p95 or latency ranking;
- throughput ranking;
- CPU/GPU ranking;
- memory-efficiency ranking;
- power/thermal conclusions.

x86 simulator evidence must not be used for performance policy.

Performance remains deferred to real arm64 hardware.

## 12. Stop conditions

STOP immediately when:

- source/HEAD safety check fails;
- dependency installation fails;
- post-install drift is not strictly proven EOL-only under section 5;
- EOL restore fails to return the isolated validation checkout to clean state;
- `scripts/verify.ps1` fails;
- simulator verification fails;
- immediate post-simulator default verification fails;
- policy/fallback behavior violates the contract;
- cancellation/stale-generation behavior violates the contract;
- WebP/cache behavior regresses;
- production Loader/cache/lifecycle behavior regresses;
- any source/test-infrastructure edit would be required.

Do not fix a stopped failure.

## 13. Report and evidence

Update:

`docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

Add fresh sanitized evidence under a new subdirectory:

`test-lab/analyzer-policy/phase3/`

The report must record:

- task ID;
- implementation source SHA;
- actual validation checkout SHA;
- isolated checkout path/worktree identity;
- proof the unrelated user workspace was left untouched;
- exact commands and exit codes;
- any EOL-only normalization proof/restore;
- actual pure/Hypium counts;
- build/artifact/ABI results;
- functional/runtime results;
- environment/device availability;
- failures and root-cause assessment when supported;
- every NOT RUN / NOT APPLICABLE / BLOCKED item;
- confirmation no protected production/test/build/semantic-lockfile content was committed.

Only actually executed items may be PASS.

## 14. Remote handoff is mandatory

The run is not complete merely because local commands finished.

After testing:

1. update only the authorized report/evidence;
2. commit only those report/evidence paths;
3. fetch the remote validation branch;
4. if the remote advanced unexpectedly outside the task's allowed operational paths, STOP before rewriting history;
5. push the evidence commit to `feat/ffmpeg-analyzer-policy-phase3` without force;
6. fetch again and verify the evidence commit is contained in the remote branch;
7. report the remotely visible evidence commit SHA.

If push is unavailable/rejected, conclude:

`BLOCKED — EVIDENCE NOT PUSHED`

and provide the local evidence commit SHA. Do not claim GPT can review a local-only run.

## 15. Final decision

Use one precise conclusion supported by evidence:

- `READY FOR PHASE 3 ARCHITECTURE ACCEPTANCE`;
- `FAIL — BUILD`;
- `FAIL — POLICY`;
- `FAIL — NETWORK MEDIA LOADER`;
- `FAIL — THUMBNAIL PIPELINE`;
- `FAIL — CANCELLATION/CLEANUP`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise FAIL/BLOCKED category justified by evidence.

Do not merge and do not start the next implementation phase.

After remote evidence is verified visible, stop and return the evidence commit SHA to GPT.
