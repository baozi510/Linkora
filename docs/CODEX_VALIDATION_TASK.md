# Codex Validation Task

> State: READY
> Task ID: phase3-rerun-3d-server-fixture
> Repository: `baozi510/Linkora`
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Validation source SHA: `cd12a3869db8a8dbe84730c6f8a118faf73f33e0`
> Role: TEST / EVIDENCE / REPORT ONLY

## 1. Authority and start rule

This file is the only execution authority for this round.

Do not reuse instructions, PASS results, assumptions or local modifications from any earlier Codex run.

Use an isolated validation clone/worktree. Leave any unrelated dirty user workspace untouched.

Fetch and check out the current remote branch:

`feat/ffmpeg-analyzer-policy-phase3`

Before testing:

1. confirm the isolated checkout is clean;
2. record the actual checkout HEAD;
3. confirm `cd12a3869db8a8dbe84730c6f8a118faf73f33e0` is an ancestor of HEAD;
4. run:

```powershell
git diff --name-only cd12a3869db8a8dbe84730c6f8a118faf73f33e0..HEAD
```

Before testing begins, the only permitted path after the validation source SHA is:

```text
docs/CODEX_VALIDATION_TASK.md
```

If any other path differs after the validation source SHA, STOP and report the mismatch.

Record both the validation source SHA and actual checkout SHA.

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

The previous `phase3-rerun-3c-eol-self-heal` result is historical evidence only. Its PASS items must be rerun fresh.

## 3. Reviewed change for this round

Previous remotely visible evidence:

`9f27f20459b4bc2060eff4e20e336a38da6e1aad`

Previous fresh failure:

`FAIL — NETWORK MEDIA LOADER`

Independent GPT review confirmed a desktop fixture/API mismatch:

- production `NetworkMediaSourceFactory.fromEntry()` calls `server.titleLabel()`;
- real `NetworkServerEntry` implements `titleLabel()`;
- the desktop `check-network-media-list.cjs` server fixture omitted that method;
- Loader calls the real factory before the mocked analysis coordinator, so the malformed fixture failed before `analysis.inspect()`;
- Loader's catch converted that fixture error into the observed null path / probe count 0.

Reviewed correction in validation source `cd12a3869db8a8dbe84730c6f8a118faf73f33e0`:

```text
server fixture:
{id, updatedAt, protocol}
    ->
{id, updatedAt, protocol, titleLabel: () => 'test'}
```

The real `NetworkMediaSourceFactory` remains in the harness. The existing `calls === 1` expectation is unchanged.

No production analyzer, storage, playback, WebP, benchmark or Direct I/O policy changed.

## 4. Codex permissions

Allowed:

- create/reuse an isolated validation clone/worktree;
- initialize pinned submodules/dependency inputs as required by the existing runbook;
- run builds/tests;
- install/run supported simulator/device where the runbook requires it;
- perform the narrowly defined EOL-only self-heal in section 5;
- collect sanitized evidence;
- update `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`;
- add a new evidence subdirectory under `test-lab/analyzer-policy/phase3/`;
- commit and push only the authorized report/evidence at the end.

Forbidden:

- production ArkTS/C/C++ edits;
- test-script or test-expectation edits;
- package manifest/build-profile/CMake edits;
- semantic lockfile edits;
- architecture/policy changes;
- gate bypasses;
- modifying this task file;
- merging;
- force-pushing.

If any stopped gate requires a source/test-infrastructure change, STOP and hand the evidence back to GPT.

## 5. Dependency install and approved EOL-only self-heal

Start from a clean isolated validation checkout.

Run:

```powershell
ohpm install
```

If the checkout remains clean, continue.

If it becomes dirty, the only self-healable tracked paths are exactly:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

Before restoring any file, prove for every affected path:

1. no additional tracked path changed;
2. `git hash-object --path=<path> <path>` equals `git rev-parse HEAD:<path>`;
3. CRLF→LF normalized worktree bytes equal HEAD bytes;
4. line content is equal;
5. no dependency/version/checksum/graph/comment/content change exists;
6. `git diff --exit-code -- <the lockfiles>` has no semantic diff;
7. EOL evidence matches the known LF-index / CRLF-worktree / `text eol=lf` case when applicable.

If any check fails, STOP. Do not restore.

Only after all checks pass, restore only the affected allowlisted lockfiles in the isolated checkout:

```powershell
git restore --source=HEAD --worktree -- <affected lockfiles>
```

Then prove `git status --porcelain=v1` is clean.

Record the proof and restore in fresh evidence. Do not commit those restored files. Do not rerun `ohpm install` merely because EOL-only files were restored.

## 6. Full default verifier

After dependency preparation ends clean, run the full unmodified gate exactly once:

```powershell
./scripts/verify.ps1
```

Freshly record all reached gates, including:

- architecture boundary checks;
- architecture fixtures and exact count;
- simulator static isolation;
- FFmpeg pure suite and exact count;
- analyzer adapter/policy pure suite and exact count;
- native-artifact fixtures and exact count;
- ArkUI migration/static guard;
- persistence regression;
- HTTP range/System-probe regression;
- network-media list/cache/lifecycle regression;
- MPV event-mapping regression;
- actual Hvigor Hypium and exact count;
- Debug/Release HAR builds;
- Debug/Release default HAP builds;
- exact AArch64 native-library/ABI audit;
- final verifier completion marker.

### Required network-media regression checks

The network-media-list harness must freshly prove:

- the corrected server fixture reaches analysis instead of failing in `NetworkMediaSourceFactory`;
- the existing `calls === 1` assertion passes;
- serial/coalesced Loader behavior passes;
- metadata/cache/WebP behavior passes;
- cancellation/stale result behavior passes;
- late native setup cleanup blocks the queued Loader job until cleanup settles;
- cancelled analysis cannot publish a late partial result;
- opened readers/sources are closed;
- SFTP media/cache fingerprint is not used as host-key trust.

If the verifier fails at any point, STOP. Do not retry, patch or bypass the failure.

## 7. Simulator -> immediate default gate

Only if section 6 fully passes:

```powershell
./scripts/verify-simulator.ps1
```

Validate simulator ABI/native whitelist and dependency restoration according to the existing runbook.

Immediately afterward, without a manual `ohpm install`, run:

```powershell
./scripts/verify.ps1
```

The immediate default verifier must fully pass.

If an official script causes only the same strictly proven EOL-only lockfile drift, apply section 5 only where doing so does not invalidate the script's own required checks. Record it explicitly.

If simulator or immediate-default verification fails, STOP.

## 8. Phase 3 functional policy

After all build gates pass, execute every achievable case in `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`.

Freshly distinguish pure/static/build/runtime evidence.

### Metadata policy

Verify:

- LIST System COMPLETE -> no FFmpeg invocation;
- LIST System incomplete/unusable -> controlled FFmpeg fallback;
- DETAIL FFmpeg COMPLETE;
- DETAIL usable FFmpeg PARTIAL -> retained, no System field merge;
- DETAIL FFmpeg unusable -> System fallback;
- ADVANCED with actual ADVANCED execution where available;
- cancellation does not start a later fallback;
- no System+FFmpeg field merger.

Do not count DETAIL as ADVANCED execution.

### Thumbnail policy

For resolvable file-like remote media verify, where environment permits:

- FFmpeg first;
- raw FFmpeg frame -> common WebP encoder/cache;
- natural FFmpeg failure -> existing System fallback;
- both engines unavailable/fail -> no invalid thumbnail persisted;
- useful metadata survives thumbnail failure where the contract permits it.

HLS / DASH / LOCAL_DOCUMENT remain System-only.

### SFTP trust ownership

Verify:

- `MediaSource.fingerprint` never becomes an SFTP host-key fingerprint;
- analysis uses an empty per-open trust override;
- persisted trust remains `NetworkServerEntry.advancedOptions.sftpFingerprint`;
- no unintended WebDAV/SMB/FTP/NFS semantic change.

## 9. Production/runtime cases

Where the available environment permits, use the real production path:

`Network page/list -> NetworkMediaLoader -> NetworkMediaAnalysisCoordinator`

Required cases remain those in the Phase 3 runbook, including:

- WebDAV H.264/AAC MP4;
- WebDAV HEVC/MKV;
- duration/width/height;
- `metadataEngine`;
- `thumbnailEngine`;
- persistent WebP;
- cache reopen;
- natural thumbnail fallback;
- both-thumbnail-engines-unavailable behavior;
- navigate-away / refresh / stale-generation rejection;
- proxy/source cleanup;
- 20-cycle lifecycle;
- HLS/DASH System-only;
- LOCAL_DOCUMENT System-only.

If simulator/device/environment is genuinely unavailable, mark affected runtime items BLOCKED or NOT RUN exactly as supported. Do not promote pure/static evidence to runtime PASS.

## 10. Security

Review fresh evidence/logs for leakage of:

- Authorization values;
- Cookie values;
- passwords/private credentials;
- proxy tokens;
- sensitive full upstream URLs/paths;
- signing/private-key material.

Production analysis logging should remain limited to safe diagnostics such as `metadataEngine`, `thumbnailEngine` and `thumbnailPlan`.

Sanitize evidence before commit.

## 11. Performance exclusion

Do not collect or interpret System-vs-FFmpeg performance ranking on x86/simulator.

No latency median/p95 ranking, throughput ranking, CPU/GPU ranking, memory-efficiency ranking, power or thermal conclusions.

Performance policy remains deferred to real arm64 hardware.

## 12. Stop conditions

STOP immediately if:

- source/HEAD safety check fails;
- dependency install fails;
- post-install drift is not strictly proven EOL-only;
- EOL restore does not return the isolated checkout to clean state;
- full default verifier fails;
- simulator verifier fails;
- immediate post-simulator default verifier fails;
- policy/fallback order violates the contract;
- cancellation/stale-generation behavior violates the contract;
- WebP/cache behavior regresses;
- production Loader/cache/lifecycle behavior regresses;
- any production/test-infrastructure edit would be required.

Do not patch the stopped gate.

## 13. Report and evidence

Update:

`docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

Add a new sanitized evidence directory under:

`test-lab/analyzer-policy/phase3/`

The report must record:

- Task ID;
- validation source SHA `cd12a3869db8a8dbe84730c6f8a118faf73f33e0`;
- actual checkout SHA;
- isolated checkout identity/path;
- proof unrelated dirty user workspace was untouched;
- exact commands/exit codes;
- EOL self-heal proof if used;
- all fresh test counts;
- build/HAR/HAP/ABI results;
- functional/runtime results;
- environment/device availability;
- precise failure/root-cause evidence where supported;
- every NOT RUN / NOT APPLICABLE / BLOCKED item;
- protected-file audit;
- security evidence review.

Only freshly executed items may be PASS.

## 14. Remote handoff

A run is not complete until evidence is remotely visible.

After testing:

1. update only the authorized report/evidence paths;
2. commit only those paths;
3. fetch the remote branch;
4. verify no unexpected source/test/build drift appeared;
5. push without force to `feat/ffmpeg-analyzer-policy-phase3`;
6. fetch again;
7. prove the evidence commit is contained in the remote branch;
8. report the remotely visible evidence commit SHA.

If push fails, conclude:

`BLOCKED — EVIDENCE NOT PUSHED`

and provide the local evidence SHA.

## 15. Final decision

Use one precise evidence-backed conclusion:

- `READY FOR PHASE 3 ARCHITECTURE ACCEPTANCE`;
- `FAIL — BUILD`;
- `FAIL — POLICY`;
- `FAIL — NETWORK MEDIA LOADER`;
- `FAIL — THUMBNAIL PIPELINE`;
- `FAIL — CANCELLATION/CLEANUP`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise FAIL/BLOCKED category supported by evidence.

Do not merge and do not start the next implementation phase.

After remote evidence is verified, stop and return the evidence commit SHA to GPT.
