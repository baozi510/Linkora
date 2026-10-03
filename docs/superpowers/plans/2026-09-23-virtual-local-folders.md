# Virtual Local Folders Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add phone-first nested virtual folders and repeatable virtual media aliases to the local library while keeping playback state attached to the underlying real document.

**Architecture:** Reuse the existing local-library page, `ManualMediaStore`, and four existing RDB tables. A virtual folder is a `media_collection` row, every import creates a unique `virtual_entry` locator, and the existing `document_picker` locator remains the shared physical identity used for playback, thumbnails, metadata, and permission ownership.

**Tech Stack:** HarmonyOS ArkTS/ArkUI, `@ohos.data.relationalStore`, existing `linkora_core` feature controllers, Hypium tests, existing `scripts/verify.ps1` verification.

**Spec:** `docs/superpowers/specs/2026-09-21-virtual-local-folders-design.md`

## Global constraints

- Keep the current single local-browser page and directory history; virtual navigation must not create page instances or transition animations.
- Root and virtual folders allow import/create; system media-library folders allow neither.
- Every import creates a new alias even when the same real document was already imported.
- Playback, progress, metadata, and thumbnails resolve through the real document URI.
- Deleting aliases or virtual folders never deletes the physical file.
- Do not add 2-in-1 permissions, real directory creation, directory import, a new service layer, or a new database table.

### Task 1: Model virtual identity in the core contract

**Files:**
- Modify: `linkora_core/src/main/ets/models/LocalMediaAsset.ets`
- Modify: `linkora_core/src/main/ets/models/LocalMediaFolder.ets`
- Modify: `linkora_core/src/main/ets/contracts/FeaturePorts.ets`
- Test: `entry/src/test/LocalMediaAsset.test.ets`

**Produces:** `LocalMediaAsset.sourceUri`, `LocalMediaAsset.contentUri()`, `LocalMediaFolder.isVirtual()`, and repository methods consumed by Tasks 2–4.

**Step 1: Write failing model tests**

Add tests proving a manually imported alias keeps its virtual `uri` for UI identity but `toMediaSource()` and `contentUri()` use the real URI, and proving empty virtual folders survive `VIDEO_ONLY` filtering.

```ts
const alias = new LocalMediaAsset('linkora://item/a', 'a.mp4', 0, 0, 0, 0, 0,
  LocalFileCategory.VIDEO, 'linkora://folder/f', LocalMediaOrigin.DOCUMENT_PICKER,
  LocalMediaAvailability.AVAILABLE, 'file://real/a.mp4');
expect(alias.toMediaSource().locator).assertEqual('file://real/a.mp4');
expect(alias.contentUri()).assertEqual('file://real/a.mp4');

const folder = new LocalMediaFolder('linkora://folder/f', 'F', 0, 0, 0, '', 0, '', 0, true);
expect(folder.isVirtual()).assertTrue();
expect(folder.matches(LocalMediaFolderFilter.VIDEO_ONLY)).assertTrue();
```

**Step 2: Run the focused tests and confirm RED**

Run the repository test command filtered to `LocalMediaAsset.test.ets` if supported; otherwise run `scripts/verify.ps1`.

Expected: compilation/test failure because the new constructor values and helpers do not exist.

**Step 3: Add the minimum core model and repository API**

- Add optional final `sourceUri` to `LocalMediaAsset`, defaulting to `uri`; use it only for manually added playback/content.
- Add optional final `virtual` boolean to `LocalMediaFolder`; virtual folders always match folder filters so an empty user folder remains visible.
- Extend `ManualMediaRepository` with:

```ts
loadFolders(): Promise<LocalMediaFolder[]>;
add(sources: MediaSource[], parentUri?: string): Promise<LocalMediaAsset[]>;
createFolder(parentUri: string, name: string): Promise<LocalMediaFolder[]>;
renameFolder(uri: string, name: string): Promise<LocalMediaFolder[]>;
removeFolder(uri: string): Promise<void>;
```

**Step 4: Run the focused tests and confirm GREEN**

Expected: model tests pass; remaining compile failures, if any, identify repository implementers to update in Task 2/3.

**Step 5: Commit**

```powershell
git add linkora_core/src/main/ets/models/LocalMediaAsset.ets linkora_core/src/main/ets/models/LocalMediaFolder.ets linkora_core/src/main/ets/contracts/FeaturePorts.ets entry/src/test/LocalMediaAsset.test.ets
git commit -m "feat: model virtual local entries"
```

### Task 2: Persist folders and aliases in the existing database

**Files:**
- Modify: `entry/src/main/ets/services/LinkoraDatabase.ets`
- Modify: `entry/src/main/ets/services/ManualMediaStore.ets`
- Test: `entry/src/test/FeatureModules.test.ets` (fake contract coverage)

**Consumes:** Task 1 repository API and identity fields.

**Produces:** schema v8 migration and the real `ManualMediaRepository` behavior used by the controller.

**Step 1: Write failing repository-contract tests in the fake**

Update the fake repository only enough to compile the new interface, then add tests that express the required behavior through the repository contract:

```ts
const first = await manual.add([source], '');
const second = await manual.add([source], '');
expect(first[0].uri === second[0].uri).assertFalse();
expect(first[0].sourceUri).assertEqual(second[0].sourceUri);

await manual.createFolder('', 'A');
const a = (await manual.loadFolders())[0];
await manual.createFolder(a.uri, 'B');
expect((await manual.loadFolders())[1].parentUri).assertEqual(a.uri);
```

Add deletion coverage showing recursive folder removal removes aliases but leaves the underlying source/progress identity available to other aliases.

**Step 2: Run tests and confirm RED**

Expected: the fake cannot satisfy duplicate alias/nested deletion behavior yet.

**Step 3: Add schema v8 migration**

- Set `SCHEMA_VERSION` to `8`.
- Add a migration that creates the virtual root collection, converts existing `@manual` memberships to deterministic `linkora://item/migrated-<locatorId>` aliases, places them in the virtual root, updates counts, and removes only the old `@manual` collection membership container.
- Keep the real `document_picker` locator and media entity intact.
- Use `INSERT OR IGNORE` so a partially retried migration is safe.

**Step 4: Replace the old single collection behavior with aliases**

Inside the existing serialized `enqueue()` and RDB transaction flow:

- `add`: upsert the real media/entity locator, create one new `virtual_entry` locator per chosen source with `util.generateRandomUUID(true)`, and add it to the root or requested virtual folder.
- `load`: join alias locator → media entity → real document locator and expose alias URI, parent folder URI, and real `sourceUri`.
- `loadFolders`: return all virtual folder collections except the internal virtual root.
- `createFolder`: trim/validate the name, reject duplicate sibling names, and insert a nested `virtual_folder` collection.
- `renameFolder`: apply the same sibling-name rule.
- `remove`: remove one alias; revoke/delete its real locator only when no other alias references that media identity.
- `removeFolder`: compute descendants from the loaded collection rows, delete their aliases and collections in one transaction, then clean up only orphan real locators.
- `verify`/`removeUnavailable`: verify physical document locators and project status back onto every alias.

**Step 5: Run tests and confirm GREEN**

Run the project test command.

Expected: duplicate-alias, nesting, shared-identity, and recursive-delete tests pass.

**Step 6: Commit**

```powershell
git add entry/src/main/ets/services/LinkoraDatabase.ets entry/src/main/ets/services/ManualMediaStore.ets entry/src/test/FeatureModules.test.ets
git commit -m "feat: persist virtual local folders"
```

### Task 3: Project virtual folders through the local-library controller

**Files:**
- Modify: `linkora_core/src/main/ets/features/LibraryFeatureController.ets`
- Modify: `entry/src/test/FeatureModules.test.ets`

**Consumes:** Task 1 model/contract and Task 2 repository behavior.

**Produces:** root/virtual/system navigation boundaries and mutations used by the page.

**Step 1: Write failing controller tests**

Cover these behaviors:

- initialization merges virtual folders and root aliases into the normal catalog;
- opening a virtual folder projects its children without calling the system scanner;
- import is allowed at root and inside a virtual folder, and rejected inside a system folder;
- create/rename/delete refresh the current projection;
- two aliases of one source both receive the same playback progress while retaining distinct UI keys.

**Step 2: Run tests and confirm RED**

Expected: virtual folders are missing and system scanning/import guards are wrong.

**Step 3: Extend the existing controller, not the navigation architecture**

- Keep `manualItems` and add `manualFolders`.
- Load both during initialization and verification.
- Merge them in `projectLocal()`.
- In `selectFolder()` and refresh, recognize a virtual folder and project it directly without `scanDirectory()`.
- Change `pickLocal(parentUri = state.selectedFolderUri)` to accept only root/virtual targets.
- Add minimal `createVirtualFolder`, `renameVirtualFolder`, and `removeVirtualFolder` methods that call the repository then reload/project.
- Include `sourceUri` and virtual status in equality checks so state updates are not skipped.

**Step 4: Run tests and confirm GREEN**

Expected: all controller tests pass and existing system folder navigation tests stay green.

**Step 5: Commit**

```powershell
git add linkora_core/src/main/ets/features/LibraryFeatureController.ets entry/src/test/FeatureModules.test.ets
git commit -m "feat: navigate virtual local folders"
```

### Task 4: Add the native toolbar and long-press UI

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/LibraryPage.ets`
- Modify: `entry/src/main/ets/components/LocalMediaBrowser.ets`
- Modify: `entry/src/main/ets/components/LocalMediaRow.ets`
- Test: `entry/src/test/FeatureModules.test.ets`

**Consumes:** Task 3 controller commands and Task 1 content identity helpers.

**Produces:** user-facing import/create/rename/delete flow.

**Step 1: Add a failing boundary test**

Add a small pure helper or controller assertion demonstrating that toolbar mutations are exposed for root/virtual folders but not system folders. The production change that makes it pass must be the shared folder-kind predicate used by the UI/controller, not duplicated guards.

**Step 2: Run tests and confirm RED**

Expected: no shared predicate/UI flow exists yet.

**Step 3: Wire the minimum ArkUI flow**

- Pass the selected folder to import from `Index`.
- Add one `MORE_VERT` toolbar menu in `LibraryPage` only for root/virtual folders, with `导入视频` and `新建虚拟文件夹`.
- Reuse the page’s native sheet style and a `TextInput` for create/rename; validate a non-empty trimmed name and surface repository errors.
- Add rename/delete actions to the existing folder long-press sheet only for virtual folders; keep system-folder hide behavior unchanged.
- Mark virtual folders with a light `虚拟` metadata chip.
- Load thumbnails with `item.contentUri()` while keeping selection/progress keyed by alias `item.uri`.
- Keep current direct local-folder navigation without page transition animation.

**Step 4: Run tests and build**

```powershell
.\scripts\verify.ps1
```

Expected: all tests, static API checks, and the debug Hap build pass.

**Step 5: Commit**

```powershell
git add entry/src/main/ets/pages/Index.ets entry/src/main/ets/pages/LibraryPage.ets entry/src/main/ets/components/LocalMediaBrowser.ets entry/src/main/ets/components/LocalMediaRow.ets entry/src/test/FeatureModules.test.ets
git commit -m "feat: manage virtual folders in local library"
```

### Task 5: Migration, cleanup, and final verification

**Files:**
- Modify only files required by failures or review findings.

**Consumes:** all prior tasks.

**Step 1: Audit all alias consumers**

Search every `LocalMediaAsset.uri`, thumbnail call, removal call, playback call, equality comparison, and hidden-item key. Confirm UI identity/removal remains alias-based while media I/O is real-URI-based.

**Step 2: Run the full verification from a clean working state**

```powershell
.\scripts\verify.ps1
git diff --check
git status --short
```

Expected: verification exits `0`, `git diff --check` emits nothing, and only intentional plan/work files are present before the final commit.

**Step 3: Review the complete branch against the spec**

Review specifically for:

- accidental physical deletion or permission revocation while another alias exists;
- duplicate imports being collapsed by SQL uniqueness or catalog projection;
- virtual folders triggering system scans;
- virtual item URI leaking into playback/thumbnail APIs;
- migration losing old manually imported entries;
- system folders exposing import/create actions;
- folder cycles or invalid parents introduced by mutation methods.

Fix Critical/Important findings test-first, then rerun the full suite.

**Step 4: Commit final fixes if needed**

```powershell
git add <reviewed-files>
git commit -m "fix: harden virtual local folders"
```

