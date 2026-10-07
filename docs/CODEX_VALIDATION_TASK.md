# Codex Validation Task

> State: READY
> Task ID: phase8b-sim-rerun-2-audio-metadata-and-device-backlog
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation source: `1c02e84f7afdc938de2b2723bae07c5869e560f1`
> Prior simulator evidence: `4e3ff969b3d1bc785d8c3e20c245ba2408e5b6e6`
> Role: BUILD / FOCUSED SIMULATOR TEST / EVIDENCE / REPORT ONLY

## 1. Operating rule

No physical ARM64 device is currently available.

Do not wait for one.

The rule for this and following work is:

```text
Anything simulator-testable -> test now
Anything genuinely device-only -> classify DEVICE REQUIRED and continue
ARM64 compile/link/artifact gates -> keep green continuously
```

A missing physical device is not a blocker unless the task itself is exclusively device-runtime work.

This task must not start real-device validation.

## 2. Purpose

Close the sole known Phase 8B-SIM instrumentation gap: audio-only FFmpeg metadata.

Also produce an explicit backlog separating:

- simulator-complete / simulator-testable work;
- device-required work that must wait for a real ARM64 device.

The prior simulator evidence already collected:

- fresh default ARM64 build gates;
- simulator build/isolation;
- 59-case forced-System simulator matrix;
- MPV stub control-flow;
- Auto fallback behavior;
- x86 FFmpeg video representatives;
- stress/recovery/WebDAV/MediaProxy function;
- schema/summarizer controls.

Do not rerun the full 59-case matrix solely for this task.

## 3. Source safety

Use a fresh isolated checkout.

Before execution:

1. fetch `feat/playback-capability-phase8`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove tracked checkout clean;
5. prove prior evidence `4e3ff969b3d1bc785d8c3e20c245ba2408e5b6e6` is an ancestor of validation source;
6. prove validation source `1c02e84f7afdc938de2b2723bae07c5869e560f1` is an ancestor of HEAD;
7. run `git diff --name-only 1c02e84f7afdc938de2b2723bae07c5869e560f1..HEAD`.

The only permitted result is:

```text
docs/CODEX_VALIDATION_TASK.md
```

Anything else => STOP.

## 4. Required reading

Read completely:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/IMPLEMENTATION_STATUS.md`
4. `docs/SESSION_HANDOFF.md`
5. `docs/CODEX_VALIDATION_TASK.md`
6. `docs/PLAYBACK_PHASE8B_SIMULATOR_RUNBOOK.md`
7. `docs/PLAYBACK_PHASE8B_REPORT.md`
8. `entry/src/simulator/ets/diagnostics/AudioMetadataSmoke.ets`
9. `entry/src/simulator/RuntimeDiagnostics.ets`
10. `scripts/check-audio-metadata-smoke.cjs`
11. `scripts/verify-simulator.ps1`

## 5. Read-only correction review

Confirm the new diagnostic is simulator/test infrastructure only.

`AudioMetadataSmoke` must:

- use `AnalysisComposition.ffmpeg(...)`;
- use `ProbeRequirement.DETAIL`;
- use the real REMOTE_FILE -> resolver -> MediaProxy -> FfmpegMediaProbeAdapter path;
- require zero video tracks;
- require at least one audio track;
- verify expected codec;
- verify positive channels/sample rate;
- verify positive duration;
- observe activeSources after probe close and before final proxy close;
- close proxy unconditionally even when assertions fail.

It must not:

- request thumbnail/frame extraction;
- fabricate video dimensions;
- modify production analysis policy;
- modify Phase 7 benchmark semantics.

`verify-simulator.ps1` must execute the new static guard.

Contradiction => STOP.

## 6. EOL-only recovery authorization

Run exactly one normal:

```powershell
ohpm install
```

The only allowlisted EOL-normalization paths are:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

For every affected file, freshly prove:

1. path is allowlisted;
2. Git-normalized worktree blob == exact HEAD blob;
3. CRLF->LF bytes == exact HEAD bytes;
4. semantic dependency/version/checksum/graph/comment content is unchanged;
5. no other tracked path changed.

Only then restore only affected allowlisted paths from HEAD in the isolated checkout.

After restore, checkout must be clean.

Any deviation =>

`BLOCKED — VALIDATION ENVIRONMENT`

The same rule applies to EOL drift caused by `verify-simulator.ps1`'s internal dependency-restoration install.

## 7. Fresh build gates

Run fresh:

```powershell
./scripts/verify.ps1
```

Production/default ARM64 compile/link/artifact audits must pass.

Then run fresh:

```powershell
./scripts/verify-simulator.ps1
```

Require:

- simulator product/isolation PASS;
- audio metadata static guard PASS;
- x86_64 simulator HAP build PASS;
- real x86 `liblinkora_ffmpeg.so` audit PASS;
- no real MPV/native-storage production libraries packaged.

After simulator dependency restoration, apply Section 6 EOL recovery if necessary and prove clean.

Then run the established final default gate again. If there is no narrower exact restoration proof, run another fresh `./scripts/verify.ps1`.

Classify failures precisely:

- default compile/link/artifact => `FAIL — ARM64 BUILD GATE`
- simulator compile/static/isolation => `FAIL — SIMULATOR BUILD`

Do not patch source.

## 8. Fresh simulator install

Install/cold-launch the exact newly built simulator artifact.

If normal unsigned install is rejected only by simulator signing enforcement, the previously accepted signing-only procedure may be used on the exact artifact without modifying source/build profiles/dependencies/ABI or disabling validation.

Record exact hashes.

Do not require a physical device.

## 9. Audio-only controlled fixtures

Freshly verify the retained owned controlled corpus bytes against committed truth.

Mandatory cases:

1. `audio-mp3` / expected codec `mp3`
2. `audio-flac` / expected codec `flac`

Additional capability observations:

3. `audio-truehd` / expected codec `truehd`
4. `audio-wavpack` / expected codec `wavpack`

Use the controlled WebDAV REMOTE_FILE path.

Do not substitute unrelated public media.

If controlled bytes/profile are unavailable or differ:

`BLOCKED — TEST ENVIRONMENT`

## 10. Execute AudioMetadataSmoke

Launch the simulator with:

`linkoraAudioMetadataSmoke=<controlled host-bridge config endpoint>`

Collect structured evidence for each case.

Required fields:

- caseId;
- status;
- errorCode;
- completeness;
- container;
- durationMs;
- videoTracks;
- audioTracks;
- codec;
- channels;
- sampleRate;
- bytesRead/readRequests/rangeRequests;
- activeSources;
- final summary total/passed/failed.

There must be no thumbnail/frame output.

### Required outcome

`audio-mp3` and `audio-flac` must PASS.

If either cannot produce usable audio-only FFmpeg metadata through the production adapter/input path:

`FAIL — X86 FFMPEG AUDIO METADATA`

TrueHD/WavPack may PASS or fail in a bounded way; preserve them as x86 capability observations.

If the diagnostic entry/config/harness itself fails:

`FAIL — AUDIO DIAGNOSTIC INFRASTRUCTURE`

## 11. Ordinary runtime regression

After the diagnostic, cold-launch normally with no diagnostic parameter.

Run one known-good controlled H.264/AAC forced-System smoke:

- open;
- real first frame;
- PLAYING;
- short position progress;
- leave/release clean.

Do not repeat the full matrix/stress suite.

## 12. Device-required classification

Create:

`device-required-backlog.json`

inside the new evidence directory.

Every remaining playback/analysis item that cannot be honestly completed in simulator must be classified.

Required minimum entries:

- real MPV runtime/load on ARM64;
- real MPV codec/container matrix;
- ARM64 FFmpeg runtime/load behavior;
- Mate60/device-specific System codec capability;
- hardware decoder path verification;
- HDR10 output correctness;
- HLG output correctness;
- Dolby Vision profile/output behavior;
- advanced audio decode/output;
- DTS-HD / TrueHD / Atmos / DTS:X passthrough semantics where applicable;
- device audio route/output constraints;
- performance/power/thermal;
- real ARM64 SMB/SFTP/FTP/NFS native I/O when simulator uses unavailable boundary;
- GPU/surface/device-only runtime integration issues;
- exact display-mode behavior that depends on real MPV/device rendering.

For each item record:

```json
{
  "id": "...",
  "status": "DEVICE_REQUIRED",
  "whySimulatorInsufficient": "...",
  "requiredBackendOrHardware": "...",
  "existingEvidence": "...",
  "nextDeviceGate": "..."
}
```

Do not mark an item DEVICE_REQUIRED merely because it has not yet been attempted. If it can be tested in simulator, it belongs in simulator work instead.

## 13. Simulator-continuable classification

Also create:

`simulator-continuable-backlog.json`

for remaining work that can continue without a device.

Examples may include, if actually still pending:

- application state/session behavior;
- settings/persistence;
- catalog/database;
- network/MediaProxy logic;
- x86 FFmpeg functional paths;
- System simulator behavior;
- runner/test infrastructure;
- native-first capability research that can be resolved from official/current docs and code;
- UI-independent playback contracts;
- error/recovery/cancellation behavior.

Do not invent work already completed.

This backlog will be used by GPT for the next simulator-only task after this closure.

## 14. Interpretation

If fresh build gates pass, MP3/FLAC pass, cleanup is clean, and the ordinary System smoke passes:

`PASS — PHASE 8B SIMULATOR FUNCTIONAL PREFLIGHT COLLECTED`

The prior 59-case System/stress/x86-video evidence remains attributable to prior evidence commit and does not need repetition.

The four System first-frame-evidence FAIL rows remain simulator observations only.

The two HLS initialization FAIL rows remain simulator System observations only.

None should be promoted to Mate60/product capability conclusions.

## 15. Security

Do not publish:

- private endpoint/IP/path/server alias;
- credentials;
- Authorization/Cookie;
- device/simulator private identifier;
- proxy token;
- signing material;
- generated media/HAP.

## 16. Authorized output

Codex may update only:

- `docs/PLAYBACK_PHASE8B_REPORT.md`
- new evidence directory:
  `test-lab/playback/phase8b-simulator-audio-closure-20261008/`

The prior evidence directory is immutable.

Suggested evidence includes:

- source-state.json;
- required-reading.json;
- EOL proof;
- fresh default/simulator/final-default build evidence;
- simulator artifact/install provenance;
- controlled audio fixture proof;
- audio-metadata-records.ndjson;
- audio-metadata-summary.json;
- normal-system-smoke.json;
- device-required-backlog.json;
- simulator-continuable-backlog.json;
- security-review.json;
- protected-audit.json.

## 17. Publication

After completion:

1. prove only authorized report/new evidence changes exist;
2. fetch remote;
3. stop on protected drift;
4. commit report + new evidence only;
5. push without force;
6. fetch again;
7. prove remote containment;
8. return full 40-character remote evidence SHA.

## 18. Final classification

Use exactly one primary classification:

- `PASS — PHASE 8B SIMULATOR FUNCTIONAL PREFLIGHT COLLECTED`;
- `FAIL — ARM64 BUILD GATE`;
- `FAIL — SIMULATOR BUILD`;
- `FAIL — X86 FFMPEG AUDIO METADATA`;
- `FAIL — AUDIO DIAGNOSTIC INFRASTRUCTURE`;
- `BLOCKED — VALIDATION ENVIRONMENT`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification if necessary.

Do not wait for a real device.
Do not begin real-device validation.
Do not patch production source.
Do not tune Auto.
Do not implement Direct I/O.
Do not modify display-mode UI.
Do not touch thumbnail research / Issue #17.
