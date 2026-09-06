import 'dart:io';
import 'dart:typed_data';

/// 수신 바이트를 파일에 기록한다. 시작/정지만 하는 얇은 래퍼 —
/// 언제 기록할지(로깅 on/off, RX만 기록할지 등), 파일 이름/위치를 어떻게
/// 정할지는 상위(provider/UI)의 몫이다.
class LogFileService {
  IOSink? _sink;
  File? _file;

  bool get isLogging => _sink != null;
  String? get filePath => _file?.path;

  /// 기본 저장 폴더 — 없으면 만들어서 경로를 반환한다.
  static Future<String> defaultDirectory() async {
    final home = Platform.environment['HOME'] ?? '.';
    final dir = Directory('$home/Downloads/usb_to_com_logs');
    await dir.create(recursive: true);
    return dir.path;
  }

  /// `<port>_<yyyyMMdd_HHmmss>.log` 형태의 기본 파일 이름 제안 — 저장
  /// 대화상자에 미리 채워주는 용도.
  static String suggestedFileName(String portName) {
    final safePort = portName.split('/').last;
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final timestamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return '${safePort}_$timestamp.log';
  }

  /// 주어진 경로에 로그 파일을 만들고 기록을 시작한다.
  Future<void> start(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    _sink = file.openWrite(mode: FileMode.writeOnlyAppend);
    _file = file;
  }

  void write(Uint8List bytes) {
    _sink?.add(bytes);
  }

  Future<void> stop() async {
    final sink = _sink;
    _sink = null;
    _file = null;
    if (sink != null) {
      await sink.flush();
      await sink.close();
    }
  }
}
