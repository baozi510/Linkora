import { common } from '@kit.AbilityKit';
import { fileShare, picker } from '@kit.CoreFileKit';
import { LocalFileCategory, LocalFileFilter, MediaSource } from 'linkora_core';

export class LocalMediaPicker {
  static async select(context: common.UIAbilityContext,
    fileFilter: LocalFileFilter = new LocalFileFilter(),
    categories: LocalFileCategory[] = [LocalFileCategory.VIDEO],
    maxSelectNumber: number = 500): Promise<MediaSource[]> {
    const extensions: string[] = fileFilter.extensionsFor(categories);
    if (extensions.length === 0) {
      return [];
    }
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    options.maxSelectNumber = Math.min(500, Math.max(1, Math.floor(maxSelectNumber)));
    options.fileSuffixFilters = [`${LocalMediaPicker.categoryLabel(categories)}|${extensions.join(',')}`];
    const selectedUris: string[] = await documentPicker.select(options);
    const sources: MediaSource[] = [];
    const acceptedUris: string[] = [];
    for (const uri of selectedUris) {
      if (acceptedUris.includes(uri)) {
        continue;
      }
      const draft: MediaSource = MediaSource.fromLocalDocument(uri);
      const category: LocalFileCategory = fileFilter.categoryOf(draft.displayName);
      if (categories.includes(category)) {
        acceptedUris.push(uri);
        sources.push(MediaSource.fromLocalDocument(uri, draft.displayName, category));
      }
    }
    // Persist only post-validated files. A failed batch falls back to individual
    // grants so one invalid URI cannot discard every selected file's permission.
    await LocalMediaPicker.persistReadAccess(acceptedUris);
    return sources;
  }

  private static categoryLabel(categories: LocalFileCategory[]): string {
    if (categories.length === 1) {
      if (categories[0] === LocalFileCategory.VIDEO) {
        return '视频文件';
      }
      if (categories[0] === LocalFileCategory.AUDIO) {
        return '音频文件';
      }
      if (categories[0] === LocalFileCategory.SUBTITLE) {
        return '字幕文件';
      }
    }
    return '媒体文件';
  }

  private static async persistReadAccess(uris: string[]): Promise<void> {
    if (uris.length === 0) {
      return;
    }
    const batchSize: number = 50;
    for (let offset: number = 0; offset < uris.length; offset += batchSize) {
      const batch: string[] = uris.slice(offset, offset + batchSize);
      const policies: fileShare.PolicyInfo[] = batch.map((uri: string): fileShare.PolicyInfo => ({
        uri: uri,
        operationMode: fileShare.OperationMode.READ_MODE
      }));
      try {
        await fileShare.persistPermission(policies);
      } catch (_batchError) {
        for (let index: number = 0; index < policies.length; index++) {
          const policy: fileShare.PolicyInfo = policies[index];
          try {
            await fileShare.persistPermission([policy]);
          } catch (_itemError) {
            // The picker grant remains usable for this session. Verification will
            // mark only this entry unavailable if the persistent grant was lost.
            console.warn(`Document picker permission persistence failed. batchOffset=${offset}, ` +
              `item=${index}`);
          }
        }
      }
    }
  }
}
