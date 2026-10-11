# Phase 8F Level-1 scoped simulator smoke

REVIEW_RESULT: DEPENDENCY_BLOCKED — SIGNED ARTIFACT.
STATE: COMPLETED WITH FAILURES / PARTIAL. LEVEL: LEVEL_1_FUNCTIONAL.

- TASK_ID: phase8f-level1-scoped-failure-three-open-smoke-v3
- REPOSITORY / BRANCH: baozi510/Linkora / feat/playback-capability-phase8
- SOURCE_SHA: 602cb10c0c346b59b6c879def7669cbaed2f2665
- TESTED_DISPATCH_SHA: 9fc247a5c89173a91e07d1695ae404e70fae82c1
- Unchanged production fix: 8174e6e4f0214958fb83fef46e92170c4c10263a
- AdaptivePlaybackPort Git blob: 1050012dbef214efba5ebccb5571cc9174345c08
- SystemPlaybackPort Git blob: cc78c2611e8582633f2a67cb323f3072f5d8a31f

Fresh clone/fetch/checkout and direct Git inspection matched dispatch, immediate SOURCE parent, task-only drift, the four allowed policy-review documents, initial clean checkout and unchanged production blobs. Actual contracts were read directly from `linkora_core/src/main/ets/playback/`; no historical failed source/staging controller was run. Current workflow, approved scoped-failure/feature-first policy, architecture/migration and CURRENT status/handoff were read. No production source, tests, task, build profile, dependency pin or historical evidence was changed.

## Independent results and dependency boundary

| Check | Observed result |
| --- | --- |
| Installed CLI availability and actual target | PASS: one connected target, HDC list exit0, x86_64 and API26 queries exit0 |
| Normal simulator boot | NOT RUN: target was already present; no reset/start/config operation |
| Existing profile and signing material | Files present; correct two-line live identifier parsing, bundle match, exact device membership and time-window checks true; check process0 |
| Required existing fixtures | PASS: healthy MP4 plus HLS H264 playlist and three segments, all five sizes/hashes match committed truth; no regeneration |
| Ownable route prerequisite | Host fixture port had no listener and no existing mapping; no server/reverse mapping created |
| Existing source-bound signed HAP | NOT PROVEN from existing installed-bundle metadata; old artifact not reused |
| Necessary dependency preparation | One initial normal install exit0; authentic pinned submodules; four current x86 FFmpeg archive hashes and pinned manifest match; dependency inputs only |
| Allowed four-lock EOL normalization | Initial and post-build LF-equivalent text and Git blobs match; only four allowlisted locks restored inside isolated checkout; clean afterward |
| ONE simulator Debug build | PASS, process0, 2026-10-11 18:22:48.2855859Z to 18:23:19.5152251Z; x86 FFmpeg-only native whitelist, one-library ELF/ABI guard and HAP verification passed |
| SDK signing of this fresh HAP | FAIL, native Java/sign-tool exit1 and caller exit1; no signed HAP produced |
| Install / actual foreground window, app tree and screenshot | NOT RUN, blocked by absent signed artifact |

The SDK error is **11014003, Init keystore failed**, with **“keystore password was incorrect”**. Existing material was read without changes; file presence/profile membership did not prove the keystore could be opened with the recorded credential. The cause beyond the tool's stated error is not established. No credential guess, profile/key/SDK mutation, signing retry, second build or permission bypass was attempted. Build PASS is retained independently; actual signature/install acceptance is FAIL/NOT RUN.

One earlier OPTIONAL context-search batch named a nonexistent `test-lab/playback/README.md` and its observed outer process exited1. The native search child code was not separately saved. This is RECORD_ONLY, not an essential source mismatch; it was not repeated. Actual Git inventory and committed fixture metadata independently supplied the needed context. No unrelated successful check was discarded because of this optional error.

| Authorized runtime case | Attempts | Result |
| --- | ---: | --- |
| Healthy System MP4 / real frame, color, positive delta and target fetch | 0 | NOT RUN |
| Separate HLS H264 PREPARING cancel / native release and early/>20s cleanup | 0 | NOT RUN / NOT PROVEN |
| Distinct recovered MP4 | 0 | NOT RUN / NOT PROVEN |

No native player release, actual Linkora foreground, screenshots/pixels, network media fetch, position delta or runtime resource zeros are asserted. Full ARM64 Debug/Release/HAR/HAP milestone audits and physical-device acceptance are **DEFERRED — LEVEL_2/LEVEL_3**. Ordinary HLS playback, HLS HEVC, FFV1, HDR/DV, advanced audio and genuine ARM64 MPV remain DEFERRED/NOT RUN.

## Evidence, privacy and preservation

The two authorized new public files are this report and `test-lab/playback/phase8f-level1-scoped-smoke-20261012/result.json`. They contain authored sanitized facts, process codes/times and explicitly labelled content hashes. Exact original build/sign output streams remain PRIVATE; their recorded SHA256 values do not make those private originals independently readable to GPT. No passwords, signing/profile contents, device/instance IDs, PIDs, private host paths/URLs, HAP, media, screenshots or full hilog are published. No duplicate gzip, inventory/controller files or old Rerun4 110-file material were copied into evidence. Historical STOP/FAIL and unresolved privacy findings remain unchanged and LOCAL UNREVIEWED.

The already-running simulator was left intact. No app installation/start, owned server, reverse mapping, HTTP row or preference mutation occurred; their cleanup is NOT APPLICABLE. No force-stop, wipe/uninstall/reset or unrelated service cleanup was used. Source archive/media and existing signing material were read only. No write/reset/stash/clean/build/checkout in user original or stopped worktrees was performed; exhaustive final bytewise snapshot comparison was NOT RUN, so preservation is limited to observed nonmutation. The isolated checkout returned clean after the authorized EOL restores before these report files were added.

Publication is independent of the signing dependency failure: inspect these two small public files semantically, stage their exact paths, read actual Git staged names/modes/blobs, then ordinary commit/push and fresh remote verification. The final evidence SHA is supplied in chat after verification, never invented or embedded self-referentially here.

Direct `git status --ignored` showed the expressly authorized new result JSON is ignored. Only these two reviewed exact paths are added with the ignore override; no ignore rule, unrelated file or protected source is changed. This is explicit evidence staging, not a force-push or a retry of a failed publication command.

NEXT_ACTION: GPT independently review the published partial outcome. Resolve valid keystore credential access as the smallest separately authorized prerequisite; the fresh source-bound unsigned Debug HAP is retained privately and may avoid an unnecessary future rebuild if its provenance is independently accepted. Do not retry signing or runtime in this completed task. Normal pending cancellation and recovery remain UNVALIDATED; no production/player defect is established.
