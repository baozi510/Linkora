export class FileSizeFormatter {
  private static readonly UNIT_STEP: number = 1024;

  static format(bytes: number): string {
    const safeBytes: number = Math.max(0, bytes);
    if (safeBytes < FileSizeFormatter.UNIT_STEP) {
      return `${Math.round(safeBytes)} B`;
    }

    const kilobytes: number = safeBytes / FileSizeFormatter.UNIT_STEP;
    if (kilobytes < FileSizeFormatter.UNIT_STEP) {
      return `${FileSizeFormatter.numberLabel(kilobytes)} KB`;
    }

    const megabytes: number = kilobytes / FileSizeFormatter.UNIT_STEP;
    if (megabytes < FileSizeFormatter.UNIT_STEP) {
      return `${FileSizeFormatter.numberLabel(megabytes)} MB`;
    }

    const gigabytes: number = megabytes / FileSizeFormatter.UNIT_STEP;
    return `${FileSizeFormatter.numberLabel(gigabytes)} GB`;
  }

  private static numberLabel(value: number): string {
    return value < 10 ? value.toFixed(1) : value.toFixed(0);
  }
}
