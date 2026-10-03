# Local Browser Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep only immediate browsing controls in the local file list sheet and move persistent display preferences, including hidden-item visibility, into Settings > Local Media.

**Architecture:** Reuse `LocalViewSettingsStore` as the single persistence source. `SettingsPage` edits the existing `LocalViewSettings`, not `AppSettings`; `Index` only broadcasts a revision so the living `LibraryPage` reloads the cached snapshot immediately.

**Tech Stack:** HarmonyOS ArkUI, ArkTS, Preferences, Hypium.

**Spec:** Conversation decision confirmed on 2026-09-20.

## Global Constraints

- Preserve all existing uncommitted work in `D:\Linkora`.
- Add no dependency and no second preference store.
- Keep the system sheet and existing native controls.
- Do not commit unless the user asks.

## Review Focus

- Folder mode must not expose file-only sorting fields.
- File mode must not retain the folder-only item-count sort.
- A preference changed in Settings must update the still-living local list page.
- Existing saved preferences must continue to load without migration.
- Hidden-item management must remain reachable when hidden items exist.

---

### Task 1: Split quick browsing controls from persistent list preferences

**Files:**
- Modify: `entry/src/main/ets/models/LocalMediaViewOptions.ets`
- Modify: `entry/src/test/LocalMediaOrdering.test.ets`
- Modify: `entry/src/main/ets/components/LocalDisplayMenu.ets`
- Modify: `entry/src/main/ets/pages/LibraryPage.ets`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: `LocalViewSettingsStore.load()`, `save()`, and `peek()`.
- Produces: mode-aware sort normalization and a settings revision callback consumed by `LibraryPage`.

- [x] **Step 1: Write the failing sorting-mode test**

Add expectations that folder mode accepts only name/item count, while file mode accepts name/date/size/type and normalizes unsupported fields to name.

- [x] **Step 2: Run the test and verify RED**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
```

Expected: compilation fails because the mode-aware sort helper does not exist.

- [x] **Step 3: Implement the minimum behavior**

Add the sort helper, reduce `LocalDisplayMenu` to view/layout/sort/multi-select, add persistent display switches and hidden-item management to local-media settings, and propagate a settings revision through `Index`.

- [x] **Step 4: Verify GREEN and rendered behavior**

Run the full unit suite, `flutter analyze` is not applicable, then build the Debug HAP. Install it on the emulator and capture both the shortened browser sheet and local-media settings page.

- [x] **Step 5: Review the diff**

Run `git diff --check` and inspect only the task files without committing.
