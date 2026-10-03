import { FileSizeFormatter } from 'linkora_core';
import { NetworkDirectorySummary } from '../services/NetworkDirectorySummaryCache';

export function networkDirectoryLabels(summary: NetworkDirectorySummary | null): string[] {
  if (summary === null) {
    return ['文件夹'];
  }
  if (summary.directoryCount === 0 && summary.fileCount === 0) {
    return ['空文件夹'];
  }
  const labels: string[] = [];
  if (summary.directoryCount > 0) {
    labels.push(`${summary.directoryCount} 个文件夹`);
  }
  if (summary.fileCount > 0) {
    labels.push(`${summary.fileCount} 个文件`);
  }
  return labels;
}

export function networkDirectoryDetail(summary: NetworkDirectorySummary | null): string {
  return networkDirectoryLabels(summary).join(' · ');
}

export function networkDirectoryPathDetail(summary: NetworkDirectorySummary): string {
  const labels: string[] = networkDirectoryLabels(summary);
  if (summary.fileCount > 0) {
    labels.push(FileSizeFormatter.format(summary.totalSize));
  }
  return labels.join(' · ');
}
