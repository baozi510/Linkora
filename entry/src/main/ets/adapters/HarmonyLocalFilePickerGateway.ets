import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LocalFileCategory, LocalFileFilter, LocalFilePickerGateway,
  LocalMediaPickResult, MediaSource } from 'linkora_core';
import { LocalMediaPicker } from '../services/LocalMediaPicker';

export class HarmonyLocalFilePickerGateway implements LocalFilePickerGateway {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async pick(fileFilter: LocalFileFilter = new LocalFileFilter(),
    categories: LocalFileCategory[] = [LocalFileCategory.VIDEO],
    maxSelectNumber: number = 500): Promise<LocalMediaPickResult> {
    try {
      const sources: MediaSource[] = await LocalMediaPicker.select(this.context, fileFilter, categories,
        maxSelectNumber);
      return new LocalMediaPickResult(sources);
    } catch (error) {
      return new LocalMediaPickResult([], (error as BusinessError).code);
    }
  }
}
