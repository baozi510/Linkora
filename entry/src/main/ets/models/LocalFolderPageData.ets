import { AppFailure, LocalMediaAsset, LocalMediaScanState } from 'linkora_core';

export class LocalFolderPageData {
  readonly folderUri: string;
  readonly items: LocalMediaAsset[];
  readonly scanState: LocalMediaScanState;
  readonly scanFailure: AppFailure | null;
  readonly refreshing: boolean;

  constructor(folderUri: string = '', items: LocalMediaAsset[] = [],
    scanState: LocalMediaScanState = LocalMediaScanState.IDLE,
    scanFailure: AppFailure | null = null, refreshing: boolean = false) {
    this.folderUri = folderUri;
    this.items = items;
    this.scanState = scanState;
    this.scanFailure = scanFailure;
    this.refreshing = refreshing;
  }

  static forRoute(routeFolderUri: string, current: LocalFolderPageData,
    incoming: LocalFolderPageData): LocalFolderPageData {
    return incoming.folderUri === routeFolderUri ? incoming : current;
  }
}
