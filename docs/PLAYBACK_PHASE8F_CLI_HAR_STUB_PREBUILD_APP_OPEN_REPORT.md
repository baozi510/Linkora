# CLI HAR-stub PreBuild and normal simulator app open

STATE: COMPLETED — SOURCE-ALIGNED CLI SIMULATOR APP OPEN PASS; MEDIA NOT RUN.
TASK_ID: phase8f-level1-cli-har-stub-prebuild-and-app-open-v1
SOURCE_SHA: 56a8ba073267305e7ecb950fd2576f94e31fbb76
DISPATCH_SHA: b46e115b5712df32a92f0afdd95ce738d096e8ac
CAN_OPEN_NORMALLY: YES within this bounded native Ability/foreground checkpoint.
CANDIDATE_SHA_OR_NONE: NONE — no tracked source repair required.

## Source, inputs and dependency proof

Fresh isolated build clone completed0, then fetch0 matched dispatch. Direct parent SOURCE; SOURCE..dispatch only the current task. Prior superseded dispatch c78bb62da04a536026833f49f86663a0208c24b8..SOURCE exactly the nine declared HAR/config/checker/status/handoff/task files. The older autonomous task ID was not executed. Full current task and relevant new HAR manifests/module registration read; workflow/Master Plan readings revalidated unchanged, latest complete CURRENT status/handoff sections read. No AGENTS found in tracked inventory.

SOURCE makes the local stub a registered simulator-only HAR: module build-profile, harTasks hvigorfile and HAR module.json are present, with package name/version unchanged and modelVersion/empty dependencies added. Default real MPV1.0.0 and production AppScope remain unchanged; simulator product selects its distinct bundle identity. This code was initially a hypothesis, not inherited compiler PASS.

Only the explicitly authorized original x86 prebuilt input subtree was read. Pinned manifest n8.1.3/FFmpeg commit1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7/x86_64 matched; original/copy manifest and four required header byte hashes matched. Copied only includes, manifest and the four archives to the new ignored scratch x86 prefix; no ARM64 libraries or old HAP/log/profile/credential material. Original and copied archive SHA256 each matched:

| Archive | SHA256 |
| --- | --- |
| libavformat.a | 697CD7D4861418A1091421337B48D6E1DE255F8EE9341005A44DA7AD7EA1AED1 |
| libavcodec.a | 9DDD5CE0292E4E372263029DE6AACB00BF8BE5BCED86AF1D989B52D927DD4170 |
| libavutil.a | 074AE78E9D6C1BFD9FDAE7A161409F48EABA39D1D979B973C3CA233BA24DBB2A |
| libswscale.a | 452F0BB617EEC5C8A9CE0872AE28B478AE74828A04725971823EB283328D74C9 |

One existing connected target: HDC list0, uname0=x86_64, API query0=26. Simulator starts0, no lifecycle/settings changes. One explicit official OHPM `install --pf oh-package-simulator-params.json5` exited0. Actual generated entry lock/source checker exited0; the installed MPV junction fully resolved to this scratch source's local stub. No remote real MPV was selected. Dependency declaration/static proof alone was not promoted to compilation acceptance.

## One build, one fresh native audit

BUILD_COUNTS: 1 of maximum3. SCRATCH_FIXES: 0. OHPM_INSTALLS: 1 of maximum2. No candidate branch/commit or repeat build.

Direct installed Hvigor: `assembleHapSeq --mode project -p module=entry@simulator -p product=simulator -p buildMode=debug -p parameterFile=oh-package-simulator-params.json5 --no-daemon`.
Original wrapper exit0; UTC2026-10-12T16:23:21.3784363Z to2026-10-12T16:23:49.8818777Z. No default ARM64/Release/full verify invocation or FFmpeg bootstrap rebuild. HAR_PREBUILD_00306060: **FIXED FOR THIS BUILD** — newly completed HAR source passed the actual PreBuild/build path. This does not isolate which individual added HAR file was causal or rewrite the prior direct-user failed build.

Exactly one newly produced HAP, 25,098,354 bytes, SHA256 `992749423D5CBE34179D5E4B9C7BB0A9FDD3AD368E16B762C8FAB368AAD2752C`. Embedded module.json reads `app.bundleName=com.linkora.player.simulator`, module entry. Actual native entry inventory: only `libs/x86_64/liblinkora_ffmpeg.so`.

Existing `scripts/check-ffmpeg-artifact.cjs <fresh-hap> x86_64` ran once, exit0: exactly one approved library, ELF64 little-endian machine62, no ARM64 or real MPV/AKI/CXX native library. NEW_HAP_X86_ABI_AUDIT: PASS. No ZIP alteration, old-HAP reuse or waived checker. Manual SDK sign-app/keytool/keystore/profile operations0; normal build pipeline behavior is not a manual signer invocation.

## One legal install and one normal Ability start

Only after bundle/ABI PASS, one ordinary HDC install of this exact fresh HAP: native exit0, explicit `install bundle successfully`; UTC2026-10-12T16:24:47.7116178Z to2026-10-12T16:24:48.6522446Z. No new9568332 or9568347. No uninstall, data clearing, force-stop, reset/wipe, signature bypass or replacement of production com.linkora.player. CLI_INSTALL: PASS.

One `aa start -a EntryAbility -b com.linkora.player.simulator -m entry`: native exit0, explicit `start ability successfully`; UTC2026-10-12T16:25:22.9838718Z to2026-10-12T16:25:23.2996291Z. No second launch. Subsequent bounded native Ability dump contains the matching simulator bundle/EntryAbility record with `state #FOREGROUND` and `app state #FOREGROUND`; named process lookup returned a numeric live process. Foreground state from other applications in the immediate dump was not used as target proof, and process existence alone was insufficient.

A single nonblocking buffered hilog read filtered to that app process exited0; no selected fatal/uncaught/crash markers were observed in the bounded output. This is not exhaustive crash-log inspection or long-term stability proof. ABILITY_OPEN_NORMAL: PASS for an installed current-source EntryAbility in foreground with no fatal error observed. No screenshot, pixel/layout assertion or desktop GUI interaction was used.

## Provenance, privacy and limits

Private original SHA256: build stdout `2832E86C9DB7CD9CA9146FECF384471E3C119DFD742BB0C9F897043789B8EF98`, build stderr `8EBBEE18E618151D7D57AB111AECDCAB51C72AC822236F25E3E5D13B2209B2CA`, HAP audit stdout `525D3009A3312CA2A5BF218DF84BD9D615DEC5A26D4E078C8D5D8E4496068BFA`, install stdout `443A8EE685786BFA5BE27D59E6A894C6EB7A7A738D61C70EF58AC1769E83AF94`, start stdout `BC4BD248D1572C3F2E55D8F5B81EA541E62C0D6C7AC7A903B220E672E2F0C83A`, later Ability dump `985D6680CD6B14459B839697EE4852166A397D8AF4CC9FCBD135875EDBA32D69`, app-scoped log `1825EC7C3EB12AAED282A3BAC0EEF8C6F2BA2BEA143E6E8485C1109DC048592E`. These hashes identify locally retained raw bytes; binaries, logs and private IDs remain private and are not remotely replayable evidence.

GUI0 means desktop/IDE/Computer Use operations0; native application launch through CLI was the intended operation. SIGN_APP0; OLD_KEYSTORE0. MEDIA_NOT_RUN: FFmpeg probe/real frame decode/cancel, WebP encoding/redecode, MP4 controls, HLS pending cancellation/resource cleanup and recovery all0/NOT RUN. No media server/rport or fixture generation. Real MPV/hardware/ARM64/advanced codecs/performance and long-running stability remain deferred. Normal app-open PASS does not imply media PASS.

USER_ORIGINAL_READ_ONLY: only approved existing x86 inputs read/copied outward; no original reset/clean/stash/checkout/build/file write. Exhaustive original bytewise snapshot NOT RUN. Build scratch has tool-generated entry lock remote-to-local semantic change and three other marked locks with no Git semantic diff reported; these remain private/uncommitted, no manual lock restore. No authored tracked source changes, so source-bound evidence remains SOURCE/dispatch above. App and simulator are left running for user use, not force-stopped as cleanup.

Report publication uses a separate clean isolated checkout at exact dispatch. Only this new regular sanitized report may be staged; no generated lock, binary, private paths/URLs, device/user/process/record IDs, certificate/profile/secret fields or raw application inventory. Full candidate reviewed before ordinary report-only push; remote exact parent/path/blob/full readback required. Final REMOTE_REPORT_SHA is supplied externally after verification.

NEXT_ACTION: owner reviews this basic app-open result, then dispatches a separate narrowly scoped decoder/encoding/playback functional checkpoint. No further build/launch/media test under this completed ID.
