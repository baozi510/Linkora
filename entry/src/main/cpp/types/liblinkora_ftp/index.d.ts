export interface FtpNativeEntry {
  name: string;
  isDirectory: boolean;
  size: number;
  modifiedAt: number;
}

export interface NativeRemoteFile { handle: number; size: number; }
interface LinkoraFtpNative {
  openReader(host: string, port: number, rootPath: string, username: string, password: string,
    securityMode: number, passiveMode: number, encoding: string, remotePath: string): Promise<NativeRemoteFile>;
  read(handle: number, offset: number, length: number): Promise<ArrayBuffer>;
  cancel(handle: number): void;
  closeReader(handle: number): Promise<void>;
  list(host: string, port: number, rootPath: string, username: string, password: string,
    securityMode: number, passiveMode: number, encoding: string): Promise<FtpNativeEntry[]>;
  download(host: string, port: number, rootPath: string, username: string, password: string,
    securityMode: number, passiveMode: number, encoding: string,
    remotePath: string, localPath: string): Promise<number>;
}

declare const linkoraFtp: LinkoraFtpNative;
export default linkoraFtp;
