import { LocalFileCategory, LocalMediaAsset, LocalMediaAvailability, LocalMediaFolder,
  LocalMediaOrigin, LocalMediaPlaybackProgress } from 'linkora_core';
import { LocalMediaAvailabilityFilter, LocalMediaSortField, LocalMediaSourceFilter,
  LocalMediaTypeFilter } from './LocalMediaViewOptions';

/** Pure filtering and ordering for the local media browser. */
export class LocalMediaOrdering {
  static folders(folders: LocalMediaFolder[], showFolders: boolean, currentDirectoryUri: string,
    searchText: string, sortField: LocalMediaSortField, sortAscending: boolean): LocalMediaFolder[] {
    const result: LocalMediaFolder[] = [];
    if (!showFolders) {
      return result;
    }
    for (const folder of folders) {
      if (folder.parentUri === currentDirectoryUri && LocalMediaOrdering.matches(folder.displayName, searchText)) {
        result.push(folder);
      }
    }
    return result.sort((left: LocalMediaFolder, right: LocalMediaFolder) => {
      let comparison: number = 0;
      if (sortField === LocalMediaSortField.ITEM_COUNT) {
        comparison = left.totalCount - right.totalCount;
      } else if (sortField === LocalMediaSortField.SIZE) {
        comparison = left.totalSizeBytes - right.totalSizeBytes;
      } else {
        comparison = LocalMediaOrdering.text(left.displayName, right.displayName);
      }
      if (comparison === 0) {
        comparison = LocalMediaOrdering.text(left.displayName, right.displayName);
        if (comparison === 0) {
          comparison = left.uri < right.uri ? -1 : 1;
        }
      }
      return sortAscending ? comparison : -comparison;
    });
  }

  static items(items: LocalMediaAsset[], playbackProgress: LocalMediaPlaybackProgress[],
    searchText: string, sortField: LocalMediaSortField, sortAscending: boolean,
    typeFilter: LocalMediaTypeFilter, sourceFilter: LocalMediaSourceFilter,
    availabilityFilter: LocalMediaAvailabilityFilter): LocalMediaAsset[] {
    const result: LocalMediaAsset[] = [];
    for (const item of items) {
      if (LocalMediaOrdering.matches(item.displayName, searchText) &&
        LocalMediaOrdering.accepts(item, typeFilter, sourceFilter, availabilityFilter)) {
        result.push(item);
      }
    }
    return result.sort((left: LocalMediaAsset, right: LocalMediaAsset) => {
      let comparison: number = LocalMediaOrdering.compareItems(
        left, right, playbackProgress, sortField);
      if (comparison === 0) {
        comparison = left.uri === right.uri ? 0 : (left.uri < right.uri ? -1 : 1);
      }
      return sortAscending ? comparison : -comparison;
    });
  }

  static naturalText(leftValue: string, rightValue: string): number {
    const left: string = leftValue.toLowerCase();
    const right: string = rightValue.toLowerCase();
    let leftIndex: number = 0;
    let rightIndex: number = 0;
    while (leftIndex < left.length && rightIndex < right.length) {
      const leftCode: number = left.charCodeAt(leftIndex);
      const rightCode: number = right.charCodeAt(rightIndex);
      if (LocalMediaOrdering.digitCode(leftCode) && LocalMediaOrdering.digitCode(rightCode)) {
        let leftEnd: number = leftIndex;
        let rightEnd: number = rightIndex;
        while (leftEnd < left.length && LocalMediaOrdering.digitCode(left.charCodeAt(leftEnd))) ++leftEnd;
        while (rightEnd < right.length && LocalMediaOrdering.digitCode(right.charCodeAt(rightEnd))) ++rightEnd;
        let leftSignificant: number = leftIndex;
        let rightSignificant: number = rightIndex;
        while (leftSignificant < leftEnd - 1 && left.charCodeAt(leftSignificant) === 48) ++leftSignificant;
        while (rightSignificant < rightEnd - 1 && right.charCodeAt(rightSignificant) === 48) ++rightSignificant;
        const leftDigits: string = left.substring(leftSignificant, leftEnd);
        const rightDigits: string = right.substring(rightSignificant, rightEnd);
        if (leftDigits.length !== rightDigits.length) return leftDigits.length - rightDigits.length;
        if (leftDigits !== rightDigits) return leftDigits < rightDigits ? -1 : 1;
        const leftRunLength: number = leftEnd - leftIndex;
        const rightRunLength: number = rightEnd - rightIndex;
        if (leftRunLength !== rightRunLength) return leftRunLength - rightRunLength;
        leftIndex = leftEnd;
        rightIndex = rightEnd;
        continue;
      }
      if (leftCode !== rightCode) return leftCode - rightCode;
      ++leftIndex;
      ++rightIndex;
    }
    return left.length - right.length;
  }

  private static matches(value: string, searchText: string): boolean {
    const query: string = searchText.trim().toLowerCase();
    return query.length === 0 || value.toLowerCase().includes(query);
  }

  private static accepts(item: LocalMediaAsset, typeFilter: LocalMediaTypeFilter,
    sourceFilter: LocalMediaSourceFilter, availabilityFilter: LocalMediaAvailabilityFilter): boolean {
    if (typeFilter === LocalMediaTypeFilter.VIDEO && item.category !== LocalFileCategory.VIDEO) return false;
    if (typeFilter === LocalMediaTypeFilter.IMAGE && item.category !== LocalFileCategory.IMAGE) return false;
    if (typeFilter === LocalMediaTypeFilter.AUDIO && item.category !== LocalFileCategory.AUDIO) return false;
    if (typeFilter === LocalMediaTypeFilter.SUBTITLE && item.category !== LocalFileCategory.SUBTITLE) return false;
    if (sourceFilter === LocalMediaSourceFilter.MEDIA_LIBRARY &&
      item.origin !== LocalMediaOrigin.MEDIA_LIBRARY) return false;
    if (sourceFilter === LocalMediaSourceFilter.MANUAL &&
      item.origin !== LocalMediaOrigin.DOCUMENT_PICKER) return false;
    if (availabilityFilter === LocalMediaAvailabilityFilter.AVAILABLE &&
      item.availability !== LocalMediaAvailability.AVAILABLE) return false;
    if (availabilityFilter === LocalMediaAvailabilityFilter.UNAVAILABLE &&
      item.availability !== LocalMediaAvailability.UNAVAILABLE) return false;
    return true;
  }

  private static compareItems(left: LocalMediaAsset, right: LocalMediaAsset,
    playbackProgress: LocalMediaPlaybackProgress[], sortField: LocalMediaSortField): number {
    if (sortField === LocalMediaSortField.MODIFIED) return left.modifiedAt - right.modifiedAt;
    if (sortField === LocalMediaSortField.SIZE) return left.sizeBytes - right.sizeBytes;
    if (sortField === LocalMediaSortField.DURATION) return left.durationMs - right.durationMs;
    if (sortField === LocalMediaSortField.RESOLUTION) return left.width * left.height - right.width * right.height;
    if (sortField === LocalMediaSortField.PLAYBACK_TIME) {
      return LocalMediaOrdering.playbackUpdatedAt(left, playbackProgress) -
        LocalMediaOrdering.playbackUpdatedAt(right, playbackProgress);
    }
    if (sortField === LocalMediaSortField.STATUS) {
      return Number(left.isAvailable()) - Number(right.isAvailable());
    }
    if (sortField === LocalMediaSortField.PATH) {
      return left.uri === right.uri ? 0 : (left.uri < right.uri ? -1 : 1);
    }
    if (sortField === LocalMediaSortField.TYPE) return LocalMediaOrdering.compareMediaTypes(left, right);
    return LocalMediaOrdering.text(left.displayName, right.displayName);
  }

  private static compareMediaTypes(left: LocalMediaAsset, right: LocalMediaAsset): number {
    const rankComparison: number = LocalMediaOrdering.mediaTypeRank(left.category) -
      LocalMediaOrdering.mediaTypeRank(right.category);
    if (rankComparison !== 0) return rankComparison;
    const leftExtension: string = LocalMediaOrdering.fileExtension(left);
    const rightExtension: string = LocalMediaOrdering.fileExtension(right);
    if (leftExtension !== rightExtension) {
      if (leftExtension.length === 0) return 1;
      if (rightExtension.length === 0) return -1;
      return leftExtension < rightExtension ? -1 : 1;
    }
    return LocalMediaOrdering.naturalText(left.displayName, right.displayName);
  }

  private static mediaTypeRank(category: LocalFileCategory): number {
    if (category === LocalFileCategory.VIDEO) return 0;
    if (category === LocalFileCategory.AUDIO) return 1;
    if (category === LocalFileCategory.IMAGE) return 2;
    if (category === LocalFileCategory.SUBTITLE) return 3;
    return 4;
  }

  private static fileExtension(item: LocalMediaAsset): string {
    const dot: number = item.displayName.lastIndexOf('.');
    return dot <= 0 || dot === item.displayName.length - 1 ? '' :
      item.displayName.substring(dot + 1).toLowerCase();
  }

  private static playbackUpdatedAt(item: LocalMediaAsset,
    playbackProgress: LocalMediaPlaybackProgress[]): number {
    for (const progress of playbackProgress) {
      if (progress.uri === item.uri) return progress.updatedAt;
    }
    return 0;
  }

  private static digitCode(code: number): boolean {
    return code >= 48 && code <= 57;
  }

  private static text(left: string, right: string): number {
    const leftName: string = left.toLowerCase();
    const rightName: string = right.toLowerCase();
    return leftName === rightName ? 0 : (leftName < rightName ? -1 : 1);
  }
}
