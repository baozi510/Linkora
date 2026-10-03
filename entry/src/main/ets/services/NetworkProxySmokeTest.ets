import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http, socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { RemoteProtocol, RemoteReadSession } from 'linkora_core';
import { NetworkFileProxy, ProxyUrlLease } from 'linkora_proxy';
import { LinkoraFeatures } from '../foundation/LinkoraFeatures';
import { NetworkDirectoryService } from './NetworkDirectoryService';
import { NetworkAdvancedOptions, NetworkServerEntry, SftpHostKeyPolicy } from './NetworkServerStore';

interface ProxyFixture {
  label: string;
  protocol: RemoteProtocol;
  host: string;
  port: number;
  rootPath: string;
  remotePath: string;
  username: string;
  password: string;
  fingerprint: string;
  size: number;
  headHex: string;
  tailHex: string;
  middleHex: string;
  cancellationControlUrl?: string;
}
interface FtpControlFixture { host: string; port: number; controlUrl: string; cancel: boolean; maxMs: number; }
interface ProxyFixtureConfig { cases: ProxyFixture[]; ftpControlChecks?: FtpControlFixture[]; }

class MemoryReader implements RemoteReadSession {
  reads: number = 0;
  closes: number = 0;
  private cancelled: boolean = false;
  private readonly count: number;
  private readonly chunk: number;
  private readonly delay: number;
  constructor(count: number = 1024, chunk: number = 262144, delay: number = 0) {
    this.count = count; this.chunk = chunk; this.delay = delay;
  }
  size(): number { return this.count; }
  async read(offset: number, length: number): Promise<ArrayBuffer> {
    if (this.cancelled) throw new Error('cancelled');
    this.reads++;
    if (this.delay > 0) await new Promise<void>((resolve) => { setTimeout(resolve, this.delay); });
    const bytes: Uint8Array = new Uint8Array(Math.min(length, this.chunk, this.size() - offset));
    for (let i: number = 0; i < bytes.length; i++) bytes[i] = (offset + i) % 251;
    return bytes.buffer;
  }
  cancel(): void { this.cancelled = true; }
  async close(): Promise<void> { this.closes++; }
}

export class NetworkProxySmokeTest {
  static async run(context: common.UIAbilityContext, configPath: string): Promise<void> {
    const proxy: NetworkFileProxy = LinkoraFeatures.createNetworkFileProxy();
    const checks: string[] = [];
    let failure: string = '';
    let stage: string = 'basic';
    const failures: string[] = [];
    try {
      const reader: MemoryReader = new MemoryReader();
      const lease: ProxyUrlLease = await proxy.buildProxyUrl(reader, 'video/mp4');
      const head = await NetworkProxySmokeTest.request(lease.url, http.RequestMethod.HEAD);
      NetworkProxySmokeTest.assert(head.responseCode === 200 && reader.reads === 0, 'HEAD');
      checks.push('HEAD');
      const range = await NetworkProxySmokeTest.request(lease.url, http.RequestMethod.GET, 'bytes=1000-');
      const bytes: Uint8Array = new Uint8Array(range.result as ArrayBuffer);
      NetworkProxySmokeTest.assert(range.responseCode === 206 && bytes.length === 24, 'tail range');
      for (let i: number = 0; i < bytes.length; i++) {
        NetworkProxySmokeTest.assert(bytes[i] === (1000 + i) % 251, 'byte equality');
      }
      checks.push('tail bytes');
      NetworkProxySmokeTest.assert((await NetworkProxySmokeTest.request(lease.url,
        http.RequestMethod.GET, 'bytes=1024-')).responseCode === 416, '416');
      checks.push('416');
      await lease.release();
      await lease.release();
      NetworkProxySmokeTest.assert(reader.closes === 1, 'idempotent release');
      NetworkProxySmokeTest.assert((await NetworkProxySmokeTest.request(lease.url,
        http.RequestMethod.GET)).responseCode === 404, 'revoked URL');
      checks.push('release and revoke');
      stage = 'HTTP edge cases';
      await NetworkProxySmokeTest.edges(proxy, checks);
      if (configPath !== 'builtin') {
        if (!/^http:\/\/10\.0\.2\.2:\d+\/[a-f0-9-]{36}$/.test(configPath)) throw new Error('Invalid fixture address');
        const client: http.HttpRequest = http.createHttp();
        let payload: string = '';
        try {
          const response: http.HttpResponse = await client.request(configPath, {
            method: http.RequestMethod.GET, expectDataType: http.HttpDataType.STRING,
            connectTimeout: 8000, readTimeout: 8000, maxLimit: 65536 });
          if (response.responseCode !== 200) throw new Error('Fixture unavailable');
          payload = response.result as string;
        } finally { client.destroy(); }
        const privateFile: fileIo.File = fileIo.openSync(`${context.cacheDir}/proxy-smoke-config.json`,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
        try { fileIo.writeSync(privateFile.fd, payload); } finally { fileIo.closeSync(privateFile.fd); }
        const config: ProxyFixtureConfig = JSON.parse(payload) as ProxyFixtureConfig;
        for (let i: number = 0; i < config.cases.length; i++) {
          const fixture: ProxyFixture = config.cases[i];
          stage = `protocol case ${i + 1}`;
          try {
            await NetworkProxySmokeTest.fixture(proxy, fixture);
            checks.push(`${fixture.protocol} bytes and cancellation`);
            if (fixture.cancellationControlUrl !== undefined) checks.push(`${fixture.protocol} native in-flight cancellation`);
          } catch (error) {
            const message: string = error instanceof Error ? error.message : 'failed';
            const code: string = message.match(/^[A-Z_]+/)?.[0] ??
              (message.startsWith('remote ') ? message : 'failed');
            failures.push(`${fixture.protocol}: ${code}`);
          }
        }
        if (config.ftpControlChecks !== undefined) {
          for (const fixture of config.ftpControlChecks) {
            stage = 'FTP control bounds';
            await NetworkProxySmokeTest.ftpControl(fixture);
          }
          checks.push('FTP trickle deadline cancellation and response limit');
        }
      }
    } catch (error) {
      failure = `${stage}: ${error instanceof Error ? error.message : 'failed'}`;
    } finally {
      await proxy.close();
      try { fileIo.unlinkSync(`${context.cacheDir}/proxy-smoke-config.json`); } catch (_error) {}
      const output: string = JSON.stringify({ complete: true, passed: failure.length === 0 && failures.length === 0,
        checks, failure, failures });
      const file: fileIo.File = fileIo.openSync(`${context.cacheDir}/proxy-smoke-result.json`,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try { fileIo.writeSync(file.fd, output); } finally { fileIo.closeSync(file.fd); }
    }
  }

  private static async edges(proxy: NetworkFileProxy, checks: string[]): Promise<void> {
    const reader: MemoryReader = new MemoryReader(700000, 777);
    const lease: ProxyUrlLease = await proxy.buildProxyUrl(reader, 'video/mp4');
    try {
      const full = await NetworkProxySmokeTest.request(lease.url, http.RequestMethod.GET, 'bytes=262140-262180');
      NetworkProxySmokeTest.assert((full.result as ArrayBuffer).byteLength === 41 && full.responseCode === 206, 'middle bytes');
      const suffix = await NetworkProxySmokeTest.request(lease.url, http.RequestMethod.GET, 'bytes=-10');
      NetworkProxySmokeTest.assert((suffix.result as ArrayBuffer).byteLength === 10, 'suffix');
      NetworkProxySmokeTest.assert((await NetworkProxySmokeTest.request(lease.url,
        http.RequestMethod.GET, 'bytes=bad-')).responseCode === 400, 'malformed range');
      NetworkProxySmokeTest.assert((await NetworkProxySmokeTest.request(lease.url,
        http.RequestMethod.POST)).responseCode === 405, 'unsupported method');
      const token: string = lease.url.substring(lease.url.lastIndexOf('/') + 1);
      const split: string = await NetworkProxySmokeTest.raw(lease.url,
        [`HEAD /${token} HTTP/1.1\r\n`, 'Host: localhost\r\n\r\n']);
      NetworkProxySmokeTest.assert(split.startsWith('HTTP/1.1 200'), 'fragmented header');
      const duplicate: string = await NetworkProxySmokeTest.raw(lease.url,
        [`GET /${token} HTTP/1.1\r\nRange: bytes=0-1\r\nRange: bytes=4-5\r\n\r\n`]);
      NetworkProxySmokeTest.assert(duplicate.startsWith('HTTP/1.1 400'), 'duplicate Range');
      const overlong: string = await NetworkProxySmokeTest.raw(lease.url, ['H'.repeat(16385)]);
      NetworkProxySmokeTest.assert(overlong.startsWith('HTTP/1.1 431'), 'header limit');
      const slow: string = await NetworkProxySmokeTest.raw(lease.url, ['HEAD /']);
      NetworkProxySmokeTest.assert(slow.length === 0, 'header timeout');
      const longRead = await NetworkProxySmokeTest.request(lease.url, http.RequestMethod.GET, 'bytes=0-999');
      const bytes: Uint8Array = new Uint8Array(longRead.result as ArrayBuffer);
      for (let i: number = 0; i < bytes.length; i++) NetworkProxySmokeTest.assert(bytes[i] === i % 251, 'short read bytes');
      NetworkProxySmokeTest.assert(bytes.length === 1000 && reader.reads > 1, 'short read continuation');
      await NetworkProxySmokeTest.connectionLimit(lease.url);
      checks.push('HTTP errors fragments limits timeout short reads and connection limit');
    } finally { await lease.release(); }
    const leases: ProxyUrlLease[] = [];
    for (let i: number = 0; i < 8; i++) leases.push(await proxy.buildProxyUrl(new MemoryReader(), 'video/mp4'));
    const excess: MemoryReader = new MemoryReader();
    let rejected: boolean = false;
    try { await proxy.buildProxyUrl(excess, 'video/mp4'); } catch (_error) { rejected = true; }
    NetworkProxySmokeTest.assert(rejected && excess.closes === 1, 'lease limit');
    await Promise.all(leases.map((item: ProxyUrlLease) => item.release()));
    const delayed: MemoryReader = new MemoryReader(1024, 262144, 250);
    const active: ProxyUrlLease = await proxy.buildProxyUrl(delayed, 'video/mp4');
    const request: Promise<void> = NetworkProxySmokeTest.request(active.url, http.RequestMethod.GET)
      .then(() => {}, () => {});
    await new Promise<void>((resolve) => { setTimeout(resolve, 50); });
    await active.release(); await request;
    NetworkProxySmokeTest.assert(delayed.closes === 1, 'release in flight');
    const closing: ProxyUrlLease = await proxy.buildProxyUrl(new MemoryReader(), 'video/mp4');
    await proxy.close(); await proxy.close();
    await closing.release();
    const restarted: NetworkFileProxy = LinkoraFeatures.createNetworkFileProxy();
    try {
      const restartedLease: ProxyUrlLease = await restarted.buildProxyUrl(new MemoryReader(0), 'video/mp4');
      const empty = await NetworkProxySmokeTest.request(restartedLease.url, http.RequestMethod.GET);
      NetworkProxySmokeTest.assert(empty.responseCode === 200 &&
        (empty.result === undefined || (empty.result as ArrayBuffer).byteLength === 0), 'empty file');
      await restartedLease.release();
    } finally { await restarted.close(); }
    checks.push('lease limit release in flight shutdown restart empty');
  }

  private static async fixture(_closedProxy: NetworkFileProxy, fixture: ProxyFixture): Promise<void> {
    const proxy: NetworkFileProxy = LinkoraFeatures.createNetworkFileProxy();
    const options: NetworkAdvancedOptions = new NetworkAdvancedOptions();
    if (fixture.fingerprint.length > 0) options.sftpHostKeyPolicy = SftpHostKeyPolicy.STRICT;
    const server: NetworkServerEntry = new NetworkServerEntry(0, 'proxy fixture', fixture.protocol,
      fixture.host, fixture.port, fixture.rootPath, fixture.username, fixture.password, false, 0, options);
    const service: NetworkDirectoryService = new NetworkDirectoryService(server);
    let lease: ProxyUrlLease | null = null;
    let reader: RemoteReadSession | null = null;
    try {
      reader = await service.openReader(fixture.remotePath, fixture.fingerprint);
      NetworkProxySmokeTest.assert(reader.size() === fixture.size, 'remote stat');
      lease = await proxy.buildProxyUrl(reader, 'video/mp4');
      const positions: number[] = [Math.max(0, fixture.size - 32), 0, Math.floor(fixture.size / 2)];
      const expected: string[] = [fixture.tailHex, fixture.headHex, fixture.middleHex];
      for (let i: number = 0; i < positions.length; i++) {
        const response = await NetworkProxySmokeTest.request(lease.url, http.RequestMethod.GET,
          `bytes=${positions[i]}-${positions[i] + 31}`);
        NetworkProxySmokeTest.assert(response.responseCode === 206 &&
          NetworkProxySmokeTest.hex(response.result as ArrayBuffer) === expected[i], 'remote range equality');
      }
      await NetworkProxySmokeTest.rejectOpen(() => service.openReader('/linkora-proxy-nonexistent.mp4',
        fixture.fingerprint), 'missing file rejected');
      if (fixture.protocol !== RemoteProtocol.NFS) {
        const wrongServer: NetworkServerEntry = new NetworkServerEntry(0, 'negative fixture', fixture.protocol,
          fixture.host, fixture.port, fixture.rootPath, fixture.username, 'deliberately-wrong', false, 0, options);
        await NetworkProxySmokeTest.rejectOpen(() => new NetworkDirectoryService(wrongServer)
          .openReader(fixture.remotePath, fixture.fingerprint), 'wrong credentials rejected');
      }
      if (fixture.protocol === RemoteProtocol.SFTP) {
        await NetworkProxySmokeTest.rejectOpen(() => service.openReader(fixture.remotePath), 'missing fingerprint rejected');
        await NetworkProxySmokeTest.rejectOpen(() => service.openReader(fixture.remotePath, 'SHA256:wrong'),
          'mismatched fingerprint rejected');
      }
      if (fixture.protocol === RemoteProtocol.FTP) {
        await NetworkProxySmokeTest.rejectOpen(() => service.openReader('/invalid\r\nNOOP'), 'FTP injection rejected');
      }
      if (fixture.cancellationControlUrl !== undefined) {
        const control: string = fixture.cancellationControlUrl;
        await NetworkProxySmokeTest.control(control, 'arm');
        const pending: Promise<boolean> = reader.read(0, 262144).then(() => false, () => true);
        await NetworkProxySmokeTest.control(control, 'entered');
        reader.cancel();
        NetworkProxySmokeTest.assert(await pending, 'in-flight read cancelled');
        await NetworkProxySmokeTest.control(control, 'resume');
        const started: number = Date.now();
        await reader.close();
        NetworkProxySmokeTest.assert(Date.now() - started < 10000, 'native close bounded');
        let rejected: boolean = false;
        try { await reader.read(0, 1); } catch (_error) { rejected = true; }
        NetworkProxySmokeTest.assert(rejected, 'read after close rejected');
      } else {
        const pending: Promise<void> = reader.read(0, 262144).then(() => {}, () => {});
        reader.cancel(); await reader.close(); await pending;
      }
    } finally {
      if (lease !== null) await lease.release();
      else if (reader !== null) await reader.close();
      await proxy.close();
    }
  }

  private static async control(url: string, action: string): Promise<void> {
    NetworkProxySmokeTest.assert(/^http:\/\/10\.0\.2\.2:\d+\/[a-f0-9-]{36}$/.test(url), 'control address');
    const response = await NetworkProxySmokeTest.request(`${url}/${action}`, http.RequestMethod.GET);
    NetworkProxySmokeTest.assert(response.responseCode === 200, 'control acknowledgement');
  }

  private static async ftpControl(fixture: FtpControlFixture): Promise<void> {
    const server: NetworkServerEntry = new NetworkServerEntry(0, 'FTP bounds fixture', RemoteProtocol.FTP,
      fixture.host, fixture.port, '/', '', '', false, 0, new NetworkAdvancedOptions());
    const reader: RemoteReadSession = await new NetworkDirectoryService(server).openReader('/sample.mp4');
    try {
      const started: number = Date.now();
      const pending: Promise<boolean> = reader.read(0, 1).then(() => false, () => true);
      await NetworkProxySmokeTest.control(fixture.controlUrl, 'entered');
      if (fixture.cancel) reader.cancel();
      NetworkProxySmokeTest.assert(await pending, 'FTP adverse read rejected');
      const closing: Promise<void> = reader.close();
      const timely: boolean = await Promise.race([closing.then(() => true),
        new Promise<boolean>((resolve) => { setTimeout(() => resolve(false), 10000); })]);
      // Release a deliberately broken test peer even on failure, so the test itself cannot leak a worker.
      await NetworkProxySmokeTest.control(fixture.controlUrl, 'resume');
      await closing;
      NetworkProxySmokeTest.assert(timely && Date.now() - started < fixture.maxMs, 'FTP cleanup bounded');
    } finally { await reader.close(); }
  }

  private static async rejectOpen(open: () => Promise<RemoteReadSession>, label: string): Promise<void> {
    let unexpected: RemoteReadSession | null = null;
    try { unexpected = await open(); } catch (_error) { return; }
    await unexpected.close();
    throw new Error(label);
  }

  private static hex(buffer: ArrayBuffer): string {
    const bytes: Uint8Array = new Uint8Array(buffer);
    let result: string = '';
    for (let i: number = 0; i < bytes.length; i++) result += bytes[i].toString(16).padStart(2, '0');
    return result;
  }

  private static async raw(url: string, pieces: string[]): Promise<string> {
    const client: socket.TCPSocket = socket.constructTCPSocketInstance();
    const port: number = Number(url.split(':')[2].split('/')[0]);
    let data: string = '';
    let finish: () => void = () => {};
    const done: Promise<void> = new Promise((resolve) => { finish = resolve; });
    client.on('message', (message: socket.SocketMessageInfo) => {
      data += new util.TextDecoder('utf-8').decodeToString(new Uint8Array(message.message));
    });
    client.on('close', finish);
    const timer: number = setTimeout(finish, 10000);
    try {
      await client.connect({ address: { address: '127.0.0.1', port, family: 1 }, timeout: 8000 });
      for (let i: number = 0; i < pieces.length; i++) {
        await client.send({ data: pieces[i] });
        if (pieces.length > 1) await new Promise<void>((resolve) => { setTimeout(resolve, 30); });
      }
      await done; return data;
    } finally { clearTimeout(timer); await client.close().catch(() => {}); }
  }

  private static async connectionLimit(url: string): Promise<void> {
    const port: number = Number(url.split(':')[2].split('/')[0]);
    const clients: socket.TCPSocket[] = [];
    let closed: boolean = false;
    try {
      for (let i: number = 0; i < 16; i++) {
        const client: socket.TCPSocket = socket.constructTCPSocketInstance();
        clients.push(client);
        await client.connect({ address: { address: '127.0.0.1', port, family: 1 }, timeout: 8000 });
      }
      const excess: socket.TCPSocket = socket.constructTCPSocketInstance();
      clients.push(excess);
      excess.on('close', () => { closed = true; });
      excess.on('error', () => { closed = true; });
      try { await excess.connect({ address: { address: '127.0.0.1', port, family: 1 }, timeout: 8000 }); }
      catch (_error) { closed = true; }
      await new Promise<void>((resolve) => { setTimeout(resolve, 150); });
      NetworkProxySmokeTest.assert(closed, 'connection limit');
    } finally { await Promise.all(clients.map((client: socket.TCPSocket) => client.close().catch(() => {}))); }
  }

  static assert(condition: boolean, label: string): void {
    if (!condition) throw new Error(label);
  }

  static async request(url: string, method: http.RequestMethod,
    range: string = ''): Promise<http.HttpResponse> {
    const client: http.HttpRequest = http.createHttp();
    try {
      return await client.request(url, { method, header: { Range: range },
        expectDataType: http.HttpDataType.ARRAY_BUFFER, connectTimeout: 8000, readTimeout: 8000 });
    } finally { client.destroy(); }
  }
}
