import { common, Want } from '@kit.AbilityKit';

/** Target boundary: production has no runtime diagnostic work. */
export class RuntimeDiagnostics {
  static configure(_want: Want): void {}
  static async run(_context: common.UIAbilityContext): Promise<void> {}
}
