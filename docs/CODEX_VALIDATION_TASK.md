# Codex Validation Task

> State: READY
> Task ID: phase3-rerun-3f-probe-wrapper-forwarding
> Repository: `baozi510/Linkora`
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Validation source SHA: `0d87488dc92f3cd8bc77319ec61197520695597e`
> Role: TEST / EVIDENCE / REPORT ONLY

## 1. Authority and source safety

This file is the only execution authority for this round.

Do not reuse PASS results, local modifications, assumptions or shortcuts from any earlier run.

Use an isolated validation clone/worktree. Leave any unrelated dirty user workspace untouched.

Fetch/check out the current remote `feat/ffmpeg-analyzer-policy-phase3`.

Before testing:

1. confirm the isolated checkout is clean;
2. record actual checkout HEAD;
3. confirm `0d87488dc92f3cd8bc77319ec61197520695597e` is an ancestor of HEAD;
4. run:

```powershell
git diff --name-only 0d87488dc92f3cd8bc77319ec61197520695597e..HEAD
```

The only permitted pre-test drift after the validation source SHA is:

```text
docs/CODEX_VALIDATION_TASK.md
```

If any other path appears, STOP.

Record validation source SHA and actual checkout SHA. Do not modify this task file.

## 2. Required reading

Read completely in this order:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md`
6. `docs/SESSION_HANDOFF.md` — CURRENT STATE first
7. `docs/CODEX_VALIDATION_TASK.md`
8. `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`
9. `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

All earlier PASS/FAIL/BLOCKED results are historical only. Execute fresh.

## 3. Reviewed change

Previous evidence commit:

`2a9a955a4cdc3da461d44f3eac0147862e06771a`

Previous conclusion:

`FAIL — NETWORK MEDIA LOADER`

The phase3-rerun-3e failure occurred because a temporary desktop `Probe.prototype.inspect` wrapper did not forward `source`, `headers` or `options`.

The coordinator mock supplied `mode: 'thumbnail'`, but the wrapper invoked `normalInspect.call(this)`; original `Probe.inspect` therefore received its default `options = {}` and recorded `both`.

GPT independently reviewed the whole harness and found the same forwarding defect in three temporary wrappers:

- deadline/cancel partial wrapper;
- complete-cache thumbnail retry wrapper;
- timed thumbnail retry wrapper.

Validation source `0d87488dc92f3cd8bc77319ec61197520695597e` corrects all three wrappers so they transparently forward:

`source, headers, options`

while retaining only their intended injected partial/result behavior.

No production ArkTS/C/C++ source changed.

Strict assertions remain in place.

## 4. Permissions

Allowed:

- isolated validation clone/worktree;
- pinned submodule/dependency preparation required by the runbook;
- build/test/simulator/device execution where supported;
- strict EOL-only lockfile self-heal in section 5;
- sanitized evidence;
- update `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`;
- add one new evidence subdirectory under `test-lab/analyzer-policy/phase3/`;
- commit/push only authorized report/evidence.

Forbidden:

- production source edits;
- test-script/test-expectation edits;
- build/profile/package/CMake edits;
- semantic lockfile edits;
- architecture/policy changes;
- retry after patching/instrumenting a stopped gate;
- gate bypass;
- task-file edits;
- merge/force-push.

Any required source/test-infrastructure fix returns to GPT.

## 5. Dependency install and EOL-only self-heal

Start clean.

Initialize pinned submodules/dependency inputs according to the existing runbook and record provenance.

Run exactly one normal:

```powershell
ohpm install
```

If tracked state stays clean, continue.

If dirty, the only self-healable paths are:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

Before restoring, freshly prove for every affected path:

- no other tracked path changed;
- `git hash-object --path=<path> <path>` equals `git rev-parse HEAD:<path>`;
- CRLF→LF normalized worktree bytes equal HEAD bytes;
- line content equal;
- no dependency/version/checksum/graph/comment/content change;
- `git diff --exit-code -- <locks>` has no semantic diff;
- EOL evidence matches the known LF-index/CRLF-worktree/`text eol=lf` case where applicable.

If any proof fails: STOP and do not restore.

If all pass:

```powershell
git restore --source=HEAD --worktree -- <affected lockfiles>
git status --porcelain=v1
```

Status must be empty.

Record proof/restore. Do not commit locks and do not rerun `ohpm install` only because of the approved EOL restore.

## 6. Full default verifier

After dependency preparation returns clean, run the complete unmodified verifier exactly once:

```powershell
./scripts/verify.ps1
```

Record every fresh reached gate, including counts/results for:

- architecture boundaries/fixtures;
- simulator static isolation;
- FFmpeg pure suite;
- analyzer adapter/policy pure suite;
- native-artifact fixtures;
- ArkUI guard;
- persistence;
- HTTP range/System probe;
- network media list/cache/lifecycle;
- MPV mapping;
- actual Hvigor Hypium;
- Debug/Release HARs;
- Debug/Release default HAP;
- exact AArch64 native set/ABI audit;
- final completion marker.

### Network-media regression requirements

The full harness must reach normal completion and freshly verify:

- real `NetworkMediaSourceFactory` path and server `titleLabel()` fixture;
- serial/coalesced loading;
- cache/legacy/WebP behavior;
- cancellation/stale result rejection;
- deadline/cancel partial wrapper preserves real caller `options/onMetadata` while injecting partial behavior;
- late native setup cleanup serialization;
- reader/source closure;
- SFTP trust ownership checks;
- no JPEG fallback after WebP failure;
- complete cached metadata + missing/corrupt thumbnail -> `thumbnail` mode;
- complete cached metadata is not overwritten by stray thumbnail-only result fields;
- incomplete cached metadata -> metadata refresh path;
- complete and partial metadata refresh values persist correctly;
- timed thumbnail retry wrapper preserves real caller arguments while injecting partial/zero-result behavior;
- timeout retry preserves known metadata;
- image-only behavior;
- server deletion cleanup;
- UI/preview lifecycle tail.

Do not reinterpret a failure. Any verifier failure -> STOP.

## 7. Simulator and immediate default verification

Only if section 6 fully passes:

```powershell
./scripts/verify-simulator.ps1
```

Then immediately, without manual `ohpm install`:

```powershell
./scripts/verify.ps1
```

Both must fully pass.

Apply the strict EOL-only self-heal only if the exact proven case recurs and doing so does not invalidate an official script's own required check.

Any failure -> STOP.

## 8. Phase 3 functional policy

After build gates pass, execute every achievable case in `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`.

Keep pure/static/build/runtime scopes distinct.

Verify fresh:

- LIST System COMPLETE -> no FFmpeg;
- LIST incomplete/unusable -> controlled FFmpeg fallback;
- DETAIL FFmpeg COMPLETE;
- DETAIL usable PARTIAL retained without System merge;
- DETAIL unusable -> System fallback;
- actual ADVANCED execution where available;
- cancellation starts no later fallback;
- no field merger;
- file-like remote thumbnail FFmpeg first;
- FFmpeg raw frame -> common WebP;
- natural FFmpeg thumbnail failure -> System fallback where safely achievable;
- both engines unavailable -> no invalid thumbnail;
- HLS/DASH/LOCAL_DOCUMENT System-only;
- SFTP media/cache fingerprint never used as host-key trust;
- per-open analysis SFTP trust override empty;
- persisted SFTP trust remains server advanced option.

## 9. Production/runtime scope

Where environment permits use:

`Network page/list -> NetworkMediaLoader -> NetworkMediaAnalysisCoordinator`

Required runbook cases include WebDAV MP4, HEVC/MKV, metadata/thumbnail engines, WebP persistence/cache reopen, fallback, both unavailable, cancellation/refresh/stale generation, cleanup, 20-cycle lifecycle, HLS/DASH/local System-only.

If target/services are unavailable, accurately report BLOCKED/NOT RUN. Never promote desktop mocks to production runtime PASS.

## 10. Security/performance boundaries

Sanitize evidence for Authorization/Cookie values, credentials, proxy tokens, sensitive upstream URLs/paths and signing/private-key material.

Do not collect/interpret x86/simulator System-vs-FFmpeg performance rankings, p50/p95, throughput, CPU/GPU, memory efficiency, power or thermal data.

Performance remains deferred to real arm64 hardware.

## 11. Stop conditions

STOP immediately if:

- source/HEAD safety fails;
- dependency preparation fails;
- lock drift is not strictly EOL-only;
- approved restore does not return clean;
- default verifier fails;
- simulator verifier fails;
- immediate default verifier fails;
- wrapper-forwarding regression or metadata/thumbnail separation fails;
- policy/cancellation/WebP/cache/Loader/lifecycle behavior regresses;
- any implementation/test-infrastructure edit would be required.

Do not patch/retry a stopped gate.

## 12. Report/evidence and remote handoff

Update only:

`docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

and one fresh sanitized directory under:

`test-lab/analyzer-policy/phase3/`

Record task/source/checkout SHAs, isolated checkout identity, untouched user-workspace proof, commands/exits, EOL proof if used, fresh counts, all build/runtime results, exact failures, NOT RUN/BLOCKED, protected-file/submodule audit and security review.

Only freshly executed items may be PASS.

Then:

1. commit only authorized report/evidence;
2. fetch remote and reject unexpected protected drift;
3. push without force to `feat/ffmpeg-analyzer-policy-phase3`;
4. fetch again;
5. prove evidence commit is contained in remote;
6. return remotely visible evidence SHA.

Push failure -> `BLOCKED — EVIDENCE NOT PUSHED`.

## 13. Final decision

Use one precise evidence-supported result:

- `READY FOR PHASE 3 ARCHITECTURE ACCEPTANCE`;
- `FAIL — BUILD`;
- `FAIL — POLICY`;
- `FAIL — NETWORK MEDIA LOADER`;
- `FAIL — THUMBNAIL PIPELINE`;
- `FAIL — CANCELLATION/CLEANUP`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise supported FAIL/BLOCKED category.

Do not merge/start next phase.

After remote evidence is verified, stop and return the evidence SHA to GPT.
