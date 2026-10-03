import { LinkIssue, LinkParseResult, MediaLink, MediaProtocol } from '../models/MediaLink';
import { MediaFormatDetector } from '../models/MediaFormatDetector';

const MAX_URL_LENGTH: number = 4096;
const SCHEME_SEPARATOR: string = '://';

export class NetworkLinkParser {
  static parse(rawValue: string): LinkParseResult {
    const input: string = rawValue.trim();
    if (input.length === 0) {
      return new LinkParseResult(null, LinkIssue.EMPTY);
    }
    if (input.length > MAX_URL_LENGTH) {
      return new LinkParseResult(null, LinkIssue.TOO_LONG);
    }

    if (NetworkLinkParser.containsWhitespace(input)) {
      return new LinkParseResult(null, LinkIssue.INVALID_URL);
    }

    const schemeEnd: number = input.indexOf(SCHEME_SEPARATOR);
    if (schemeEnd <= 0) {
      return new LinkParseResult(null, LinkIssue.INVALID_URL);
    }
    const protocolValue: string = input.substring(0, schemeEnd).toLowerCase();
    if (protocolValue !== MediaProtocol.HTTP && protocolValue !== MediaProtocol.HTTPS) {
      return new LinkParseResult(null, LinkIssue.UNSUPPORTED_PROTOCOL);
    }

    const authorityStart: number = schemeEnd + SCHEME_SEPARATOR.length;
    const authorityEnd: number = NetworkLinkParser.findAuthorityEnd(input, authorityStart);
    const authority: string = input.substring(authorityStart, authorityEnd);
    if (authority.length === 0) {
      return new LinkParseResult(null, LinkIssue.MISSING_HOST);
    }
    if (authority.includes('@')) {
      return new LinkParseResult(null, LinkIssue.EMBEDDED_CREDENTIALS);
    }

    const host: string | null = NetworkLinkParser.extractHost(authority);
    if (host === null) {
      return new LinkParseResult(null, LinkIssue.INVALID_URL);
    }

    const protocol: MediaProtocol = protocolValue === MediaProtocol.HTTPS ?
      MediaProtocol.HTTPS : MediaProtocol.HTTP;
    const pathEnd: number = NetworkLinkParser.findPathEnd(input, authorityEnd);
    const pathname: string = input.substring(authorityEnd, pathEnd);
    return new LinkParseResult(new MediaLink(
      input,
      host,
      protocol,
      MediaFormatDetector.detect(pathname)
    ), LinkIssue.NONE);
  }

  private static containsWhitespace(value: string): boolean {
    return /\s/.test(value);
  }

  private static findAuthorityEnd(value: string, start: number): number {
    const slashIndex: number = value.indexOf('/', start);
    const queryIndex: number = value.indexOf('?', start);
    const fragmentIndex: number = value.indexOf('#', start);
    let end: number = value.length;
    if (slashIndex >= 0 && slashIndex < end) {
      end = slashIndex;
    }
    if (queryIndex >= 0 && queryIndex < end) {
      end = queryIndex;
    }
    if (fragmentIndex >= 0 && fragmentIndex < end) {
      end = fragmentIndex;
    }
    return end;
  }

  private static findPathEnd(value: string, start: number): number {
    const queryIndex: number = value.indexOf('?', start);
    const fragmentIndex: number = value.indexOf('#', start);
    let end: number = value.length;
    if (queryIndex >= 0 && queryIndex < end) {
      end = queryIndex;
    }
    if (fragmentIndex >= 0 && fragmentIndex < end) {
      end = fragmentIndex;
    }
    return end;
  }

  private static extractHost(authority: string): string | null {
    if (authority.startsWith('[')) {
      const bracketEnd: number = authority.indexOf(']');
      if (bracketEnd <= 1) {
        return null;
      }
      const suffix: string = authority.substring(bracketEnd + 1);
      if (!NetworkLinkParser.isValidPortSuffix(suffix)) {
        return null;
      }
      return authority.substring(0, bracketEnd + 1);
    }

    const colonIndex: number = authority.lastIndexOf(':');
    if (colonIndex < 0) {
      return authority.length > 0 ? authority : null;
    }
    if (authority.indexOf(':') !== colonIndex) {
      return null;
    }
    const host: string = authority.substring(0, colonIndex);
    const portSuffix: string = authority.substring(colonIndex);
    if (host.length === 0 || !NetworkLinkParser.isValidPortSuffix(portSuffix)) {
      return null;
    }
    return host;
  }

  private static isValidPortSuffix(suffix: string): boolean {
    if (suffix.length === 0) {
      return true;
    }
    if (!suffix.startsWith(':') || suffix.length === 1) {
      return false;
    }
    const portText: string = suffix.substring(1);
    if (!/^\d+$/.test(portText)) {
      return false;
    }
    const port: number = Number(portText);
    return port >= 1 && port <= 65535;
  }

}
