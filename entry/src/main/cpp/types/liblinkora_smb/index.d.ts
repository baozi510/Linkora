export interface SmbNativeEntry {
  name: string;
  isDirectory: boolean;
  size: number;
  modifiedAt: number;
}

export interface NativeRemoteFile { handle: number; size: number; }
interface LinkoraSmbNative {
  openReader(host: string, port: number, share: string, path: string, username: string,
    password: string, domain: string, remotePath: string): Promise<NativeRemoteFile>;
  read(handle: number, offset: number, length: number): Promise<ArrayBuffer>;
  cancel(handle: number): void;
  closeReader(handle: number): Promise<void>;
  list(host: string, port: number, share: string, path: string,
    username: string, password: string, domain: string): Promise<SmbNativeEntry[]>;
  download(host: string, port: number, share: string, path: string,
    username: string, password: string, domain: string, remotePath: string,
    localPath: string): Promise<number>;
}

declare const linkoraSmb: LinkoraSmbNative;
export default linkoraSmb;
