import { NetworkMediaCache } from './NetworkMediaCache';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { RemoteProtocol } from 'linkora_core';
import { LinkoraDatabase } from './LinkoraDatabase';
import { NetworkCredentialStore } from './NetworkCredentialStore';

export enum FtpSecurityMode {
  AUTO = 'auto',
  PLAIN = 'plain',
  EXPLICIT_TLS = 'explicit_tls',
  IMPLICIT_TLS = 'implicit_tls'
}

export enum FtpPassiveMode {
  AUTO = 'auto',
  PASSIVE = 'passive',
  ACTIVE = 'active'
}

export enum SftpAuthMode {
  PASSWORD = 'password',
  PRIVATE_KEY = 'private_key'
}

export enum SftpHostKeyPolicy {
  ASK = 'ask',
  STRICT = 'strict'
}

export class NetworkAdvancedOptions {
  workgroup: string = '';
  ftpSecurityMode: FtpSecurityMode = FtpSecurityMode.AUTO;
  ftpPassiveMode: FtpPassiveMode = FtpPassiveMode.AUTO;
  ftpEncoding: string = 'auto';
  sftpAuthMode: SftpAuthMode = SftpAuthMode.PASSWORD;
  sftpHostKeyPolicy: SftpHostKeyPolicy = SftpHostKeyPolicy.ASK;
  sftpFingerprint: string = '';
  webdavFollowRedirects: boolean = true;
  webdavVerifyTls: boolean = true;
  nfsVersion: string = 'auto';

  serialize(): string {
    const values: string[] = [this.workgroup, this.ftpSecurityMode, this.ftpPassiveMode,
      this.ftpEncoding, this.sftpAuthMode, this.sftpHostKeyPolicy,
      this.webdavFollowRedirects ? '1' : '0', this.webdavVerifyTls ? '1' : '0', this.nfsVersion,
      this.sftpFingerprint];
    return values.map((value: string) => encodeURIComponent(value)).join('|');
  }

  static deserialize(serialized: string): NetworkAdvancedOptions {
    const options: NetworkAdvancedOptions = new NetworkAdvancedOptions();
    if (serialized.length === 0) {
      return options;
    }
    const values: string[] = serialized.split('|');
    const decoded: string[] = values.map((value: string) => {
      try {
        return decodeURIComponent(value);
      } catch (_error) {
        return '';
      }
    });
    options.workgroup = decoded[0] ?? '';
    options.ftpSecurityMode = decoded[1] === FtpSecurityMode.PLAIN ? FtpSecurityMode.PLAIN :
      decoded[1] === FtpSecurityMode.EXPLICIT_TLS ? FtpSecurityMode.EXPLICIT_TLS :
      decoded[1] === FtpSecurityMode.IMPLICIT_TLS ? FtpSecurityMode.IMPLICIT_TLS : FtpSecurityMode.AUTO;
    options.ftpPassiveMode = decoded[2] === FtpPassiveMode.PASSIVE ? FtpPassiveMode.PASSIVE :
      decoded[2] === FtpPassiveMode.ACTIVE ? FtpPassiveMode.ACTIVE : FtpPassiveMode.AUTO;
    options.ftpEncoding = decoded[3] ?? 'auto';
    options.sftpAuthMode = decoded[4] === SftpAuthMode.PRIVATE_KEY ?
      SftpAuthMode.PRIVATE_KEY : SftpAuthMode.PASSWORD;
    options.sftpHostKeyPolicy = decoded[5] === SftpHostKeyPolicy.STRICT ?
      SftpHostKeyPolicy.STRICT : SftpHostKeyPolicy.ASK;
    options.webdavFollowRedirects = decoded[6] !== '0';
    options.webdavVerifyTls = decoded[7] !== '0';
    options.nfsVersion = decoded[8] ?? 'auto';
    options.sftpFingerprint = decoded[9] ?? '';
    return options;
  }
}

export class NetworkServerDraft {
  readonly displayName: string;
  readonly protocol: RemoteProtocol;
  readonly host: string;
  readonly port: number;
  readonly rootPath: string;
  readonly username: string;
  readonly password: string;
  readonly secureTransport: boolean;
  readonly advancedOptions: NetworkAdvancedOptions;

  constructor(displayName: string, protocol: RemoteProtocol, host: string, port: number,
    rootPath: string = '/', username: string = '', password: string = '',
    secureTransport: boolean = false, advancedOptions: NetworkAdvancedOptions = new NetworkAdvancedOptions()) {
    this.displayName = displayName;
    this.protocol = protocol;
    this.host = host;
    this.port = port;
    this.rootPath = rootPath;
    this.username = username;
    this.password = password;
    this.secureTransport = secureTransport;
    this.advancedOptions = advancedOptions;
  }
}

export class NetworkServerEntry extends NetworkServerDraft {
  readonly id: number;
  readonly updatedAt: number;

  constructor(id: number, displayName: string, protocol: RemoteProtocol, host: string, port: number,
    rootPath: string = '/', username: string = '', password: string = '',
    secureTransport: boolean = false, updatedAt: number = 0,
    advancedOptions: NetworkAdvancedOptions = new NetworkAdvancedOptions()) {
    super(displayName, protocol, host, port, rootPath, username, password, secureTransport, advancedOptions);
    this.id = id;
    this.updatedAt = updatedAt;
  }

  locationLabel(): string {
    const path: string = this.rootPath.length === 0 ? '/' : this.rootPath;
    if (this.protocol === RemoteProtocol.HTTP || this.protocol === RemoteProtocol.WEBDAV) {
      const scheme: string = this.secureTransport ? 'https' : 'http';
      const defaultPort: number = this.secureTransport ? 443 : 80;
      const portLabel: string = this.port === defaultPort ? '' : `:${this.port}`;
      const suffix: string = path.startsWith('/') || path.startsWith('?') || path.startsWith('#') ?
        path : `/${path}`;
      return `${scheme}://${this.host}${portLabel}${suffix}`;
    }
    return `${this.host}:${this.port}${path.startsWith('/') ? path : `/${path}`}`;
  }

  titleLabel(): string {
    const name: string = this.displayName.trim();
    // Keep list titles compact and protocol-independent: use the custom name
    // when present, otherwise show only the server address (host). Connection
    // details such as scheme, port and path belong to the locator, not the UI title.
    return name.length > 0 ? name : this.host;
  }

  urlLabel(): string {
    if (this.protocol === RemoteProtocol.HTTP || this.protocol === RemoteProtocol.WEBDAV) {
      return this.locationLabel();
    }
    const path: string = this.rootPath.length === 0 ? '/' :
      (this.rootPath.startsWith('/') ? this.rootPath : `/${this.rootPath}`);
    return `${this.protocol}://${this.host}:${this.port}${path}`;
  }
}

class StoredNetworkServerRow {
  readonly id: number;
  readonly displayName: string;
  readonly protocol: RemoteProtocol;
  readonly host: string;
  readonly port: number;
  readonly rootPath: string;
  readonly username: string;
  readonly legacyPassword: string;
  readonly credentialAlias: string;
  readonly secureTransport: boolean;
  readonly updatedAt: number;
  readonly advancedOptions: NetworkAdvancedOptions;

  constructor(id: number, displayName: string, protocol: RemoteProtocol, host: string,
    port: number, rootPath: string, username: string, legacyPassword: string,
    credentialAlias: string, secureTransport: boolean, updatedAt: number,
    advancedOptions: NetworkAdvancedOptions) {
    this.id = id;
    this.displayName = displayName;
    this.protocol = protocol;
    this.host = host;
    this.port = port;
    this.rootPath = rootPath;
    this.username = username;
    this.legacyPassword = legacyPassword;
    this.credentialAlias = credentialAlias;
    this.secureTransport = secureTransport;
    this.updatedAt = updatedAt;
    this.advancedOptions = advancedOptions;
  }
}

export class NetworkServerStore {
  private database: LinkoraDatabase;
  private readonly context: common.UIAbilityContext;
  private credentials: NetworkCredentialStore = new NetworkCredentialStore();

  constructor(context: common.UIAbilityContext) {
    this.database = LinkoraDatabase.shared(context); this.context = context;
  }

  async load(): Promise<NetworkServerEntry[]> {
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    return this.loadEntries(store);
  }

  async add(draft: NetworkServerDraft): Promise<NetworkServerEntry[]> {
    const credentialAlias: string | null = await this.credentials.save(draft.password);
    if (credentialAlias === null) {
      throw new Error('Unable to save the network credential');
    }
    try {
      await this.database.enqueueWrite(async (): Promise<void> => {
        const store: relationalStore.RdbStore = await this.database.store();
        const now: number = Date.now();
        await store.execute(
          `INSERT INTO network_server
            (display_name, protocol, host, port, root_path, username, password_value,
             credential_alias, secure_transport, advanced_options, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, '', ?, ?, ?, ?, ?)`,
          [draft.displayName, draft.protocol, draft.host, draft.port, draft.rootPath,
            draft.username, credentialAlias, draft.secureTransport ? 1 : 0,
            draft.advancedOptions.serialize(), now, now]);
      });
    } catch (_error) {
      await this.credentials.remove(credentialAlias);
      throw new Error('Unable to save the network server');
    }
    return this.load();
  }

  async update(id: number, draft: NetworkServerDraft): Promise<NetworkServerEntry[]> {
    const previousAlias: string = await this.credentialAliasFor(id);
    const nextAlias: string | null = await this.credentials.save(draft.password);
    if (nextAlias === null) {
      throw new Error('Unable to save the network credential');
    }
    try {
      await this.database.enqueueWrite(async (): Promise<void> => {
        const store: relationalStore.RdbStore = await this.database.store();
        await store.execute(
          `UPDATE network_server SET
            display_name = ?, protocol = ?, host = ?, port = ?, root_path = ?, username = ?,
            password_value = '', credential_alias = ?, secure_transport = ?, advanced_options = ?, updated_at = ?
           WHERE id = ?`,
          [draft.displayName, draft.protocol, draft.host, draft.port, draft.rootPath,
            draft.username, nextAlias, draft.secureTransport ? 1 : 0,
            draft.advancedOptions.serialize(), Date.now(), id]);
      });
    } catch (_error) {
      await this.credentials.remove(nextAlias);
      throw new Error('Unable to update the network server');
    }
    await this.credentials.remove(previousAlias);
    return this.load();
  }

  async remove(id: number): Promise<NetworkServerEntry[]> {
    const credentialAlias: string = await this.credentialAliasFor(id);
    await this.database.enqueueWrite(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      const keys: string[] = [];
      const result = await store.querySql('SELECT cache_key FROM network_media_metadata WHERE server_id = ?', [id]);
      try { while (result.goToNextRow()) keys.push(result.getString(result.getColumnIndex('cache_key'))); }
      finally { result.close(); }
      // Retain ownership rows until cleanup succeeds, so interruption or I/O failure is retryable.
      NetworkMediaCache.removeFiles(this.context, keys);
      await store.execute('DELETE FROM network_server WHERE id = ?', [id]);
    });
    await this.credentials.remove(credentialAlias);
    return this.load();
  }

  private async loadEntries(store: relationalStore.RdbStore): Promise<NetworkServerEntry[]> {
    let result: relationalStore.ResultSet | null = null;
    const rows: StoredNetworkServerRow[] = [];
    try {
      result = await store.querySql(
        `SELECT id, display_name, protocol, host, port, root_path, username,
          password_value, credential_alias, secure_transport, advanced_options, updated_at
         FROM network_server ORDER BY updated_at DESC, id DESC`);
      while (result.goToNextRow()) {
        rows.push(new StoredNetworkServerRow(
          result.getLong(result.getColumnIndex('id')),
          result.getString(result.getColumnIndex('display_name')),
          this.protocol(result.getString(result.getColumnIndex('protocol'))),
          result.getString(result.getColumnIndex('host')),
          result.getLong(result.getColumnIndex('port')),
          result.getString(result.getColumnIndex('root_path')),
          result.getString(result.getColumnIndex('username')),
          result.getString(result.getColumnIndex('password_value')),
          result.getString(result.getColumnIndex('credential_alias')),
          result.getLong(result.getColumnIndex('secure_transport')) === 1,
          result.getLong(result.getColumnIndex('updated_at')),
          NetworkAdvancedOptions.deserialize(result.getString(result.getColumnIndex('advanced_options')))));
      }
    } finally {
      if (result !== null) {
        try {
          result.close();
        } catch (_closeError) {
        }
      }
    }
    const entries: NetworkServerEntry[] = [];
    for (const row of rows) {
      let password: string = '';
      if (row.credentialAlias.length > 0) {
        password = await this.credentials.load(row.credentialAlias) ?? '';
      }
      if (password.length === 0 && row.legacyPassword.length > 0) {
        const migratedAlias: string | null = await this.credentials.save(row.legacyPassword);
        if (migratedAlias !== null) {
          await store.execute(
            `UPDATE network_server SET credential_alias = ?, password_value = '' WHERE id = ?`,
            [migratedAlias, row.id]);
          await this.credentials.remove(row.credentialAlias);
          password = row.legacyPassword;
        }
      }
      entries.push(new NetworkServerEntry(row.id, row.displayName, row.protocol, row.host,
        row.port, row.rootPath, row.username, password, row.secureTransport, row.updatedAt,
        row.advancedOptions));
    }
    return entries;
  }

  private async credentialAliasFor(id: number): Promise<string> {
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        'SELECT credential_alias FROM network_server WHERE id = ? LIMIT 1', [id]);
      return result.goToNextRow() ?
        result.getString(result.getColumnIndex('credential_alias')) : '';
    } finally {
      if (result !== null) {
        try {
          result.close();
        } catch (_closeError) {
        }
      }
    }
  }

  private protocol(value: string): RemoteProtocol {
    if (value === RemoteProtocol.SMB) {
      return RemoteProtocol.SMB;
    }
    if (value === RemoteProtocol.SFTP) {
      return RemoteProtocol.SFTP;
    }
    if (value === RemoteProtocol.FTP) {
      return RemoteProtocol.FTP;
    }
    if (value === RemoteProtocol.HTTP) {
      return RemoteProtocol.HTTP;
    }
    if (value === RemoteProtocol.NFS) {
      return RemoteProtocol.NFS;
    }
    return RemoteProtocol.WEBDAV;
  }
}
