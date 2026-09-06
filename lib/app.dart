import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/sessions_provider.dart';
import 'state/settings_provider.dart';

/// 메뉴/버튼/라벨용 Light 굵기 + 살짝 작은 크기 텍스트 테마. Material 기본
/// 텍스트 테마는 두께가 Regular라 커스텀 폰트를 얹어도 밋밋해 보여서,
/// 전 스타일을 우리 폰트의 Light 웨이트(300)로 강제하고 1pt씩 줄인다.
TextTheme _lightTextTheme(TextTheme base) {
  TextStyle? light(TextStyle? style) {
    if (style == null) return null;
    return style.copyWith(
      fontFamily: 'ClipartKorea',
      fontWeight: FontWeight.w300,
      fontSize: (style.fontSize ?? 14) - 1,
    );
  }

  return TextTheme(
    displayLarge: light(base.displayLarge),
    displayMedium: light(base.displayMedium),
    displaySmall: light(base.displaySmall),
    headlineLarge: light(base.headlineLarge),
    headlineMedium: light(base.headlineMedium),
    headlineSmall: light(base.headlineSmall),
    titleLarge: light(base.titleLarge),
    titleMedium: light(base.titleMedium),
    titleSmall: light(base.titleSmall),
    bodyLarge: light(base.bodyLarge),
    bodyMedium: light(base.bodyMedium),
    bodySmall: light(base.bodySmall),
    labelLarge: light(base.labelLarge),
    labelMedium: light(base.labelMedium),
    labelSmall: light(base.labelSmall),
  );
}

ThemeData _buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF), brightness: Brightness.dark),
  );
  return base.copyWith(
    textTheme: _lightTextTheme(base.textTheme),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

class UsbToComApp extends StatefulWidget {
  const UsbToComApp({super.key});

  @override
  State<UsbToComApp> createState() => _UsbToComAppState();
}

class _UsbToComAppState extends State<UsbToComApp> with WidgetsBindingObserver {
  late final _sessions = SessionsProvider();
  late final _settings = SettingsProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 스크롤백 줄 수는 SettingsProvider(전역 설정)가 값을 들고 있고 실제
    // 적용은 각 TerminalSessionProvider의 Terminal 재생성으로 이뤄지는데,
    // provider들이 서로를 몰라도 되게 이 앱 레벨에서 이어준다. 설정이
    // 바뀌거나(_settings) 탭이 새로 생기거나(_sessions) 둘 중 하나만
    // 일어나도 전체 탭에 다시 맞춰준다 — setScrollbackLines가 값이 같으면
    // no-op이라 중복 호출해도 안전하다.
    _settings.addListener(_syncScrollback);
    _sessions.addListener(_syncScrollback);
  }

  void _syncScrollback() {
    for (final session in _sessions.sessions) {
      session.setScrollbackLines(_settings.scrollbackLines);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_syncScrollback);
    _sessions.removeListener(_syncScrollback);
    _sessions.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    // ⌘Q 등으로 앱이 종료될 때는 위젯 dispose가 보장되지 않으므로, 종료
    // 직전에 모든 탭의 로그 파일을 확실히 flush/close한다.
    await _sessions.prepareAllForExit();
    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _sessions),
        ChangeNotifierProvider.value(value: _settings),
      ],
      child: Builder(
        builder: (context) {
          // 포커스가 터미널/Line Sender 어디에 있든 동작하는 앱 전역
          // 단축키. 로깅 토글/새 탭/탭 닫기는 전부 "활성 탭" 기준이다.
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true): () =>
                  context.read<SessionsProvider>().active.toggleLogging(),
              const SingleActivator(LogicalKeyboardKey.keyT, meta: true): () =>
                  context.read<SessionsProvider>().addSession(),
              const SingleActivator(LogicalKeyboardKey.keyW, meta: true): () {
                final sessions = context.read<SessionsProvider>();
                sessions.closeSession(sessions.activeIndex);
              },
            },
            child: MaterialApp(
              title: 'Portside',
              theme: _buildTheme(),
              home: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
