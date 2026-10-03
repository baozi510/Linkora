export interface SftpNativeEntry {
  name: string;
  isDirectory: boolean;
  size: number;
  modifiedAt: number;
}

export interface NativeRemoteFile { handle: number; size: number; }
interface LinkoraSftpNative {
  openReader(host: string, port: number, path: string, username: string, password: string,
    privateKeyPath: string, passphrase: string, expectedFingerprint: string, hostKeyPolicy: number,
    authMode: number, remotePath: string): Promise<NativeRemoteFile>;
  read(handle: number, offset: number, length: number): Promise<ArrayBuffer>;
  cancel(handle: number): void;
  closeReader(handle: number): Promise<void>;
  list(host: string, port: number, path: string, username: string, password: string,
    privateKeyPath: string, passphrase: string, expectedFingerprint: string,
    hostKeyPolicy: number, authMode: number): Promise<SftpNativeEntry[]>;
  download(host: string, port: number, path: string, username: string, password: string,
    privateKeyPath: string, passphrase: string, expectedFingerprint: string,
    hostKeyPolicy: number, authMode: number, remotePath: string, localPath: string): Promise<number>;
}

declare const linkoraSftp: LinkoraSftpNative;
export default linkoraSftp;
