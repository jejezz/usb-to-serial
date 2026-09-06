import 'package:flutter/foundation.dart';

import '../services/serial_service.dart';
import 'terminal_session_provider.dart';

/// 탭(=세션) 목록과 어떤 탭이 활성인지 관리한다. 세션 하나하나의 연결
/// 상태/버퍼/로깅은 각 [TerminalSessionProvider]가 스스로 들고 있고,
/// 여기서는 그 목록과 순서/활성 인덱스만 다룬다.
class SessionsProvider extends ChangeNotifier {
  SessionsProvider() {
    _sessions.add(TerminalSessionProvider(SerialService()));
  }

  final List<TerminalSessionProvider> _sessions = [];
  int _activeIndex = 0;

  List<TerminalSessionProvider> get sessions => List.unmodifiable(_sessions);
  int get activeIndex => _activeIndex;
  TerminalSessionProvider get active => _sessions[_activeIndex];

  void addSession() {
    _sessions.add(TerminalSessionProvider(SerialService()));
    _activeIndex = _sessions.length - 1;
    notifyListeners();
  }

  void setActive(int index) {
    if (index == _activeIndex || index < 0 || index >= _sessions.length) return;
    _activeIndex = index;
    notifyListeners();
  }

  /// 탭이 하나뿐이면 닫지 못하게 막는다 — 항상 최소 하나는 남아 있어야
  /// 화면에 보여줄 게 있다.
  void closeSession(int index) {
    if (_sessions.length <= 1 || index < 0 || index >= _sessions.length) return;
    final removed = _sessions.removeAt(index);
    removed.dispose();
    if (_activeIndex >= _sessions.length) {
      _activeIndex = _sessions.length - 1;
    } else if (index < _activeIndex) {
      _activeIndex -= 1;
    }
    notifyListeners();
  }

  /// 앱 종료 직전 모든 탭의 로그 파일을 flush/close한다.
  Future<void> prepareAllForExit() async {
    for (final session in _sessions) {
      await session.prepareForExit();
    }
  }

  @override
  void dispose() {
    for (final session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }
}
