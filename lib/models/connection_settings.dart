/// 하나의 시리얼 연결에 필요한 최소 설정.
class ConnectionSettings {
  const ConnectionSettings({required this.portName, required this.baudRate});

  final String portName;
  final int baudRate;
}
