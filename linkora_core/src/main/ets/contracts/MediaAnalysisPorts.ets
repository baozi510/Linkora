import { MediaInfo } from '../models/MediaInfo';
import { MediaSource } from '../models/MediaSource';

export enum ProbeRequirement {
  LIST = 'list',
  DETAIL = 'detail',
  ADVANCED = 'advanced'
}

export enum ProbeCompleteness {
  COMPLETE = 'complete',
  PARTIAL = 'partial',
  UNAVAILABLE = 'unavailable'
}

export class ProbeFieldOrigin {
  readonly field: string;
  readonly engine: string;

  constructor(field: string, engine: string) {
    this.field = field;
    this.engine = engine;
  }
}

export class MediaProbeDiagnostics {
  readonly engine: string;
  readonly prepareMs: number;
  readonly probeMs: number;
  readonly totalMs: number;
  readonly bytesRead: number;
  readonly rangeRequests: number;
  readonly notes: string[];

  constructor(engine: string = '', prepareMs: number = 0, probeMs: number = 0,
    totalMs: number = 0, bytesRead: number = 0, rangeRequests: number = 0,
    notes: string[] = []) {
    this.engine = engine;
    this.prepareMs = Math.max(0, prepareMs);
    this.probeMs = Math.max(0, probeMs);
    this.totalMs = Math.max(0, totalMs);
    this.bytesRead = Math.max(0, bytesRead);
    this.rangeRequests = Math.max(0, rangeRequests);
    this.notes = notes;
  }
}

export class ProbeResult {
  readonly info: MediaInfo | null;
  readonly completeness: ProbeCompleteness;
  readonly fieldOrigins: ProbeFieldOrigin[];
  readonly diagnostics: MediaProbeDiagnostics;
  readonly errorCode: number;

  constructor(info: MediaInfo | null, completeness: ProbeCompleteness,
    fieldOrigins: ProbeFieldOrigin[] = [], diagnostics: MediaProbeDiagnostics = new MediaProbeDiagnostics(),
    errorCode: number = 0) {
    this.info = info;
    this.completeness = completeness;
    this.fieldOrigins = fieldOrigins;
    this.diagnostics = diagnostics;
    this.errorCode = Math.max(0, errorCode);
  }

  isUsable(): boolean {
    return this.info !== null && this.completeness !== ProbeCompleteness.UNAVAILABLE;
  }
}

export interface IMediaProbe {
  name(): string;
  canProbe(source: MediaSource): Promise<boolean>;
  probe(source: MediaSource, requirement: ProbeRequirement): Promise<ProbeResult>;
  cancel(): void;
  close(): Promise<void>;
}
