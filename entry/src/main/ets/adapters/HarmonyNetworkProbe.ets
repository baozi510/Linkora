import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { http } from '@kit.NetworkKit';
import { FailureCatalog, NetworkProbePort, NetworkProbeResult } from 'linkora_core';

const PROBE_CONNECT_TIMEOUT: number = 8000;
const PROBE_READ_TIMEOUT: number = 8000;

interface ProbeHeaderMap {
  Accept: string;
  authorization: string;
  Range?: string;
  Depth?: string;
}

export class HarmonyNetworkProbe implements NetworkProbePort {
  private activeRequest: http.HttpRequest | null = null;

  async inspect(url: string): Promise<NetworkProbeResult> {
    this.cancel();
    const headResult: NetworkProbeResult = await this.request(url, http.RequestMethod.HEAD, false, '');
    if (headResult.statusCode !== 405 && headResult.statusCode !== 501) {
      return headResult;
    }
    return this.request(url, http.RequestMethod.GET, true, '');
  }

  async inspectWithCredentials(url: string, username: string, password: string): Promise<NetworkProbeResult> {
    this.cancel();
    const authorization: string = this.basicAuthorization(username, password);
    const headResult: NetworkProbeResult = await this.request(url, http.RequestMethod.HEAD, false, authorization);
    if (headResult.statusCode !== 405 && headResult.statusCode !== 501) {
      return headResult;
    }
    return this.request(url, http.RequestMethod.GET, true, authorization);
  }

  /** WebDAV servers validate access with PROPFIND, not an HTTP HEAD probe. */
  async inspectWebDavWithCredentials(url: string, username: string, password: string): Promise<NetworkProbeResult> {
    this.cancel();
    const authorization: string = this.basicAuthorization(username, password);
    return this.requestWebDav(url, authorization);
  }

  cancel(): void {
    const request: http.HttpRequest | null = this.activeRequest;
    this.activeRequest = null;
    request?.destroy();
  }

  private async request(url: string, method: http.RequestMethod,
    rangeProbe: boolean, authorization: string): Promise<NetworkProbeResult> {
    const request: http.HttpRequest = http.createHttp();
    this.activeRequest = request;
    try {
      const headers: ProbeHeaderMap = rangeProbe ? {
        Accept: '*/*',
        Range: 'bytes=0-0',
        authorization: authorization
      } : {
        Accept: '*/*',
        authorization: authorization
      };
      const response: http.HttpResponse = await request.request(url, {
        method: method,
        header: headers,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        usingCache: false,
        maxLimit: rangeProbe ? 1024 : 1,
        connectTimeout: PROBE_CONNECT_TIMEOUT,
        readTimeout: PROBE_READ_TIMEOUT
      });
      const statusCode: number = Number(response.responseCode);
      if (!rangeProbe && (statusCode === 405 || statusCode === 501)) {
        return new NetworkProbeResult(statusCode, false, null);
      }
      return new NetworkProbeResult(statusCode, true, FailureCatalog.fromHttpStatus(statusCode));
    } catch (error) {
      const code: number = (error as BusinessError).code;
      return new NetworkProbeResult(0, false, FailureCatalog.fromNetworkError(code));
    } finally {
      if (this.activeRequest === request) {
        this.activeRequest = null;
      }
      request.destroy();
    }
  }

  private async requestWebDav(url: string, authorization: string): Promise<NetworkProbeResult> {
    const request: http.HttpRequest = http.createHttp();
    this.activeRequest = request;
    try {
      const headers: ProbeHeaderMap = {
        Accept: 'application/xml, text/xml, */*',
        authorization: authorization,
        Depth: '0'
      };
      const response: http.HttpResponse = await request.request(url, {
        method: 'PROPFIND' as http.RequestMethod,
        header: headers,
        expectDataType: http.HttpDataType.STRING,
        usingCache: false,
        maxLimit: 64 * 1024,
        connectTimeout: PROBE_CONNECT_TIMEOUT,
        readTimeout: PROBE_READ_TIMEOUT
      });
      const statusCode: number = Number(response.responseCode);
      return new NetworkProbeResult(statusCode, true, FailureCatalog.fromHttpStatus(statusCode));
    } catch (error) {
      const code: number = (error as BusinessError).code;
      return new NetworkProbeResult(0, false, FailureCatalog.fromNetworkError(code));
    } finally {
      if (this.activeRequest === request) {
        this.activeRequest = null;
      }
      request.destroy();
    }
  }

  private basicAuthorization(username: string, password: string): string {
    if (username.length === 0) {
      return '';
    }
    const encoder: util.TextEncoder = new util.TextEncoder();
    const bytes: Uint8Array = encoder.encodeInto(`${username}:${password}`);
    const encoded: string = new util.Base64Helper().encodeToStringSync(bytes);
    return `Basic ${encoded}`;
  }
}
