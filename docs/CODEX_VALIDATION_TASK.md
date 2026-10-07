# Codex Validation Task

> State: READY
> Task ID: phase8b-mate60-system-mpv-capability-matrix
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Phase 8A accepted evidence: `e894775c0bc81b39a6217a0a0516cec46158b82b`
> Phase 8B source: `9a60eca55164a5da604bfb48f5f08f18b2161f63`
> Role: BUILD / FUNCTIONAL CAPABILITY TEST / EVIDENCE / REPORT ONLY

## 1. Purpose

Collect the real-Mate60 System-vs-MPV **functional media capability matrix** using the permanent 59-case corpus.

This phase tests:

- container support;
- video codec/profile representatives;
- audio codec representatives;
- basic stream-manifest support;
- clean failure/release behavior.

This phase does **not** test UI polish, fullscreen layout, display-mode selector, performance ranking, Auto policy or advanced output semantics.

Read completely:

- `docs/PLAYBACK_PHASE8B_RUNBOOK.md`
- `test-lab/media-compatibility/cases.json`

The manifest is the matrix authority.

## 2. Source safety

Use a fresh isolated checkout, for example:

`D:\Linkora-playback-phase8b`

Do not mutate the user's existing workspace.

Before execution:

1. fetch `feat/playback-capability-phase8`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove tracked checkout clean;
5. prove `9a60eca55164a5da604bfb48f5f08f18b2161f63` is an ancestor of HEAD;
6. prove accepted Phase 8A evidence `e894775c0bc81b39a6217a0a0516cec46158b82b` is an ancestor of source;
7. run:

```powershell
git diff --name-only 9a60eca55164a5da604bfb48f5f08f18b2161f63..HEAD
```

Only:

```text
docs/CODEX_VALIDATION_TASK.md
```

is permitted.

Anything else => STOP.

Record actual tested checkout SHA separately.

## 3. Required reading

Read completely:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/IMPLEMENTATION_STATUS.md`
4. `docs/SESSION_HANDOFF.md` — CURRENT STATE first
5. `docs/CODEX_VALIDATION_TASK.md`
6. `docs/PLAYBACK_PHASE8B_RUNBOOK.md`
7. `docs/PLAYBACK_PHASE8B_REPORT.md`
8. `test-lab/media-compatibility/README.md`
9. `test-lab/media-compatibility/cases.json`
10. `test-lab/media-compatibility/generate-samples.ps1`
11. `test-lab/media-compatibility/fetch-external-samples.ps1`
12. historical `docs/MEDIA_COMPATIBILITY_REPORT.md`

Historical simulator outcomes are context only and never count as Mate60 results.

## 4. Read-only scope review

Confirm before execution:

- `cases.json` contains exactly 59 unique case IDs;
- every case requires both `system` and `mpv`;
- expected complete result count is 118;
- Tier A/B/C semantics match the Master Plan;
- `scripts/summarize-playback-capability.cjs` rejects unexpected, duplicate and invalid verdict rows;
- Phase 8B source changed no production playback implementation from the accepted Phase 8A functional source;
- no fullscreen-layout experiment remains as a new functional dependency;
- no Auto selector change exists.

Contradiction => STOP. Do not patch.

## 5. Fresh build gate

Run exactly one normal:

```powershell
ohpm install
```

Use the established strict known-lockfile EOL-only proof/restore if Windows normalization occurs.

Then run one fresh:

```powershell
./scripts/verify.ps1
```

Required evidence includes actual fresh:

- architecture fixture count;
- FFmpeg pure count;
- analysis pure count;
- artifact fixture count;
- MPV mapping count;
- Hypium count;
- Debug/Release HAR/HAP;
- both exact-nine AArch64 audits;
- final verifier marker.

Any build/static gate failure:

`FAIL — BUILD`

STOP. Do not patch or retry-after-fix.

## 6. Fresh exact-source signed HAP

After fresh verifier PASS:

- use the already accepted signing-only overlay procedure;
- change signing fields/path only;
- no SDK/module/dependency/ABI/source/build-option change;
- build one fresh signed default/debug arm64 HAP;
- audit that exact HAP with the existing checker;
- record exact SHA-256 and byte size;
- restore signing overlay to HEAD;
- prove checkout clean;
- install that exact HAP on the real Mate60.

Do not uninstall or clear app data automatically.

Failure:

`BLOCKED — SIGNING/DEPLOYMENT`

## 7. Fixture preparation and truth

Generate the corpus in a fresh host directory:

```powershell
test-lab/media-compatibility/generate-samples.ps1
test-lab/media-compatibility/fetch-external-samples.ps1
```

Do not commit generated media.

For all 56 file fixtures produce a sanitized truth manifest containing:

- case ID;
- relative fixture path;
- file size;
- SHA-256;
- ffprobe format/container;
- ffprobe stream codecs;
- width/height/profile/pixel format where present;
- audio codec/channels/sample rate where present;
- subtitle codec where present.

For HLS/DASH:

- record manifest SHA-256;
- record segment/init files and SHA-256;
- verify the manifest references only the controlled corpus files.

If the installed host FFmpeg build cannot generate a declared fixture, do not silently substitute a different codec. Record the exact generator blocker and stop with:

`BLOCKED — TEST CORPUS`

unless a byte-identical previously controlled fixture with fresh SHA/truth proof is available.

## 8. Controlled remote source

Use a dedicated controlled test directory on the existing private test source, preferably WebDAV because it exercises the production REMOTE_FILE path already accepted in Phase 8A.

Upload/copy only the generated capability corpus.

Freshly verify remote bytes against local SHA-256 before playback.

Do not publish:

- private server name;
- endpoint/IP;
- credentials;
- private path;
- device identifier.

If a case cannot be reached because of test-environment setup, distinguish that from backend UNSUPPORTED.

Do **not** record a backend UNSUPPORTED verdict when the app never actually handed the fixture to that backend.

If the full corpus cannot be made reachable through a controlled production source, stop:

`BLOCKED — TEST ENVIRONMENT`

Do not modify production file filters solely for the test.

## 9. Execution matrix

Execute every manifest case once in:

1. forced System;
2. forced MPV.

Expected:

```text
59 cases × 2 backends = 118 rows
```

Do not run Auto for this matrix.

Backend order should alternate by case to reduce order bias:

- even case index: System then MPV;
- odd case index: MPV then System.

This is functional compatibility testing, not a speed benchmark.

## 10. Per-case verdict

Use exactly:

- `PASS`
- `UNSUPPORTED`
- `FAIL`
- `TIMEOUT`
- `NOT_RUN`

### Video PASS

Require:

- prepare/open succeeds inside bounded timeout;
- PLAYING state;
- real first frame;
- position advances;
- clean leave/release.

A short pause/resume is desirable where safely automatable, but lack of a separate pause checkpoint does not fail an otherwise valid 3-second compatibility case.

### Audio PASS

Require:

- prepare/open succeeds;
- PLAYING state;
- position advances for at least about 800 ms;
- clean leave/release.

App audio-renderer evidence may support the result.

Do not claim subjective audible output unless actually human-verified.

`firstFrameObserved` must be null/false as appropriate for audio-only media; never fabricate video evidence.

### Stream PASS

Require:

- manifest opens;
- PLAYING;
- first frame;
- position advances;
- clean leave/release.

### UNSUPPORTED

Use only when the backend itself produces a stable unsupported/container/decoder result.

A UI navigation problem, missing fixture, auth failure or test-server error is not UNSUPPORTED.

## 11. Stability rule for every tier

Regardless of A/B/C, the following are infrastructure failures:

- crash;
- ANR;
- unbounded prepare/loading;
- endless retry/fallback;
- stale previous-session state;
- inability to leave;
- unreleased surface/player/audio resource accumulation.

If one such defect appears, STOP after preserving evidence and classify precisely.

Do not continue through 118 cases after a proven infrastructure defect merely to increase coverage.

## 12. Tier interpretation

### Tier A

Tier A is the product compatibility gate.

For each Tier A case:

```text
System PASS OR MPV PASS
```

is required.

It is valid for one backend to be UNSUPPORTED when the other passes.

If both backends are non-PASS, record a Tier A product capability gap.

Do not patch/tune Auto in this task.

### Tier B

Individual unsupported formats are non-blocking compatibility findings.

### Tier C

Success is desirable but not required.

Tier C unsupported is acceptable if failure is controlled and resources release cleanly.

## 13. Raw evidence

Create one NDJSON row per case/backend with at least:

```json
{
  "caseId": "mp4-h264-aac",
  "backend": "system",
  "verdict": "PASS",
  "prepareObserved": true,
  "playingObserved": true,
  "firstFrameObserved": true,
  "positionAdvanced": true,
  "audioRendererObserved": null,
  "errorCode": null,
  "errorClass": null,
  "releaseClean": true,
  "crash": false,
  "anr": false,
  "unbounded": false,
  "notes": ""
}
```

Preserve backend errors as sanitized numeric/classification evidence where possible.

Do not publish raw private URLs or proxy tokens.

## 14. Matrix validation

After the run execute the repository summarizer unchanged:

```powershell
node scripts/summarize-playback-capability.cjs <raw.ndjson>
```

Require for a complete run:

- `manifestCases = 59`;
- `expectedRecords = 118`;
- `actualRecords = 118`;
- `missing = []`;
- no duplicate rows;
- no infrastructure failures.

Report System and MPV counts independently.

Report Tier A product gaps independently from per-backend unsupported counts.

## 15. Display modes / UI

Do not test fullscreen layout as a release gate.

Do not implement or test a UI display-mode selector.

System and MPV display-mode capability is tracked separately. Current planned normalized modes are:

- FIT_CONTAIN;
- FILL_CROP;
- STRETCH;
- ORIGINAL where truly supported.

This matrix is about media-format playback function only.

## 16. Analyzer sharing

This corpus is also the permanent Analyzer corpus.

Do not infer:

`Playback PASS -> Analyzer PASS`.

Do not reopen Phase 3/7 analysis acceptance.

If analyzer observations happen naturally, keep them clearly separate and non-gating for this task.

## 17. Advanced AV boundary

Do not claim from these 3-second synthetic fixtures:

- correct HDR10/HLG output;
- Dolby Vision output/signaling;
- DTS-HD/TrueHD/Atmos/DTS:X passthrough;
- subtitle visual correctness;
- hardware decode path;
- bitstream passthrough;
- power/thermal performance.

Those require later real-content / output-capability validation.

A basic TrueHD or DTS fixture can still record container/decoder playback PASS without making a passthrough claim.

## 18. Security/protection

Scan all publishable evidence for:

- Authorization;
- Cookie;
- password;
- private server endpoint/path;
- proxy token;
- private target identifier;
- signing/SSH material.

Before commit prove production source/test/build/task files remain byte-identical to the tested dispatch HEAD.

Generated media remains untracked/unpublished.

## 19. Authorized repository output

Codex may update only:

- `docs/PLAYBACK_PHASE8B_REPORT.md`
- one new evidence directory:
  `test-lab/playback/phase8b-mate60-capability-matrix-20261007/`

Suggested evidence:

- source-state.json;
- required-reading.json;
- dependency/EOL/build evidence;
- signing/artifact provenance;
- sanitized target preflight;
- generated fixture truth manifest;
- remote SHA verification summary;
- `raw-records.ndjson`;
- summarizer output;
- per-tier/per-backend observations;
- security review;
- protected audit.

Do not commit generated fixtures or HAP.

## 20. Publication

After completion:

1. restore signing overlay;
2. prove only authorized report/new evidence changes;
3. fetch remote;
4. stop on protected drift;
5. commit evidence/report only;
6. push without force;
7. fetch again;
8. prove remote containment;
9. return full 40-character remote evidence SHA.

## 21. Final classification

Use one primary classification:

- `PASS — PHASE 8B CAPABILITY MATRIX COLLECTED`;
- `FAIL — BUILD`;
- `FAIL — PLAYBACK INFRASTRUCTURE`;
- `FAIL — TIER A PRODUCT CAPABILITY GAP`;
- `BLOCKED — TEST CORPUS`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — SIGNING/DEPLOYMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification when necessary.

Do not patch production source.
Do not tune Auto.
Do not implement display-mode UI.
Do not implement Direct I/O.
Do not touch thumbnail research / Issue #17.
