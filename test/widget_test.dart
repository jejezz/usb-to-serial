import 'package:flutter_test/flutter_test.dart';
import 'package:usb_to_com/app.dart';

void main() {
  testWidgets('홈 화면이 크래시 없이 뜨는지', (WidgetTester tester) async {
    await tester.pumpWidget(const UsbToComApp());
    expect(find.text('Connect'), findsOneWidget);
    expect(find.byTooltip('Terminal'), findsOneWidget);
  });
}
