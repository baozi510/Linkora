# Phase 3 Production Runtime Acceptance Manual

> Scope: FFmpeg Analyzer Production Policy Phase 3 runtime acceptance on a real HarmonyOS target.
>
> Stable manual: this document defines **how** to execute runtime acceptance.
>
> Dispatch authority: `docs/CODEX_VALIDATION_TASK.md` defines **whether** a run is allowed, the exact source SHA, branch drift, permissions, stop conditions and evidence paths.
>
> If the current task is not `READY`, **do not execute this manual**.

## 1. Purpose

Phase 3 build/static/pure validation has already demonstrated that the current implementation can compile, package and satisfy its desktop/pure contracts. Runtime acceptance answers a different question:

> Does the real production path behave correctly on a HarmonyOS target with real media, real storage I/O, real native FFmpeg, real ImagePacker/WebP persistence and real application lifecycle?

The production path under test is:

```text
Network page/list
  -> NetworkMediaLoader
  -> NetworkMediaAnalysisCoordinator
  -> ProductionMediaAnalysisPolicy
  -> System / FFmpeg analysis
  -> RandomAccessSource
  -> shared NetworkFileProxy
  -> localhost HTTP/Range
  -> thumbnail encoder/cache
```

This manual must not be used to convert desktop mocks, static source review or simulator-only packaging into production runtime PASS.

## 2. Authority and non-goals

Before any runtime action, read the current:

`docs/CODEX_VALIDATION_TASK.md`

The task file overrides this manual for:

- task state;
- exact implementation/source SHA;
- actual checkout rules;
- allowed branch drift;
- allowed mutations;
- required evidence directory;
- stop conditions;
- final decision wording.

This manual does **not** authorize:

- production-source changes;
- test-script changes;
- build-profile/signing changes;
- semantic lockfile changes;
- temporary debug instrumentation committed to the branch;
- bypassing a failed runtime gate;
- weakening assertions;
- collecting System-vs-FFmpeg performance rankings;
- starting a later implementation phase.

If a runtime failure appears to require code or test-infrastructure modification, preserve evidence and return to GPT.

## 3. Repository facts relevant to runtime

Current application identity:

```text
bundleName: com.linkora.player
entry module: entry
runtimeOS: HarmonyOS
production/default ABI: arm64-v8a
device types: phone, tablet
```

The committed root build profile currently has no signing configuration:

```text
signingConfigs: []
```

Therefore a runtime environment must provide a supported development signing/install path externally. Do not commit private keys or weaken tracked signing/build configuration merely to install the application.

Persistent network-media images are stored by production code under:

```text
<context.filesDir>/network-media/
```

New persistent thumbnails are expected to use:

```text
<cacheKey>.webp
```

Legacy JPEG read compatibility may still read:

```text
<cacheKey>.jpg
```

but Phase 3 must not introduce a new JPEG-generation fallback.

Production analysis logging currently emits the safe diagnostic shape:

```text
Network media analysis: {
  metadataEngine,
  thumbnailEngine,
  thumbnailPlan
}
```

Do not add upstream URL, password, Authorization, Cookie or proxy token to runtime evidence.

## 4. Required environment before a READY run

All mandatory prerequisites below must be satisfied before GPT changes the task to `READY`.

### 4.1 HarmonyOS target

Run the environment's SDK HDC and record:

```text
hdc list targets
```

Required:

- at least one usable HarmonyOS target is listed;
- the target is reachable for install, launch and log collection;
- the target identity is recorded in sanitized form;
- target architecture/API/runtime information is recorded where available.

A generic Android AVD is not a substitute for a HarmonyOS target.

If HDC remains `[Empty]`, runtime acceptance is BLOCKED and this manual must not be executed further.

### 4.2 Deployable application

A supported development signing/install path must exist.

Requirements:

- no private signing material is committed;
- no tracked build profile is changed only to make installation possible;
- exact build/sign/install commands used by the environment are recorded;
- the installed artifact must correspond to the source SHA dispatched by the READY task.

The repository's build verifier produces unsigned HAP artifacts. Do not assume an unsigned HAP is directly installable on every target.

### 4.3 Reachable WebDAV service

The target must be able to reach a dedicated test WebDAV service.

Record only sanitized connection metadata:

- protocol: HTTP or HTTPS;
- logical server alias;
- fixture names/IDs;
- whether authentication is enabled.

Do not commit:

- username/password;
- Authorization header;
- Cookie;
- access token;
- private hostname/path if it is sensitive;
- TLS private-key material.

If HTTP rather than HTTPS is intentionally used in an isolated test environment, record that fact; do not turn it into a production security recommendation.

### 4.4 Evidence observability

Before starting media cases, confirm the environment can capture enough information to determine:

- app launch/crash state;
- sanitized application logs;
- generated persistent thumbnail files or an equivalent verifiable cache observation;
- whether cache reopen avoids unnecessary regeneration;
- source/proxy cleanup, if current diagnostics are observable;
- lifecycle results across repeated opens/leaves.

If a required observation is unavailable without modifying production code, mark that sub-check BLOCKED/NOT RUN and return to GPT if it prevents acceptance. Do not add ad-hoc production logging during a Codex test-only run.

## 5. Test corpus

Create a sanitized fixture manifest before execution.

At minimum the corpus must include:

| ID | Required media | Purpose |
| --- | --- | --- |
| `webdav-mp4` | H.264 video + AAC audio in MP4 | normal System LIST + FFmpeg-first thumbnail path |
| `webdav-mkv` | HEVC video + AAC audio in Matroska | non-trivial container/codec and FFmpeg thumbnail path |
| `webdav-corrupt` | unsupported or intentionally corrupt media | both-engine/no-invalid-thumbnail and bounded retry behavior |

Recommended additional fixtures:

| ID | Media | Purpose |
| --- | --- | --- |
| `webdav-fallback` | source for which FFmpeg thumbnail extraction naturally fails but System can succeed | natural FFmpeg -> System thumbnail fallback |
| `hls-basic` | safe HLS fixture | System-only production flow |
| `dash-basic` | safe DASH fixture | System-only production flow |
| `local-basic` | local document playable by existing System/local flow | LOCAL_DOCUMENT regression |

For every committed fixture manifest entry, record when known:

- sanitized fixture ID;
- container;
- video codec;
- audio codec;
- approximate duration;
- dimensions;
- file size;
- content SHA-256 if the exact test file is controlled locally.

Do not commit credential-bearing fixture URLs.

The optional natural fallback case must remain NOT RUN if no safe existing media condition triggers it. Do not modify production code or corrupt a valid source at runtime merely to force a particular engine.

## 6. Pre-run integrity capture

A future READY task may narrow or extend these steps. At minimum record:

```text
git rev-parse HEAD
git status --porcelain=v1
git submodule status --recursive
hdc list targets
```

Also record:

- dispatched implementation/source SHA;
- actual checkout SHA;
- target identity/runtime summary;
- exact installed artifact identity/hash if available;
- fixture manifest;
- exact signing/install method used by the environment.

The validation checkout must satisfy the current task's source-safety rules before runtime evidence is considered valid.

## 7. Build/install rule for runtime acceptance

Runtime acceptance is not an excuse to repeatedly rerun a previously green build matrix.

Follow the current READY task.

If the task requires a fresh runtime artifact build, build only through the repository-supported Hvigor/project path named by that task and capture the artifact hash.

If an already-built artifact is explicitly authorized by the task, prove its source/artifact identity.

Installation/launch commands vary by target and signing environment and are not fixed by this repository. Record the exact commands used rather than inventing a repository-standard command.

After installation:

1. launch `com.linkora.player`;
2. verify the app reaches its normal UI;
3. begin sanitized application log capture;
4. do not clear app data unless the specific test case requires a cold-cache state.

## 8. Evidence naming

For each runtime case create a case ID, for example:

```text
R01-webdav-mp4-cold
R02-webdav-mp4-reopen
R03-webdav-mkv-cold
R04-thumbnail-fallback
R05-both-engines-unavailable
R06-cancel-refresh
R07-lifecycle-20
R08-hls
R09-dash
R10-local
```

For each case record:

- start/end UTC timestamp;
- target identity;
- fixture ID;
- initial cache state;
- user actions;
- relevant sanitized log lines;
- observed metadata;
- observed thumbnail state;
- cache evidence;
- cleanup/lifecycle evidence;
- PASS / FAIL / NOT RUN / NOT APPLICABLE / BLOCKED;
- reason for any non-PASS result.

Screenshots may support a UI observation but must not be the only proof for engine routing, file format or cleanup.

## 9. R01 — WebDAV H.264/AAC MP4 cold load

### Setup

Use `webdav-mp4`.

Ensure this exact source has no current generated Phase 3 thumbnail cache entry, using a supported environment method. Do not globally wipe unrelated user data unless the task explicitly authorizes it.

### Actions

1. Open Linkora.
2. Enter the Network page.
3. Open the configured WebDAV server.
4. Navigate to the directory containing `webdav-mp4`.
5. Allow the row/preview analysis to complete without leaving the page.
6. Record the visible duration/resolution and thumbnail.
7. Capture the corresponding sanitized `Network media analysis` log.
8. Leave the directory/page and allow resources to settle.

### Required observations

PASS requires all applicable observations:

- directory/list opens successfully;
- no crash/ANR;
- metadata appears;
- duration is plausible for the fixture;
- width/height are plausible for the fixture;
- thumbnail appears;
- production analysis log is present;
- `thumbnailEngine = ffmpeg` for the normal supported remote-file case;
- `metadataEngine` may be `system` or empty when metadata was already supplied from cache/hints;
- generated persistent thumbnail is WebP;
- no new JPEG fallback is written;
- source/proxy state returns to idle when observable.

If System LIST metadata is complete and FFmpeg metadata does not run, that is expected and is not a failure.

## 10. R02 — WebDAV MP4 cache reopen

Use the same fixture without deleting its newly created cache.

### Actions

1. Leave the directory or app state enough to exercise reopen.
2. Re-enter the same WebDAV directory.
3. Observe the same media row/preview.
4. Capture logs and cache state.

### PASS criteria

- cached metadata remains correct;
- cached thumbnail remains decodable;
- persistent `.webp` entry is reused;
- no new JPEG is created;
- no visible duplicate/stale row appears;
- resource state settles after leaving.

Do not claim a timing/performance win. Cache acceptance here is functional only.

## 11. R03 — WebDAV HEVC/AAC MKV

Use `webdav-mkv`.

Perform a cold-load and reopen sequence equivalent to R01/R02.

PASS requires:

- metadata appears;
- duration/dimensions are plausible;
- thumbnail appears;
- no System-only MKV thumbnail regression;
- normal remote thumbnail routing reports `thumbnailEngine = ffmpeg`;
- persistent result is WebP;
- reopen works;
- cleanup returns to idle where observable;
- no crash/ANR.

A complete System LIST result may satisfy basic metadata before FFmpeg thumbnail extraction; this is expected.

## 12. R04 — Natural FFmpeg thumbnail fallback to System

This case is optional unless the current READY task provides a known safe fixture.

Use only an existing natural condition where:

```text
FFmpeg thumbnail extraction fails
AND
System thumbnail extraction succeeds
```

Do not patch engine capability checks, inject exceptions into production, or alter test expectations.

PASS requires:

- list remains usable;
- FFmpeg failure does not crash the app;
- System produces the thumbnail;
- log reports `thumbnailEngine = system`;
- persistent thumbnail is WebP;
- source/proxy resources settle.

If no natural fixture exists, record `NOT RUN — NO SAFE NATURAL FALLBACK FIXTURE`.

## 13. R05 — Both thumbnail engines unavailable/fail

Use `webdav-corrupt` or another predeclared safe unsupported fixture.

PASS requires:

- directory/list remains usable;
- app does not crash;
- useful metadata may persist if valid metadata is obtainable;
- no invalid thumbnail is persisted;
- no new JPEG fallback is written;
- repeated immediate requests are bounded by existing retry/backoff behavior;
- resources settle after the case.

Do not interpret “no thumbnail” alone as a failure when both engines correctly reject the source.

## 14. R06 — Cancellation, refresh and stale-generation rejection

Use a remote fixture that takes long enough for analysis to be observable without adding artificial production delays.

Execute these actions separately and record each result:

1. enter directory -> leave while analysis is active;
2. enter directory -> trigger refresh while analysis is active;
3. enter directory -> leave -> re-enter quickly;
4. cancel/re-enter where the UI exposes the normal cancellation path.

Required:

- no old-generation metadata is delivered into the new view;
- no stale thumbnail is inserted after navigation/refresh;
- no fallback engine starts after policy cancellation;
- no duplicate/stale row appears;
- source/proxy state returns to idle after operations settle;
- no crash/ANR.

If the operation completes too quickly to exercise cancellation naturally, do not add production delays. Record the specific cancellation subcase as NOT RUN.

## 15. R07 — 20-cycle production lifecycle

This is a correctness/stability loop, **not** a benchmark.

Choose one normal remote fixture, preferably `webdav-mp4`.

One cycle is:

```text
open Network page
-> open WebDAV directory
-> allow at least one video preview to reach a stable state
-> leave the directory/page
-> allow cleanup to settle
```

Repeat exactly 20 cycles unless a failure occurs earlier.

Record a table:

| Cycle | preview usable | duplicate/stale row | crash/ANR | activeSources after settle | activeClients after settle | note |
| ---: | --- | --- | --- | ---: | ---: | --- |
| 1 |  |  |  |  |  |  |
| ... |  |  |  |  |  |  |
| 20 |  |  |  |  |  |  |

If proxy diagnostics are not externally observable in the authorized build, use the strongest available cleanup evidence and explicitly mark the unavailable counters as BLOCKED/NOT RUN. Do not add instrumentation during the validation run.

PASS requires:

- all 20 completed cycles have no crash/ANR;
- no duplicate/stale rows accumulate;
- cached thumbnails remain decodable;
- no observable persistent resource growth.

Do not calculate latency, p50/p95 or throughput from this table.

## 16. R08/R09 — HLS and DASH production regression

Use the app's normal user-facing flow for existing HLS/DASH support.

Required:

- source remains usable through the existing System path;
- no FFmpeg native analysis is attempted for HLS/DASH;
- no manifest-only MediaProxy path is presented as full FFmpeg media support;
- no regression in normal playback/probe behavior attributable to Phase 3.

Record routing evidence from safe logs when available.

These cases validate routing correctness, not FFmpeg capability.

## 17. R10 — LOCAL_DOCUMENT production regression

Use `local-basic`.

Required:

- existing local media flow works;
- Phase 3 does not route LOCAL_DOCUMENT into native FFmpeg analysis;
- no content-URI-to-native-path workaround is introduced;
- existing System/local thumbnail behavior remains functional.

Do not infer this PASS only from policy unit tests when a runtime target is available.

## 18. Direct HTTP/HTTPS file-like path

Execute only if the current product exposes a production consumer for file-like HTTP/HTTPS media analysis.

If such a production consumer exists:

- verify resolver uses the intended safe input/proxy path;
- verify no credential-bearing upstream URL reaches native FFmpeg logs;
- verify functional analysis succeeds where supported.

If there is no production UI/runtime consumer, record:

`NOT APPLICABLE — NO PRODUCTION RUNTIME CONSUMER IN CURRENT PHASE`

and retain the existing pure/resolver evidence separately.

## 19. ADVANCED target execution

Phase 3 does not require a new production UI for ADVANCED metadata.

If the current READY task supplies an already-supported, non-invasive target diagnostic path, execute ADVANCED COMPLETE/PARTIAL/UNAVAILABLE and verify:

- FFmpeg first;
- usable partial FFmpeg result retained;
- System fallback only when FFmpeg unusable;
- no field merger;
- cancellation starts no later fallback.

Otherwise record target-native ADVANCED as NOT RUN. Existing pure tests remain distinct evidence.

## 20. SFTP runtime smoke

SFTP runtime is optional for this Phase 3 acceptance unless the current READY task explicitly requires it.

If a safe arm64 SFTP target/server is already available:

- perform a simple open/read smoke;
- verify persisted host-key trust remains server-owned;
- verify media/cache fingerprint is not used as SSH host-key trust;
- sanitize server identity in evidence.

Do not create unrelated SFTP infrastructure solely for this optional case.

## 21. WebP/cache verification

The production cache implementation uses:

```text
<context.filesDir>/network-media/
```

Expected new thumbnail extension:

```text
.webp
```

Runtime evidence should prove as much of the following as the environment permits:

- a new WebP file exists after successful thumbnail generation;
- file is non-empty and decodable;
- no sibling new `.jpg` fallback was generated;
- reopen uses the persisted thumbnail;
- metadata-only records survive thumbnail failure where contract permits;
- unsupported/both-fail case leaves no invalid image.

Do not commit the user's private cache contents wholesale. Prefer a sanitized inventory containing:

- sanitized cache-key prefix or hash;
- extension;
- byte size;
- decode success/failure;
- before/after existence.

Do not expose upstream path/credentials through cache metadata.

## 22. Proxy/source cleanup verification

`NetworkFileProxy.diagnostics()` exposes:

```text
activeSources
activeClients
readRequests
bytesRead
releasedSources
```

For runtime acceptance, the important correctness values are:

- `activeSources`;
- `activeClients`;
- monotonic release behavior where observable.

Do not interpret bytes/read-request counts as a performance ranking in this phase.

If diagnostics are available through the authorized runtime environment, capture sanitized before/after snapshots for:

- cold load;
- page leave;
- cancellation;
- both-engine failure;
- selected lifecycle cycles.

Expected settled state:

```text
activeSources = 0
activeClients = 0
```

If the production build exposes no authorized way to observe diagnostics, do not modify source during validation. Mark the direct counter check unavailable and rely only on other cleanup evidence until GPT decides whether dedicated observability is required.

## 23. Safe log capture

Collect only the minimum logs needed for:

- crash/ANR;
- analysis engine routing;
- cancellation/fallback;
- error code/category;
- lifecycle cleanup evidence.

Before committing evidence, scan for:

- `Authorization`;
- `Cookie`;
- passwords;
- usernames when sensitive;
- proxy tokens;
- full private WebDAV URLs/paths;
- private signing paths/key material;
- device identifiers that should not be published.

Redact values, not the fact that a check occurred.

Never fabricate a sanitized replacement that changes the meaning of an error or routing record.

## 24. Failure handling

At the first required-case failure:

1. stop mutating the runtime state except what is necessary to preserve evidence safely;
2. capture exact user action, case ID and timestamp;
3. capture sanitized relevant logs;
4. capture cache/resource state when safe;
5. classify the failure by layer:
   - deploy/environment;
   - Network page/storage;
   - Loader/cache;
   - metadata policy;
   - thumbnail pipeline;
   - cancellation/cleanup;
   - crash/ANR;
6. do not patch/rebuild/retry with modified source;
7. follow the current task's STOP and report rules.

A retry is allowed only when the task explicitly defines it as part of the test procedure, such as cache reopen or bounded-retry observation. It must not be used to erase a first failure.

## 25. PASS / FAIL / BLOCKED rules

### Full production runtime acceptance PASS

Do not declare full Phase 3 runtime acceptance unless all mandatory current-task cases are executed and pass.

At minimum, when the current task follows this manual, acceptance normally requires:

- WebDAV MP4 cold + reopen PASS;
- WebDAV HEVC/MKV cold + reopen PASS;
- persistent WebP behavior PASS;
- both-engines-unavailable/corrupt behavior PASS;
- cancellation/refresh/stale-generation PASS in naturally exercisable cases;
- 20-cycle lifecycle PASS;
- HLS/DASH/LOCAL_DOCUMENT production routing regression PASS;
- no unresolved required cleanup/resource leak;
- security evidence review PASS.

Natural FFmpeg->System fallback may be NOT RUN only when no safe natural fixture exists and the task explicitly permits it.

### FAIL

Use a precise failure category when a required production behavior is executed and wrong, for example:

- `FAIL — NETWORK MEDIA LOADER`;
- `FAIL — THUMBNAIL PIPELINE`;
- `FAIL — POLICY`;
- `FAIL — CANCELLATION/CLEANUP`;
- `FAIL — RUNTIME CRASH`;
- another exact category supported by evidence.

### BLOCKED

Use BLOCKED when the behavior cannot be executed because the environment is missing a prerequisite, for example:

- no connected target;
- deploy/signing path unavailable;
- required WebDAV service unreachable;
- required observation unavailable and essential to acceptance.

Do not convert BLOCKED into PASS using desktop evidence.

### NOT RUN vs NOT APPLICABLE

- NOT RUN: the case belongs to the phase but was not executed.
- NOT APPLICABLE: the case truly has no production consumer/path in the current phase.

Explain every NOT RUN/NOT APPLICABLE entry.

## 26. Runtime evidence directory

The future READY task will name the exact evidence directory. A runtime evidence bundle should normally contain sanitized equivalents of:

```text
README.md
environment.json
source-state.txt
target-state.txt
artifact.json
fixture-manifest.json
install-launch.txt
runtime-log.txt
security-review.txt
cache-before.json
cache-after.json
proxy-diagnostics.json
case-results.json
lifecycle-20.json
screenshots/                  # optional supporting evidence
```

Not every environment supports every file. Do not create fake empty evidence to imitate this layout.

`case-results.json` should have one record per case:

```json
{
  "caseId": "R01-webdav-mp4-cold",
  "fixtureId": "webdav-mp4",
  "result": "PASS",
  "observations": {
    "metadataVisible": true,
    "thumbnailVisible": true,
    "thumbnailEngine": "ffmpeg",
    "persistentExtension": "webp"
  }
}
```

Never include real credentials or private URLs in JSON evidence.

## 27. Final runtime report

Update the Phase 3 report only when authorized by the current task:

`docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

The runtime section must record:

- Task ID;
- implementation/source SHA;
- actual checkout SHA;
- target/runtime identity;
- artifact identity/hash;
- fixture manifest identity;
- exact deploy/launch method;
- each runtime case result;
- cache/WebP result;
- routing evidence;
- cancellation/cleanup result;
- 20-cycle result;
- all NOT RUN/NOT APPLICABLE/BLOCKED items;
- security review;
- whether any required case remains unresolved.

Do not splice old build PASS items into runtime execution as if they were rerun. Reference the previously reviewed build/static evidence separately.

## 28. Remote evidence handoff

When the future READY task authorizes report/evidence publication:

1. commit only authorized report/evidence paths;
2. fetch the branch;
3. reject unexpected source/test/build drift;
4. push without force to the exact task branch;
5. fetch again;
6. prove the evidence commit is contained in the remote branch;
7. return the remotely visible evidence SHA to GPT.

Local-only evidence is not a completed handoff.

## 29. After runtime acceptance

If mandatory runtime cases PASS, Codex still does not merge or start the next phase.

GPT independently reviews the evidence and decides whether to:

- mark Phase 3 fully accepted;
- require a targeted rerun;
- fix an implementation defect;
- proceed to real arm64 Analysis Benchmark + Policy work.

Performance benchmarking is a separate phase and must not be mixed into this acceptance run.
