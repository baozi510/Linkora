# Codex Validation Task

> State: READY
> Task ID: phase8b-sim-rerun-1-eol-recovery
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation source: `cd5b1d98baba8b80f6910d040cf43c36f1a9ab71`
> Prior blocked evidence: `a6058b0a79516e334a342680b557552f7a7ceae1`
> Strategy base: `2dda6ccc84547cf2c3ec65caf5d0b546fac9949c`
> Phase 8A accepted evidence: `e894775c0bc81b39a6217a0a0516cec46158b82b`
> Role: BUILD / SIMULATOR FUNCTIONAL TEST / EVIDENCE / REPORT ONLY

## 1. Purpose

Freshly rerun Linkora Phase 8B simulator validation after GPT accepted the prior stop as a valid EOL-only validation-environment dispatch blocker. The prior blocked attempt contributes no build/runtime PASS; every downstream gate must run fresh.

This task intentionally uses the x86_64 HarmonyOS simulator for functional development and validation.

The execution rule is:

```text
Simulator first
+ ARM64 build always
+ real-device acceptance batched later
```

Do not wait for a physical device.

Do not claim simulator results as final Mate60 / real-MPV / hardware-codec capability.

Read completely:

- `docs/PLAYBACK_PHASE8B_SIMULATOR_RUNBOOK.md`
- `test-lab/media-compatibility/cases.json`

## 2. Source safety

Use a fresh isolated checkout, for example:

`D:\Linkora-playback-phase8b-sim`

Do not modify the user's existing workspace.

Before testing:

1. fetch `feat/playback-capability-phase8`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove tracked checkout clean;
5. prove prior blocked evidence `a6058b0a79516e334a342680b557552f7a7ceae1` is an ancestor of validation source;
6. prove validation source `cd5b1d98baba8b80f6910d040cf43c36f1a9ab71` is an ancestor of HEAD;
7. prove `e894775c0bc81b39a6217a0a0516cec46158b82b` is an ancestor of validation source;
8. run:

```powershell
git diff --name-only cd5b1d98baba8b80f6910d040cf43c36f1a9ab71..HEAD
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
6. `docs/PLAYBACK_PHASE8B_SIMULATOR_RUNBOOK.md`
7. `docs/PLAYBACK_PHASE8B_RUNBOOK.md`
8. `docs/PLAYBACK_PHASE8B_REPORT.md`
9. `docs/SIMULATOR_TEST_MANUAL.md`
10. `docs/SIMULATOR_VALIDATION_REPORT.md`
11. `test-lab/media-compatibility/README.md`
12. `test-lab/media-compatibility/cases.json`
13. `test-lab/media-compatibility/generate-samples.ps1`
14. `test-lab/media-compatibility/fetch-external-samples.ps1`

Historical simulator evidence is context only, not fresh PASS.

## 4. Strategy confirmation

Before execution, confirm:

- default product remains production ARM64;
- simulator product remains x86_64;
- simulator target replaces real MPV only at the package/native boundary;
- simulator does not package real libmpv;
- simulator may package real x86_64 `liblinkora_ffmpeg.so`;
- `verify-simulator.ps1` restores the default dependency graph using normal `ohpm install` in its finally path;
- production MPV / native-storage source is not rewritten to make simulator pass;
- immediate Mate60 118-record task is superseded.

Contradiction => STOP. Do not patch.

## 5. Explicit EOL-only recovery authorization + fresh ARM64 production build gate

Even though no ARM64 device is present, production ARM64 compile/link/artifact validation remains mandatory.

Run exactly one normal:

```powershell
ohpm install
```

This task explicitly allowlists **only** these four paths for validation-workspace EOL normalization recovery:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

After `ohpm install`, inspect the complete tracked worktree before any restore.

If any allowlisted path changed, recovery is permitted only after freshly proving for every affected path:

1. the path is in the four-path allowlist above;
2. the worktree file's Git-normalized blob equals the exact `HEAD:<path>` blob;
3. CRLF-to-LF normalized bytes are exactly identical to the HEAD blob bytes;
4. dependency entries, versions, checksums, graph, comments and all other semantic content are identical;
5. no other tracked path changed.

Only when all five conditions pass may Codex restore **only the affected allowlisted files** from HEAD in the isolated validation checkout. This restore is workspace cleanup only: do not stage or commit it.

After restore, `git status --porcelain` must be clean.

If any non-allowlisted path changed, any normalized content differs, semantic content differs, restore fails, or the checkout is not clean afterward:

`BLOCKED — VALIDATION ENVIRONMENT`

STOP.

Do not use a second `ohpm install` to repair this condition.

The proof in prior evidence `a6058b0a...` is historical only. This checkout needs its own fresh EOL proof.

Only after the checkout is clean, run one fresh:

```powershell
./scripts/verify.ps1
```

Record actual fresh:

- architecture fixtures;
- FFmpeg pure tests;
- analysis pure tests;
- artifact fixtures;
- MPV mapping tests;
- Hypium count;
- Debug/Release HAR/HAP;
- exact-nine AArch64 audits;
- final verifier marker.

Any production/default build failure:

`FAIL — ARM64 BUILD GATE`

STOP.

Do not postpone a real ARM64 compile/link failure merely because no device is attached.

## 6. Fresh simulator build gate

Run:

```powershell
./scripts/verify-simulator.ps1
```

Require:

- simulator parity/isolation checks PASS;
- x86_64 simulator HAP builds;
- no real libmpv/mpv wrapper in simulator HAP;
- no production SMB/SFTP/FTP/NFS native libraries in simulator HAP;
- only whitelisted simulator native libraries;
- if `liblinkora_ffmpeg.so` is present, it must be x86_64 and pass ABI audit;
- script restores default dependency graph afterward.

After simulator verification, prove the default dependency graph is restored.

`verify-simulator.ps1` invokes normal `ohpm install` in its finally path. If that internal restoration produces EOL-only drift, the **same four-path allowlist and same five-condition proof from Section 5** apply. Inspect the full tracked worktree, prove the conditions fresh, restore only affected allowlisted paths, and prove clean before continuing. Any other drift => `BLOCKED — VALIDATION ENVIRONMENT`.

Run the repository's established post-simulator/default verification needed to prove simulator target resolution did not contaminate production ARM64 dependencies. If no narrower safe gate exists, run a second fresh `./scripts/verify.ps1`.

Any simulator build/isolation failure:

`FAIL — SIMULATOR BUILD`

STOP. Do not weaken the whitelist.

## 7. Simulator target

Use the x86_64 HarmonyOS simulator.

Freshly record sanitized:

- HDC version;
- emulator ABI;
- HarmonyOS/API;
- bundle/version;
- install/launch result.

Do not require or wait for a physical ARM64 device.

Do not publish private host network identifiers.

## 8. Corpus generation

Generate the permanent corpus fresh:

```powershell
test-lab/media-compatibility/generate-samples.ps1
test-lab/media-compatibility/fetch-external-samples.ps1
```

Require exactly 59 manifest cases.

Produce a sanitized fixture truth manifest:

- case ID;
- relative path;
- file size;
- SHA-256;
- ffprobe format/container;
- stream codecs;
- profile/pixel format/width/height when present;
- audio codec/channels/sample rate when present;
- subtitle codec when present;
- generated/fetched provenance.

For HLS/DASH record manifest and segment/init hashes.

Do not commit generated media.

If the host FFmpeg build cannot generate a declared fixture, do not silently substitute a different codec.

Stop:

`BLOCKED — TEST CORPUS`

unless a byte-identical previously controlled fixture with fresh hash/truth proof is available.

## 9. Controlled simulator source

Use a controlled host-served source reachable by the simulator.

Prefer the existing simulator lab convention:

- controlled HTTP/WebDAV;
- same bytes as local generated corpus;
- no public/uncontrolled media URLs for official matrix evidence.

Freshly verify served bytes/hashes where applicable.

Do not publish host/private IP/path/credential.

## 10. System simulator matrix

Run all 59 manifest cases through **forced System** where the simulator environment can actually hand the fixture to AVPlayer.

Use simulator-specific verdicts:

- `PASS`
- `SYSTEM_SIMULATOR_UNSUPPORTED`
- `FAIL`
- `TIMEOUT`
- `NOT_RUN`

Do not use product-level `UNSUPPORTED` based on simulator codec availability.

### Video PASS

Require:

- prepare/open succeeds;
- PLAYING;
- first real frame;
- position advances;
- bounded leave/release.

### Audio PASS

Require:

- prepare/open succeeds;
- PLAYING;
- position advances for about 800 ms;
- bounded leave/release.

Do not fabricate first-frame evidence for audio-only cases.

### Streams

Require:

- manifest opens;
- PLAYING;
- first frame;
- position advances;
- bounded leave/release.

A simulator HEVC/AV1/other codec limitation is recorded only as:

`SYSTEM_SIMULATOR_UNSUPPORTED`

and must not be extrapolated to Mate60.

## 11. MPV simulator control-flow subset

Do not run a fake 59-case MPV capability matrix.

The simulator MPV dependency is a stub/native-unavailable boundary.

Use representative cases only to prove control flow.

At minimum:

### Forced MPV

Use:

- one MP4/H.264 case;
- one MKV case.

Require:

- production PlaybackEngine / AdaptivePlaybackPort path is entered;
- failure occurs at the simulator MPV unavailable boundary;
- forced MPV does not silently fall back to System;
- failure is bounded/recoverable;
- next valid System case can open afterward.

### Auto MPV-first representative

Use at least one case where current selector tries MPV first, such as Matroska.

Require:

- first candidate reaches simulator MPV unavailable boundary;
- Auto performs at most one intended fallback;
- candidate failure state does not pollute the committed System session;
- final System result is recorded separately;
- release clean.

Do not claim this proves real MPV behavior.

## 12. Real x86_64 FFmpeg function

Unlike MPV, `linkora_ffmpeg` is a real x86_64 native module in simulator.

Use the simulator to functionally exercise the existing FFmpeg Analyzer/thumbnail path on a representative cross-section of the shared corpus.

At minimum include representatives for:

- MP4/H.264;
- MP4/HEVC if generated;
- MKV/H.264;
- MKV/HEVC;
- WebM/VP9;
- TS;
- AVI/MPEG-4 Part 2;
- MPEG-PS or VOB;
- one audio-only case;
- one legacy/rare case.

For each representative:

- metadata open/probe is bounded;
- result classification is sane;
- thumbnail is attempted only for video;
- release/cancellation remains bounded;
- no crash/ANR.

This is simulator/x86 functional evidence only.

Do not use it to decide final ARM64 analyzer compatibility or policy.

Do not reopen Phase 3/7 acceptance.

## 13. Runner/schema/summarizer validation

Validate:

`test-lab/media-compatibility/cases.json`

and:

`scripts/summarize-playback-capability.cjs`

using controlled result files.

Prove:

- 59 unique case IDs;
- no duplicate case/backend records accepted;
- invalid verdict rejected;
- unexpected case rejected;
- missing rows detected;
- complete synthetic official-shape input expects 118 records.

Do not fabricate official MPV results just to make an official PASS matrix.

Simulator raw results must be clearly labeled simulator-specific.

## 14. Functional stress / recovery

Prioritize ordinary functionality while the simulator is available.

At minimum test:

- repeated System case transitions;
- supported -> unsupported -> supported recovery;
- timeout/failure -> next valid case recovery;
- 20 player open/leave cycles;
- 10 background/foreground cycles;
- 10 Auto MPV-first stub fallback cycles;
- WebDAV/MediaProxy open/play/seek on a supported H.264 case;
- stale-session protection;
- no crash/ANR;
- bounded cancellation/retry;
- clean release.

If a production functional bug appears that is independent of simulator-only platform limitations:

STOP and classify:

`FAIL — FUNCTIONAL DEFECT`

Do not patch source in this task.

## 15. UI and display-mode boundary

Do not block on fullscreen/player visual polish.

Do not implement:

- fullscreen layout refinement;
- display-mode selector;
- Fit/Fill/Stretch/Original UI.

Backend display-mode capability is tracked separately.

Only record UI issues if they prevent ordinary functional testing.

## 16. What remains DEVICE REQUIRED

Keep explicit `DEVICE REQUIRED / NOT RUN` for:

- real MPV runtime;
- real MPV codec/container capability;
- ARM64 FFmpeg runtime/load behavior;
- Mate60-specific System codec capability;
- hardware decode;
- HDR10/HLG/Dolby Vision output;
- advanced audio output/passthrough;
- power/thermal/performance;
- native ARM64 storage I/O where simulator uses unavailable boundaries.

Do not wait for these items.

## 17. Security

Scan publishable evidence for:

- Authorization;
- Cookie;
- password;
- private WebDAV/host endpoint/path;
- simulator/host private identifiers;
- proxy token;
- signing paths/material;
- SSH data.

Do not publish generated media, HAP, credentials or private screenshots.

## 18. Authorized repository output

Codex may update only:

- `docs/PLAYBACK_PHASE8B_REPORT.md`
- one new evidence directory:
  `test-lab/playback/phase8b-simulator-functional-preflight-rerun1-20261007/`

The prior blocked evidence directory `test-lab/playback/phase8b-simulator-functional-preflight-20261007/` is immutable.

Suggested evidence:

- source-state.json;
- required-reading.json;
- strategy-review.json;
- fresh default build evidence;
- fresh simulator build/isolation evidence;
- post-simulator default-restore evidence;
- simulator target preflight;
- fixture truth manifest;
- System simulator raw matrix;
- MPV stub control-flow observations;
- x86 FFmpeg functional observations;
- summarizer/schema tests;
- stress/recovery observations;
- security review;
- protected audit.

Do not modify source/tests/expectations/policies.

## 19. Publication

After completion:

1. prove tracked production source/test/task files unchanged;
2. prove only authorized report/new evidence changes exist;
3. fetch remote;
4. stop on protected drift;
5. commit report + evidence only;
6. push without force;
7. fetch again;
8. prove remote containment;
9. return full 40-character remote evidence SHA.

## 20. Final classification

Use one primary classification:

- `PASS — PHASE 8B SIMULATOR FUNCTIONAL PREFLIGHT COLLECTED`;
- `FAIL — ARM64 BUILD GATE`;
- `BLOCKED — VALIDATION ENVIRONMENT`;
- `FAIL — SIMULATOR BUILD`;
- `FAIL — FUNCTIONAL DEFECT`;
- `BLOCKED — TEST CORPUS`;
- `BLOCKED — SIMULATOR ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification if necessary.

Do not wait for a real device.
Do not patch source.
Do not tune Auto.
Do not implement display-mode UI.
Do not implement Direct I/O.
Do not touch thumbnail research / Issue #17.
