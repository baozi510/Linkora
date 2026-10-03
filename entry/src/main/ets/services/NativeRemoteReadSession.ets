import { connection } from '@kit.NetworkKit';
import { RemoteReadSession } from 'linkora_core';

export class NativeRemoteFile {
  readonly handle: number;
  readonly size: number;
  constructor(handle: number, size: number) { this.handle = handle; this.size = size; }
}

export class NativeRemoteReadSession implements RemoteReadSession {
  private readonly file: NativeRemoteFile;
  private readonly nativeRead: (handle: number, offset: number, length: number) => Promise<ArrayBuffer>;
  private readonly nativeCancel: (handle: number) => void;
  private readonly nativeClose: (handle: number) => Promise<void>;
  private readonly waiters: Set<() => void> = new Set();
  private tail: Promise<void> = Promise.resolve();
  private cancelled: boolean = false;
  private closing: Promise<void> | null = null;
  constructor(file: NativeRemoteFile,
    read: (handle: number, offset: number, length: number) => Promise<ArrayBuffer>,
    cancel: (handle: number) => void, close: (handle: number) => Promise<void>) {
    this.file = file; this.nativeRead = read; this.nativeCancel = cancel; this.nativeClose = close;
  }
  size(): number { return this.file.size; }
  async read(offset: number, length: number): Promise<ArrayBuffer> {
    if (this.cancelled) throw new Error('Remote reader cancelled');
    if (!Number.isSafeInteger(offset) || offset < 0 || offset > this.size() ||
      !Number.isSafeInteger(length) || length <= 0 || length > 262144) throw new Error('Invalid remote read range');
    const work: Promise<ArrayBuffer> = this.tail.then(() => {
      if (this.cancelled) throw new Error('Remote reader cancelled');
      return this.nativeRead(this.file.handle, offset, length);
    });
    this.tail = work.then(() => {}, () => {});
    let abort: () => void = () => {};
    const cancelled: Promise<ArrayBuffer> = new Promise((_resolve, reject) => {
      abort = () => reject(new Error('Remote reader cancelled'));
    });
    this.waiters.add(abort);
    const timer: number = setTimeout(() => this.cancel(), 8000);
    try { return await Promise.race([work, cancelled]); }
    finally { clearTimeout(timer); this.waiters.delete(abort); }
  }
  cancel(): void {
    if (this.cancelled) return;
    this.cancelled = true;
    this.nativeCancel(this.file.handle);
    this.waiters.forEach((abort: () => void) => abort());
    this.waiters.clear();
  }
  close(): Promise<void> {
    if (this.closing === null) {
      this.cancel();
      this.closing = this.tail.then(() => this.nativeClose(this.file.handle));
    }
    return this.closing;
  }
}

/** Bound DNS and setup; a late native open is always closed instead of being leaked. */
export async function openNativeRemoteReader(host: string, open: (address: string) => Promise<NativeRemoteFile>,
  read: (handle: number, offset: number, length: number) => Promise<ArrayBuffer>,
  cancel: (handle: number) => void, close: (handle: number) => Promise<void>,
  setupObserver: (settled: Promise<void>) => void = () => {}): Promise<RemoteReadSession> {
  let expired: boolean = false;
  let timer: number = -1;
  const timeout: Promise<RemoteReadSession> = new Promise((_resolve, reject) => {
    timer = setTimeout(() => { expired = true; reject(new Error('Remote reader setup timed out')); }, 8000);
  });
  const work: Promise<RemoteReadSession> = (async (): Promise<RemoteReadSession> => {
    let address: string = host;
    if (!/^[0-9.]+$/.test(host) && !/^[0-9a-fA-F:]+$/.test(host)) {
      const addresses: connection.NetAddress[] = await connection.getAddressesByName(host);
      if (addresses.length === 0) throw new Error('Remote host unavailable');
      address = addresses[0].address;
    }
    if (expired) throw new Error('Remote setup expired');
    const file: NativeRemoteFile = await open(address);
    if (expired || !Number.isSafeInteger(file.size) || file.size < 0) {
      cancel(file.handle); await close(file.handle); throw new Error('Remote setup expired');
    }
    return new NativeRemoteReadSession(file, read, cancel, close);
  })();
  setupObserver(work.then(() => {}, () => {}));
  try { return await Promise.race([work, timeout]); }
  finally { clearTimeout(timer); }
}
