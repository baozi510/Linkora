import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AudioTrackChoice, AudioTrackRepository, MediaSource } from 'linkora_core';
import { SourceIdentity } from './SourceIdentity';

export class AudioTrackMemoryStore implements AudioTrackRepository {
  private static writes: Promise<void> = Promise.resolve();
  private readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) { this.context = context; }

  async loadChoice(source: MediaSource): Promise<AudioTrackChoice | null> {
    await AudioTrackMemoryStore.writes;
    const store: preferences.Preferences = await this.store();
    const value: preferences.ValueType = await store.get(await this.sourceKey(source), '');
    return typeof value === 'string' ? AudioTrackChoice.decode(value) : null;
  }

  saveChoice(source: MediaSource, value: AudioTrackChoice | null): Promise<void> {
    return this.enqueue(async () => {
      const store: preferences.Preferences = await this.store();
      const key: string = await this.sourceKey(source);
      if (value === null) await store.delete(key);
      else await store.put(key, value.encode());
      await store.flush();
    });
  }

  private async sourceKey(source: MediaSource): Promise<string> {
    const identity: string = await SourceIdentity.key(source);
    return 'track_' + (source.fingerprint.length === 0 ? identity :
      await SourceIdentity.value(identity + ':' + source.fingerprint));
  }

  private store(): Promise<preferences.Preferences> {
    return preferences.getPreferences(this.context, 'player_audio_tracks');
  }

  private enqueue(operation: () => Promise<void>): Promise<void> {
    const result: Promise<void> = AudioTrackMemoryStore.writes.then(operation);
    AudioTrackMemoryStore.writes = result.catch(() => {});
    return result;
  }
}
