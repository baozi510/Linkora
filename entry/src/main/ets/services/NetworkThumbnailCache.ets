import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { ThumbnailPlan } from 'linkora_core';
import { NetworkDirectoryEntry } from '../models/NetworkDirectoryState';
import { NetworkServerEntry } from './NetworkServerStore';
import { SourceIdentity } from './SourceIdentity';

const MAX_THUMBNAIL_BYTES: number = 512 * 1024;

export class NetworkThumbnailCache {
  private readonly directory: string;

  constructor(context: common.UIAbilityContext, serverId: number) {
    this.directory = `${context.cacheDir}/network-thumbnails/${serverId}`;
  }

  key(server: NetworkServerEntry, entry: NetworkDirectoryEntry, plan: ThumbnailPlan): Promise<string> {
    return SourceIdentity.value(JSON.stringify([
      server.id,
      server.updatedAt,
      server.protocol,
      entry.path,
      entry.size,
      entry.modifiedAt,
      plan.timeMs,
      plan.width,
      plan.height,
      plan.quality,
      plan.algorithmVersion
    ]));
  }

  get(key: string): ArrayBuffer | null {
    if (!this.safeKey(key)) {
      return null;
    }
    try {
      const path: string = `${this.directory}/${key}.webp`;
      const size: number = fileIo.statSync(path).size;
      if (size <= 0 || size > MAX_THUMBNAIL_BYTES) {
        return null;
      }
      const data: ArrayBuffer = new ArrayBuffer(size);
      const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      try {
        return fileIo.readSync(file.fd, data) === size ? data : null;
      } finally {
        fileIo.closeSync(file.fd);
      }
    } catch (_error) {
      return null;
    }
  }

  put(key: string, data: ArrayBuffer): boolean {
    if (!this.safeKey(key) || data.byteLength <= 0 || data.byteLength > MAX_THUMBNAIL_BYTES) {
      return false;
    }
    try {
      if (!fileIo.accessSync(this.directory)) {
        fileIo.mkdirSync(this.directory, true);
      }
      const path: string = `${this.directory}/${key}.webp`;
      const temporary: string = `${path}.tmp`;
      const file = fileIo.openSync(temporary,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try {
        if (fileIo.writeSync(file.fd, data) !== data.byteLength) {
          throw new Error('Incomplete thumbnail write');
        }
      } finally {
        fileIo.closeSync(file.fd);
      }
      fileIo.renameSync(temporary, path);
      return true;
    } catch (_error) {
      return false;
    }
  }

  private safeKey(key: string): boolean {
    return /^[a-f0-9]{64}$/.test(key);
  }
}
