# Codex Validation Task

> State: READY
> Task ID: phase8c-sim-native-first-capability-audit
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation source: `99ab47020f81391b7640d44c58ccb719491b4106`
> Phase 8B-SIM accepted evidence: `dcb34487e2043ba37f763c2ee50f4e040b597fbd`
> Role: BUILD / RESEARCH / SIMULATOR VERIFICATION / EVIDENCE / REPORT ONLY

## 1. Operating rule

No physical ARM64 device is available.

Do not wait for one.

Continue all work that can be completed honestly with:

- repository source;
- installed DevEco/HarmonyOS SDK;
- current official documentation;
- pinned dependency source;
- upstream MPV documentation/source;
- x86_64 simulator.

Anything that truly requires real ARM64 / real MPV / target hardware must be marked:

`DEVICE_CONFIRMATION_REQUIRED`

and must not block this audit.

When uncertain, search current authoritative sources. Do not infer capability from memory, method names, old docs, or backend similarity.

## 2. Purpose

Complete Linkora's native-first playback capability audit before any new playback feature is implemented.

Audit all 39 features in:

`test-lab/playback/native-capability-features.json`

for:

- System AVPlayer;
- MPV / the pinned `@mpv-ohos/mpv-arkts` wrapper;
- current Linkora exposure;
- possible normalized Linkora contract semantics.

This is an audit only.

Do not implement production playback features.

## 3. Source safety

Use a fresh isolated checkout.

Before execution:

1. fetch `feat/playback-capability-phase8`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove tracked checkout clean;
5. prove accepted evidence `dcb34487e2043ba37f763c2ee50f4e040b597fbd` is an ancestor of validation source;
6. prove validation source `99ab47020f81391b7640d44c58ccb719491b4106` is an ancestor of HEAD;
7. run `git diff --name-only 99ab47020f81391b7640d44c58ccb719491b4106..HEAD`.

Only:

```text
docs/CODEX_VALIDATION_TASK.md
```

is permitted.

Anything else => STOP.

## 4. Required reading

Read completely:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/IMPLEMENTATION_STATUS.md`
4. `docs/SESSION_HANDOFF.md`
5. `docs/CODEX_VALIDATION_TASK.md`
6. `docs/PLAYBACK_NATIVE_CAPABILITY_AUDIT_RUNBOOK.md`
7. `test-lab/playback/native-capability-features.json`
8. `linkora_core/src/main/ets/playback/PlaybackPort.ets`
9. `linkora_core/src/main/ets/playback/PlaybackBackend.ets`
10. `entry/src/main/ets/playback/SystemPlaybackPort.ets`
11. `entry/src/main/ets/playback/MpvPlaybackPort.ets`
12. pinned `@mpv-ohos/mpv-arkts` package source actually resolved by this checkout.

## 5. EOL-only recovery authorization

Run exactly one normal:

```powershell
ohpm install
```

Only these paths are allowlisted for proven Windows EOL normalization recovery:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

For every affected path freshly prove:

1. allowlisted path;
2. Git-normalized worktree blob == HEAD blob;
3. CRLF->LF bytes == exact HEAD bytes;
4. dependency/version/checksum/graph/comment semantics unchanged;
5. no other tracked path changed.

Only then restore affected allowlisted paths from HEAD in the isolated checkout.

Any deviation =>

`BLOCKED — VALIDATION ENVIRONMENT`

The same rule applies to EOL drift produced by simulator dependency restoration.

## 6. Fresh build gates

Run fresh:

```powershell
./scripts/verify.ps1
./scripts/verify-simulator.ps1
```

Then prove default dependency restoration and run the established final default gate; if no narrower exact proof exists, run another fresh `./scripts/verify.ps1`.

Require:

- production ARM64 compile/link/artifact gates green;
- simulator build/isolation green;
- x86 FFmpeg artifact audit green;
- audio metadata static guard green;
- no production MPV/native-storage libraries in simulator HAP.

Do not postpone compile/link defects.

## 7. Audio diagnostic schema regression

Because validation source changed `AudioMetadataSmoke`, verify the schema fix before starting the capability audit.

Using the same four controlled audio fixtures from accepted Phase 8B-SIM:

- MP3;
- FLAC;
- TrueHD;
- WavPack;

dispatch `AudioMetadataSmoke` once.

Expected event structure:

```text
4 fixture records
+ 1 summary
= 5 events total
```

There must be:

- no duplicate code-only post-assertion record for TrueHD;
- no duplicate code-only post-assertion record for WavPack;
- MP3/FLAC still PASS;
- TrueHD/WavPack may remain bounded FAIL/23002;
- cleanup remains bounded.

If duplicate fixture events still occur:

`FAIL — AUDIO DIAGNOSTIC SCHEMA`

Do not patch.

## 8. System capability evidence — authoritative order

For every audit feature, use evidence in this order:

1. **installed SDK declarations actually used by this checkout**;
2. current official Huawei/OpenHarmony documentation;
3. simulator runtime only where it can honestly verify semantics.

Record sanitized SDK identity:

- SDK/API version;
- declaration file relative identity;
- SHA-256 of relevant declaration source where practical.

Do not publish user-private absolute installation paths.

For each System feature record:

- exact class/property/method/event/enum name;
- minimum API level when supported by authoritative evidence;
- accepted values/range;
- valid player states / state restrictions;
- callback/event behavior;
- whether it is truly AVPlayer-native or belongs to another system API such as AVSession/window/audio routing;
- whether current Linkora `SystemPlaybackPort` exposes it;
- whether simulator runtime can verify the semantics;
- whether target-device confirmation is still required.

If official docs and installed SDK disagree, record both and treat installed build declarations as the compile-time truth for this repo; do not silently reconcile the mismatch.

## 9. MPV capability evidence — authoritative order

For every audit feature inspect:

1. pinned `@mpv-ohos/mpv-arkts` package source actually resolved by Linkora;
2. exact wrapper surface available to Linkora, including generic property/command access if exposed;
3. current upstream mpv stable manual/source;
4. master documentation only when needed to distinguish newer behavior from the stable version.

For each MPV feature record:

- native mpv property/option/command/event;
- exact semantics/range;
- whether runtime modification is supported;
- wrapper-native convenience API vs generic setProperty/command access;
- whether the pinned wrapper exposes the capability directly, indirectly, or not at all;
- dependency on VO/AO/libplacebo/FFmpeg/platform integration when relevant;
- current Linkora `MpvPlaybackPort` exposure;
- whether real-device confirmation is required.

Do not classify an upstream mpv feature as immediately usable if the pinned HarmonyOS wrapper cannot reach it.

Use:

`WRAPPER_NOT_EXPOSED`

when core mpv has a feature but Linkora's pinned wrapper/API surface cannot currently access it.

## 10. Search / uncertainty rule

For any field that is uncertain:

- search current official docs/upstream docs;
- inspect the actual installed declaration or dependency source;
- record the source and what remains uncertain.

Create a research log containing:

- query/topic;
- source;
- publication/version context where available;
- conclusion;
- unresolved point.

Do not write “probably”, “should”, or “likely supported” as a capability verdict.

Use `DEVICE_CONFIRMATION_REQUIRED` or `NATIVE_PARTIAL` instead.

## 11. Matrix output

Produce:

`native-capability-matrix.json`

with exactly 39 feature rows.

Each row must contain at least:

```json
{
  "id": "display.fit-contain",
  "system": {
    "verdict": "NATIVE_VERIFIED",
    "nativeApi": "...",
    "apiLevel": "...",
    "semantics": "...",
    "linkoraExposure": "...",
    "simulatorTestable": true,
    "deviceConfirmationRequired": false,
    "sources": []
  },
  "mpv": {
    "verdict": "DEVICE_CONFIRMATION_REQUIRED",
    "nativeApi": "...",
    "wrapperExposure": "...",
    "semantics": "...",
    "linkoraExposure": "...",
    "deviceConfirmationRequired": true,
    "sources": []
  },
  "normalizedContract": {
    "recommendation": "...",
    "commonSemantics": "...",
    "backendDifference": "...",
    "implementationDecision": "DEFER_TO_GPT"
  }
}
```

Allowed backend verdicts:

- `NATIVE_VERIFIED`
- `NATIVE_PARTIAL`
- `NATIVE_ABSENT`
- `WRAPPER_NOT_EXPOSED`
- `DEVICE_CONFIRMATION_REQUIRED`
- `NOT_APPLICABLE`

No `AUDIT_REQUIRED` may remain in the final matrix.

## 12. Important distinction: capability vs product implementation

A native capability being found does **not** authorize implementation.

The audit report may recommend a normalized contract, but:

- do not edit `PlaybackPort`;
- do not edit `SystemPlaybackPort`;
- do not edit `MpvPlaybackPort`;
- do not add UI controls;
- do not change Auto;
- do not change backend selection;
- do not add display-mode implementation.

GPT owns later contract/adapter implementation after reviewing this audit.

## 13. Existing Linkora baseline audit

Explicitly audit existing baseline features too:

- play;
- pause;
- seek;
- speed;
- volume;
- buffering;
- track observation;
- first-frame/video-size;
- seek-complete;
- surface sizing.

If current Linkora implements a behavior differently from native semantics, report the mismatch.

Do not “grandfather” existing code without review.

## 14. Device backlog delta

Produce:

`device-confirmation-delta.json`

containing only audit items whose native capability is statically identified but whose actual semantics/output need a physical target.

Do not duplicate unrelated old device backlog entries unless the capability audit adds or refines them.

No real-device test is started.

## 15. Simulator runtime spot checks

Runtime spot checks are allowed only for System capabilities that are already reachable through unchanged production code or existing diagnostics.

Do not add temporary production hooks.

At minimum preserve one normal System playback smoke after the audio diagnostic.

If a capability is native in the SDK but not currently exposed by Linkora, static evidence is sufficient for this audit; mark implementation as deferred.

## 16. Six historical System observations

Do not reclassify the six prior System simulator FAIL observations in this task.

They remain pending simulator investigation:

- two HLS initialization observations;
- four first-frame-evidence observations.

A later focused simulator task will investigate them.

This audit must not conflate native API capability with codec/container support.

## 17. Security

Do not publish:

- private endpoints/paths/credentials;
- user-private SDK absolute paths;
- signing material;
- simulator identifiers;
- generated media/HAP.

Web/SDK source references may be published.

## 18. Authorized output

Codex may create/update only:

- `docs/PLAYBACK_NATIVE_CAPABILITY_AUDIT_REPORT.md`
- one new evidence directory:
  `test-lab/playback/phase8c-native-capability-audit-20261008/`

Suggested evidence:

- source-state.json;
- required-reading.json;
- EOL/build evidence;
- audio-schema-regression.ndjson;
- sdk-declaration-evidence.json;
- mpv-wrapper-evidence.json;
- upstream-research-log.json;
- native-capability-matrix.json;
- device-confirmation-delta.json;
- normal-system-smoke.json;
- security-review.json;
- protected-audit.json.

## 19. Publication

After completion:

1. prove only authorized report/new evidence changed;
2. fetch remote;
3. stop on protected drift;
4. commit report + evidence only;
5. push without force;
6. fetch again;
7. prove remote containment;
8. return full 40-character remote evidence SHA.

## 20. Final classification

Use exactly one primary classification:

- `PASS — NATIVE PLAYBACK CAPABILITY AUDIT COLLECTED`;
- `FAIL — ARM64 BUILD GATE`;
- `FAIL — SIMULATOR BUILD`;
- `FAIL — AUDIO DIAGNOSTIC SCHEMA`;
- `FAIL — AUDIT EVIDENCE INCOMPLETE`;
- `BLOCKED — VALIDATION ENVIRONMENT`;
- `BLOCKED — SIMULATOR ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification if necessary.

Do not wait for a real device.
Do not patch production playback.
Do not implement UI.
Do not tune Auto.
Do not implement Direct I/O.
Do not touch thumbnail research / Issue #17.
