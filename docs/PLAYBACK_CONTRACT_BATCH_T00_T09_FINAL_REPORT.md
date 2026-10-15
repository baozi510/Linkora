# T00–T09 wrapper contract batch: partial results and candidate handoff

STATE: PARTIAL — acceptance gaps remain; one final owner review required. This is not ALL PASS, native cleanup certification, or permission to repeat completed cases.

- BATCH_TASK_ID: `phase8f-level1-cli-all-wrapper-contracts-batch-t00-t09-v1`
- SOURCE_SHA: `7a13dc55dbf0f5f830b47aa5d0b3f316f0ef17f8`
- DISPATCH_SHA: `02355d12c84c061fea30cd2e6dd6d8b28450ce05`
- CANDIDATE_BRANCH: `codex/linkora-contract-batch-t00-t09-v1`
- FINAL_CANDIDATE_SHA: `da15f074a53270b603315c23fb46610f82a7c15c`
- Checkpoint commits: `2d6c113975237620160b1e48c6e78494d71ae145`, `b4aa6df01a9e61b77747cf6d036f09014b804f15`, then final candidate above.
- User explicitly extended the simulator dispatch to real ARM64/API26 hardware, normal official signing, actual application/WebDAV media, minimal causal repairs, and phase reports. Actual media rounds used explicit SYSTEM then MPV, not AUTO. Subtitles are a user-deferred TODO. Timed automation was cancelled and has not been restored.

## Outcomes by checkpoint

|ID|Outcome and executed evidence|First remaining acceptance gap / affected-path stop|
|---|---|---|
|T00|PARTIAL. Final-source controlled System/HLS contracts pass. Earlier candidate b4aa actual app System HLS remained opening while an owned fixture held a segment; normal Back closed that request after about 1.102s. Own PlayerServer and UID Renderer entries were zero at about 3.506s and 24.503s.|Reliable ownership of the actual video Surface was not established. Actual app uses XComponent, not ImageReceiver. Final-source native diagnostic harness/ImageReceiver run NOT RUN; complete cleanup NOT PROVEN; dependent recovered-MP4 case NOT RUN. Stop this dependent path as required.|
|T01|PARTIAL. Final SDK suite 221/221 and controlled System/MPV adapter checks pass. Final hardware candidate independently played MV-02 through both explicit backends, rendered real frames, sought, paused stably, resumed with progressing time, and exited normally.|Complete native first-frame/tracks/buffering/interruption/error event parity and all controls on all samples NOT PROVEN. Human audio confirmations below bind to b4aa, not automatically to final SHA.|
|T02|PARTIAL. Final Adaptive 12/12 plus selector scenarios: preference, failed prepare/fallback, commit/stale/reentrant gates, candidate/source cleanup, concurrent/repeated release and failure propagation.|Native forced fallback/error-injection matrix NOT RUN. A failed candidate disposal now blocks fallback instead of claiming safe recovery.|
|T03|PARTIAL. Existing authored SDK storage/read tests and actual RemoteReadSessionAdapter byte/EOF/close case pass in final 221-case suite. Actual approved WebDAV list/open was used in app rounds.|Full live concrete-provider parity, SMB/NFS connectivity and concurrent fault/cancel matrix NOT RUN; do not infer it from fake providers or WebDAV success.|
|T04|PARTIAL. Controlled HTTP range/cancel/isolation checks passed on b4aa; final SDK proxy/read-adapter cases pass. No corresponding production proxy code changed after b4aa.|Final-source native NetworkFileProxy/progressive live client/source-zero matrix NOT RUN. Direct playback does not prove that every proxy route was exercised.|
|T05|PARTIAL. Host analysis contracts 46/46 passed on b4aa, unchanged probe sources in final. On b4aa, one previously untested approved large MKV changed from generic list icon/no duration to actual thumbnail and 2:00:52; fresh app-owned diagnostic selected System basic metadata and FFmpeg thumbnail.|Native System-vs-FFmpeg normalized-field/provenance/completeness/cancel matrix NOT PROVEN. Filename codec/HDR hints are not native probe results. Final-source repeat of that analysis round NOT RUN.|
|T06|PARTIAL. Host thumbnail contracts passed. b4aa actual app showed a fresh FFmpeg thumbnail through existing SystemWebPEncoder/cache/PixelMap display path.|Encoded byte export, independent decode/dimension/pixel oracle, mutation/release matrix and final-source native repeat NOT RUN. Requested 480×259 bounds are not measured output dimensions; no lossy pixel-equality claim.|
|T07|PARTIAL. Final 221 SDK cases and adapter checks include stale async isolation, rejection and shared disposal; final hardware normal exit has attributable early/late zero rows. Earlier b4aa System and MPV paused automatically on Home and remained paused after return.|Full native cleanup, failure injection and complete lifecycle event parity NOT PROVEN. Retained disposal rejection deliberately fails closed; it is not proof resources were released.|
|T08|PARTIAL. Final host persistence checks pass with disposable data; remote server/path bookmark collision reproduced and isolated keys verified. b4aa actual app bookmark resumes observed in both backends.|Complete device database corruption/partial-write/delete/refresh matrix NOT RUN. No user database was extracted or modified for destructive tests. Legacy ambiguous remote bookmark keys intentionally are not reused; data is not deleted.|
|T09|PARTIAL. Authored deterministic backend/thumbnail/probe selection, cache and timing-policy cases pass in final SDK suite.|Reproducible native hardware performance/cost benchmark NOT RUN; no performance, hardware codec or broad format certification inferred.|

All ten checkpoints were attempted or explicitly classified. PARTIAL rows retain their missing gates; deterministic green tests do not satisfy unexecuted native criteria.

## Actual application media rounds and source boundaries

At b4aa, nine user-approved samples from tv/movie/x were inventoried, then each opened through explicit System and explicit native ARM64 MPV. Containers included MP4, MKV and M2TS, with displayed rounded sizes about 25MB–59GB. File names, private directory paths and network credentials are not published. These were the packaged actual application and actual WebDAV files, not only a capability demo.

System progressed on most samples; TV-03 remained buffering at 0 in its bounded observation, and MV-03 progressed briefly then buffered. MPV showed progress/pause/seek/resume for all nine; selected frames were manually reviewed. This is bounded evidence, not full-file viewing or proof of every listed codec/HDR/audio format. One additional large MKV was analysis-only, not an extra dual-backend playback result.

System rate measurements on one private sample were approximately 0.966/1.291/1.514/1.950 at requested 1/1.25/1.5/2×. MPV 1.25× and 1.5× labels and bounded progression were observed; its 2× observation hit the clip end, so it is not a valid full-window 2× ratio. End, manual replay and bookmark resume were observed on the short sample. Automatic looping is NOT IMPLEMENTED; manual replay does not prove loop support.

On b4aa, independent TV-02 rounds through both explicit backends showed actual 3840×1606 frames and playback progress. The same app's AudioRenderer was STATE_RUNNING (2), and the user separately confirmed normal audible sound for System and MPV. Audio output state alone was not used as hearing evidence. No full multi-track, sound-quality or A/V synchronization claim.

Final da15f07 was compiled, normally signed/installed and independently checked with MV-02 only. System: seek/play 0:16, pause 0:17 stable across the observation, resume 0:21. MPV: seek/play 0:16, pause 0:18 stable, resume 0:22. Actual 1920×800 frames were reviewed in both. Normal Back was used; attributable PlayerServer/Renderer rows were checked early and after >20s. This limited new regression does not rebind the old nine-sample, HLS, analysis or human-hearing results to final source. Screenshots containing text do not count as subtitle acceptance.

## Causal changes and regression evidence

- Prepared-source bookmark seek no longer waits for late duration metadata.
- Adaptive fences uncommitted/stale/reentrant events and retains cleanup ownership/results. Candidate disposal failure prevents AUTO fallback; committed/pending backend and source cleanup are each awaited once.
- System shares native release completion/rejection, still attempts descriptor cleanup and ignores late non-release events.
- Engine guards stale operations, publishes pending disposal before notifying error observers, and makes replacement/release await it. A failed close remains a failure instead of later becoming RELEASED or a replacement.
- Remote source identity includes source kind, server identity and path before hashing. Local keys stay unchanged; no ambiguous remote legacy fallback or user-data deletion.
- Existing HLS diagnostic releases its owned ImageReceiver before early/late sampling. Proxy tests exercise actual RemoteReadSessionAdapter with controlled bytes/EOF/close. Focused check scripts are integrated into existing verification.

Final tracked candidate regression: SDK/Hypium 221 tests, 0 Failure, 0 Error; Adaptive 12/12; System/HLS controlled adapter 6/6; MPV controlled adapter 7/7; architecture boundary and disposable local persistence checks pass. These are source contracts with controlled native/network boundaries, not all-native passes. Previously captured analysis 46/46 and HTTP four-category host checks remain b4aa evidence for unchanged implementations.

The latest Engine red run was 221 tests / 2 Failure / 219 Pass despite native tool exit0. Adaptive first expanded run had 9 cases / 3 failures; further candidate/lease-disposal tests exposed three additional missing waits. Engine and Adaptive targeted fixes then passed. Some early Adaptive test assertions sampled too soon and produced a false green; those results were rejected, the completion barrier was corrected first, and the unchanged implementation then failed before the causal fix. One initial assertion-abort produced an unhandled-rejection warning in the red harness; raw local logs retain it. No failure was relabeled as successful native behavior.

A read-only independent code reviewer found the pending-disposal gaps and rechecked the narrow fixes. No further concrete ownership/deadlock finding remained in that final delta. This was not owner approval or independent test execution.

## Final build, installation and finite execution

Final source `da15f074a53270b603315c23fb46610f82a7c15c`: official Hvigor ARM64/default Debug build native0 / BUILD SUCCESSFUL. Signed HAP 64,568,078 bytes, SHA256 `15F295A00C82A462D453FECC1DA3B55D9FB8BEAB2331AFA3AD4B7E19997BB3F3`. Current unsigned SHA256 `F732BCF3E5961A58B7B9F1DBA2D555621443CAF9B66ED5C3AC58A3F02E73B166`. Embedded bundle/module identity matched; strict ARM64 audit native0, nine native libraries and one ABC matched signed/unsigned bytes. Normal nondestructive HDC upgrade and Ability start both returned actual semantic success. No signing bypass, uninstall, wipe/reset or manual sign-app.

Recorded cumulative batch operations: 3 ARM64 HAP build invocations, 0 x86 HAP builds, 1 dependency install, 3 actual target installation attempts (one earlier unsigned semantic failure, two later signed upgrades); additionally one local-path opening error that did not install. One official normal signature-generation invocation; GUI0, manual SIGN_APP0, simulator start0. Ten SDK test invocations include two earlier infrastructure failures and preserved semantic-red runs. Conservatively counted causal fixes: 15 total, including five in the final disposal checkpoint. Exact cumulative active minutes cannot be reconstructed from older interrupted journals, so compliance with the global minute ceiling is NOT independently certified; it was not reset. No further expanding test/repair loop is authorized by this report.

Temporary host HLS input generation was fixture preparation, not application video/audio encoding support. The task-owned stream entry, server process/listener and exact reverse mapping were removed and checked. Normal Back exited final playback; original AUTO preference was restored without an AUTO playback test. Temporary maximum awake override was retained per user request; this does not prove a permanent OS always-on setting.

## Privacy, publication and owner decision

Candidate changes are only the reviewed source/test/check scripts, separate from the feature branch. Private signing configuration, generated locks, input libraries, HAPs, media, screenshots, raw device identifiers, network URLs, credentials and logs are excluded. The build scratch intentionally retains unstaged generated signing/lock changes and is not claimed clean. A separate clean checkout is used for this one report-only publication. No original-workspace write/build/reset/clean/stash/checkout command was issued; only the specifically authorized pinned FFmpeg input reads/copy-out occurred. Incidental historical GUI autosave and exhaustive bytewise nonmutation were not measured, so only observed scope is claimed.

Raw evidence and per-round behavioral reports are retained privately. Hashes can be locally corroborated; private raw logs are not remotely replayable. Publishing this report does not validate missing runtime gates. No final review-thread message has been delivered by the current tool set.

FIRST_OPEN_BLOCKER: T00 complete attributable Surface/native resource cleanup is NOT PROVEN, so dependent recovery remains stopped. Other remaining gaps are listed by row. FINAL_OWNER_DECISION_NEEDED: review the single candidate and this consolidated partial evidence; decide follow-up for missing native gates, protocol parity and performance. Do not accept this batch as ALL PASS or merge automatically. Subtitles remain TODO for the user; loop/transcoding features were not added.
