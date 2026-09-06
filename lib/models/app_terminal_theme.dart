import 'package:flutter/widgets.dart';
import 'package:xterm2/xterm.dart';

/// xterm2가 기본 제공하는 테마는 2개뿐이라, 직접 만든 것들(그린 포스포/라이트
/// + 유명 터미널 색상 프로파일들)을 더해서 고른다. 값들은 각 테마의
/// 공식/통용 16-ANSI-color 팔레트를 그대로 옮긴 것.
enum AppTerminalTheme {
  defaultDark,
  whiteOnBlack,
  greenPhosphor,
  light,
  solarizedDark,
  solarizedLight,
  dracula,
  nord,
  gruvboxDark,
}

extension AppTerminalThemeX on AppTerminalTheme {
  String get label => switch (this) {
        AppTerminalTheme.defaultDark => '기본 (다크)',
        AppTerminalTheme.whiteOnBlack => '화이트 온 블랙',
        AppTerminalTheme.greenPhosphor => '그린 포스포',
        AppTerminalTheme.light => '라이트',
        AppTerminalTheme.solarizedDark => 'Solarized Dark',
        AppTerminalTheme.solarizedLight => 'Solarized Light',
        AppTerminalTheme.dracula => 'Dracula',
        AppTerminalTheme.nord => 'Nord',
        AppTerminalTheme.gruvboxDark => 'Gruvbox Dark',
      };

  TerminalTheme get theme => switch (this) {
        AppTerminalTheme.defaultDark => TerminalThemes.defaultTheme,
        AppTerminalTheme.whiteOnBlack => TerminalThemes.whiteOnBlack,
        AppTerminalTheme.greenPhosphor => _greenPhosphor,
        AppTerminalTheme.light => _light,
        AppTerminalTheme.solarizedDark => _solarizedDark,
        AppTerminalTheme.solarizedLight => _solarizedLight,
        AppTerminalTheme.dracula => _dracula,
        AppTerminalTheme.nord => _nord,
        AppTerminalTheme.gruvboxDark => _gruvboxDark,
      };
}

// 검색 하이라이트 색은 프로파일의 정체성과 무관해서 모든 커스텀 테마가 공유한다.
const _searchHitBackground = Color(0xFFFFFF2B);
const _searchHitBackgroundCurrent = Color(0xFF31FF26);
const _searchHitForeground = Color(0xFF000000);

const _greenPhosphor = TerminalTheme(
  cursor: Color(0xFF33FF66),
  selection: Color(0xFF215E2D),
  foreground: Color(0xFF33FF66),
  background: Color(0xFF000000),
  black: Color(0xFF000000),
  red: Color(0xFFCD3131),
  green: Color(0xFF33FF66),
  yellow: Color(0xFFE5E510),
  blue: Color(0xFF2472C8),
  magenta: Color(0xFFBC3FBC),
  cyan: Color(0xFF11A8CD),
  white: Color(0xFFCFFFDD),
  brightBlack: Color(0xFF666666),
  brightRed: Color(0xFFF14C4C),
  brightGreen: Color(0xFF7CFFA0),
  brightYellow: Color(0xFFF5F543),
  brightBlue: Color(0xFF3B8EEA),
  brightMagenta: Color(0xFFD670D6),
  brightCyan: Color(0xFF29B8DB),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: _searchHitBackground,
  searchHitBackgroundCurrent: _searchHitBackgroundCurrent,
  searchHitForeground: _searchHitForeground,
);

const _light = TerminalTheme(
  cursor: Color(0xFF333333),
  selection: Color(0xFFB3D7FF),
  foreground: Color(0xFF1E1E1E),
  background: Color(0xFFFFFFFF),
  black: Color(0xFF000000),
  red: Color(0xFFC91B00),
  green: Color(0xFF00A600),
  yellow: Color(0xFF999900),
  blue: Color(0xFF0037DA),
  magenta: Color(0xFF981788),
  cyan: Color(0xFF00A6B2),
  white: Color(0xFFCCCCCC),
  brightBlack: Color(0xFF666666),
  brightRed: Color(0xFFE50000),
  brightGreen: Color(0xFF00D900),
  brightYellow: Color(0xFFE5E500),
  brightBlue: Color(0xFF0037FF),
  brightMagenta: Color(0xFFD900D9),
  brightCyan: Color(0xFF00D9D9),
  brightWhite: Color(0xFFE5E5E5),
  searchHitBackground: _searchHitBackground,
  searchHitBackgroundCurrent: _searchHitBackgroundCurrent,
  searchHitForeground: _searchHitForeground,
);

// 아래 16색은 각 테마의 공식/통용 ANSI 팔레트를 그대로 옮긴 값 —
// Solarized 계열은 accent 색(red~brightCyan)이 dark/light 버전에서 동일하고
// 배경/전경/black/white 쪽만 base 톤이 바뀐다.
const _solarizedRed = Color(0xFFDC322F);
const _solarizedGreen = Color(0xFF859900);
const _solarizedYellow = Color(0xFFB58900);
const _solarizedBlue = Color(0xFF268BD2);
const _solarizedMagenta = Color(0xFFD33682);
const _solarizedCyan = Color(0xFF2AA198);
const _solarizedBrightRed = Color(0xFFCB4B16);
const _solarizedBrightMagenta = Color(0xFF6C71C4);

const _solarizedDark = TerminalTheme(
  cursor: Color(0xFF839496),
  selection: Color(0xFF073642),
  foreground: Color(0xFF839496),
  background: Color(0xFF002B36),
  black: Color(0xFF073642),
  red: _solarizedRed,
  green: _solarizedGreen,
  yellow: _solarizedYellow,
  blue: _solarizedBlue,
  magenta: _solarizedMagenta,
  cyan: _solarizedCyan,
  white: Color(0xFFEEE8D5),
  brightBlack: Color(0xFF002B36),
  brightRed: _solarizedBrightRed,
  brightGreen: Color(0xFF586E75),
  brightYellow: Color(0xFF657B83),
  brightBlue: Color(0xFF839496),
  brightMagenta: _solarizedBrightMagenta,
  brightCyan: Color(0xFF93A1A1),
  brightWhite: Color(0xFFFDF6E3),
  searchHitBackground: _searchHitBackground,
  searchHitBackgroundCurrent: _searchHitBackgroundCurrent,
  searchHitForeground: _searchHitForeground,
);

const _solarizedLight = TerminalTheme(
  cursor: Color(0xFF657B83),
  selection: Color(0xFFEEE8D5),
  foreground: Color(0xFF657B83),
  background: Color(0xFFFDF6E3),
  black: Color(0xFF073642),
  red: _solarizedRed,
  green: _solarizedGreen,
  yellow: _solarizedYellow,
  blue: _solarizedBlue,
  magenta: _solarizedMagenta,
  cyan: _solarizedCyan,
  white: Color(0xFFEEE8D5),
  brightBlack: Color(0xFF002B36),
  brightRed: _solarizedBrightRed,
  brightGreen: Color(0xFF586E75),
  brightYellow: Color(0xFF657B83),
  brightBlue: Color(0xFF839496),
  brightMagenta: _solarizedBrightMagenta,
  brightCyan: Color(0xFF93A1A1),
  brightWhite: Color(0xFFFDF6E3),
  searchHitBackground: _searchHitBackground,
  searchHitBackgroundCurrent: _searchHitBackgroundCurrent,
  searchHitForeground: _searchHitForeground,
);

// 공식 Dracula 터미널 팔레트 (draculatheme.com).
const _dracula = TerminalTheme(
  cursor: Color(0xFFF8F8F2),
  selection: Color(0xFF44475A),
  foreground: Color(0xFFF8F8F2),
  background: Color(0xFF282A36),
  black: Color(0xFF21222C),
  red: Color(0xFFFF5555),
  green: Color(0xFF50FA7B),
  yellow: Color(0xFFF1FA8C),
  blue: Color(0xFFBD93F9),
  magenta: Color(0xFFFF79C6),
  cyan: Color(0xFF8BE9FD),
  white: Color(0xFFF8F8F2),
  brightBlack: Color(0xFF6272A4),
  brightRed: Color(0xFFFF6E6E),
  brightGreen: Color(0xFF69FF94),
  brightYellow: Color(0xFFFFFFA5),
  brightBlue: Color(0xFFD6ACFF),
  brightMagenta: Color(0xFFFF92DF),
  brightCyan: Color(0xFFA4FFFF),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: _searchHitBackground,
  searchHitBackgroundCurrent: _searchHitBackgroundCurrent,
  searchHitForeground: _searchHitForeground,
);

// 공식 Nord 팔레트 (nordtheme.com).
const _nord = TerminalTheme(
  cursor: Color(0xFFD8DEE9),
  selection: Color(0xFF434C5E),
  foreground: Color(0xFFD8DEE9),
  background: Color(0xFF2E3440),
  black: Color(0xFF3B4252),
  red: Color(0xFFBF616A),
  green: Color(0xFFA3BE8C),
  yellow: Color(0xFFEBCB8B),
  blue: Color(0xFF81A1C1),
  magenta: Color(0xFFB48EAD),
  cyan: Color(0xFF88C0D0),
  white: Color(0xFFE5E9F0),
  brightBlack: Color(0xFF4C566A),
  brightRed: Color(0xFFBF616A),
  brightGreen: Color(0xFFA3BE8C),
  brightYellow: Color(0xFFEBCB8B),
  brightBlue: Color(0xFF81A1C1),
  brightMagenta: Color(0xFFB48EAD),
  brightCyan: Color(0xFF8FBCBB),
  brightWhite: Color(0xFFECEFF4),
  searchHitBackground: _searchHitBackground,
  searchHitBackgroundCurrent: _searchHitBackgroundCurrent,
  searchHitForeground: _searchHitForeground,
);

// 통용되는 Gruvbox Dark(medium contrast) 팔레트.
const _gruvboxDark = TerminalTheme(
  cursor: Color(0xFFEBDBB2),
  selection: Color(0xFF504945),
  foreground: Color(0xFFEBDBB2),
  background: Color(0xFF282828),
  black: Color(0xFF282828),
  red: Color(0xFFCC241D),
  green: Color(0xFF98971A),
  yellow: Color(0xFFD79921),
  blue: Color(0xFF458588),
  magenta: Color(0xFFB16286),
  cyan: Color(0xFF689D6A),
  white: Color(0xFFA89984),
  brightBlack: Color(0xFF928374),
  brightRed: Color(0xFFFB4934),
  brightGreen: Color(0xFFB8BB26),
  brightYellow: Color(0xFFFABD2F),
  brightBlue: Color(0xFF83A598),
  brightMagenta: Color(0xFFD3869B),
  brightCyan: Color(0xFF8EC07C),
  brightWhite: Color(0xFFEBDBB2),
  searchHitBackground: _searchHitBackground,
  searchHitBackgroundCurrent: _searchHitBackgroundCurrent,
  searchHitForeground: _searchHitForeground,
);

/// 설정 다이얼로그에서 고를 수 있는 폰트 목록 — macOS에 기본 설치된
/// 고정폭 폰트들.
const kFontFamilies = ['Menlo', 'Monaco', 'SF Mono', 'Courier New'];
