export class AppColors {
  static readonly BACKGROUND: ResourceColor = $r('sys.color.background_secondary');
  static readonly PLAYER_BACKGROUND: ResourceColor = $r('app.color.player_background');
  static readonly NAVIGATION_BACKGROUND: ResourceColor = $r('sys.color.background_primary');
  static readonly SURFACE: ResourceColor = $r('sys.color.background_primary');
  static readonly SURFACE_RAISED: ResourceColor = $r('sys.color.comp_background_primary');
  static readonly SURFACE_INPUT: ResourceColor = $r('sys.color.comp_background_secondary');
  static readonly CONTROL_SURFACE: ResourceColor = $r('sys.color.comp_background_tertiary');
  static readonly TRACK: ResourceColor = $r('sys.color.background_fourth');
  static readonly DIVIDER: ResourceColor = $r('sys.color.comp_divider');
  static readonly OUTLINE: ResourceColor = $r('sys.color.comp_divider');
  static readonly PRESSED_BACKGROUND: ResourceColor = $r('sys.color.interactive_pressed');
  static readonly SELECTED_BACKGROUND: ResourceColor = $r('sys.color.interactive_select');
  static readonly PRIMARY: ResourceColor = $r('app.color.primary');
  static readonly PRIMARY_SOFT: ResourceColor = $r('app.color.primary_soft');
  static readonly TEXT_PRIMARY: ResourceColor = $r('sys.color.font_primary');
  static readonly TEXT_SECONDARY: ResourceColor = $r('sys.color.font_secondary');
  static readonly TEXT_MUTED: ResourceColor = $r('sys.color.font_tertiary');
  static readonly TEXT_DISABLED: ResourceColor = $r('sys.color.font_fourth');
  static readonly TEXT_CONTROL: ResourceColor = $r('sys.color.font_primary');
  static readonly TEXT_STATUS: ResourceColor = $r('sys.color.font_secondary');
  static readonly ICON_PRIMARY: ResourceColor = $r('sys.color.icon_primary');
  static readonly ICON_SECONDARY: ResourceColor = $r('sys.color.icon_secondary');
  static readonly ICON_TERTIARY: ResourceColor = $r('sys.color.icon_tertiary');
  static readonly ICON_DISABLED: ResourceColor = $r('sys.color.icon_fourth');
  static readonly CHIP_BACKGROUND: ResourceColor = $r('sys.color.comp_background_tertiary');
  static readonly SUCCESS: ResourceColor = $r('sys.color.confirm');
  static readonly WARNING_TEXT: ResourceColor = $r('sys.color.warning');
  static readonly ERROR_TEXT: ResourceColor = $r('app.color.error_text');
  static readonly DESTRUCTIVE_ACTION: ResourceColor = $r('app.color.destructive_action');
  static readonly ERROR_MUTED: ResourceColor = $r('app.color.error_muted');
  static readonly ERROR_SURFACE: ResourceColor = $r('app.color.error_surface');
  static readonly ERROR_BORDER: ResourceColor = $r('app.color.error_border');

  static accent(accentColor: string): ResourceColor {
    if (accentColor === 'system') {
      return $r('sys.color.brand');
    }
    if (accentColor === 'purple') {
      return $r('app.color.accent_purple');
    }
    if (accentColor === 'green') {
      return $r('app.color.accent_green');
    }
    if (accentColor === 'orange') {
      return $r('app.color.accent_orange');
    }
    if (accentColor === 'pink') {
      return $r('app.color.accent_pink');
    }
    return $r('app.color.accent_blue');
  }

  static accentForeground(accentColor: string): ResourceColor {
    if (accentColor === 'system') {
      return $r('app.color.accent_system_foreground');
    }
    if (accentColor === 'purple') {
      return $r('app.color.accent_purple_foreground');
    }
    if (accentColor === 'green') {
      return $r('app.color.accent_green_foreground');
    }
    if (accentColor === 'orange') {
      return $r('app.color.accent_orange_foreground');
    }
    if (accentColor === 'pink') {
      return $r('app.color.accent_pink_foreground');
    }
    return $r('app.color.accent_blue_foreground');
  }

}

// Playback chrome stays dark so controls remain legible over arbitrary video content.
export class PlayerColors {
  static readonly BACKGROUND: ResourceColor = '#0B0D12';
  static readonly SURFACE_RAISED: ResourceColor = '#151A22';
  static readonly CONTROL_SURFACE: ResourceColor = '#242A34';
  static readonly TRACK: ResourceColor = '#343A45';
  static readonly PRIMARY: ResourceColor = '#7957F6';
  static readonly PRIMARY_SOFT: ResourceColor = '#9A79FF';
  static readonly TEXT_PRIMARY: ResourceColor = '#F4F5F7';
  static readonly TEXT_SECONDARY: ResourceColor = '#858C99';
  static readonly TEXT_DISABLED: ResourceColor = '#67707E';
  static readonly TEXT_CONTROL: ResourceColor = '#D8DBE2';
  static readonly TEXT_STATUS: ResourceColor = '#C6CAD2';
}

export class AppSpacing {
  static readonly PAGE_HORIZONTAL: number = 16;
  static readonly PAGE_TOP: number = 0;
  static readonly PAGE_BOTTOM: number = 20;
  static readonly SECTION: number = 18;
  static readonly CARD: number = 14;
  static readonly ITEM: number = 10;
}

export class AppRadius {
  static readonly NONE: number = 0;
  static readonly SMALL: number = 4;
  static readonly CONTROL: number = 5;
  static readonly CARD: number = 6;
  static readonly SHEET: number = 16;
  static readonly FULL: number = 999;
}

// Keep the unconfirmed player design independent from the app shell theme.
export class PlayerRadius {
  static readonly CONTROL: number = 8;
  static readonly CARD: number = 10;
  static readonly ACTION: number = 12;
  static readonly PANEL: number = 18;
}

export class AppTypography {
  static readonly PAGE_TITLE: number = 18;
  static readonly SHEET_TITLE: number = 20;
  static readonly SECTION_TITLE: number = 17;
  static readonly BODY: number = 13;
  static readonly INPUT: number = 12;
  static readonly CAPTION: number = 11;
  static readonly META: number = 10;
}

export class AppLayout {
  static readonly BOTTOM_BAR_HEIGHT: number = 52;
  static readonly SIDE_BAR_WIDTH: number = 224;
  static readonly MEDIUM_BREAKPOINT: number = 600;
  static readonly EXPANDED_BREAKPOINT: number = 840;
  static readonly CONTENT_MAX_WIDTH: number = 1180;
  static readonly TOP_BAR_HEIGHT: number = 48;
  static readonly TOP_BAR_LEADING_SIZE: number = 48;
  static readonly TOP_BAR_ACTION_SIZE: number = 34;
}

export class AppIconSize {
  static readonly TOP_BAR: number = 19;
  static readonly BOTTOM_BAR: number = 20;
  static readonly CHEVRON: number = 16;
}

export class MediaLayout {
  static readonly VIRTUAL_SCROLL_CACHED_ROWS: number = 2;
  static readonly BROWSER_TOP_INSET: number = 8;
  static readonly ITEM_VERTICAL_GAP: number = 12;
  static readonly LIST_THUMBNAIL_WIDTH: number = 80;
  static readonly LIST_THUMBNAIL_HEIGHT: number = 45;
  static readonly ASPECT_RATIO: number = 16 / 9;
  static readonly FOLDER_ASPECT_RATIO: number = 5 / 4;
  static readonly GRID_ICON_HEIGHT: string = '60%';
  static readonly LIST_FILE_ICON_SIZE: number = 28;
  static readonly LIST_MEDIA_ITEM_HEIGHT: number = 54;
  static readonly LIST_FOLDER_ITEM_HEIGHT: number = 54;
  static readonly LIST_REMOTE_ITEM_HEIGHT: number = 54;
  static readonly LIST_ITEM_VERTICAL_GAP: number = 8;
  static readonly NETWORK_SERVER_ITEM_HEIGHT: number = 48;
  static readonly NETWORK_SERVER_ITEM_GAP: number = 4;
  static readonly GRID_COLUMN_GAP: number = 12;
  static readonly GRID_ROW_GAP: number = 16;
  static readonly GRID_MEDIA_COPY_HEIGHT: number = 48;
}
