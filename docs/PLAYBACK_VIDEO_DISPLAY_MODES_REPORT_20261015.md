# Three native video display modes — 2026-10-15

Outcome: IMPLEMENTED AND COMPILED; DEVICE RENDERING ACCEPTANCE NOT RUN.

Direct user request: expose the conventional Fit, Crop and Stretch modes for System AVPlayer and MPV. Use native scaling rather than implementing video-size or crop calculations. The 100% original-size mode is excluded.

- Base: `770a2a3650f28ebd1a9ce9e22ba9845c82b15f6c` (the preceding event/control candidate).
- Candidate branch: `codex/linkora-video-display-modes-v1`; not merged to the product branch.
- No new package dependency, compatibility layer, credentials, or media input.

## Contract and actual implementation

| Public mode | Meaning | System AVPlayer | MPV native properties |
| --- | --- | --- | --- |
| `VideoDisplayMode.FIT` | Preserve aspect ratio, show the whole image, allow letterboxing | `VIDEO_SCALE_TYPE_SCALED_ASPECT` (API20+) | `keepaspect=true`, `panscan=0`, `video-unscaled=no` |
| `VideoDisplayMode.CROP` | Preserve aspect ratio, fill the viewport and crop excess edges | `VIDEO_SCALE_TYPE_FIT_CROP` | `keepaspect=true`, `panscan=1`, `video-unscaled=no` |
| `VideoDisplayMode.STRETCH` | Fill the viewport without preserving aspect ratio | `VIDEO_SCALE_TYPE_FIT` | `keepaspect=false`, `panscan=0`, `video-unscaled=no` |

- Added `PlaybackPort.setDisplayMode(mode)` and the appended optional `onDisplayModeChange(mode)` callback, relayed through the existing Adaptive and Engine layers.
- Engine requests FIT after prepare. `PlaybackSnapshot.displayMode` is initially null and updates only after native configuration readback; rejection leaves it unknown and publishes a nonfatal `display-mode` warning. A successful later setting clears that warning.
- The last successful requested mode is reapplied on reopen/retry/stop-replay within the same Engine instance. No new cross-session settings persistence was added.
- Existing normal/fullscreen controls have one button cycling Fit → Crop → Stretch → Fit. The visible current-mode label is also the accessible button text. An unknown applied mode uses the generic mode label.
- Fullscreen Surface now fills the available window; the normal viewport retains its existing 16:9 layout. Existing vp-to-physical-pixel Surface sizing remains. Neither backend uses application-computed scaling ratios or crop rectangles.
- MPV resets all three owned properties on every switch, so previous crop/stretch configuration is not left behind. Simulator MPV remains explicitly unavailable; its declarations only mirror the required native API signatures.

Readback establishes native API configuration acceptance, not renderer/frame completion. System AVPlayer in particular returns a cached property value while renderer configuration is queued. MPV options may also depend on the current video output. No actual rendering result is inferred from those getters.

## Validation and operations

| Check/action | Actual result |
| --- | --- |
| Production adapter/Engine host checks | 52/52 PASS; controlled native boundaries, not physical playback |
| SDK/Hypium suite | One invocation, native0 and semantic 224/224 PASS, zero failures/errors |
| New SDK feature case | FIT/CROP/STRETCH cycle, initial unknown state, selection retained after stop/replay |
| Architecture/artifact-checker self-tests | 22/22 PASS |
| Architecture boundary check / diff whitespace | PASS |
| ARM64 debug application build | Two successful invocations; second contains the reviewed accessibility adjustment |
| Fresh HAP native ABI audit | PASS, nine ARM64 libraries |
| Independent read-only code review | Accessible-label issue fixed; no other actionable correctness finding; device-rendering limitation retained |
| Device inventory | Empty; no reconnect attempt in this round |
| Signing / install / start / video playback | NOT RUN |
| GUI / simulator / original workspace writes | No such operation issued |

Six initial display-mode regressions failed before implementation. Additional tests verified platform error details and rejected initial configuration without stopping playback. The final suite covers native enum mapping, crop/stretch resets, invalid/released calls, readback disagreement, stale candidate callbacks, reopening and nonfatal failure behavior.

Fresh unsigned artifact: `entry-default-unsigned.hap`, 64,089,612 bytes, SHA256 `527C1D6E7EFEBCC3F80E99D98C748375B224F85DD9EB3D7A1C374D8DB02A7E7E`. Raw logs/HAP remain private. Existing prebuilt inputs and pinned dependencies were reused from this isolated checkout. Four pre-existing generated lock-file modifications remain unstaged; they are excluded from this change. Cancelled automation remains cancelled.

## Remaining device acceptance

Use the actual application on an unlocked phone. Select System and MPV separately, use videos whose aspect differs from the viewport, and verify all three modes in both normal and fullscreen windows. Check crop removes edges without distortion, fit preserves the entire image, stretch fills the viewport, and switching back removes prior transforms. Include pause/resume and window rotation. These visual checks, screenshots and frame calibration are NOT RUN; no physical or simulator rendering PASS is claimed.

API references: installed SDK media declarations; [official VideoScaleType documentation](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-media-kit/arkts-apis-media-e.md#videoscaletype9); [MPV reference manual](https://mpv.io/manual/stable/#video); [System native setter/getter implementation](https://github.com/openharmony/multimedia_player_framework/blob/master/frameworks/js/avplayer/avplayer_napi.cpp). Subtitle work remains deferred.
