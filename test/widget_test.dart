// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_inventory/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify key UI elements are present.
    expect(find.text('POS KIOS ZAGA'), findsOneWidget);
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

  });
}
