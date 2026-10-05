# Codex Validation Task

> State: READY
> Task ID: phase3-rerun-3e-thumbnail-metadata-separation
> Repository: `baozi510/Linkora`
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Validation source SHA: `198854ed2e6c14378e692f86852a78656d0aebe8`
> Role: TEST / EVIDENCE / REPORT ONLY

## 1. Authority and source safety

This file is the only execution authority for this round.

Do not reuse PASS results, local modifications, assumptions or execution shortcuts from earlier runs.

Use an isolated validation clone/worktree and leave any unrelated dirty user workspace untouched.

Fetch/check out the current remote `feat/ffmpeg-analyzer-policy-phase3`.

Before testing:

1. confirm the isolated checkout is clean;
2. record actual checkout HEAD;
3. confirm `198854ed2e6c14378e692f86852a78656d0aebe8` is an ancestor of HEAD;
4. run:

```powershell
git diff --name-only 198854ed2e6c14378e692f86852a78656d0aebe8..HEAD
```

The only permitted pre-test drift after the validation source SHA is:

```text
docs/CODEX_VALIDATION_TASK.md
```

If any other path appears, STOP and report the mismatch.

Record both validation source SHA and actual checkout SHA. Do not modify this task file.

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

All previous runs are historical evidence only. Rerun every required gate fresh.

## 3. Reviewed change for this round

Previous evidence commit:

`a21c658eca78cefa5e9a330ca17ad3722e55ac84`

Previous conclusion:

`FAIL — NETWORK MEDIA LOADER`

The prior failing row seeded complete cached metadata `[12000, 1920, 1080]`, then expected a corrupt-thumbnail retry to replace duration with `9000`.

GPT independently reviewed the production contract and the older pre-Phase-3 Loader:

- old coupled `NetworkMediaProbe` THUMBNAIL results were still passed through Loader `updateInfo()`, so a thumbnail retry could incidentally refresh metadata;
- Phase 3 intentionally separates metadata probing from thumbnail extraction;
- current `NetworkMediaAnalysisCoordinator` starts from metadata hints and only performs LIST metadata probing when duration/width/height are incomplete;
- complete cached metadata therefore remains authoritative during thumbnail-only repair.

Reviewed test-infrastructure change in `198854ed2e6c14378e692f86852a78656d0aebe8`:

1. complete cached metadata retry cases now explicitly assert:
   - `thumbnail` mode;
   - cached duration/dimensions remain unchanged;
   - persistent metadata remains unchanged even if a thumbnail-only mock returns stray metadata-like numbers;
2. separate incomplete-cache cases now explicitly assert:
   - metadata refresh path (`both` in this desktop coordinator mock);
   - complete refresh can update duration/dimensions;
   - partial refresh fills missing duration while preserving known dimensions;
   - refreshed values persist.

No production ArkTS/C/C++ source changed in this review.

## 4. Codex permissions

Allowed:

- isolated validation clone/worktree;
- pinned submodule/dependency preparation required by the existing runbook;
- builds/tests/simulator/device execution where available;
- strict EOL-only self-heal in section 5;
- sanitized evidence collection;
- update `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`;
- add one fresh evidence subdirectory under `test-lab/analyzer-policy/phase3/`;
- commit/push only authorized report/evidence changes after testing.

Forbidden:

- production ArkTS/C/C++ edits;
- test-script/test-expectation edits;
- package/build/CMake/profile edits;
- semantic lockfile edits;
- architecture/policy changes;
- retrying a stopped gate after patching/instrumenting it;
- gate bypass;
- modifying this task file;
- merge or force-push.

A stopped gate that needs any implementation/test-infrastructure change returns to GPT.

## 5. Dependency install and EOL-only self-heal

Start from a clean isolated checkout.

Initialize pinned submodules/dependency inputs as required by the existing runbook, preserving provenance.

Run exactly one normal:

```powershell
ohpm install
```

If tracked state stays clean, continue.

If dirty, the only self-healable tracked paths are:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

For every changed allowlisted lockfile, before restoring, freshly prove:

- no other tracked path changed;
- `git hash-object --path=<path> <path>` equals `git rev-parse HEAD:<path>`;
- CRLF→LF normalized worktree bytes exactly equal HEAD bytes;
- line content is equal;
- no dependency/version/checksum/graph/comment/content change exists;
- `git diff --exit-code -- <allowlisted locks>` has no semantic diff;
- EOL evidence matches the known LF-index / CRLF-worktree / `text eol=lf` case when applicable.

If any proof fails: STOP, do not restore.

If all pass, restore only the affected allowlisted lockfiles in the isolated validation checkout:

```powershell
git restore --source=HEAD --worktree -- <affected lockfiles>
```

Then confirm `git status --porcelain=v1` is empty.

Record proof and restore as evidence. Do not commit restored locks. Do not rerun `ohpm install` solely because of this approved EOL-only restore.

## 6. Full default verifier

After dependency preparation returns the isolated checkout to clean state, run the complete unmodified verifier exactly once:

```powershell
./scripts/verify.ps1
```

Record every reached gate fresh, including exact counts/results for:

- architecture boundary checks;
- architecture fixtures;
- simulator static isolation;
- FFmpeg pure suite;
- analyzer adapter/policy pure suite;
- native artifact fixtures;
- ArkUI migration/static guard;
- persistence;
- HTTP range/System probe;
- network media list/cache/lifecycle;
- MPV event mapping;
- actual Hvigor Hypium;
- Debug/Release HARs;
- Debug/Release default HAP;
- exact AArch64 native-library/ABI audit;
- final completion marker.

### Network-media harness requirements

Freshly verify the whole harness reaches its normal completion marker, including:

- server `titleLabel()` fixture / real `NetworkMediaSourceFactory` path;
- serial/coalesced loading;
- cache/legacy/WebP behavior;
- consumer cancellation/stale result rejection;
- late native setup cleanup serialization;
- cancelled late partial result rejection;
- reader/source closure;
- SFTP fingerprint ownership checks;
- no JPEG fallback on WebP failure;
- **complete cached metadata + missing/corrupt thumbnail -> thumbnail-only retry, metadata unchanged**;
- stray metadata-like numbers from the thumbnail-only mock do not rewrite complete cached metadata;
- **incomplete cached metadata -> metadata refresh path**, including complete and partial refresh cases;
- timeout retry preserves known metadata;
- image-only completion behavior;
- server-deletion cleanup and UI/preview lifecycle tail.

Do not reinterpret a failed assertion. If this gate fails, STOP and preserve exact evidence.

## 7. Simulator and immediate default gate

Only if the full default verifier passes:

```powershell
./scripts/verify-simulator.ps1
```

Validate the simulator dependency/native/ABI whitelist required by the runbook.

Immediately afterward, without a manual `ohpm install`, run:

```powershell
./scripts/verify.ps1
```

The immediate post-simulator default verifier must fully pass.

If official script execution leaves only the exact strictly proven EOL-only lockfile drift, the section 5 rule may be used only where it does not invalidate a script's own required check. Record it.

Any failure -> STOP.

## 8. Phase 3 policy validation

After build gates pass, execute every achievable case in `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`.

Keep pure/static/build/runtime evidence distinct.

Metadata policy requirements:

- LIST System COMPLETE -> no FFmpeg call;
- LIST System incomplete/unusable -> controlled FFmpeg fallback;
- DETAIL FFmpeg COMPLETE;
- DETAIL usable FFmpeg PARTIAL retained without System merge;
- DETAIL FFmpeg unusable -> System fallback;
- actual ADVANCED execution where available;
- cancellation does not start a later fallback;
- no System+FFmpeg field merger.

Thumbnail requirements for resolvable file-like remote media where environment permits:

- FFmpeg first;
- raw FFmpeg frame -> common WebP encoder/cache;
- natural FFmpeg failure -> System fallback;
- both engines unavailable/fail -> no invalid thumbnail persisted;
- useful metadata survives thumbnail failure according to contract.

HLS / DASH / LOCAL_DOCUMENT remain System-only.

SFTP ownership requirements:

- media/cache fingerprint never becomes SFTP host-key trust;
- analysis per-open trust override remains empty;
- persisted trust remains `NetworkServerEntry.advancedOptions.sftpFingerprint`;
- no unintended WebDAV/SMB/FTP/NFS semantic change.

## 9. Production/runtime cases

Where environment permits, use the real production path:

`Network page/list -> NetworkMediaLoader -> NetworkMediaAnalysisCoordinator`

Required runbook cases include:

- WebDAV H.264/AAC MP4;
- WebDAV HEVC/MKV;
- duration/width/height and engine identities;
- FFmpeg-first thumbnail -> WebP persistence;
- cache reopen;
- natural System thumbnail fallback;
- both engines unavailable;
- navigate-away/refresh/stale-generation rejection;
- proxy/source cleanup;
- 20-cycle lifecycle;
- HLS/DASH System-only;
- LOCAL_DOCUMENT System-only.

If target/services are genuinely unavailable, classify affected cases accurately as BLOCKED/NOT RUN. Do not turn desktop mocks into production runtime PASS.

## 10. Security and performance boundaries

Review fresh evidence/logs for secrets including Authorization/Cookie values, passwords/private credentials, proxy tokens, sensitive full upstream URLs/paths, signing/private-key material.

Do not collect or interpret x86/simulator System-vs-FFmpeg performance ranking, median/p95, throughput, CPU/GPU, memory efficiency, power or thermal conclusions.

Performance policy remains deferred to real arm64 hardware.

## 11. Stop conditions

STOP immediately if:

- source/HEAD safety fails;
- dependency preparation fails;
- post-install drift is not strictly proven EOL-only;
- approved EOL restore fails to return checkout clean;
- default verifier fails;
- simulator verifier fails;
- immediate post-simulator default verifier fails;
- metadata/thumbnail separation contract fails;
- policy/fallback/cancellation contract fails;
- WebP/cache/Loader/lifecycle behavior regresses;
- a source/test-infrastructure edit is required.

Do not patch or retry a stopped gate.

## 12. Report/evidence and remote handoff

Update only:

`docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

and one new sanitized directory under:

`test-lab/analyzer-policy/phase3/`

Report:

- Task ID;
- validation source SHA `198854ed2e6c14378e692f86852a78656d0aebe8`;
- actual checkout SHA;
- isolated checkout identity;
- proof unrelated user workspace untouched;
- commands and exit codes;
- EOL proof/restore if used;
- fresh test counts and gate results;
- build/HAR/HAP/ABI results;
- functional/runtime scope;
- precise failures/root cause only when supported;
- all NOT RUN/NOT APPLICABLE/BLOCKED;
- protected-file/submodule audit;
- security review.

Only freshly executed items may be PASS.

After testing:

1. commit only authorized report/evidence paths;
2. fetch remote branch and verify no unexpected protected drift;
3. push without force to `feat/ffmpeg-analyzer-policy-phase3`;
4. fetch again;
5. prove the evidence commit is contained in remote;
6. return the remotely visible evidence SHA.

If push fails: `BLOCKED — EVIDENCE NOT PUSHED`.

## 13. Final decision

Use one precise evidence-backed conclusion:

- `READY FOR PHASE 3 ARCHITECTURE ACCEPTANCE`;
- `FAIL — BUILD`;
- `FAIL — POLICY`;
- `FAIL — NETWORK MEDIA LOADER`;
- `FAIL — THUMBNAIL PIPELINE`;
- `FAIL — CANCELLATION/CLEANUP`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise supported FAIL/BLOCKED category.

Do not merge or start the next phase.

After evidence is remotely verified, stop and hand the evidence SHA back to GPT.
