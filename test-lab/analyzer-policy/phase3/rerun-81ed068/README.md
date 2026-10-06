# Phase 3 post-review validation rerun evidence

Source: `81ed0684b273e25afbed056a055ee23aded0b661`.
Branch: `feat/ffmpeg-analyzer-policy-phase3`.
Date: 2026-10-05 Asia/Shanghai (UTC command records start on 2026-10-04).

Fresh full `scripts/verify.ps1`: **FAIL**, exit 1, at desktop network-media-list module loading. ArkUI guard passed; new failure is ENOENT for `entry/AnalysisComposition.ets`. No Hvigor Hypium, HAR/HAP, simulator or production runtime was executed. This directory contains no old-run results.

- `verify-stdout.txt` / `verify-stderr.txt`: original redirected output, unchanged.
- `verify-command.json`: actual wrapper timestamps, exit code and missing Debug checkpoint.
- `verify-command-details.json`: source, executable, cwd, nested failure and stop condition.
- `ohpm-install.txt` / `ohpm-command.json`: normal dependency install, exit 0.
- `failure-context.txt`: numbered original imports/desktop-loader/verifier context, absent alias-file check and real target composition hashes.
- `protected-before.json` / `protected-after.json`: 863 tracked source/build/package/script files, changed 0.

Secret scan candidates were reviewed: a fixed test-only `http://127.0.0.1/test` stub, the parameter name `fingerprint`, and descriptive authorization case text. No actual credential, proxy token, upstream locator or signing material is present. Raw stdout includes existing harness durations only; they are not analyzer performance metrics or comparisons.

Historical first-run evidence remains in the parent directory. The current report is `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`, beginning with the post-review rerun section. Do not interpret historical tables as this rerun's results.
