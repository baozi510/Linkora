import { NetworkAccessPolicyPort, NetworkProbePort, NetworkProbeResult } from '../contracts/NetworkPorts';
import { AppFailure, RecoveryAction } from '../errors/AppFailure';
import { FailureCatalog } from '../errors/FailureCatalog';
import { LinkParseResult, MediaLink } from '../models/MediaLink';
import { MediaSource } from '../models/MediaSource';
import { NetworkLinkParser } from '../services/NetworkLinkParser';

export class NetworkLinkState {
  readonly input: string;
  readonly link: MediaLink | null;
  readonly probe: NetworkProbeResult | null;
  readonly failure: AppFailure | null;
  readonly checking: boolean;

  constructor(input: string = '', link: MediaLink | null = null,
    probe: NetworkProbeResult | null = null, failure: AppFailure | null = null,
    checking: boolean = false) {
    this.input = input;
    this.link = link;
    this.probe = probe;
    this.failure = failure;
    this.checking = checking;
  }

  playableSource(): MediaSource | null {
    return this.link === null || this.probe === null || this.failure !== null ? null :
      MediaSource.fromNetworkLink(this.link);
  }
}

export type NetworkLinkObserver = (state: NetworkLinkState) => void;

export class NetworkLinkController {
  private probePort: NetworkProbePort;
  private observer: NetworkLinkObserver;
  private accessPolicy: NetworkAccessPolicyPort | null;
  private state: NetworkLinkState = new NetworkLinkState();
  private requestId: number = 0;
  private active: boolean = true;

  constructor(probePort: NetworkProbePort, observer: NetworkLinkObserver,
    accessPolicy: NetworkAccessPolicyPort | null = null) {
    this.probePort = probePort;
    this.observer = observer;
    this.accessPolicy = accessPolicy;
  }

  setInput(value: string): void {
    ++this.requestId;
    this.probePort.cancel();
    this.state = new NetworkLinkState(value);
    this.notify();
  }

  async check(): Promise<void> {
    if (this.state.checking) {
      return;
    }
    const requestId: number = ++this.requestId;
    const parsed: LinkParseResult = NetworkLinkParser.parse(this.state.input);
    if (!parsed.isValid() || parsed.value === null) {
      this.state = new NetworkLinkState(this.state.input, null, null,
        FailureCatalog.fromLinkIssue(parsed.issue), false);
      this.notify();
      return;
    }
    this.state = new NetworkLinkState(this.state.input, parsed.value, null, null, true);
    this.notify();
    if (this.accessPolicy !== null) {
      const accessFailure: AppFailure | null = await this.accessPolicy.check();
      if (!this.active || requestId !== this.requestId) {
        return;
      }
      if (accessFailure !== null) {
        this.state = new NetworkLinkState(this.state.input, parsed.value, null, accessFailure, false);
        this.notify();
        return;
      }
    }
    let probe: NetworkProbeResult;
    try {
      probe = await this.probePort.inspect(parsed.value.url);
    } catch (_error) {
      if (this.active && requestId === this.requestId) {
        this.state = new NetworkLinkState(this.state.input, parsed.value, null,
          FailureCatalog.unknown(), false);
        this.notify();
      }
      return;
    }
    if (!this.active || requestId !== this.requestId) {
      return;
    }
    this.state = new NetworkLinkState(this.state.input, parsed.value, probe, probe.failure, false);
    this.notify();
  }

  recover(): void {
    const failure: AppFailure | null = this.state.failure;
    if (failure !== null && failure.action === RecoveryAction.RETRY) {
      this.check().catch(() => {});
      return;
    }
    this.state = new NetworkLinkState(this.state.input);
    this.notify();
  }

  currentSource(): MediaSource | null {
    return this.state.playableSource();
  }

  currentState(): NetworkLinkState {
    return this.state;
  }

  dispose(): void {
    this.active = false;
    ++this.requestId;
    this.probePort.cancel();
  }

  private notify(): void {
    if (this.active) {
      this.observer(this.state);
    }
  }
}
