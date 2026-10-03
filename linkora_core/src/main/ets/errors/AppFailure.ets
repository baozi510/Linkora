export enum FailureDomain {
  INPUT = 'input',
  NETWORK = 'network',
  PLAYBACK = 'playback',
  FILE = 'file',
  STORAGE = 'storage',
  SYSTEM = 'system'
}

export enum FailureCode {
  LINK_EMPTY = 'LNK-INPUT-001',
  LINK_TOO_LONG = 'LNK-INPUT-002',
  LINK_INVALID = 'LNK-INPUT-003',
  LINK_UNSUPPORTED_PROTOCOL = 'LNK-INPUT-004',
  LINK_MISSING_HOST = 'LNK-INPUT-005',
  LINK_EMBEDDED_CREDENTIALS = 'LNK-INPUT-006',
  NETWORK_UNAUTHORIZED = 'LNK-NET-001',
  NETWORK_FORBIDDEN = 'LNK-NET-002',
  NETWORK_NOT_FOUND = 'LNK-NET-003',
  NETWORK_TIMEOUT = 'LNK-NET-004',
  NETWORK_HOST_NOT_FOUND = 'LNK-NET-005',
  NETWORK_CONNECTION_FAILED = 'LNK-NET-006',
  NETWORK_TLS_FAILED = 'LNK-NET-007',
  NETWORK_SERVER_FAILED = 'LNK-NET-008',
  NETWORK_PERMISSION_DENIED = 'LNK-NET-009',
  NETWORK_CLEARTEXT_BLOCKED = 'LNK-NET-010',
  NETWORK_REQUEST_FAILED = 'LNK-NET-011',
  NETWORK_CELLULAR_DISABLED = 'LNK-NET-012',
  NETWORK_REDIRECT_FAILED = 'LNK-NET-013',
  MEDIA_UNSUPPORTED = 'LNK-PLAY-001',
  MEDIA_READ_FAILED = 'LNK-PLAY-002',
  MEDIA_TIMEOUT = 'LNK-PLAY-003',
  MEDIA_SERVICE_UNAVAILABLE = 'LNK-PLAY-004',
  MEDIA_INVALID_SOURCE = 'LNK-PLAY-005',
  MEDIA_STATE_INVALID = 'LNK-PLAY-006',
  PLAYBACK_FAILED = 'LNK-PLAY-007',
  LOCAL_FILE_UNAVAILABLE = 'LNK-FILE-001',
  LOCAL_FILE_PERMISSION_DENIED = 'LNK-FILE-002',
  LOCAL_SCAN_PERMISSION_DENIED = 'LNK-FILE-003',
  LOCAL_SCAN_FAILED = 'LNK-FILE-004',
  STORAGE_READ_FAILED = 'LNK-DATA-001',
  STORAGE_WRITE_FAILED = 'LNK-DATA-002',
  UNKNOWN = 'LNK-SYS-001'
}

export enum RecoveryAction {
  NONE = 'none',
  RETRY = 'retry',
  EDIT_SOURCE = 'edit_source',
  CHOOSE_FILE = 'choose_file',
  OPEN_SETTINGS = 'open_settings'
}

export class AppFailure {
  readonly domain: FailureDomain;
  readonly code: FailureCode;
  readonly title: string;
  readonly message: string;
  readonly action: RecoveryAction;
  readonly actionLabel: string;
  readonly retryable: boolean;
  readonly diagnosticCode: string;

  constructor(domain: FailureDomain, code: FailureCode, title: string, message: string,
    action: RecoveryAction, actionLabel: string, retryable: boolean, diagnosticCode: string) {
    this.domain = domain;
    this.code = code;
    this.title = title;
    this.message = message;
    this.action = action;
    this.actionLabel = actionLabel;
    this.retryable = retryable;
    this.diagnosticCode = diagnosticCode;
  }

  hasAction(): boolean {
    return this.action !== RecoveryAction.NONE && this.actionLabel.length > 0;
  }
}
