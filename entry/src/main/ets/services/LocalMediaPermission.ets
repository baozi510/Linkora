import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LocalMediaPermissionResult } from 'linkora_core';

const READ_IMAGE_VIDEO: Permissions = 'ohos.permission.READ_IMAGEVIDEO';

export class LocalMediaPermission {
  static async isGranted(): Promise<boolean> {
    try {
      const bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const status: abilityAccessCtrl.GrantStatus = await manager.checkAccessToken(
        bundleInfo.appInfo.accessTokenId,
        READ_IMAGE_VIDEO
      );
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (_error) {
      return false;
    }
  }

  static async request(context: common.UIAbilityContext): Promise<LocalMediaPermissionResult> {
    try {
      const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const result: PermissionRequestResult = await manager.requestPermissionsFromUser(context, [READ_IMAGE_VIDEO]);
      let granted: boolean = result.authResults.length > 0 &&
        result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      if (!granted && result.dialogShownResults?.[0] === false) {
        const statuses: abilityAccessCtrl.GrantStatus[] =
          await manager.requestPermissionOnSetting(context, [READ_IMAGE_VIDEO]);
        granted = statuses.length > 0 &&
          statuses[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      }
      return new LocalMediaPermissionResult(granted, granted ? 0 : 201);
    } catch (error) {
      return new LocalMediaPermissionResult(false, (error as BusinessError).code);
    }
  }
}
