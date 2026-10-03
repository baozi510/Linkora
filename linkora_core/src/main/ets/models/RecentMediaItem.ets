import { MediaSource } from './MediaSource';

export class RecentMediaItem {
  readonly source: MediaSource;
  readonly openedAt: number;

  constructor(source: MediaSource, openedAt: number) {
    this.source = source;
    this.openedAt = openedAt;
  }
}
