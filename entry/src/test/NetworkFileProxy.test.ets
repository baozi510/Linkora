import { describe, expect, it } from '@ohos/hypium';
import {
  NetworkFileProxy,
  NetworkFileProxyConfig,
  resolveHttpByteRange
} from 'linkora_proxy';
import { NativeRemoteFile, NativeRemoteReadSession } from '../main/ets/services/NativeRemoteReadSession';
import { RemoteReadSessionAdapter } from 'linkora_core';

export default function networkFileProxyTest(): void {
  describe('NetworkFileProxy', () => {
    it('preserves byte-exact random reads short EOF and closed-source isolation', 0, async () => {
      const bytes: Uint8Array = new Uint8Array([7, 19, 31, 43, 59, 67]);
      let reads: number = 0;
      const reader = new NativeRemoteReadSession(new NativeRemoteFile(1, bytes.length),
        async (_handle: number, offset: number, length: number): Promise<ArrayBuffer> => {
          reads++;
          return bytes.slice(offset, offset + length).buffer as ArrayBuffer;
        }, () => {}, async () => {});
      const source = new RemoteReadSessionAdapter('owned-fixture', reader);
      const values: ArrayBuffer[] = await Promise.all([source.readAt(3, 2), source.readAt(0, 3),
        source.readAt(5, 4), source.readAt(6, 4)]);
      expect(new Uint8Array(values[0]).toString()).assertEqual('43,59');
      expect(new Uint8Array(values[1]).toString()).assertEqual('7,19,31');
      expect(new Uint8Array(values[2]).toString()).assertEqual('67');
      expect(values[3].byteLength).assertEqual(0);
      await source.close();
      let rejected: boolean = false;
      try { await source.readAt(0, 1); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue();
      expect(reads).assertEqual(4);
    });
    it('startsWithEmptyDiagnosticsAndClampsConfiguration', 0, async () => {
      const proxy = new NetworkFileProxy(new NetworkFileProxyConfig(1024 * 1024, 1, 0, 0));
      const diagnostics = proxy.diagnostics();
      expect(diagnostics.activeSources).assertEqual(0);
      expect(diagnostics.activeClients).assertEqual(0);
      expect(diagnostics.bytesRead).assertEqual(0);
      expect(diagnostics.readRequests).assertEqual(0);
      expect(diagnostics.rangeRequests).assertEqual(0);
      await proxy.close();
    });

    it('closes an unused proxy repeatedly', 0, async () => {
      const proxy: NetworkFileProxy = new NetworkFileProxy();
      await proxy.close();
      await proxy.close();
    });

    it('serializes remote reads and releases only once', 0, async () => {
      let active: number = 0;
      let maximum: number = 0;
      let closed: number = 0;
      let cancelled: number = 0;
      const reader: NativeRemoteReadSession = new NativeRemoteReadSession(new NativeRemoteFile(1, 100),
        async (_handle: number, _offset: number, length: number): Promise<ArrayBuffer> => {
          active++; maximum = Math.max(maximum, active);
          await Promise.resolve(); active--;
          return new ArrayBuffer(length);
        }, (_handle: number): void => { cancelled++; },
        async (_handle: number): Promise<void> => { closed++; });
      const values: ArrayBuffer[] = await Promise.all([reader.read(0, 10), reader.read(10, 10)]);
      expect(values[0].byteLength).assertEqual(10);
      expect(maximum).assertEqual(1);
      reader.cancel();
      let rejected: boolean = false;
      try { await reader.read(0, 1); } catch (_error) { rejected = true; }
      expect(rejected).assertTrue();
      await reader.close(); await reader.close();
      expect(closed).assertEqual(1);
      expect(cancelled).assertEqual(1);
    });

    it('rejects unsafe remote offsets and oversized reads', 0, async () => {
      const reader: NativeRemoteReadSession = new NativeRemoteReadSession(new NativeRemoteFile(1, 100),
        async (_handle: number, _offset: number, length: number): Promise<ArrayBuffer> => new ArrayBuffer(length),
        (_handle: number): void => {}, async (_handle: number): Promise<void> => {});
      let rejected: number = 0;
      try { await reader.read(-1, 10); } catch (_error) { rejected++; }
      try { await reader.read(0, 262145); } catch (_error) { rejected++; }
      try { await reader.read(9007199254740992, 10); } catch (_error) { rejected++; }
      expect(rejected).assertEqual(3);
      await reader.close();
    });

    it('cancels queued reads but waits for native completion before close', 0, async () => {
      let finish: () => void = () => {};
      let reads: number = 0;
      let closes: number = 0;
      const reader: NativeRemoteReadSession = new NativeRemoteReadSession(new NativeRemoteFile(1, 100),
        async (_handle: number, _offset: number, _length: number): Promise<ArrayBuffer> => {
          reads++; await new Promise<void>((resolve) => { finish = resolve; });
          return new ArrayBuffer(1);
        }, (_handle: number): void => {},
        async (_handle: number): Promise<void> => { closes++; });
      const first: Promise<boolean> = reader.read(0, 1).then(() => false, () => true);
      await Promise.resolve();
      const queued: Promise<boolean> = reader.read(1, 1).then(() => false, () => true);
      reader.cancel();
      expect(await first).assertTrue();
      expect(await queued).assertTrue();
      const closing: Promise<void> = reader.close();
      expect(closes).assertEqual(0);
      finish(); await closing;
      expect(reads).assertEqual(1);
      expect(closes).assertEqual(1);
    });

    it('resolves closed open and suffix ranges', 0, () => {
      const closed = resolveHttpByteRange('bytes=0-9', 100);
      expect(closed.status).assertEqual(206);
      expect(closed.offset).assertEqual(0);
      expect(closed.length).assertEqual(10);
      expect(closed.contentRange).assertEqual('bytes 0-9/100');
      expect(resolveHttpByteRange('bytes=95-', 100).length).assertEqual(5);
      expect(resolveHttpByteRange('bytes=-8', 100).offset).assertEqual(92);
      expect(resolveHttpByteRange('bytes=95-200', 100).length).assertEqual(5);
    });

    it('rejects invalid and unsatisfiable ranges', 0, () => {
      expect(resolveHttpByteRange('bytes=100-', 100).status).assertEqual(416);
      expect(resolveHttpByteRange('bytes=100-', 100).contentRange).assertEqual('bytes */100');
      expect(resolveHttpByteRange('bytes=1-0', 100).status).assertEqual(400);
      expect(resolveHttpByteRange('bytes=abc-9', 100).status).assertEqual(400);
      expect(resolveHttpByteRange('bytes=9007199254740992-', 100).status).assertEqual(400);
      expect(resolveHttpByteRange('bytes=-0', 100).status).assertEqual(416);
      expect(resolveHttpByteRange('bytes=0-0', 0).status).assertEqual(416);
    });

    it('handles full empty multipart and large files', 0, () => {
      expect(resolveHttpByteRange('', 0).length).assertEqual(0);
      expect(resolveHttpByteRange('', 0).status).assertEqual(200);
      expect(resolveHttpByteRange('items=0-9', 100).status).assertEqual(200);
      expect(resolveHttpByteRange('bytes=0-9,20-29', 100).status).assertEqual(200);
      expect(resolveHttpByteRange('bytes=4294967296-', 5368709120).length).assertEqual(1073741824);
      expect(resolveHttpByteRange('', -1).status).assertEqual(400);
    });
  });
}
