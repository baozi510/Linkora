export interface NfsNativeEntry {
  name: string;
  isDirectory: boolean;
  size: number;
  modifiedAt: number;
}

export interface NativeRemoteFile { handle: number; size: number; }
interface LinkoraNfsNative {
  openReader(host: string, port: number, rootPath: string, version: number,
    remotePath: string): Promise<NativeRemoteFile>;
  read(handle: number, offset: number, length: number): Promise<ArrayBuffer>;
  cancel(handle: number): void;
  closeReader(handle: number): Promise<void>;
  list(host: string, port: number, rootPath: string, version: number): Promise<NfsNativeEntry[]>;
  download(host: string, port: number, rootPath: string, version: number,
    remotePath: string, localPath: string): Promise<number>;
}

declare const linkoraNfs: LinkoraNfsNative;
export default linkoraNfs;
