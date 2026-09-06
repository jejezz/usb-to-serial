import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

/// [flutter_libserialport]에 대한 얇은 래퍼.
/// 포트 열기/닫기/읽기/쓰기만 담당하고 연결 상태·버퍼 관리는 하지 않는다
/// (그건 [TerminalSessionProvider]의 책임).
class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;

  /// 네이티브 라이브러리를 로드할 수 없는 환경(예: 앱 번들 밖에서 도는
  /// `flutter test`)에서도 UI가 크래시하지 않도록 빈 목록으로 대체한다.
  static List<String> availablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (_) {
      return const [];
    }
  }

  bool get isOpen => _port != null;

  /// 포트를 열고 수신 스트림을 반환한다. 실패하면 [SerialServiceException]을 던진다.
  Stream<Uint8List> open(String portName, int baudRate) {
    close();

    final port = SerialPort(portName);
    if (!port.openReadWrite()) {
      final message = SerialPort.lastError?.message ?? '알 수 없는 오류';
      port.dispose();
      throw SerialServiceException(message);
    }

    port.config = SerialPortConfig()..baudRate = baudRate;

    _port = port;
    _reader = SerialPortReader(port);
    return _reader!.stream;
  }

  /// 바이트를 전송하고 실제로 쓰여진 바이트 수를 반환한다.
  int write(Uint8List bytes) {
    final port = _port;
    if (port == null) {
      throw SerialServiceException('연결되어 있지 않습니다');
    }
    try {
      return port.write(bytes);
    } on SerialPortError catch (e) {
      // 기기가 도중에 뽑히면 여기서 네이티브 에러가 난다 — 그대로 던지지
      // 않고 상위(provider)가 일관되게 처리할 수 있는 타입으로 감싼다.
      throw SerialServiceException(e.message);
    }
  }

  /// 이미 뽑혀서 죽은 포트를 닫으려 할 때 네이티브 쪽에서 예외가 나도
  /// 앱이 죽지 않도록, 각 단계를 독립적으로 방어한다.
  void close() {
    try {
      _reader?.close();
    } catch (_) {}
    try {
      _port?.close();
    } catch (_) {}
    try {
      _port?.dispose();
    } catch (_) {}
    _reader = null;
    _port = null;
  }
}

class SerialServiceException implements Exception {
  SerialServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
