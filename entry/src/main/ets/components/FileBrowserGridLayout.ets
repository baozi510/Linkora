import { AppLayout } from '../ui/AppTheme';

export function fileBrowserGridColumnsTemplate(contentWidth: number): string {
  const count: number = contentWidth >= AppLayout.EXPANDED_BREAKPOINT ? 4 :
    (contentWidth >= AppLayout.MEDIUM_BREAKPOINT ? 3 : 2);
  let template: string = '1fr';
  for (let index: number = 1; index < count; index++) {
    template += ' 1fr';
  }
  return template;
}
