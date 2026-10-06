import { socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import {
  RandomAccessSource,
  RemoteReadSession,
  RemoteReadSessionAdapter
} from 'linkora_core';
import { HttpByteRange, resolveHttpByteRange } from './HttpByteRange';

const MAX_UPSTREAM_READ: number = 256 * 1024;
const HEADER_LIMIT: number = 16 * 1024;

export class NetworkFileProxyConfig {
  readonly blockSizeBytes: number;
  readonly timeoutMs: number;
  readonly maxSources: number;
  readonly maxClients: number;

  constructor(blockSizeBytes: number = MAX_UPSTREAM_READ, timeoutMs: number = 8000,
    maxSources: number = 8, maxClients: number = 16) {
    this.blockSizeBytes = Math.max(1, Math.min(MAX_UPSTREAM_READ, Math.floor(blockSizeBytes)));
    this.timeoutMs = Math.max(1000, Math.floor(timeoutMs));
    this.maxSources = Math.max(1, Math.floor(maxSources));
    this.maxClients = Math.max(1, Math.floor(maxClients));
  }
}

export class NetworkFileProxyDiagnostics {
  readonly activeSources: number;
  readonly activeClients: number;
  readonly readRequests: number;
  readonly rangeRequests: number;
  readonly bytesRead: number;
  readonly releasedSources: number;
  readonly rangeTraces: string[];
  readonly readTraces: Array<[number, number]>;

  constructor(activeSources: number, activeClients: number, readRequests: number,
    bytesRead: number, releasedSources: number, rangeRequests: number = 0,
    rangeTraces: string[] = [], readTraces: Array<[number, number]> = []) {
    this.activeSources = Math.max(0, activeSources);
    this.activeClients = Math.max(0, activeClients);
    this.readRequests = Math.max(0, readRequests);
    this.rangeRequests = Math.max(0, rangeRequests);
    this.bytesRead = Math.max(0, bytesRead);
    this.releasedSources = Math.max(0, releasedSources);
    this.rangeTraces = rangeTraces.slice(0);
    this.readTraces = readTraces.slice(0);
  }

  uniqueByteSpan(): number {
    if (this.readTraces.length === 0) return 0;
    const intervals: Array<[number, number]> = this.readTraces
      .map((r: [number, number]): [number, number] => [r[0], r[0] + r[1]])
      .sort((a: [number, number], b: [number, number]): number => a[0] - b[0]);
    let mergedLen = 0;
    let curStart = intervals[0][0];
    let curEnd = intervals[0][1];
    for (let i = 1; i < intervals.length; i++) {
      if (intervals[i][0] <= curEnd) {
        curEnd = Math.max(curEnd, intervals[i][1]);
      } else {
        mergedLen += curEnd - curStart;
        curStart = intervals[i][0];
        curEnd = intervals[i][1];
      }
    }
    mergedLen += curEnd - curStart;
    return mergedLen;
  }

  overlappingBytes(): number {
    return Math.max(0, this.bytesRead - this.uniqueByteSpan());
  }

  headRereads(): number {
    let passed1Mb = false;
    let count = 0;
    for (const r of this.readTraces) {
      if (r[0] >= 1048576) {
        passed1Mb = true;
      } else if (passed1Mb && r[0] < 1048576) {
        count++;
      }
    }
    return count;
  }
}

class ProxySource {
  readonly source: RandomAccessSource;
  readonly contentType: string;
  active: boolean = true;
  tail: Promise<void> = Promise.resolve();
  readRequests: number = 0;
  rangeRequests: number = 0;
  bytesRead: number = 0;
  readonly rangeTraces: string[] = [];
  readonly readTraces: Array<[number, number]> = [];

  constructor(source: RandomAccessSource, contentType: string) {
    this.source = source;
    this.contentType = contentType;
  }

  size(): number {
    return this.source.size();
  }

  read(offset: number, length: number): Promise<ArrayBuffer> {
    const operation: Promise<ArrayBuffer> = this.tail.then(async (): Promise<ArrayBuffer> => {
      if (!this.active) throw new Error('Proxy source closed');
      const data: ArrayBuffer = await this.source.readAt(offset, length);
      this.readRequests++;
      this.bytesRead += data.byteLength;
      this.readTraces.push([offset, data.byteLength]);
      return data;
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

  constructor(connection: socket.TCPSocketConnection) {
    this.connection = connection;
  }
}

export class ProxyUrlLease {
  readonly url: string;
  readonly sourceId: string;
  private readonly releaseSource: () => Promise<void>;
  private releasing: Promise<void> | null = null;

  constructor(url: string, sourceId: string, releaseSource: () => Promise<void>) {
    this.url = url;
    this.sourceId = sourceId;
    this.releaseSource = releaseSource;
  }

  release(): Promise<void> {
    if (this.releasing === null) this.releasing = this.releaseSource();
    return this.releasing;
  }
}

/**
 * Loopback Range transport.
 *
 * The primary API owns RandomAccessSource. buildProxyUrl(RemoteReadSession)
 * remains as a migration facade for existing callers.
 */
export class NetworkFileProxy {
  private readonly config: NetworkFileProxyConfig;
  private server: socket.TCPSocketServer | null = null;
  private starting: Promise<void> | null = null;
  private closing: Promise<void> | null = null;
  private closed: boolean = false;
  private port: number = 0;
  private pending: number = 0;
  private releasedReadRequests: number = 0;
  private releasedRangeRequests: number = 0;
  private releasedBytesRead: number = 0;
  private releasedSources: number = 0;
  private releasedRangeTraces: string[] = [];
  private releasedReadTraces: Array<[number, number]> = [];
  private readonly sources: Map<string, ProxySource> = new Map();
  private readonly clients: Map<number, ProxyClient> = new Map();
  private readonly releases: Set<Promise<void>> = new Set();

  constructor(config: NetworkFileProxyConfig = new NetworkFileProxyConfig()) {
    this.config = config;
  }

  async buildSourceUrl(source: RandomAccessSource, contentType: string): Promise<ProxyUrlLease> {
    const capabilities = source.capabilities();
    if (this.closed || this.sources.size + this.pending >= this.config.maxSources ||
      !capabilities.seekable || !capabilities.sizeKnown ||
      !Number.isSafeInteger(source.size()) || source.size() < 0 ||
      !/^[a-zA-Z0-9!#$&^_.+-]+\/[a-zA-Z0-9!#$&^_.+-]+$/.test(contentType)) {
      source.cancel();
      await source.close();
      throw new Error('Proxy registration rejected');
    }

    this.pending++;
    try {
      if (this.starting === null) this.starting = this.start();
      await this.starting;
      if (this.closed) throw new Error('Proxy closed');
      const token: string = util.generateRandomUUID(true);
      const proxySource: ProxySource = new ProxySource(source, contentType);
      this.sources.set(token, proxySource);
      return new ProxyUrlLease(
        `http://127.0.0.1:${this.port}/${token}`,
        source.id(),
        () => this.release(token, proxySource)
      );
    } catch (_error) {
      source.cancel();
      await source.close();
      throw new Error('Proxy registration failed');
    } finally {
      this.pending--;
    }
  }

  async buildProxyUrl(reader: RemoteReadSession, contentType: string): Promise<ProxyUrlLease> {
    const adapter = new RemoteReadSessionAdapter(
      `legacy:${util.generateRandomUUID(true)}`,
      reader
    );
    return this.buildSourceUrl(adapter, contentType);
  }

  diagnostics(): NetworkFileProxyDiagnostics {
    let activeReadRequests: number = 0;
    let activeRangeRequests: number = 0;
    let activeBytesRead: number = 0;
    const allRangeTraces: string[] = this.releasedRangeTraces.slice(0);
    const allReadTraces: Array<[number, number]> = this.releasedReadTraces.slice(0);
    this.sources.forEach((source: ProxySource) => {
      activeReadRequests += source.readRequests;
      activeRangeRequests += source.rangeRequests;
      activeBytesRead += source.bytesRead;
      allRangeTraces.push(...source.rangeTraces);
      allReadTraces.push(...source.readTraces);
    });
    return new NetworkFileProxyDiagnostics(
      this.sources.size,
      this.clients.size,
      this.releasedReadRequests + activeReadRequests,
      this.releasedBytesRead + activeBytesRead,
      this.releasedSources,
      this.releasedRangeRequests + activeRangeRequests,
      allRangeTraces,
      allReadTraces
    );
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
    if (this.closed || this.clients.size >= this.config.maxClients) {
      connection.close().catch(() => {});
      return;
    }
    const client: ProxyClient = new ProxyClient(connection);
    this.clients.set(connection.clientId, client);
    client.timer = setTimeout(() => { this.disconnect(client); }, this.config.timeoutMs);
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
        seenRange = true;
        range = value;
      }
      if (name === 'transfer-encoding' || (name === 'content-length' && value !== '0')) {
        await this.respond(client, 400); return;
      }
    }

    const proxySource: ProxySource | undefined = this.sources.get(request[1].substring(1));
    if (!request[1].startsWith('/') || proxySource === undefined || !proxySource.active) {
      await this.respond(client, 404); return;
    }

    client.source = proxySource;
    const result: HttpByteRange =
      resolveHttpByteRange(request[0] === 'HEAD' ? '' : range, proxySource.size());
    if (request[0] === 'GET' && seenRange && result.status === 206) {
      proxySource.rangeRequests++;
      proxySource.rangeTraces.push(range);
    }
    if (result.status === 400 || result.status === 416) {
      await this.respond(client, result.status, 0, result.contentRange); return;
    }

    let position: number = result.offset;
    let remaining: number = result.length;
    let first: ArrayBuffer | null = null;
    try {
      if (request[0] === 'GET' && remaining > 0) {
        first = await proxySource.read(position, Math.min(this.config.blockSizeBytes, remaining));
      }
      if (first !== null &&
        (first.byteLength === 0 || first.byteLength > Math.min(this.config.blockSizeBytes, remaining))) {
        throw new Error('Invalid remote read');
      }
    } catch (_error) {
      if (!client.closed) await this.respond(client, 502);
      return;
    }

    if (client.closed || !proxySource.active) return;
    await this.respond(client, result.status, result.length, result.contentRange, proxySource.contentType);
    if (request[0] === 'HEAD') return;

    while (remaining > 0 && !client.closed && proxySource.active) {
      const block: ArrayBuffer = first ??
        await proxySource.read(position, Math.min(this.config.blockSizeBytes, remaining));
      first = null;
      if (block.byteLength === 0 ||
        block.byteLength > Math.min(this.config.blockSizeBytes, remaining)) {
        throw new Error('Remote EOF');
      }
      if (client.closed || !proxySource.active) return;
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
    const timer: number = setTimeout(() => { this.disconnect(client); }, this.config.timeoutMs);
    try {
      await client.connection.send({ data });
    } finally {
      clearTimeout(timer);
    }
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

  private release(token: string, proxySource: ProxySource): Promise<void> {
    if (!proxySource.active) return Promise.resolve();
    proxySource.active = false;
    this.sources.delete(token);
    this.releasedReadRequests += proxySource.readRequests;
    this.releasedRangeRequests += proxySource.rangeRequests;
    this.releasedBytesRead += proxySource.bytesRead;
    this.releasedRangeTraces.push(...proxySource.rangeTraces);
    this.releasedReadTraces.push(...proxySource.readTraces);
    this.releasedSources++;
    proxySource.source.cancel();
    const operation: Promise<void> = this.dispose(proxySource);
    this.releases.add(operation);
    operation.then(() => this.releases.delete(operation), () => this.releases.delete(operation));
    return operation;
  }

  private async dispose(proxySource: ProxySource): Promise<void> {
    const clients: ProxyClient[] = [];
    this.clients.forEach((client: ProxyClient) => {
      if (client.source === proxySource) clients.push(client);
    });
    await Promise.all(clients.map((client: ProxyClient) => this.disconnect(client)));
    await proxySource.tail;
    await proxySource.source.close();
  }

  private async shutdown(): Promise<void> {
    await this.starting?.catch(() => {});
    const operations: Promise<void>[] = [];
    this.sources.forEach((source: ProxySource, token: string) =>
      operations.push(this.release(token, source)));
    this.clients.forEach((client: ProxyClient) =>
      operations.push(this.disconnect(client)));
    this.releases.forEach((operation: Promise<void>) => operations.push(operation));
    if (this.server !== null) operations.push(this.server.close().catch(() => {}));
    await Promise.all(operations);
    this.server = null;
  }
}
