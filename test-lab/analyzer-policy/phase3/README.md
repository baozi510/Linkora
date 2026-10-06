# Phase 3 test-only evidence

Tested source: `72e74d11a790bd0d258e219e3a8de18f3c59fd17`.
Result: FAIL at the first default verification static gate; stop condition applied.

- `verify-stdout.txt` / `verify-stderr.txt`: original complete failing output. No signing/credentials/proxy URLs or upstream locators occurred in this run.
- `verify-command.json`: actual exit1 and command record. `verify-command-details.json` identifies the PowerShell executable, working directory, source SHA and stop point.
- `ohpm-install.txt` / `ohpm-command.json`: normal dependency install, exit0; no tracked lock change.
- `protected-before.json` / `protected-after.json`: 791 tracked source/profile/lock/test hashes and unchanged-file result. Hashes are not secret file contents.
- `failure-context.txt`: exact unchanged method-parameter and verifier-regex context.

Executed existing pure cases: FFmpeg15/15, adapter/policy45/45, architecture fixtures5/5 and artifact guard fixtures17/17. These are not a Hypium run or a new HAP ABI audit. Hypium, HAR/HAP builds, simulator, production-loader runtime, fallback/cache/lifecycle and runtime security scans remain NOT RUN. Old Phase2 binaries/results were not reused as Phase3 evidence.

The default verifier classified a defaulted method callback parameter as an ArkUI output-field violation. Root cause assessment is read-only; review is required before changing source/checker. No source/config/lock/test-expectation edits, bypasses or fixes were made.

No performance samples or benchmark report. Incidental Node fixture-runner durations in original stdout are preserved as exact test output, not compared between engines.
