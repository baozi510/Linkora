export class HttpByteRange {
  readonly status: number;
  readonly offset: number;
  readonly length: number;
  readonly contentRange: string;
  constructor(status: number, offset: number, length: number, contentRange: string = '') {
    this.status = status;
    this.offset = offset;
    this.length = length;
    this.contentRange = contentRange;
  }
}

export function resolveHttpByteRange(range: string, size: number): HttpByteRange {
  if (!Number.isSafeInteger(size) || size < 0) return new HttpByteRange(400, 0, 0);
  const value: string = range.trim();
  if (value.length === 0 || !value.startsWith('bytes=') || value.includes(',')) {
    return new HttpByteRange(200, 0, size);
  }
  const match: RegExpMatchArray | null = value.match(/^bytes=(\d*)-(\d*)$/);
  if (match === null || (match[1].length === 0 && match[2].length === 0)) {
    return new HttpByteRange(400, 0, 0);
  }
  const first: number = match[1].length > 0 ? Number(match[1]) : -1;
  const last: number = match[2].length > 0 ? Number(match[2]) : -1;
  if (!Number.isSafeInteger(first) || !Number.isSafeInteger(last) ||
    (first >= 0 && last >= 0 && last < first)) return new HttpByteRange(400, 0, 0);
  if (size === 0 || first >= size || (first < 0 && last === 0)) {
    return new HttpByteRange(416, 0, 0, `bytes */${size}`);
  }
  const start: number = first < 0 ? Math.max(0, size - last) : first;
  const end: number = first < 0 || last < 0 ? size - 1 : Math.min(last, size - 1);
  return new HttpByteRange(206, start, end - start + 1, `bytes ${start}-${end}/${size}`);
}
