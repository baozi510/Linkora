import { PlayerBackendPreference, RemoteProtocol } from 'linkora_core';

export class RuntimeProfile {
  static systemOnlyPlayback(): boolean {
    return true;
  }

  static supportsBackendPreference(preference: PlayerBackendPreference): boolean {
    return preference === PlayerBackendPreference.SYSTEM;
  }

  static supportsNetworkProtocol(protocol: RemoteProtocol): boolean {
    return protocol === RemoteProtocol.WEBDAV || protocol === RemoteProtocol.HTTP;
  }

  static label(): string {
    return 'simulator';
  }
}
