import { PlayerBackendPreference, RemoteProtocol } from 'linkora_core';

export class RuntimeProfile {
  static systemOnlyPlayback(): boolean {
    return false;
  }

  static supportsBackendPreference(_preference: PlayerBackendPreference): boolean {
    return true;
  }

  static supportsNetworkProtocol(_protocol: RemoteProtocol): boolean {
    return true;
  }

  static label(): string {
    return 'default';
  }
}
