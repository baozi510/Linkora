// Execute the actual ArkTS services against disposable SQLite databases.
// Harmony bindings are replaced here; device interaction is verified separately.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { DatabaseSync } = require('node:sqlite');
const { randomUUID } = require('node:crypto');
const studio = process.argv[2] || 'C:/Program Files/Huawei/DevEco Studio';
const ts = require(path.join(studio, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript'));
const root = path.resolve(__dirname, '..');
const cache = new Map();
const revoked = [];
const kits = {
  '@kit.AbilityKit': {}, '@kit.BasicServicesKit': {},
  '@kit.ArkData': { relationalStore: {} },
  '@kit.ArkTS': { util: { generateRandomUUID: () => randomUUID() } },
  '@kit.CoreFileKit': { fileShare: { OperationMode: { READ_MODE: 1 },
    revokePermission: async policies => revoked.push(...policies.map(policy => policy.uri)) } },
  '@kit.MediaKit': {}
};
function load(file) {
  if (kits[file]) return kits[file];
  if (file === 'linkora_core') file = path.join(root, 'linkora_core/Index.ets');
  if (!file.endsWith('.ets')) file += '.ets';
  if (cache.has(file)) return cache.get(file).exports;
  const module = { exports: {} };
  cache.set(file, module);
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  vm.runInThisContext(`(function(require,module,exports){${code}\n})`, { filename: file })(
    name => load(name.startsWith('.') ? path.resolve(path.dirname(file), name) : name), module, module.exports);
  return module.exports;
}
class Store {
  constructor() { this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON'); }
  get version() { return this.db.prepare('PRAGMA user_version').get().user_version; }
  set version(value) { this.db.exec(`PRAGMA user_version = ${value}`); }
  beginTransaction() { this.db.exec('BEGIN'); }
  commit() { this.db.exec('COMMIT'); }
  rollBack() { this.db.exec('ROLLBACK'); }
  async execute(sql, args = []) {
    if (this.fail && this.fail(sql, args)) throw new Error('Injected write failure');
    return this.db.prepare(sql).run(...args);
  }
  async querySql(sql, args = []) {
    const statement = this.db.prepare(sql);
    const names = statement.columns().map(column => column.name);
    const rows = statement.all(...args);
    let index = -1;
    return { goToNextRow: () => ++index < rows.length, getColumnIndex: name => names.indexOf(name),
      getString: column => rows[index][names[column]] ?? '', getLong: column => rows[index][names[column]] ?? 0,
      close: () => {} };
  }
}
const service = name => load(path.join(root, 'entry/src/main/ets/services', name));
const { LinkoraDatabase } = service('LinkoraDatabase');
const { ManualMediaStore } = service('ManualMediaStore');
const { HiddenLocalItemStore, HiddenLocalItem } = service('HiddenLocalItemStore');
const { LocalMediaMetadataReader, LocalMediaMetadata } = service('LocalMediaMetadataReader');
const { MediaSource, LibraryFeatureController, LocalMediaPickResult } = load('linkora_core');
LocalMediaMetadataReader.read = async uri => new LocalMediaMetadata(!uri.includes('missing'), 100, 1, 90000, 1920, 1080, true);
const sqlSource = fs.readFileSync(path.join(root, 'entry/src/main/ets/services/LinkoraDatabase.ets'), 'utf8');
const versions = [...sqlSource.matchAll(/const VERSION_\w+_STATEMENTS: string\[\] = (\[[\s\S]*?\]);/g)]
  .map(match => new Function('return ' + match[1])());
function seed(store, version) {
  for (let index = 0; index < version; index++) {
    for (const sql of versions[index]) store.db.exec(sql);
    store.version = index + 1;
  }
}
function seedImportedFile(store) {
  store.db.exec(`INSERT INTO media_entity (id, identity_key, display_name, created_at, updated_at) VALUES (1, 'legacy', 'legacy.mp4', 1, 1);
    INSERT INTO media_locator (id, media_id, source_kind, locator, added_at) VALUES (1, 1, 'document_picker', 'file://legacy.mp4', 1);
    INSERT INTO media_collection (id, source_kind, source_key, display_name, updated_at) VALUES (1, 'document_picker', '@manual', 'Imported', 1);
    INSERT INTO collection_membership (collection_id, media_id, locator_id, added_at) VALUES (1, 1, 1, 1);`);
}
async function check(name, test) { await test(); console.log(`PASS: ${name}`); }
(async () => {
  await check('migration failure rolls back schema and version; retry succeeds', async () => {
    const store = new Store(); seed(store, 4);
    const db = LinkoraDatabase.shared({});
    store.fail = sql => sql.startsWith('ALTER TABLE');
    await assert.rejects(() => db.ensureSchema(store));
    assert.equal(store.version, 4);
    store.fail = null;
    // Interrupt immediately after a successful ALTER, before the version marker.
    const execute = store.execute.bind(store);
    store.execute = async (...args) => { await execute(...args); throw new Error('Interrupted after SQL'); };
    await assert.rejects(() => db.ensureSchema(store));
    assert.equal(store.db.prepare('PRAGMA table_info(media_collection)').all().some(row => row.name === 'total_size_bytes'), false);
    store.execute = execute;
    await db.ensureSchema(store);
    assert.equal(store.version, 9);
    assert.equal(store.db.prepare('PRAGMA integrity_check').get().integrity_check, 'ok');
    store.db.close();
  });
  await check('legacy half-migrated v3/v5/v6/v7 recover without losing rows', async () => {
    for (const version of [3, 5, 6, 7]) {
      const store = new Store(); seed(store, version - 1);
      seedImportedFile(store);
      store.db.exec(versions[version - 1][0]);
      await LinkoraDatabase.shared({}).ensureSchema(store);
      assert.equal(store.version, 9);
      assert.equal(store.db.prepare('SELECT display_name FROM media_entity WHERE id = 1').get().display_name, 'legacy.mp4');
      assert.equal(store.db.prepare('SELECT COUNT(*) AS count FROM collection_membership').get().count, 1);
      assert.deepEqual(store.db.prepare('PRAGMA foreign_key_check').all(), []);
      store.db.close();
    }
  });
  await check('v8 reference migration rolls back completely before retry', async () => {
    const store = new Store(); seed(store, 7); seedImportedFile(store);
    store.fail = sql => sql.startsWith('DELETE FROM media_collection');
    await assert.rejects(() => LinkoraDatabase.shared({}).ensureSchema(store));
    assert.equal(store.version, 7);
    assert.equal(store.db.prepare("SELECT COUNT(*) AS count FROM media_locator WHERE source_kind = 'virtual_entry'").get().count, 0);
    assert.equal(store.db.prepare('SELECT collection_id FROM collection_membership').get().collection_id, 1);
    store.fail = null;
    await LinkoraDatabase.shared({}).ensureSchema(store);
    assert.equal(store.version, 9);
    assert.equal(store.db.prepare('SELECT COUNT(*) AS count FROM collection_membership').get().count, 1);
    assert.deepEqual(store.db.prepare('PRAGMA foreign_key_check').all(), []);
    store.db.close();
  });
  await check('v9 network metadata migration rolls back and retries without losing v8 media', async () => {
    const store = new Store(); seed(store, 7); seedImportedFile(store);
    for (const statement of versions[7]) store.db.exec(statement); store.version = 8;
    store.fail = sql => sql.includes('CREATE INDEX IF NOT EXISTS idx_network_media_server');
    await assert.rejects(() => LinkoraDatabase.shared({}).ensureSchema(store));
    assert.equal(store.version, 8);
    assert.equal(store.db.prepare("SELECT COUNT(*) AS n FROM sqlite_master WHERE name='network_media_metadata'").get().n, 0);
    store.fail = null; await LinkoraDatabase.shared({}).ensureSchema(store);
    assert.equal(store.version, 9);
    assert.equal(store.db.prepare('SELECT display_name FROM media_entity WHERE id=1').get().display_name, 'legacy.mp4');
    assert.deepEqual(store.db.prepare('PRAGMA foreign_key_check').all(), []); store.db.close();
  });
  const store = new Store();
  await LinkoraDatabase.shared({}).ensureSchema(store);
  LinkoraDatabase.shared({}).activeStore = store;
  const manual = new ManualMediaStore({});
  const hidden = new HiddenLocalItemStore({});
  await check('same-folder deduplication and cross-folder references survive removal', async () => {
    const folder = (await manual.createFolder('', 'Test'))[0];
    const source = MediaSource.fromLocalDocument('file://old.mp4');
    await manual.add([source, source]); await manual.add([source]); await manual.add([source], folder.uri);
    assert.equal((await manual.load()).length, 2);
    await manual.remove((await manual.load()).find(item => item.parentUri === '').uri);
    assert.equal((await manual.load()).length, 1);
    assert.equal(revoked.includes(source.locator), false);
  });
  await check('reauthorization preserves alias and folder; cancellation preserves data', async () => {
    const original = (await manual.load())[0];
    const controller = new LibraryFeatureController({}, { pick: async () => new LocalMediaPickResult([]) },
      { load: async () => [] }, () => {}, manual);
    controller.manualItems = await manual.load(); controller.manualFolders = await manual.loadFolders();
    assert.equal(await controller.reauthorizeManual(original.uri), false);
    assert.equal((await manual.load())[0].sourceUri, original.sourceUri);
    controller.filePicker = { pick: async () => new LocalMediaPickResult([MediaSource.fromLocalDocument('file://missing.mp4')]) };
    assert.equal(await controller.reauthorizeManual(original.uri), false);
    assert.notEqual(controller.currentState().localFailure, null);
    controller.filePicker = { pick: async () => new LocalMediaPickResult([MediaSource.fromLocalDocument('file://new.mp4')]) };
    assert.equal(await controller.reauthorizeManual(original.uri), true);
    assert.equal(controller.currentState().localFailure, null);
    const repaired = (await manual.load())[0];
    assert.equal(repaired.uri, original.uri); assert.equal(repaired.parentUri, original.parentUri);
    assert.equal(repaired.sourceUri, 'file://new.mp4');
    await manual.reauthorize(original.uri, MediaSource.fromLocalDocument('file://new.mp4'));
    assert.equal((await manual.load()).length, 1);
    assert.equal(revoked.includes(original.sourceUri), true);
    await assert.rejects(() => manual.reauthorize(original.uri, MediaSource.fromLocalDocument('file://missing.mp4')));
    assert.equal((await manual.load())[0].sourceUri, 'file://new.mp4');
    await manual.add([MediaSource.fromLocalDocument('file://other.mp4')], original.parentUri);
    await assert.rejects(() => manual.reauthorize(original.uri, MediaSource.fromLocalDocument('file://other.mp4')));
    assert.equal((await manual.load()).length, 2);
    // Force a failure after the alias changes, before its membership changes.
    store.fail = sql => sql.includes('UPDATE collection_membership');
    await assert.rejects(() => manual.reauthorize(original.uri, MediaSource.fromLocalDocument('file://rollback.mp4')));
    store.fail = null;
    assert.equal((await manual.load()).find(item => item.uri === original.uri).sourceUri, 'file://new.mp4');
    assert.deepEqual(store.db.prepare('PRAGMA foreign_key_check').all(), []);
  });
  await check('batch hide/restore rolls back partial writes and remains usable', async () => {
    const entries = [new HiddenLocalItem('file', 'a', 'A'), new HiddenLocalItem('file', 'b', 'B')];
    store.fail = (sql, args) => sql.includes('hidden_local_item') && args.includes('b');
    await assert.rejects(() => hidden.hideMany(entries));
    store.fail = null;
    assert.equal((await hidden.load()).length, 0);
    await hidden.hideMany(entries);
    store.fail = (sql, args) => sql.startsWith('DELETE') && args.includes('b');
    await assert.rejects(() => hidden.restoreMany(entries));
    store.fail = null;
    assert.equal((await hidden.load()).length, 2);
    assert.equal((await hidden.restoreMany(entries)).length, 0);
  });
  store.db.close();
  console.log('Local persistence checks passed (desktop SQLite; Harmony bindings and authorization require device verification).');
})().catch(error => { console.error(error); process.exitCode = 1; });
