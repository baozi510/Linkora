# Phase1B evidence index

Sanitized records from real x86_64 emulator executions and host builds at tested source `d8dad1d757c5b7e6a13b9603d540903aba99567a`. Full raw hilog, binaries, launch nonce, signing material and unfiltered logs remain ignored under artifacts/ffmpeg-phase1b.

- runtime-01-records.json: initial 45 PASS / 1 real WebDAV HEAD FAIL, retained.
- runtime-02-records.json and runtime-03-records.json: fresh-process matrices, each 46 PASS / 0 FAIL. DATA, native-initialize and complete are not extra caseRun tests.
- runtime-*-observations.json: process samples and cold-launch/background/foreground observations, limited to captured windows.
- upstream-range-ledger.json and range-summary.json: final round03 real upstream GET/HEAD, ranges and wire byte counts; round01/02 collector was incomplete.
- fixtures.json: independent host ffprobe and SHA256 for synthetic fixtures. No media binaries.
- command-evidence.json: excerpts and original ignored-log SHA256 for failures, build gates, guard red/green, dependency restoration and actual installs. Excerpts are not complete logs.
- hypium.json: actual 164/164 summary and result-file digest.
- x86-final-package-audit.json: simulator HAP native contents and SHA256; unsigned hash is not signed hash.
- final-artifacts.json: final default Release HAP and explicit simulator HAR audits.
- default-isolation.json: actual Debug/Release source-map isolation checks.
- security-scan.json: bounded app PID hilog scan, not proof against every possible leak.
- cleanup.json: own helpers/fixture cleanup; existing protocol services preserved.

Reproduction order is defined by docs/CODEX_FFMPEG_PHASE1B_RUNTIME_RUNBOOK.md. Build/sign using the accepted temporary local signing procedure; supply synthetic fixtures to scripts/ffmpeg-runtime-lab.cjs and run scripts/collect-ffmpeg-runtime.cjs against the simulator. Keep local signing/config and launch endpoint files ignored. Run normal ohpm install after simulator overrides, then full default verification. Do not route production probes to this harness.
