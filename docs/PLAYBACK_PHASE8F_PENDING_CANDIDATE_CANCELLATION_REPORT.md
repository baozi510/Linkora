# Phase 8F Pending Candidate Cancellation Validation

Primary **FAIL — REQUIRED TEST GATE**. Strict STOP after the single healthy baseline private-helper assertion; cancellation and recovery are **NOT RUN / NOT PROVEN**. This does not establish a production playback regression or validate the pending-candidate fix.

- Task: `phase8f-sim-adaptive-pending-candidate-cancel-recovery`
- Repository/branch: `baozi510/Linkora`, `feat/playback-capability-phase8`
- Source: `8174e6e4f0214958fb83fef46e92170c4c10263a`
- Tested dispatch: `616e0ed6ddb838edb2b7cc50dcd88fff1193f46f`
- Prior Phase 8E failed evidence `e99ad8928811d394e65efb1ca31d77fb1c885c72` remains immutable.

## Fresh gates and deployment

Exact source/ancestry/Task-only drift, distinct clean checkout, three exact committed submodule pins with checked upstream origins. One normal initial install; separately complete fresh four-lock EOL proofs after initial and simulator finally installs. Full default → simulator → immediate final default PASS. Both independent Hypium raw captures show 210/210, zero failure/error/ignore. Each default has two exact-nine ARM64 audits; simulator has only the approved x86 FFmpeg library, parity/isolation/audio static guard. Dependency archives are authenticated inputs; no old app artifact or test result reused.

New signed simulator HAP SHA256 `E5427B9796ADC1B3D59E2DD591C6461C97C8709A68DFB43E03ECF0C7581F081D`, 25295980 bytes. Existing legal profile/signature checks unchanged; signed whitelist/ABI PASS, explicit replace-install success, ordinary coldlaunch, app data retained. A private CLI setup invocation used `--abi=x86_64` instead of positional `x86_64`; it was rejected as Unsupported ABI before validation. Original logs remain; corrected invocation checked the same signed HAP successfully. No build/sign/install/playback repetition resulted.

## One baseline open and precise STOP

Four retained fixtures / ten files freshly match local, authenticated TLS WebDAV whole GET/Range, ffprobe and committed truth. Own loopback server served all ten matching bodies. Exactly one actual `rport tcp:19084 tcp:19084`, explicit success and actual Reverse listing. The one official MP4 invocation proves native AVPlayer device→host GET/Range206 separately from host probes.

The healthy baseline native timeline shows initialized → prepared → play → playing, actual first-frame submission callback and 320×180 size. Real XComponent screenshot ROI shows the expected multicolor pattern. Position advanced positively by **766ms**. Leave sampled surface/service/audio entries all zero.

The reused private helper retained its **>=800ms** predicate: original `positionAdvanced=false`, `BOUNDED FAIL / UNRESOLVED`, and assertion failure/exit1 are published unchanged. The repo task asks for positive progress, so the 766ms observation meets that narrow observation; it does not make the helper assertion pass. Codex stopped at the failure, did not relax the helper, rerun, append further fixture opens, or claim an unhealthy production source solely from this threshold. GPT should resolve the task/helper criterion explicitly in a **new READY task**.

| Scenario | Actual execution |
|---|---|
| A healthy MP4 | 1 open; native/pixels/positive progress/clean leave observed; raw helper threshold FAIL |
| B HLS H264 / HEVC | NOT RUN |
| C FFV1 representative | NOT RUN |
| D pending HLS cancellation | NOT RUN / NOT PROVEN |
| E distinct healthy recovery | NOT RUN / NOT PROVEN |

Total **1 distinct official open**, **0 retries**. No Phase 8E or other historical PASS is inherited. Static exact-source checklist finds pending candidate ownership/release and stale result checks in the new patch; runtime cancellation, late commit, double release, resolver/factory races, initialization/prepare promise rejection/timer clear remain NOT PROVEN.

## Cleanup, evidence and scope

Normal cleanup restored original Auto and local UI, removed only owned temporary HTTP row and reverse mapping (list Empty), stopped only owned server (19084 listener absent). Final surface/app-matching PlayerDistributedService/audio renderer entries zero. No force-stop after the fixture, no wipe/uninstall. Service entries are not proven native object counts; audio records are not audibility; sampled zeros do not prove exhaustive absence of leaks. Owned media/WebDAV and unrelated services remain.

Evidence: `test-lab/playback/phase8f-adaptive-candidate-cancel-recovery-sim-20261008/`. Native selected logs are explicitly **after-minus-before subsets**; healthy native capture ended before leave, so its missing native release line is not a release-failure verdict. Private originals, screenshot/HAP/signing/credentials are retained locally and not published. Sanitized logs preserve original errors, warnings, counters and gzip/SHA256 provenance. Protected audit covers all 2872 initial regular Git files and original workspace state; only this report/new evidence is authorized.

No physical ARM64, real MPV, Mate60 codec, HDR/DV/passthrough/performance certification. The current correction remains unvalidated until a new authorized cancellation/recovery execution. GPT owns any source/task adjustment; Codex made no production/test/expectation/policy/task change.
