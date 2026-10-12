# Simulator ABI dependency and installed-identity diagnosis

STATE: COMPLETED READ-ONLY DIAGNOSIS — OWNER CONFIG CHANGE REQUIRED; NOT RUNTIME PASS.
TASK_ID: phase8f-level0-simulator-abi-dependency-install-identity-diagnosis-v1
SOURCE_SHA: 3ee01e2b8c3fd85960e9f857a1efc6452b81ee2b
DISPATCH_SHA: f4eeece4e0384924b75b85a2b0422ac10ee1d1c5
PREVIOUS_EVIDENCE_SHA: 5cd9166f725be3418545a0ef2ea2277390d4bd83
REVIEW_RESULT: SOURCE/LOCK FINDING CONFIRMED; SAME-BUNDLE RECORD PRESENT; EFFECTIVE TARGET MECHANISM AND EXACT SIGNATURE COLLISION NOT PROVEN.

## Source binding and inspected inputs

Fresh independent clone/fetch matched dispatch. Its direct parent is SOURCE; SOURCE's direct parent is previous evidence. SOURCE..dispatch changes only the task; previous evidence..SOURCE changes exactly status and handoff. Initial checkout clean. Full current task/workflow and current status/handoff sections read; unchanged Master Plan revalidated and relevant/full plan contents read in bounded segments. Older archived status/handoff statements do not override the new current sections. No protected workspace, stopped checkout, prior HAP or private old log inspection.

These source blobs are identical at SOURCE and dispatch (full listed source files read, including both checker scripts; scripts were NOT executed):

| File | Git blob |
| --- | --- |
| build-profile.json5 | 2aa38cb8e731ff314d1e99929245cb8550d58e62 |
| entry/build-profile.json5 | adef91aba9a751efe44b0260ee9d2874f9a2c7b5 |
| entry/oh-package.json5 | fcc5e3f9e580b4979bf44b4e08ebb7da79893c98 |
| entry/oh-package-lock.json5 | 68d0837470f09dc81b4d1f787f19eee84254e02a |
| oh-package.json5 | ea81be43f3bcf6e586067e7cf22da899ea41a6df |
| hvigorfile.ts | 91cbb1dc2348d6ec12bea4904212202cd50ab477 |
| entry/hvigorfile.ts | cfc6fc98581ad9fc0355e68188e090295967ffec |
| entry/simulator-stubs/mpv-arkts/oh-package.json5 | 498805011467e6596dbaa596669809dea250254c |
| linkora_ffmpeg/build-profile.json5 | 609e3a208f396d2b7f971c76f2ffa9f4be353c72 |
| scripts/check-simulator-product.cjs | a2f4756e456f52f3359b821a521073c50478c320 |
| scripts/check-ffmpeg-artifact.cjs | 0c42d93cfa28753e8df4a9ed850af8c95db36fab |
| AppScope/app.json5 | 89c04cb90ec269ebed845c92a2a885ce84f59a16 |

## Effective MPV dependency finding

`entry.dependencies['@mpv-ohos/mpv-arkts']='1.0.0'` is unconditional. The checked-in lock's specifier/package record resolves the published `mpv-arkts-1.0.0.har` from the public ohpm registry, not the local stub. The stub has the same package name/version and no native dependency declaration. A separate `simulatorTargetDependencies` field names the stub, but the checked-in entry Hvigor file has no custom consumer; the root only registers assembleSeqPlugin. The static checker at lines88–90 checks that field's value, not actual resolved dependencies or native package contents. These source facts explain why declaration-only STATIC OK cannot establish isolation; exact installed Hvigor/plugin consumption and packaging causality remain **MECHANISM UNCONFIRMED**.

The fresh scratch checkout has no `.hvigor`, `oh_modules`, generated dependencyMap.json5, target-specific generated manifest or simulator lock. They are **NOT PRESENT**, not proof they never existed in the prior run. No install/sync/build was used to generate metadata. Installed ohpm version26.0.0.630 and DevEco CLI1.3.0-stable version queries each exited0; run help and ohpm install help exited0. Help only: no dependency installation. Run help does not expose a parameterFile selection option.

[Official ohpm install documentation](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hmos-ohpm-install) documents target-context manifests selected with `--target_path`, a dependencyMap containing `targetName`, `rootDependency`, `dependencyMap`, and target-specific locks. Thus a generated simulator entry manifest must actually resolve the stub; the current custom declaration alone supplies no such evidence. No reviewed official source establishes `simulatorTargetDependencies` as a supported ohpm key. This is **NOT PROVEN**, not a universal claim about every plugin/version.

## Minimal supported split proposal — OWNER ONLY, not applied

[Official parameterFile configuration](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hmos-oh-package-json5) supports parameter references in dependencies and relative local paths resolved from the parameter file. A concrete alternative to an unconsumed custom key is:

| Proposed file/key | Proposed behavior |
| --- | --- |
| Root oh-package.json5: parameterFile | Point to `./oh-package-default-params.json5` by default. |
| entry/oh-package.json5: dependencies['@mpv-ohos/mpv-arkts'] | Use `@param:dependencies.mpv`; remove the misleading simulatorTargetDependencies field once the supported route is wired. |
| New root oh-package-default-params.json5: dependencies.mpv | `1.0.0`, preserving real production MPV. |
| New root oh-package-simulator-params.json5: dependencies.mpv | `./entry/simulator-stubs/mpv-arkts`, existing compile-only stub. |

Owner must bind selection consistently: simulator dependency resolution uses documented `ohpm --pf` and the subsequent official Hvigor invocation uses `-p parameterFile=oh-package-simulator-params.json5`; default uses default parameters. The Hvigor parameter is [documented](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-hvigor-commandline). This is a proposal for explicit official CLI orchestration, **not** a claim current `devecocli run` automatically forwards the setting. Four configuration files alone do not prove that integration. Alternatively owner may wire the documented target_path manifests; do not combine two override schemes or globally replace production MPV. Lock changes must be generated/reviewed in the later authorized correction, not manually falsified here.

Update `scripts/check-simulator-product.cjs` to test the chosen supported configuration and effective generated resolution/target lock, replacing the custom-field existence assertion. Keep the existing native artifact checker strict. Later one newly source-bound simulator build must pass its x86 audit BEFORE installation: exactly machine62 `libs/x86_64/liblinkora_ffmpeg.so`, no ARM64 directory or real MPV/AKI/CXX foreign-ABI libraries. Merely excluding native files from a still-real MPV dependency is not proof of using the stub. Actual installed toolchain parameter propagation/generated target resolution remains NOT PROVEN until that later controlled checkpoint; no second identical diagnosis is needed first.

## Simulator bundle identity finding

One read-only connected-target check: HDC list0, exactly one target; uname0=x86_64, API query0=26. No lifecycle/config change. bm help0 and dump help0 documented `dump -n`; exactly one `bm dump -n com.linkora.player` query returned transport0, a matching same-bundle record and no semantic error. Classification **SAME_BUNDLE_PREEXISTS / KNOWN categorical presence**. Raw output remains private; SHA256 `253C87A51B056E71C1F4D1ED37F8390E2C0B11AD82BC5F4D10DBF9F07FD24207` identifies only locally retained bytes, not remote raw evidence. No installed-app inventory, signing fingerprint/key export or identity disclosure is published.

An optional PowerShell JSON-object interpretation failed on differently cased `metaData`/`metadata` keys. RECORD_ONLY, not retried; enclosing command ended0, no separate native parser exit. Subsequent False values from an unset object are invalid and do not mean NOT_INSTALLED. Presence relies on the successful bounded named-bundle query's original matching record, not that parser. No claim of independently comparing signatures is made.

AppScope currently sets `com.linkora.player`; neither product overrides bundleName. Existing same-bundle presence makes a collision plausible, but **EXACT SIGNATURE MISMATCH NOT PROVEN**: no new package/certificate was examined and no old HAP was reopened. Multiple-artifact mismatch is UNKNOWN. [Official bm error documentation](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/bm-tool-V5) describes 9568332 as installed/retained-data identity inconsistency or differences among packaged HAP/HSP signatures. It does not establish a wrong keystore password. Separate user-reported 9568347 refers to native ABI parsing, not this signature result.

[Official product customization](https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-hmos-customized-multi-targets-and-products-guides) supports product-specific bundleName. Non-destructive proposal: only root `app.products[name=simulator].bundleName` becomes an owner-selected distinct simulator identity (e.g. `com.linkora.player.simulator`); keep AppScope and default identity unchanged. Intentional checker changes must replace its lines52–57 shared-identity assertions with explicit default preservation plus simulator identity checks. Distinct-name availability and lawful installation are NOT TESTED; no claim this alone fixes signing, ABI or app behavior. Never uninstall/replace/clear existing app data as a shortcut.

## Prior evidence and execution boundary

Prior V2 audit1 and four AArch64 MPV/AKI/CXX entries alongside x86 FFmpeg are **LOCALLY REPORTED** in previous published evidence; they were not replayed from old private artifacts here. Prior actual installer9568332 and user default-HAP9568347 stay distinct historical failures. FFmpeg probe/frame/cancel, WebP output, System MP4/HLS controls/native release/early/>20s cleanup/recovery remain NOT RUN/NOT PROVEN. Simulator MPV stub is unavailable, not real MPV decode; hardware/advanced formats remain deferred.

BUILDS=0; DEPENDENCY_INSTALLS=0; SYNC=0; SIGNS=0; KEYSTORE_OPERATIONS=0; INSTALLS=0; UNINSTALLS=0; RESET/CLEAR_DATA=0; EMULATOR_STARTS=0; MEDIA=NOT RUN; GUI=0. No fixture generation, old-HAP audit, test execution, new helper, source/config/lock edits or protected-workspace operations. Output-truncated policy discovery was followed by bounded relevant reads; no acceptance was inferred from missing text. No exhaustive protected-workspace bytewise comparison claim.

Only this new sanitized report is authorized for publication. Whole candidate reviewed; no private target/device/account/certificate metadata, raw logs, package bytes or local private paths. Ordinary exact-path commit/push and fresh remote readback remain required; final REPORT_SHA is supplied externally after verification.
NEXT_ACTION: GPT commits the supported dependency split plus intentional simulator identity/guard changes, then separately dispatches one source-bound package-audit/install/function checkpoint. Preserve default ARM64 capability and existing user data; do not repeat this diagnosis or V2.
