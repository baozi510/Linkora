# Codex Build Isolation Hardening Runbook

> Branch: `fix/simulator-default-dependency-restore`  
> Base: `test/ffmpeg-media-analysis-phase1b-runtime`  
> Purpose: close the one build-system risk discovered during otherwise successful FFmpeg Phase 1B runtime validation.

## 1. Review verdict

FFmpeg Phase 1B runtime is accepted.

The only important remaining issue is build-state contamination between simulator and default dependency resolution.

Observed evidence from Phase 1B:

- after simulator target dependency resolution, one default build produced only 6 native libraries and omitted real MPV;
- running normal `ohpm install` restored the default dependency graph;
- final default HAPs were correct and contained 9 AArch64 native libraries.

The runtime implementation itself does not need redesign.

## 2. Changes already on this branch

### Simulator verification restores default dependency graph

`scripts/verify-simulator.ps1` now runs DevEco's bundled:

```text
ohpm install
```

in its cleanup path after simulator verification.

The restore must happen on:

- successful simulator verification;
- simulator build failure after the repository root has been entered;
- artifact-audit failure.

The script must leave the workspace ready for a normal default build.

### Default artifact guard is complete

`scripts/check-ffmpeg-artifact.cjs` now requires these AArch64 libraries in default HAPs:

- libaki_jsbind.so
- libc++_shared.so
- liblinkora_ffmpeg.so
- liblinkora_smb.so
- liblinkora_sftp.so
- liblinkora_ftp.so
- liblinkora_nfs.so
- libmpv.so
- libmpv_wrapper.so

A future default build must fail verification if any of these disappear.

### FFmpeg manifest matching is exact-line based

`linkora_ffmpeg/src/main/cpp/CMakeLists.txt` now uses exact manifest lines for:

- pinned FFmpeg commit;
- requested ABI.

Do not weaken this back to substring regex matching.

## 3. Validation sequence

Start from a clean checkout of this branch.

Record:

- initial SHA;
- `git status`;
- DevEco / SDK / Hvigor / ohpm versions.

Then run:

```powershell
ohpm install
./scripts/verify.ps1
```

This establishes a valid default baseline.

## 4. Prove the simulator script restores dependency state

Run:

```powershell
./scripts/verify-simulator.ps1
```

Do not manually run `ohpm install` afterward.

Immediately run:

```powershell
./scripts/verify.ps1
```

Required:

- default verify exit 0;
- Debug default HAP has all 9 required AArch64 libraries;
- Release default HAP has all 9 required AArch64 libraries;
- real MPV is present;
- all four production native storage libraries are present.

This is the primary acceptance test.

## 5. Repeat the target switch

Run the sequence a second time:

```powershell
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Again, do not insert manual dependency restoration.

Both iterations must pass.

The intent is to prove the simulator verifier is self-cleaning rather than succeeding accidentally on a fresh workspace.

## 6. Failure-path restoration

Create a temporary local-only failure condition that makes the simulator verification fail after target dependency resolution but before completion.

Preferred safe method:

- temporarily rename/copy aside the x86 FFmpeg prebuilt directory after dependency resolution can occur, or another reversible local artifact-only condition;
- do not commit the temporary change.

Run simulator verification and confirm it fails for the intended reason.

Then restore the local artifact, **without running manual `ohpm install`**, and run:

```powershell
./scripts/verify.ps1
```

Required:

- default verify passes;
- all 9 production native libraries are present.

This proves the `finally` restoration path executes on failure.

Do not intentionally corrupt tracked lockfiles.

## 7. Artifact guard fixtures

Run:

```powershell
node --test scripts/check-ffmpeg-artifact.test.cjs
```

Required:

- complete 9-library arm64 fixture passes;
- missing production native libraries fail;
- x86 simulator only accepts x86 FFmpeg analyzer library;
- wrong ELF machine fails.

If useful, add a fixture proving one missing protocol library fails independently of MPV.

## 8. FFmpeg manifest negative checks

Use temporary copied manifest fixtures or temporary local generated prebuilt copies.

Prove CMake configure rejects:

- wrong commit line;
- wrong ABI line;
- line containing the expected commit only as a substring of another value.

Do not alter the real pinned bootstrap manifest permanently.

## 9. Lockfile / tracked-state check

After all validation:

```powershell
git status --short
git diff -- entry/oh-package-lock.json5 linkora_ffmpeg/oh-package-lock.json5
```

Required:

- no unintended tracked dependency changes;
- no signing config committed;
- no generated FFmpeg binaries committed.

## 10. Regression requirements

Final:

- simulator parity guard PASS;
- FFmpeg pure tests PASS;
- Hypium >= 164 with zero failures;
- simulator HAP x86 FFmpeg artifact audit PASS;
- default Debug/Release HAP artifact audits PASS;
- existing Phase 1B runtime code unchanged unless a real regression is found.

No need to rerun the full 46-case FFmpeg runtime matrix unless this hardening change unexpectedly affects simulator install/runtime.

At minimum do one simulator install/launch smoke after the final simulator build.

## 11. Out of scope

Do not change:

- FFmpeg probe/frame native logic;
- MediaProxy;
- NetworkMediaLoader;
- probe routing;
- System metadata/thumbnail implementation;
- Auto/System/MPV policy;
- playback code;
- protocol implementation.

Do not start FFmpeg production analyzer routing in this branch.

## 12. Report

Fill:

`docs/BUILD_ISOLATION_HARDENING_REPORT.md`

Record:

- final tested SHA;
- two simulator -> default switch cycles;
- failure-path restoration result;
- default 9-library manifests;
- simulator artifact manifest;
- artifact fixture count;
- manifest negative checks;
- Hypium result;
- tracked-state cleanliness;
- any code fix and commit SHA.

## 13. Stop condition

Stop after:

- two clean simulator -> default cycles PASS;
- one intentional simulator failure -> automatic default restoration PASS;
- full default regression PASS;
- artifact/manifest guards PASS.

Then return for architecture review.

Do not merge.
