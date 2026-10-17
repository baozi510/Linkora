import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AudioTrackChoice, AudioTrackPreferences, AudioTrackRepository, MediaSource } from 'linkora_core';
import { SourceIdentity } from './SourceIdentity';

export class AudioTrackPreferencesStore implements AudioTrackRepository {
  private static writes: Promise<void> = Promise.resolve();
  private readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) { this.context = context; }

  async loadPreferences(): Promise<AudioTrackPreferences> {
    await AudioTrackPreferencesStore.writes;
    const store: preferences.Preferences = await this.store();
    const languages: preferences.ValueType = await store.get('languages', '');
    const remember: preferences.ValueType = await store.get('remember', true);
    return new AudioTrackPreferences(typeof languages === 'string' && languages.length > 0 ? languages.split(',') : [],
      typeof remember === 'boolean' ? remember : true);
  }

  savePreferences(value: AudioTrackPreferences): Promise<void> {
    return this.enqueue(async () => {
      const store: preferences.Preferences = await this.store();
      await store.put('languages', value.languages.join(','));
      await store.put('remember', value.remember);
      await store.flush();
    });
  }

  async loadChoice(source: MediaSource): Promise<AudioTrackChoice | null> {
    await AudioTrackPreferencesStore.writes;
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
    const result: Promise<void> = AudioTrackPreferencesStore.writes.then(operation);
    AudioTrackPreferencesStore.writes = result.catch(() => {});
    return result;
  }
}
