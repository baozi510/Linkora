# Build isolation evidence

Tested source: ce24be1daf12892bfaa028bcd138fca25116a320. Runbook: docs/CODEX_BUILD_ISOLATION_HARDENING.md. Full logs, HAPs, signing material and local fixture drivers remain ignored under artifacts/build-isolation.

- commands.json: actual outer verifier commands, timestamps and child exit codes. cycle2-simulator with null exit code and its initial default are not counted as an accepted cycle; the complete final cycle was rerun.
- restoration-sequences.json: two accepted success switches and the fault switch; restoration occurred in simulator verifier finally. No manual install inserted. Gap is between outer invocations, not child startup duration.
- baseline / cycle1-default / cycle2-default-final / failure-default Debug and Release JSON: separate actual HAP SHA256 and complete native entry/path/ELF/SHA256 manifests, captured after each mode audit.
- cycle1-simulator and cycle2-simulator-final simulator JSON: actual one-library x86 manifests; final signed HAP was retained and installed.
- failure-mechanism.json: local-only generated artifact move, original manifest hash verification and intended nonzero simulator result.
- command-evidence.json: sanitized success/failure excerpts and original ignored-log hashes, including the null collector attempt and initially incomplete CMake toolchain arguments. No unrelated failure is treated as manifest guard PASS.
- manifest-negative-results.json: real production CMake configure arguments and expected guard rejection for three copied manifests. No fake headers/libs; real manifests unchanged.
- hypium.json: final actual 164/164 result summary and result-file hash.
- signing-restoration.json and install-launch.json: local signing config exact restoration and actual HDC install/ordinary launch/foreground observation. No fresh 46-case runtime claim.
- tracked-state.json: protected paths with empty diff from starting SHA, no generated binaries tracked; status recorded before report commit.
- environment.json: actual toolchain versions.

Snapshots are read-only observations. Default Debug is captured immediately after its successful audit marker before Release overwrites the common output filename. Reproduce only via the ordered runbook; do not insert manual dependency restoration in target switches.
