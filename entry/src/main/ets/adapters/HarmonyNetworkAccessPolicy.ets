import { connection } from '@kit.NetworkKit';
import { AppFailure, AppSettings, FailureCatalog, NetworkAccessPolicyPort } from 'linkora_core';
import { BusinessError } from '@kit.BasicServicesKit';

export class HarmonyNetworkAccessPolicy implements NetworkAccessPolicyPort {
  private settings: AppSettings;

  constructor(settings: AppSettings) {
    this.settings = settings;
  }

  async check(): Promise<AppFailure | null> {
    if (this.settings.allowCellularPlayback) {
      return null;
    }
    try {
      const netHandle: connection.NetHandle = await connection.getDefaultNet();
      const capabilities: connection.NetCapabilities = await connection.getNetCapabilities(netHandle);
      return capabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR) ?
        FailureCatalog.cellularPlaybackDisabled() : null;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      return FailureCatalog.fromNetworkError(businessError.code ?? 0);
    }
  }
}
