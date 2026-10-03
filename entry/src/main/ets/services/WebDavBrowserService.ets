import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { http } from '@kit.NetworkKit';
import { NetworkServerEntry } from './NetworkServerStore';
import { NetworkDirectorySummaryCache } from './NetworkDirectorySummaryCache';

const LIST_CONNECT_TIMEOUT: number = 8000;
const LIST_READ_TIMEOUT: number = 12000;
const LIST_RESPONSE_LIMIT: number = 2 * 1024 * 1024;

interface WebDavListHeaderMap {
  Accept: string;
  authorization: string;
  depth: string;
  'Content-Type': string;
}

export enum WebDavEntryKind {
  FILE = 'file',
  DIRECTORY = 'directory'
}

export class WebDavBrowserEntry {
  readonly path: string;
  readonly displayName: string;
  readonly kind: WebDavEntryKind;
  readonly size: number;
  readonly modifiedAt: number;

  constructor(path: string, displayName: string, kind: WebDavEntryKind,
    size: number = 0, modifiedAt: number = 0) {
    this.path = path;
    this.displayName = displayName;
    this.kind = kind;
    this.size = size;
    this.modifiedAt = modifiedAt;
  }
}

export class WebDavBrowserService {
  private static directoryCache: Map<string, WebDavBrowserEntry[]> =
    new Map<string, WebDavBrowserEntry[]>();
  private server: NetworkServerEntry;
  private activeRequest: http.HttpRequest | null = null;

  constructor(server: NetworkServerEntry) {
    this.server = server;
  }

  async list(path: string, forceRefresh: boolean = false): Promise<WebDavBrowserEntry[]> {
    const cacheKey: string = NetworkDirectorySummaryCache.keyForServer(this.server, path);
    const cached: WebDavBrowserEntry[] | undefined = WebDavBrowserService.directoryCache.get(cacheKey);
    if (!forceRefresh && cached !== undefined) {
      return cached.slice();
    }
    this.cancel();
    const request: http.HttpRequest = http.createHttp();
    this.activeRequest = request;
    try {
      const headers: WebDavListHeaderMap = {
        Accept: 'application/xml, text/xml, */*',
        authorization: this.basicAuthorization(),
        depth: '1',
        'Content-Type': 'application/xml; charset=utf-8'
      };
      const response: http.HttpResponse = await request.request(this.url(path), {
        // NetStack forwards the enum's string value, so WebDAV's standard
        // extension verb can be supplied even though RequestMethod only lists
        // the core HTTP verbs in its type declaration.
        method: 'PROPFIND' as http.RequestMethod,
        header: headers,
        extraData: '<?xml version="1.0" encoding="utf-8"?><D:propfind xmlns:D="DAV:"><D:allprop/></D:propfind>',
        expectDataType: http.HttpDataType.STRING,
        usingCache: false,
        maxLimit: LIST_RESPONSE_LIMIT,
        connectTimeout: LIST_CONNECT_TIMEOUT,
        readTimeout: LIST_READ_TIMEOUT
      });
      const statusCode: number = Number(response.responseCode);
      if (statusCode === 401 || statusCode === 403) {
        throw new Error('账号或密码不正确，服务器拒绝访问。');
      }
      if (statusCode < 200 || statusCode >= 300) {
        throw new Error(`服务器返回 HTTP ${statusCode}，无法读取目录。`);
      }
      const body: string = response.result as string;
      const entries: WebDavBrowserEntry[] = this.parseEntries(body, path);
      if (!WebDavBrowserService.directoryCache.has(cacheKey) &&
        WebDavBrowserService.directoryCache.size >= 256) {
        WebDavBrowserService.directoryCache.clear();
      }
      WebDavBrowserService.directoryCache.set(cacheKey, entries.slice());
      return entries;
    } catch (error) {
      if (error instanceof Error && error.message.length > 0) {
        throw error;
      }
      const code: number = (error as BusinessError).code;
      throw new Error(code > 0 ? `无法读取目录（错误码 ${code}）。` : '无法读取目录，请检查网络连接。');
    } finally {
      if (this.activeRequest === request) {
        this.activeRequest = null;
      }
      request.destroy();
    }
  }

  cancel(): void {
    const request: http.HttpRequest | null = this.activeRequest;
    this.activeRequest = null;
    request?.destroy();
  }

  fileUrl(path: string): string {
    return this.url(path);
  }

  fileHeaders(): Record<string, string> {
    const headers: Record<string, string> = {};
    const authorization: string = this.basicAuthorization();
    if (authorization.length > 0) headers['authorization'] = authorization;
    return headers;
  }

  private url(path: string): string {
    const scheme: string = this.server.secureTransport ? 'https' : 'http';
    const defaultPort: number = this.server.secureTransport ? 443 : 80;
    const portLabel: string = this.server.port === defaultPort ? '' : `:${this.server.port}`;
    return `${scheme}://${this.server.host}${portLabel}${this.encodedPath(path)}`;
  }

  private encodedPath(path: string): string {
    const normalized: string = path.startsWith('/') ? path : `/${path}`;
    const segments: string[] = normalized.split('/');
    const encoded: string[] = [];
    for (let index: number = 0; index < segments.length; index++) {
      encoded.push(encodeURIComponent(segments[index]));
    }
    const value: string = encoded.join('/');
    return value.length === 0 ? '/' : value;
  }

  private basicAuthorization(): string {
    if (this.server.username.length === 0) {
      return '';
    }
    const encoder: util.TextEncoder = new util.TextEncoder();
    const bytes: Uint8Array = encoder.encodeInto(`${this.server.username}:${this.server.password}`);
    const encoded: string = new util.Base64Helper().encodeToStringSync(bytes);
    return `Basic ${encoded}`;
  }

  private parseEntries(xml: string, requestedPath: string): WebDavBrowserEntry[] {
    const entries: WebDavBrowserEntry[] = [];
    const requested: string = this.comparablePath(requestedPath);
    // WebDAV servers are allowed to choose any namespace prefix (or no
    // prefix), and the prefix/casing is not consistent across servers. Keep
    // the parser namespace-aware by matching the local element names instead
    // of requiring the literal `D:` prefix used by one particular server.
    const responsePattern: RegExp = /<(?:[A-Za-z0-9_-]+:)?response\b[^>]*>[\s\S]*?<\/(?:[A-Za-z0-9_-]+:)?response\s*>/gi;
    const responseBlocks: RegExpMatchArray | null = xml.match(responsePattern);
    if (responseBlocks === null) {
      return entries;
    }
    for (const block of responseBlocks) {
      const href: string = this.xmlValue(block, 'href');
      const path: string = this.decodedHrefPath(href);
      if (path.length === 0 || this.comparablePath(path) === requested) {
        continue;
      }
      let displayName: string = this.decodeXml(this.xmlValue(block, 'displayname')).trim();
      if (displayName.length === 0) {
        displayName = this.lastPathSegment(path);
      }
      if (displayName.length === 0 || displayName.startsWith('.')) {
        continue;
      }
      const isDirectory: boolean = /<(?:[A-Za-z0-9_-]+:)?collection\b/i.test(block);
      const sizeValue: number = Number(this.xmlValue(block, 'getcontentlength'));
      const modifiedValue: string = this.xmlValue(block, 'getlastmodified');
      const modifiedAt: number = modifiedValue.length > 0 ? new Date(modifiedValue).getTime() : 0;
      entries.push(new WebDavBrowserEntry(path, displayName,
        isDirectory ? WebDavEntryKind.DIRECTORY : WebDavEntryKind.FILE,
        Number.isFinite(sizeValue) ? sizeValue : 0,
        Number.isFinite(modifiedAt) ? modifiedAt : 0));
    }
    entries.sort((left: WebDavBrowserEntry, right: WebDavBrowserEntry): number => {
      if (left.kind !== right.kind) {
        return left.kind === WebDavEntryKind.DIRECTORY ? -1 : 1;
      }
      return left.displayName.localeCompare(right.displayName);
    });
    return entries;
  }

  private xmlValue(block: string, tag: string): string {
    const pattern: RegExp = new RegExp(
      `<(?:[A-Za-z0-9_-]+:)?${tag}\\b[^>]*>([\\s\\S]*?)<\\/(?:[A-Za-z0-9_-]+:)?${tag}\\s*>`,
      'i');
    const match: RegExpExecArray | null = pattern.exec(block);
    return match === null ? '' : match[1];
  }

  private decodedHrefPath(href: string): string {
    let value: string = this.decodeXml(href).trim();
    const scheme: number = value.indexOf('://');
    if (scheme >= 0) {
      const pathStart: number = value.indexOf('/', scheme + 3);
      value = pathStart >= 0 ? value.substring(pathStart) : '/';
    }
    try {
      value = decodeURIComponent(value);
    } catch (_error) {
      // Keep the encoded path when a server returns malformed percent escapes.
    }
    return value.startsWith('/') ? value : `/${value}`;
  }

  private decodeXml(value: string): string {
    return value.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"').replace(/&#39;/g, "'");
  }

  private comparablePath(path: string): string {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path.length === 0 ? '/' : path;
  }

  private lastPathSegment(path: string): string {
    const normalized: string = this.comparablePath(path);
    const slash: number = normalized.lastIndexOf('/');
    return slash >= 0 ? normalized.substring(slash + 1) : normalized;
  }
}
