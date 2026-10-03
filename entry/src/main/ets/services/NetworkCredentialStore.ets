import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { SourceIdentity } from './SourceIdentity';

const ALIAS_PREFIX: string = 'linkora.network.credential.';
const MAX_CREDENTIAL_BYTES: number = 4096;

/** Stores network credentials outside the relational database. */
export class NetworkCredentialStore {
  private static sequence: number = 0;

  async save(secretValue: string): Promise<string | null> {
    if (secretValue.length === 0) {
      return '';
    }
    const encoder: util.TextEncoder = new util.TextEncoder();
    const secret: Uint8Array = encoder.encodeInto(secretValue);
    if (secret.length > MAX_CREDENTIAL_BYTES) {
      return null;
    }
    const nonce: string = `${Date.now()}:${++NetworkCredentialStore.sequence}`;
    const alias: string = `${ALIAS_PREFIX}${await SourceIdentity.value(nonce)}`;
    const attributes: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    attributes.set(asset.Tag.ALIAS, encoder.encodeInto(alias));
    attributes.set(asset.Tag.SECRET, secret);
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    attributes.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
    attributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
    try {
      await asset.add(attributes);
      return alias;
    } catch (_error) {
      return null;
    }
  }

  async load(alias: string): Promise<string | null> {
    if (!alias.startsWith(ALIAS_PREFIX)) {
      return null;
    }
    try {
      const encoder: util.TextEncoder = new util.TextEncoder();
      const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
      query.set(asset.Tag.ALIAS, encoder.encodeInto(alias));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
      const results: Array<asset.AssetMap> = await asset.query(query);
      if (results.length !== 1) {
        return null;
      }
      const value: asset.Value | undefined = results[0].get(asset.Tag.SECRET);
      if (!(value instanceof Uint8Array)) {
        return null;
      }
      return new util.TextDecoder('utf-8').decodeToString(value);
    } catch (_error) {
      return null;
    }
  }

  async remove(alias: string): Promise<void> {
    if (!alias.startsWith(ALIAS_PREFIX)) {
      return;
    }
    try {
      const encoder: util.TextEncoder = new util.TextEncoder();
      const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
      query.set(asset.Tag.ALIAS, encoder.encodeInto(alias));
      await asset.remove(query);
    } catch (_error) {
    }
  }
}
