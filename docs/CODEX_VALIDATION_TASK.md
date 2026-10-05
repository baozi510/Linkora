# Codex Validation Task

> State: READY
> Task ID: phase3-runtime-acceptance-1-mate60-webdav
> Repository: `baozi510/Linkora`
> Branch: `feat/ffmpeg-analyzer-policy-phase3`
> Implementation source SHA: `44d0f62816b73ebd3bab8069be5b74f51e2c6999`
> Runtime validation source SHA: `4ced68f1b5cae7000ce9a24183d4a1d1b1c747a8`
> Role: TEST / EVIDENCE / REPORT ONLY

## 1. Authority

This file is the only execution authority for this runtime round.

Stable runtime procedure:

`docs/PHASE3_RUNTIME_ACCEPTANCE_MANUAL.md`

Read that manual completely before runtime cases.

This is a **runtime-only acceptance task**. The reviewed 3g build/static/pure acceptance remains separate prior evidence. Do not rerun `scripts/verify.ps1`, `scripts/verify-simulator.ps1` or the full green build matrix merely to reproduce it.

Do not reuse any old runtime result as PASS.

## 2. Source and checkout safety

Use the isolated runtime checkout:

`D:\Linkora-runtime-phase3`

Leave the user's dirty `D:\Linkora` workspace untouched except for explicitly permitted **read-only** access to its local signing configuration references if needed.

Before doing anything:

1. fetch `feat/ffmpeg-analyzer-policy-phase3`;
2. check out the current remote branch in the isolated runtime checkout;
3. confirm the checkout is clean;
4. record actual checkout HEAD;
5. confirm `4ced68f1b5cae7000ce9a24183d4a1d1b1c747a8` is an ancestor of HEAD;
6. run:

```powershell
git diff --name-only 4ced68f1b5cae7000ce9a24183d4a1d1b1c747a8..HEAD
```

The only permitted post-source path is:

```text
docs/CODEX_VALIDATION_TASK.md
```

Anything else => STOP.

Also record that production/test/build implementation remains `44d0f62816b73ebd3bab8069be5b74f51e2c6999`. GPT independently reviewed implementation->runtime-source drift as docs/evidence only.

## 3. Required reading

Read completely:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md`
6. `docs/SESSION_HANDOFF.md` — CURRENT STATE first
7. `docs/CODEX_VALIDATION_TASK.md`
8. `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`
9. `docs/PHASE3_RUNTIME_ACCEPTANCE_MANUAL.md`
10. `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

## 4. Prepared environment

Expected preparation already established:

- real Mate60 ARM64 target visible to HDC;
- aarch64 / arm64-v8a, API 26 environment;
- process Hilog readable;
- clean isolated runtime checkout with pinned submodules;
- local fixture directory:
  `D:\Linkora-runtime-preparation-20261006\media`
- prepared fixtures:
  - H.264/AAC MP4, 1280x720, ~20 s;
  - HEVC/AAC MKV, 1280x720, ~20 s;
  - corrupt MP4;
- isolated authenticated read-only WebDAV service on host port `19082`;
- HDC reverse mapping:
  device `127.0.0.1:19082` -> host `19082`;
- target browser has already authenticated and received a DAV multistatus containing all three fixtures;
- credentials exist only locally and must not enter Git/evidence.

Freshly verify the target and reverse mapping still exist before formal runtime cases.

## 5. Dependency preparation

Do not run the full verifier.

If dependency resolution is required, run exactly one normal `ohpm install` in the isolated runtime checkout before applying the signing overlay.

Known Windows EOL-only self-heal is permitted only for:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

Use the same strict proof already defined by prior tasks:

- no other tracked path changed;
- Git-normalized blob equals HEAD;
- CRLF->LF normalized bytes equal HEAD;
- line content equal;
- no dependency/version/checksum/graph/comment/content change.

Only then restore the affected lockfiles. Return clean. No reinstall just because of the restore.

Any semantic lock drift => STOP.

## 6. Exact-source signing overlay and artifact provenance

The pre-existing installed `com.linkora.player` is **not** an acceptance artifact.

A fresh signed default/debug arm64 HAP must be built from this runtime checkout.

### 6.1 Allowed signing preparation

A temporary local change to the repository-root:

`build-profile.json5`

is explicitly allowed **only in the isolated runtime checkout**.

Permitted semantics only:

- development/debug signing material references under `app.signingConfigs`;
- selection/reference of that signing config by the applicable product/target/build.

No other tracked file may change.

No SDK, product, module, dependency, ABI, native, build option or source semantic may change.

You may read `D:\Linkora\build-profile.json5` **read-only** to reuse the user's existing local DevEco development signing references. Do not modify that dirty workspace and do not copy signing secrets into evidence.

Before and after this read-only access, preserve/compare the user's dirty-workspace status/diff hashes as already practiced.

If DevEco automatic signing generates the equivalent overlay directly in the runtime clone, that is also allowed under the same semantic restrictions.

If any other tracked path changes => STOP.

### 6.2 Signing evidence

Locally inspect the raw signing diff, but committed evidence must contain only a sanitized summary:

- changed tracked path = `build-profile.json5`;
- signing config present = yes;
- applicable default/debug target references it = yes;
- all non-signing semantics unchanged = yes;
- SHA-256 of the overlaid `build-profile.json5`.

Do not commit:

- certificate/profile/key contents;
- passwords;
- private key paths;
- raw secret-bearing signing diff.

### 6.3 Build runtime artifact

Use the repository-supported DevEco/Hvigor default/debug HAP build path.

The expected logical invocation is equivalent to:

```powershell
hvigorw assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Use the actual DevEco Studio tool path from the environment and record it.

Identify the HAP produced by this exact invocation.

Required:

- it is installable/signed for the connected Mate60;
- bundle = `com.linkora.player`;
- version = `0.1.0`;
- current default arm64 native inventory remains valid.

Run the existing artifact checker on this exact HAP:

```text
scripts/check-ffmpeg-artifact.cjs <signed-hap> arm64-v8a
```

Record:

- artifact path sanitized as needed;
- file size;
- SHA-256;
- artifact-check result.

If the build produces only an unsigned/uninstallable artifact => `BLOCKED — SIGNING/DEPLOYMENT`.

### 6.4 Restore tracked signing overlay

After the signed HAP hash is recorded:

```powershell
git restore --source=HEAD --worktree -- build-profile.json5
git status --porcelain=v1
```

The checkout must return clean before runtime evidence publication.

Do not delete the built artifact merely because the signing overlay was restored.

### 6.5 Install exact artifact

Explicitly install the exact hashed HAP onto the connected Mate60 using the environment-supported HDC/DevEco installation command and record the exact command/result.

Then prove:

- installed bundle is `com.linkora.player`;
- version is `0.1.0`;
- app launches;
- process Hilog is readable.

If replacement is rejected because the pre-existing app has a different signature, **do not automatically uninstall it**. STOP with:

`BLOCKED — SIGNING/DEPLOYMENT`

and report that explicit user authorization would be needed to remove the existing app/data.

Do not silently use the pre-existing package.

## 7. WebDAV runtime preflight

Freshly verify:

- HDC target still connected;
- reverse mapping `tcp:19082 -> tcp:19082` is present;
- isolated host fixture service is still read-only/reachable;
- local fixture hashes still match the prepared manifest.

Inside the freshly installed Linkora app, configure a WebDAV server using:

```text
http://127.0.0.1:19082/
```

with the local test credentials.

Credentials must not be committed or echoed into evidence.

Use Linkora's normal connection test/browse flow. Successful app-side WebDAV browse is the formal runtime transport preflight.

Failure here => precise environment/storage FAIL/BLOCKED; do not patch the app.

## 8. Mandatory runtime cases

Follow `docs/PHASE3_RUNTIME_ACCEPTANCE_MANUAL.md`.

Mandatory core cases for this task:

- R01 — WebDAV H.264/AAC MP4 cold load;
- R02 — same MP4 cache reopen;
- R03 — WebDAV HEVC/AAC MKV cold load + reopen;
- R05 — corrupt/both-thumbnail-engines-unavailable behavior;
- R06 — naturally exercisable cancellation/refresh/stale-generation cases;
- R07 — 20-cycle production network lifecycle;
- R10 — LOCAL_DOCUMENT smoke using the prepared valid MP4 when safe to import/open.

Natural FFmpeg-thumbnail-failure -> System-success fallback:

- run only if a safe natural fixture is available;
- otherwise `NOT RUN — NO SAFE NATURAL FALLBACK FIXTURE`;
- do not force failure by patching source.

HLS/DASH target smoke:

- run if safe prepared streaming fixtures already exist;
- otherwise `NOT RUN — NO PREPARED STREAMING FIXTURE`;
- this does not block this remote-file Phase 3 runtime verdict because 3g already freshly verified System-only policy;
- an executed HLS/DASH regression does fail acceptance.

ADVANCED target-native diagnostic and SFTP smoke remain optional unless a safe existing path is already available.

## 9. Cache/WebP evidence

Do not inspect the wrong cache location.

Current generated thumbnails are expected under:

```text
<context.cacheDir>/network-thumbnails/<serverId>/<thumbnailKey>.webp
```

Metadata is separate in the app RDB.

Compatibility/legacy image paths include:

```text
<context.filesDir>/network-media/
<context.cacheDir>/network-media/
```

For MP4/MKV cases, prove where observable:

- new `.webp` exists in `network-thumbnails`;
- non-empty/decodable;
- reopen uses it;
- no new JPEG fallback appears;
- metadata remains available independently.

Commit only sanitized inventories/hashes, not private app data wholesale.

## 10. Cleanup observability

The current app has no external endpoint exposing its shared production `NetworkFileProxy.diagnostics()`.

Therefore direct `activeSources/activeClients` counters are **not mandatory**.

If no authorized existing endpoint appears, record:

`NOT RUN — NO PRODUCTION DIAGNOSTIC ENDPOINT`

Do not instrument production code.

Cleanup/lifecycle is still mandatory and must be judged through:

- no late old-generation metadata/thumbnail;
- no stale/duplicate rows after refresh/re-enter;
- corrupt media does not wedge the list;
- cancellation produces no later visible fallback result;
- app remains responsive with no crash/ANR;
- 20-cycle run shows no accumulating visible stale work;
- cached thumbnails remain usable after repeated transitions;
- relevant Hilog shows no repeated unrecovered lifecycle failure.

Any concrete cleanup regression => `FAIL — CANCELLATION/CLEANUP`.

## 11. Security

Sanitize evidence for:

- Authorization;
- Cookie;
- username/password;
- WebDAV credential;
- proxy token;
- full private URL/path;
- device private identifier;
- signing certificate/profile/key paths or contents;
- private signing material.

Allowed safe routing evidence includes:

- `metadataEngine`;
- `thumbnailEngine`;
- `thumbnailPlan`;
- sanitized fixture IDs.

Do not collect performance rankings.

## 12. Stop conditions

STOP immediately if:

- source/HEAD safety fails;
- dependency drift is semantic;
- signing overlay changes anything beyond explicitly allowed signing semantics;
- signed artifact provenance cannot be established;
- exact HAP cannot be installed/launched;
- app-side WebDAV preflight fails in a way requiring source modification;
- a mandatory runtime case fails;
- a production/test/build/source modification would be required.

Do not patch/rebuild with changed source after a stopped runtime gate.

## 13. Evidence/report output

Authorized repository outputs only:

- `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`
- one new sanitized directory:
  `test-lab/analyzer-policy/phase3/runtime-acceptance-1-mate60-webdav-20261006/`

The evidence bundle should include sanitized equivalents of:

- source/checkout state;
- dirty-workspace untouched proof;
- target/runtime summary;
- fixture manifest + SHA-256;
- HDC reverse mapping proof;
- signing-overlay sanitized summary;
- signed HAP SHA-256 + artifact check;
- exact install/launch result;
- app-side WebDAV preflight;
- case results;
- relevant sanitized Hilog;
- cache/WebP inventory;
- 20-cycle lifecycle table;
- security review;
- final protected-file/submodule/checkout audit.

Do not commit the signed HAP, credentials or signing material.

## 14. Remote handoff

After runtime execution:

1. restore any permitted local signing overlay;
2. prove tracked checkout clean except authorized report/evidence;
3. commit only report + new evidence directory;
4. fetch remote and reject unexpected protected drift;
5. push without force to `feat/ffmpeg-analyzer-policy-phase3`;
6. fetch again;
7. prove the evidence commit is contained in remote;
8. return the remotely visible evidence SHA.

Push failure => `BLOCKED — EVIDENCE NOT PUSHED`.

## 15. Final decision

Use one precise result:

- `READY FOR PHASE 3 ARCHITECTURE ACCEPTANCE`;
- `FAIL — NETWORK MEDIA LOADER`;
- `FAIL — THUMBNAIL PIPELINE`;
- `FAIL — POLICY`;
- `FAIL — CANCELLATION/CLEANUP`;
- `FAIL — RUNTIME CRASH`;
- `BLOCKED — SIGNING/DEPLOYMENT`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise evidence-supported FAIL/BLOCKED category.

Do not merge or start the next phase.
