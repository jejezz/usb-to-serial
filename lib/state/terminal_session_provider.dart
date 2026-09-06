import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:xterm2/xterm.dart';

import '../models/connection_settings.dart';
import '../models/line_ending.dart';
import '../services/log_file_service.dart';
import '../services/serial_service.dart';

enum ConnectionStatus { disconnected, connected, error }

enum ViewMode { terminal, hex }

/// 연결 상태와 수신 바이트 버퍼를 갖고 있는 단일 세션 상태.
///
/// 화면 렌더링/키보드(IME 포함) 입력은 `xterm2`의 [Terminal]에 맡긴다 —
/// 직접 만든 raw 키 캡처는 한글 조합, backspace, 이스케이프 시퀀스에서
/// 전부 문제가 있어서 걷어냈다. [_rawBytes]는 화면 렌더링과 별개로 실제
/// 수신한 바이트만 담아 Hex View/로깅(Phase 5, 6)의 소스로 쓴다.
class TerminalSessionProvider extends ChangeNotifier {
  TerminalSessionProvider(this._service) {
    terminal.onOutput = (data) => sendRaw(utf8.encode(data));
  }

  static const int _maxBufferBytes = 2 * 1024 * 1024;

  final SerialService _service;
  final LogFileService _logService = LogFileService();
  Terminal terminal = Terminal(maxLines: 10000);
  StreamSubscription<Uint8List>? _sub;
  bool _notifyScheduled = false;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  String? _portName;
  int? _baudRate;
  final List<int> _rawBytes = [];

  LineEnding _lineEnding = LineEnding.lf;
  bool _localEcho = true;

  // 탭 UI 상태 — 연결 전에 고르고 있는 포트/보드레이트, 지금 보고 있는 뷰
  // 모드. 탭을 전환해도 유지돼야 해서 위젯 로컬 State가 아니라 여기 둔다.
  String? _pendingPort;
  int? _pendingBaudRate = 115200;
  ViewMode _viewMode = ViewMode.terminal;

  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get portName => _portName;
  int? get baudRate => _baudRate;
  int get byteCount => _rawBytes.length;
  String get displayText => utf8.decode(_rawBytes, allowMalformed: true);
  List<int> get rawBytes => _rawBytes;
  LineEnding get lineEnding => _lineEnding;
  bool get localEcho => _localEcho;
  bool get isLogging => _logService.isLogging;
  String? get logFilePath => _logService.filePath;
  String? get pendingPort => _pendingPort;
  int? get pendingBaudRate => _pendingBaudRate;
  ViewMode get viewMode => _viewMode;

  /// 탭에 표시할 제목: 연결됐으면 실제 포트, 아니면 고르고 있는 포트,
  /// 그것도 없으면 "새 세션".
  String get tabTitle {
    final name = _portName ?? _pendingPort;
    if (name == null) return '새 세션';
    return name.startsWith('/dev/') ? name.substring(5) : name;
  }

  void setLineEnding(LineEnding value) {
    _lineEnding = value;
    notifyListeners();
  }

  void setLocalEcho(bool value) {
    _localEcho = value;
    notifyListeners();
  }

  void setPendingPort(String? value) {
    _pendingPort = value;
    notifyListeners();
  }

  void setPendingBaudRate(int? value) {
    _pendingBaudRate = value;
    notifyListeners();
  }

  void setViewMode(ViewMode value) {
    _viewMode = value;
    notifyListeners();
  }

  /// 화면(뷰포트+스크롤백)만 지운다 — 로그 파일이나 Hex View용 raw 버퍼는
  /// 그대로 유지된다.
  void clearTerminal() {
    terminal.clear();
  }

  /// xterm2의 `Terminal.maxLines`는 생성 시에만 정해지는 값이라, 스크롤백
  /// 줄 수를 바꾸려면 터미널을 통째로 새로 만들어야 한다 — 그 과정에서
  /// 지금까지 쌓인 화면 내용(스크롤백)은 비워진다.
  void setScrollbackLines(int maxLines) {
    if (terminal.maxLines == maxLines) return;
    final old = terminal;
    terminal = Terminal(maxLines: maxLines)..onOutput = (data) => sendRaw(utf8.encode(data));
    old.dispose();
    notifyListeners();
  }

  void connect(ConnectionSettings settings) {
    try {
      final stream = _service.open(settings.portName, settings.baudRate);
      _sub = stream.listen(_onData, onError: _onStreamError, onDone: _onStreamDone);
      _status = ConnectionStatus.connected;
      _errorMessage = null;
      _portName = settings.portName;
      _baudRate = settings.baudRate;
      // 많은 시리얼 콘솔(임베디드 리눅스/안드로이드 디버그 콘솔 등)은 뭔가
      // 받기 전엔 프롬프트를 안 찍어준다 — 연결하자마자 Enter를 한 번 보내서
      // 깨워준다.
      sendRaw(const [0x0D, 0x0A]);
    } on SerialServiceException catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.message;
    }
    notifyListeners();
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _service.close();
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  /// Line Sender에서 한 줄을 보낸다. 설정된 줄바꿈을 붙이고, Local Echo가
  /// 켜져 있으면 보낸 내용을 터미널 화면에도 그대로 반영한다.
  void send(String text) {
    if (_status != ConnectionStatus.connected) return;
    final line = text + _lineEnding.suffix;
    try {
      _service.write(Uint8List.fromList(utf8.encode(line)));
      if (_localEcho) {
        terminal.write(line);
      }
    } on SerialServiceException catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  /// 터미널 화면에 직접 타이핑했을 때(`Terminal.onOutput`)의 TX 경로.
  /// 실제 터미널처럼, 타이핑한 내용은 상대가 에코해줘야 화면에 보인다 —
  /// 여기서 별도로 로컬 에코를 하지 않는다.
  void sendRaw(List<int> bytes) {
    if (_status != ConnectionStatus.connected) return;
    try {
      _service.write(Uint8List.fromList(bytes));
    } on SerialServiceException catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  /// 로깅 시작/정지를 토글한다. 로그 파일에는 뷰 모드/로컬 에코와 무관하게
  /// 실제로 수신한 raw bytes만 기록된다 — 연결돼 있을 때만 시작할 수 있다.
  /// 이제 탭 여러 개가 동시에 기록할 수 있어서, 시작할 때마다 파일 이름을
  /// 물어본다(취소하면 로깅을 켜지 않는다).
  Future<void> toggleLogging() async {
    if (_logService.isLogging) {
      await _logService.stop();
      notifyListeners();
      return;
    }

    final port = _portName;
    if (_status != ConnectionStatus.connected || port == null) return;

    final location = await getSaveLocation(
      initialDirectory: await LogFileService.defaultDirectory(),
      suggestedName: LogFileService.suggestedFileName(port),
      confirmButtonText: '기록 시작',
    );
    if (location == null) return;

    await _logService.start(location.path);
    notifyListeners();
  }

  void _onData(Uint8List chunk) {
    _rawBytes.addAll(chunk);
    final overflow = _rawBytes.length - _maxBufferBytes;
    if (overflow > 0) {
      _rawBytes.removeRange(0, overflow);
    }
    if (_logService.isLogging) {
      _logService.write(chunk);
    }
    terminal.write(utf8.decode(chunk, allowMalformed: true));
    _scheduleNotify();
  }

  /// 기기가 갑자기 뽑히는 등 스트림에서 에러가 나면, 죽은 포트를 붙잡고
  /// 있지 않도록 정리하고 연결 끊김 상태로 전환한다. 로깅 중이었다면
  /// 로그 파일도 flush/close한다.
  void _onStreamError(Object error) {
    _sub?.cancel();
    _sub = null;
    _service.close();
    if (_logService.isLogging) {
      unawaited(_logService.stop());
    }
    _status = ConnectionStatus.error;
    _errorMessage = error.toString();
    notifyListeners();
  }

  /// 기기가 뽑혔을 때 에러 없이 스트림이 그냥 끝나버리는 경우도 있어서,
  /// 그것도 연결 끊김으로 취급한다.
  void _onStreamDone() {
    if (_status != ConnectionStatus.connected) return;
    _onStreamError('기기와의 연결이 끊어졌습니다');
  }

  /// 고빈도 스트림에서 바이트 청크마다 리렌더하지 않도록 한 마이크로태스크에
  /// 몰아서 한 번만 notify한다 (바이트 카운터 등 provider 의존 UI용 — 터미널
  /// 자체는 xterm2가 알아서 다시 그린다).
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  /// 앱 종료 요청(⌘Q 등) 시 위젯 트리 dispose가 보장되지 않으므로, 종료
  /// 직전에 명시적으로 호출해서 로그 파일이 확실히 flush/close되게 한다.
  Future<void> prepareForExit() async {
    await _logService.stop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.close();
    unawaited(_logService.stop());
    terminal.dispose();
    super.dispose();
  }
}
