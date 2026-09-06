import 'package:flutter_test/flutter_test.dart';
import 'package:usb_to_com/utils/hex_dump.dart';

void main() {
  test('빈 목록은 빈 문자열', () {
    expect(hexDump([]), '');
  });

  test('한 줄 미만이면 오프셋 다음에 헥사, 끝에 아스키가 나온다', () {
    final line = hexDump('Hi'.codeUnits).trimRight();
    expect(line.startsWith('00000000  48 69'), isTrue);
    expect(line.endsWith('|Hi|'), isTrue);
  });

  test('출력 불가능한 바이트는 점으로 표시', () {
    final out = hexDump([0x00, 0x1f, 0x41]);
    expect(out.contains('|..A|'), isTrue);
  });

  test('16바이트 넘으면 다음 줄의 오프셋이 16(0x10)부터 시작', () {
    final bytes = List<int>.generate(20, (i) => i);
    final lines = hexDump(bytes).trimRight().split('\n');
    expect(lines.length, 2);
    expect(lines[1].startsWith('00000010'), isTrue);
  });
}
