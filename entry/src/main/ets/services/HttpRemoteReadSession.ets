import { http } from '@kit.NetworkKit';
import { RemoteReadSession } from 'linkora_core';

/** Bounded authenticated byte ranges for the existing loopback proxy. No file cache. */
export class HttpRemoteReadSession implements RemoteReadSession {
  private readonly source: string;
  private readonly headers: Record<string, string>;
  private readonly length: number;
  private stopped: boolean = false;
  private active: http.HttpRequest | null = null;
  private work: Promise<ArrayBuffer> | null = null;

  private constructor(source: string, headers: Record<string, string>, length: number) {
    this.source = source; this.headers = headers; this.length = length;
  }

  static async open(source: string, headers: Record<string, string>): Promise<HttpRemoteReadSession> {
    const client = http.createHttp();
    try {
      const response = await client.request(source, { method: http.RequestMethod.HEAD, header: headers,
        usingCache: false, expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 8000, readTimeout: 8000, maxLimit: 262144 });
      const length: number = Number(HttpRemoteReadSession.header(response, 'content-length'));
      if (response.responseCode !== 200 || !Number.isSafeInteger(length) || length < 0 ||
        HttpRemoteReadSession.header(response, 'content-length').length === 0) throw new Error('HTTP source unavailable');
      return new HttpRemoteReadSession(source, headers, length);
    } catch (_error) { throw new Error('HTTP source unavailable'); }
    finally { client.destroy(); }
  }

  size(): number { return this.length; }
  read(offset: number, length: number): Promise<ArrayBuffer> {
    if (this.stopped || this.work !== null || !Number.isSafeInteger(offset) || offset < 0 ||
      !Number.isSafeInteger(length) || length <= 0 || length > 262144 || offset >= this.length) {
      return Promise.reject(new Error('HTTP read unavailable'));
    }
    const count: number = Math.min(length, this.length - offset);
    const client = http.createHttp(); this.active = client;
    const headers: Record<string, string> = {};
    for (const key of Object.keys(this.headers)) headers[key] = this.headers[key];
    headers['Range'] = `bytes=${offset}-${offset + count - 1}`;
    headers['Accept-Encoding'] = 'identity';
    this.work = (async (): Promise<ArrayBuffer> => {
      try {
        const response = await client.request(this.source, { method: http.RequestMethod.GET, header: headers,
          usingCache: false, expectDataType: http.HttpDataType.ARRAY_BUFFER,
          connectTimeout: 8000, readTimeout: 8000, maxLimit: count });
        const data: ArrayBuffer = response.result as ArrayBuffer;
        const range: string = HttpRemoteReadSession.header(response, 'content-range');
        if (this.stopped || response.responseCode !== 206 ||
          range !== `bytes ${offset}-${offset + count - 1}/${this.length}` ||
          data.byteLength !== count) throw new Error('HTTP range unavailable');
        return data;
      } catch (_error) { throw new Error('HTTP range unavailable'); }
      finally { client.destroy(); }
    })().finally(() => { this.active = null; this.work = null; });
    return this.work;
  }
  cancel(): void { this.stopped = true; this.active?.destroy(); }
  async close(): Promise<void> { this.cancel(); try { await this.work; } catch (_error) {} }
  private static header(response: http.HttpResponse, name: string): string {
    const headers = response.header as Record<string, string>;
    for (const key of Object.keys(headers)) if (key.toLowerCase() === name) return String(headers[key]);
    return '';
  }
}
