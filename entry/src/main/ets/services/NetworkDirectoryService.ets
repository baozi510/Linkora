import { RemoteProtocol, RemoteReadSession } from 'linkora_core';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind } from '../models/NetworkDirectoryState';
import { FileProtocolBrowserService, FtpBrowserService, NfsBrowserService,
  RemoteBrowserEntry, RemoteEntryKind } from './FileProtocolBrowserService';
import { NetworkServerEntry } from './NetworkServerStore';
import { SftpBrowserEntry, SftpBrowserService, SftpEntryKind } from './SftpBrowserService';
import { SmbBrowserEntry, SmbBrowserService, SmbEntryKind } from './SmbBrowserService';
import { WebDavBrowserEntry, WebDavBrowserService, WebDavEntryKind } from './WebDavBrowserService';
import { HttpRemoteReadSession } from './HttpRemoteReadSession';

export class NetworkDirectoryService {
  private readonly server: NetworkServerEntry;
  private readonly smb: SmbBrowserService | null;
  private readonly sftp: SftpBrowserService | null;
  private readonly webDav: WebDavBrowserService | null;
  private readonly fileProtocol: FileProtocolBrowserService | null;

  constructor(server: NetworkServerEntry) {
    this.server = server;
    this.smb = server.protocol === RemoteProtocol.SMB ? new SmbBrowserService(server) : null;
    this.sftp = server.protocol === RemoteProtocol.SFTP ? new SftpBrowserService(server) : null;
    this.webDav = server.protocol === RemoteProtocol.WEBDAV ? new WebDavBrowserService(server) : null;
    this.fileProtocol = server.protocol === RemoteProtocol.FTP ? new FtpBrowserService(server) :
      (server.protocol === RemoteProtocol.NFS ? new NfsBrowserService(server) : null);
  }

  initialPath(): string {
    if (this.smb !== null) {
      return this.smb.location.initialPath;
    }
    if (this.sftp !== null) {
      return this.sftp.initialPath;
    }
    if (this.webDav !== null) {
      return this.normalizedWebDavDirectory(this.server.rootPath);
    }
    return this.fileProtocol?.initialPath() ?? '/';
  }

  displayPath(path: string): string {
    if (this.smb !== null) {
      return this.smb.displayPath(path);
    }
    if (this.sftp !== null) {
      return this.sftp.displayPath(path);
    }
    if (this.fileProtocol !== null) {
      return this.fileProtocol.displayPath(path);
    }
    return path;
  }

  directoryPath(path: string): string {
    return this.webDav === null ? path : this.normalizedWebDavDirectory(path);
  }

  async list(path: string, forceRefresh: boolean = false): Promise<NetworkDirectoryEntry[]> {
    if (this.smb !== null) {
      const entries: SmbBrowserEntry[] = await this.smb.list(path, forceRefresh);
      return entries.map((entry: SmbBrowserEntry): NetworkDirectoryEntry =>
        new NetworkDirectoryEntry(entry.displayName, entry.path,
          entry.kind === SmbEntryKind.DIRECTORY ? NetworkDirectoryEntryKind.DIRECTORY :
            NetworkDirectoryEntryKind.FILE, entry.size, entry.modifiedAt));
    }
    if (this.sftp !== null) {
      const entries: SftpBrowserEntry[] = await this.sftp.list(path, forceRefresh);
      return entries.map((entry: SftpBrowserEntry): NetworkDirectoryEntry =>
        new NetworkDirectoryEntry(entry.displayName, entry.path,
          entry.kind === SftpEntryKind.DIRECTORY ? NetworkDirectoryEntryKind.DIRECTORY :
            NetworkDirectoryEntryKind.FILE, entry.size, entry.modifiedAt));
    }
    if (this.webDav !== null) {
      const entries: WebDavBrowserEntry[] = await this.webDav.list(path, forceRefresh);
      return entries.map((entry: WebDavBrowserEntry): NetworkDirectoryEntry =>
        new NetworkDirectoryEntry(entry.displayName, entry.path,
          entry.kind === WebDavEntryKind.DIRECTORY ? NetworkDirectoryEntryKind.DIRECTORY :
            NetworkDirectoryEntryKind.FILE, entry.size, entry.modifiedAt));
    }
    if (this.fileProtocol !== null) {
      const entries: RemoteBrowserEntry[] = await this.fileProtocol.list(path, forceRefresh);
      return entries.map((entry: RemoteBrowserEntry): NetworkDirectoryEntry =>
        new NetworkDirectoryEntry(entry.displayName, entry.path,
          entry.kind === RemoteEntryKind.DIRECTORY ? NetworkDirectoryEntryKind.DIRECTORY :
            NetworkDirectoryEntryKind.FILE, entry.size, entry.modifiedAt));
    }
    throw new Error('该服务器不支持目录浏览');
  }

  async download(path: string, localPath: string): Promise<number> {
    if (this.smb !== null) {
      return this.smb.download(path, localPath);
    }
    if (this.sftp !== null) {
      return this.sftp.download(path, localPath);
    }
    if (this.fileProtocol !== null) {
      return this.fileProtocol.download(path, localPath);
    }
    throw new Error('当前协议不需要下载缓存');
  }

  directFileUrl(path: string): string {
    return this.webDav?.fileUrl(path) ?? '';
  }

  async openReader(path: string, expectedFingerprint: string = '',
    setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RemoteReadSession> {
    if (this.webDav !== null) return HttpRemoteReadSession.open(this.webDav.fileUrl(path), this.webDav.fileHeaders());
    if (this.smb !== null) return this.smb.openReader(path, setupObserver);
    if (this.sftp !== null) return this.sftp.openReader(path, expectedFingerprint || this.server.advancedOptions.sftpFingerprint, setupObserver);
    if (this.fileProtocol !== null) return this.fileProtocol.openReader(path, setupObserver);
    throw new Error('This source uses a direct HTTP URL');
  }

  cachePrefix(): string {
    return this.server.protocol;
  }

  cancel(): void {
    this.webDav?.cancel();
  }

  private normalizedWebDavDirectory(path: string): string {
    let value: string = path.trim();
    if (value.length === 0) {
      return '/';
    }
    if (!value.startsWith('/')) {
      value = `/${value}`;
    }
    return value.endsWith('/') ? value : `${value}/`;
  }
}
