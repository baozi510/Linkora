export class DirectoryHistory {
  private paths: string[] = [];

  enter(currentPath: string): void {
    this.paths.push(currentPath);
  }

  back(): string | null {
    return this.paths.pop() ?? null;
  }

  reset(): string {
    this.paths = [];
    return '';
  }
}
