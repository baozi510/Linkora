import { AppFailure, LocalMediaAsset, LocalMediaScanState } from 'linkora_core';

export class LocalFolderPageData {
  readonly folderUri: string;
  readonly items: LocalMediaAsset[];
  readonly scanState: LocalMediaScanState;
  readonly scanFailure: AppFailure | null;
  readonly refreshing: boolean;
  readonly snapshotComplete: boolean;

  constructor(folderUri: string = '', items: LocalMediaAsset[] = [],
    scanState: LocalMediaScanState = LocalMediaScanState.IDLE,
    scanFailure: AppFailure | null = null, refreshing: boolean = false,
    snapshotComplete: boolean = false) {
    this.folderUri = folderUri;
    this.items = items;
    this.scanState = scanState;
    this.scanFailure = scanFailure;
    this.refreshing = refreshing;
    this.snapshotComplete = snapshotComplete;
  }

  static forRoute(routeFolderUri: string, current: LocalFolderPageData,
    incoming: LocalFolderPageData): LocalFolderPageData {
    return incoming.folderUri === routeFolderUri ? incoming : current;
  }

  isComplete(): boolean {
    return (this.scanState === LocalMediaScanState.READY || this.scanState === LocalMediaScanState.EMPTY) &&
      this.scanFailure === null && !this.refreshing && this.snapshotComplete;
  }
}
