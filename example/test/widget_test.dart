import 'package:flutter_test/flutter_test.dart';
import 'package:root_toast_example/main.dart';

void main() {
  testWidgets('shows a toast above a modal sheet', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Toast above a modal bottom sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Minimum price not met').hitTestable(), findsOneWidget);
  });
}
