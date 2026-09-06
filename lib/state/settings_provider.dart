import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xterm2/xterm.dart';

import '../models/app_terminal_theme.dart';

/// 흔히 쓰는 스크롤백 줄 수 프리셋.
const kScrollbackLinesOptions = <int>[1000, 5000, 10000, 20000, 50000, 100000];

/// 터미널 폰트/테마/스크롤백 설정. `shared_preferences`로 영속화해서
/// 재실행 후에도 유지된다.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _load();
  }

  static const _kFontSizeKey = 'font_size';
  static const _kFontFamilyKey = 'font_family';
  static const _kThemeKey = 'theme';
  static const _kScrollbackLinesKey = 'scrollback_lines';

  double _fontSize = 14;
  String _fontFamily = kFontFamilies.first;
  AppTerminalTheme _appTheme = AppTerminalTheme.defaultDark;
  int _scrollbackLines = 10000;

  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  AppTerminalTheme get appTheme => _appTheme;
  int get scrollbackLines => _scrollbackLines;
  TerminalStyle get terminalStyle => TerminalStyle(fontSize: _fontSize, fontFamily: _fontFamily);
  TerminalTheme get terminalTheme => _appTheme.theme;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_kFontSizeKey) ?? _fontSize;
    _fontFamily = prefs.getString(_kFontFamilyKey) ?? _fontFamily;
    _scrollbackLines = prefs.getInt(_kScrollbackLinesKey) ?? _scrollbackLines;
    final themeName = prefs.getString(_kThemeKey);
    if (themeName != null) {
      _appTheme = AppTerminalTheme.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => AppTerminalTheme.defaultDark,
      );
    }
    notifyListeners();
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSizeKey, value);
  }

  Future<void> setFontFamily(String value) async {
    _fontFamily = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontFamilyKey, value);
  }

  Future<void> setAppTheme(AppTerminalTheme value) async {
    _appTheme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, value.name);
  }

  Future<void> setScrollbackLines(int value) async {
    _scrollbackLines = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kScrollbackLinesKey, value);
  }
}
