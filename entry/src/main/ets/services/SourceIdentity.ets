import { util } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { MediaSource } from 'linkora_core';

export class SourceIdentity {
  static async key(source: MediaSource): Promise<string> {
    return SourceIdentity.value(`${source.kind}:${source.locator}`);
  }

  static async value(inputValue: string): Promise<string> {
    try {
      const digest: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
      const input: Uint8Array = new util.TextEncoder().encodeInto(inputValue);
      await digest.update({ data: input });
      const bytes: Uint8Array = (await digest.digest()).data;
      let value: string = '';
      for (let index: number = 0; index < bytes.length; index++) {
        value += bytes[index].toString(16).padStart(2, '0');
      }
      return value;
    } catch (_error) {
      throw new Error('Unable to create source identity');
    }
  }
}
