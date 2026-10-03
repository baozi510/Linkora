import { SettingsRepository } from '../contracts/FeaturePorts';
import { AppAccentColor, AppSettings, AppThemeMode } from '../models/AppSettings';
import { LocalMediaFolderFilter } from '../models/LocalMediaFolder';

export class SettingsFeatureState {
  readonly settings: AppSettings;
  readonly loading: boolean;
  readonly saving: boolean;

  constructor(settings: AppSettings = new AppSettings(), loading: boolean = false,
    saving: boolean = false) {
    this.settings = settings;
    this.loading = loading;
    this.saving = saving;
  }
}

export type SettingsFeatureObserver = (state: SettingsFeatureState) => void;

export class SettingsFeatureController {
  private repository: SettingsRepository;
  private observer: SettingsFeatureObserver;
  private state: SettingsFeatureState = new SettingsFeatureState();
  private active: boolean = true;
  private revision: number = 0;
  private saveQueue: Promise<void> = Promise.resolve();

  constructor(repository: SettingsRepository, observer: SettingsFeatureObserver) {
    this.repository = repository;
    this.observer = observer;
  }

  async initialize(): Promise<void> {
    const revision: number = this.revision;
    this.state = new SettingsFeatureState(this.state.settings, true, false);
    this.notify();
    const settings: AppSettings = await this.repository.load();
    if (!this.active || revision !== this.revision) {
      return;
    }
    this.state = new SettingsFeatureState(settings, false, false);
    this.notify();
  }

  setRememberPlaybackPosition(enabled: boolean): void {
    this.update(this.state.settings.withRememberPlaybackPosition(enabled));
  }

  setKeepScreenOnDuringPlayback(enabled: boolean): void {
    this.update(this.state.settings.withKeepScreenOnDuringPlayback(enabled));
  }

  setAllowCellularPlayback(enabled: boolean): void {
    this.update(this.state.settings.withAllowCellularPlayback(enabled));
  }

  setExperimentalNetworkStorage(enabled: boolean): void {
    this.update(this.state.settings.withExperimentalNetworkStorage(enabled));
  }

  setLocalMediaFolderFilter(filter: LocalMediaFolderFilter): void {
    this.update(this.state.settings.withLocalMediaFolderFilter(filter));
  }

  setThemeMode(mode: AppThemeMode): void {
    this.update(this.state.settings.withThemeMode(mode));
  }

  setAccentColor(accentColor: AppAccentColor): void {
    this.update(this.state.settings.withAccentColor(accentColor));
  }

  setLocalVideoExtensions(extensions: string[]): void {
    this.update(this.state.settings.withLocalVideoExtensions(extensions));
  }

  setLocalSubtitleExtensions(extensions: string[]): void {
    this.update(this.state.settings.withLocalSubtitleExtensions(extensions));
  }

  setLocalFileExtensions(videoExtensions: string[], subtitleExtensions: string[]): void {
    this.update(this.state.settings.withLocalFileExtensions(videoExtensions, subtitleExtensions));
  }

  currentState(): SettingsFeatureState {
    return this.state;
  }

  dispose(): void {
    this.active = false;
    ++this.revision;
  }

  private update(settings: AppSettings): void {
    if (!this.active) {
      return;
    }
    const revision: number = ++this.revision;
    this.state = new SettingsFeatureState(settings, false, true);
    this.notify();
    this.saveQueue = this.saveQueue.then(async () => {
      await this.repository.save(settings);
      if (this.active && revision === this.revision) {
        this.state = new SettingsFeatureState(settings, false, false);
        this.notify();
      }
    }).catch(() => {
      if (this.active && revision === this.revision) {
        this.state = new SettingsFeatureState(settings, false, false);
        this.notify();
      }
    });
  }

  private notify(): void {
    if (this.active) {
      this.observer(this.state);
    }
  }
}
