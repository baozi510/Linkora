import { socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { RemoteReadSession } from 'linkora_core';
import { HttpByteRange, resolveHttpByteRange } from './HttpByteRange';

const BLOCK_SIZE: number = 256 * 1024;
const HEADER_LIMIT: number = 16 * 1024;
const TIMEOUT: number = 8000;

class ProxySource {
  readonly reader: RemoteReadSession;
  readonly contentType: string;
  active: boolean = true;
  tail: Promise<void> = Promise.resolve();
  constructor(reader: RemoteReadSession, contentType: string) {
    this.reader = reader;
    this.contentType = contentType;
  }
  read(offset: number, length: number): Promise<ArrayBuffer> {
    const operation: Promise<ArrayBuffer> = this.tail.then(() => {
      if (!this.active) throw new Error('Proxy source closed');
      return this.reader.read(offset, length);
    });
    this.tail = operation.then(() => {}, () => {});
    return operation;
  }
}

class ProxyClient {
  readonly connection: socket.TCPSocketConnection;
  header: Uint8Array = new Uint8Array(0);
  handled: boolean = false;
  closed: boolean = false;
  source: ProxySource | null = null;
  timer: number = -1;
  constructor(connection: socket.TCPSocketConnection) { this.connection = connection; }
}

export class ProxyUrlLease {
  readonly url: string;
  private readonly releaseSource: () => Promise<void>;
  private releasing: Promise<void> | null = null;
  constructor(url: string, releaseSource: () => Promise<void>) {
    this.url = url;
    this.releaseSource = releaseSource;
  }
  release(): Promise<void> {
    if (this.releasing === null) this.releasing = this.releaseSource();
    return this.releasing;
  }
}

/** Optional loopback transport. It owns readers after buildProxyUrl is called. */
export class NetworkFileProxy {
  private server: socket.TCPSocketServer | null = null;
  private starting: Promise<void> | null = null;
  private closing: Promise<void> | null = null;
  private closed: boolean = false;
  private port: number = 0;
  private pending: number = 0;
  private readonly sources: Map<string, ProxySource> = new Map();
  private readonly clients: Map<number, ProxyClient> = new Map();
  private readonly releases: Set<Promise<void>> = new Set();

  async buildProxyUrl(reader: RemoteReadSession, contentType: string): Promise<ProxyUrlLease> {
    if (this.closed || this.sources.size + this.pending >= 8 ||
      !Number.isSafeInteger(reader.size()) || reader.size() < 0 ||
      !/^[a-zA-Z0-9!#$&^_.+-]+\/[a-zA-Z0-9!#$&^_.+-]+$/.test(contentType)) {
      reader.cancel();
      await reader.close();
      throw new Error('Proxy registration rejected');
    }
    this.pending++;
    try {
      if (this.starting === null) this.starting = this.start();
      await this.starting;
      if (this.closed) throw new Error('Proxy closed');
      const token: string = util.generateRandomUUID(true);
      const source: ProxySource = new ProxySource(reader, contentType);
      this.sources.set(token, source);
      return new ProxyUrlLease(`http://127.0.0.1:${this.port}/${token}`,
        () => this.release(token, source));
    } catch (_error) {
      reader.cancel();
      await reader.close();
      throw new Error('Proxy registration failed');
    } finally { this.pending--; }
  }

  close(): Promise<void> {
    if (this.closing === null) {
      this.closed = true;
      this.closing = this.shutdown();
    }
    return this.closing;
  }

  private async start(): Promise<void> {
    const server: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
    this.server = server;
    server.on('error', () => { this.close().catch(() => {}); });
    try {
      await server.listen({ address: '127.0.0.1', port: 0, family: 1 });
      const address: socket.NetAddress = await server.getLocalAddress();
      if (address.address !== '127.0.0.1' || !address.port) throw new Error('Invalid loopback binding');
      this.port = address.port;
      server.on('connect', (connection: socket.TCPSocketConnection) => this.accept(connection));
    } catch (_error) {
      await server.close().catch(() => {});
      this.server = null;
      throw new Error('Proxy listener failed');
    }
  }

  private accept(connection: socket.TCPSocketConnection): void {
    if (this.closed || this.clients.size >= 16) {
      connection.close().catch(() => {});
      return;
    }
    const client: ProxyClient = new ProxyClient(connection);
    this.clients.set(connection.clientId, client);
    client.timer = setTimeout(() => { this.disconnect(client); }, TIMEOUT);
    connection.on('close', () => this.forget(client));
    connection.on('error', () => { this.disconnect(client); });
    connection.on('message', (message: socket.SocketMessageInfo) => {
      if (client.handled || client.closed) return;
      const input: Uint8Array = new Uint8Array(message.message);
      if (client.header.length + input.length > HEADER_LIMIT) {
        client.handled = true;
        this.respond(client, 431).catch(() => {}).finally(() => this.disconnect(client));
        return;
      }
      const header: Uint8Array = new Uint8Array(client.header.length + input.length);
      header.set(client.header);
      header.set(input, client.header.length);
      client.header = header;
      const text: string = new util.TextDecoder('utf-8').decodeToString(header);
      if (!text.includes('\r\n\r\n')) return;
      client.handled = true;
      clearTimeout(client.timer);
      this.serve(client, text).catch(() => {}).finally(() => this.disconnect(client));
    });
  }

  private async serve(client: ProxyClient, header: string): Promise<void> {
    const end: number = header.indexOf('\r\n\r\n');
    const lines: string[] = header.substring(0, end).split('\r\n');
    const request: string[] = lines[0].split(' ');
    if (request.length !== 3 || !/^HTTP\/1\.[01]$/.test(request[2]) || end + 4 !== header.length) {
      await this.respond(client, 400); return;
    }
    if (request[0] !== 'GET' && request[0] !== 'HEAD') {
      await this.respond(client, 405, 0, '', 'application/octet-stream', 'Allow: GET, HEAD\r\n'); return;
    }
    let range: string = '';
    let seenRange: boolean = false;
    for (let i: number = 1; i < lines.length; i++) {
      const colon: number = lines[i].indexOf(':');
      if (colon <= 0 || /^[ \t]/.test(lines[i])) { await this.respond(client, 400); return; }
      const name: string = lines[i].substring(0, colon).toLowerCase();
      const value: string = lines[i].substring(colon + 1).trim();
      if (name === 'range') {
        if (seenRange) { await this.respond(client, 400); return; }
        seenRange = true; range = value;
      }
      if (name === 'transfer-encoding' || (name === 'content-length' && value !== '0')) {
        await this.respond(client, 400); return;
      }
    }
    const source: ProxySource | undefined = this.sources.get(request[1].substring(1));
    if (!request[1].startsWith('/') || source === undefined || !source.active) {
      await this.respond(client, 404); return;
    }
    client.source = source;
    const result: HttpByteRange = resolveHttpByteRange(request[0] === 'HEAD' ? '' : range, source.reader.size());
    if (result.status === 400 || result.status === 416) {
      await this.respond(client, result.status, 0, result.contentRange); return;
    }
    let position: number = result.offset;
    let remaining: number = result.length;
    let first: ArrayBuffer | null = null;
    try {
      if (request[0] === 'GET' && remaining > 0) first = await source.read(position, Math.min(BLOCK_SIZE, remaining));
      if (first !== null && (first.byteLength === 0 || first.byteLength > Math.min(BLOCK_SIZE, remaining))) {
        throw new Error('Invalid remote read');
      }
    } catch (_error) { if (!client.closed) await this.respond(client, 502); return; }
    if (client.closed || !source.active) return;
    await this.respond(client, result.status, result.length, result.contentRange, source.contentType);
    if (request[0] === 'HEAD') return;
    while (remaining > 0 && !client.closed && source.active) {
      const block: ArrayBuffer = first ?? await source.read(position, Math.min(BLOCK_SIZE, remaining));
      first = null;
      if (block.byteLength === 0 || block.byteLength > Math.min(BLOCK_SIZE, remaining)) throw new Error('Remote EOF');
      if (client.closed || !source.active) return;
      await this.send(client, block);
      position += block.byteLength;
      remaining -= block.byteLength;
    }
  }

  private respond(client: ProxyClient, status: number, length: number = 0, contentRange: string = '',
    contentType: string = 'application/octet-stream', extra: string = ''): Promise<void> {
    const text: string = `HTTP/1.1 ${status} Response\r\nContent-Length: ${length}\r\n` +
      `Content-Type: ${contentType}\r\nAccept-Ranges: bytes\r\nConnection: close\r\n` +
      (contentRange.length > 0 ? `Content-Range: ${contentRange}\r\n` : '') + extra + '\r\n';
    return this.send(client, new util.TextEncoder().encodeInto(text).buffer as ArrayBuffer);
  }

  private async send(client: ProxyClient, data: ArrayBuffer): Promise<void> {
    if (client.closed) throw new Error('Client closed');
    const timer: number = setTimeout(() => { this.disconnect(client); }, TIMEOUT);
    try { await client.connection.send({ data }); } finally { clearTimeout(timer); }
  }

  private forget(client: ProxyClient): void {
    client.closed = true;
    clearTimeout(client.timer);
    this.clients.delete(client.connection.clientId);
  }
  private async disconnect(client: ProxyClient): Promise<void> {
    if (client.closed) return;
    this.forget(client);
    await client.connection.close().catch(() => {});
  }

  private release(token: string, source: ProxySource): Promise<void> {
    if (!source.active) return Promise.resolve();
    source.active = false;
    this.sources.delete(token);
    source.reader.cancel();
    const operation: Promise<void> = this.dispose(source);
    this.releases.add(operation);
    operation.then(() => this.releases.delete(operation), () => this.releases.delete(operation));
    return operation;
  }
  private async dispose(source: ProxySource): Promise<void> {
    const clients: ProxyClient[] = [];
    this.clients.forEach((client: ProxyClient) => { if (client.source === source) clients.push(client); });
    await Promise.all(clients.map((client: ProxyClient) => this.disconnect(client)));
    await source.tail;
    await source.reader.close();
  }
  private async shutdown(): Promise<void> {
    await this.starting?.catch(() => {});
    const operations: Promise<void>[] = [];
    this.sources.forEach((source: ProxySource, token: string) => operations.push(this.release(token, source)));
    this.clients.forEach((client: ProxyClient) => operations.push(this.disconnect(client)));
    this.releases.forEach((operation: Promise<void>) => operations.push(operation));
    if (this.server !== null) operations.push(this.server.close().catch(() => {}));
    await Promise.all(operations);
    this.server = null;
  }
}
