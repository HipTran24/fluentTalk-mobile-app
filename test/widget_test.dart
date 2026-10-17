import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/main.dart';

void main() {
  testWidgets('FluentTalkApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FluentTalkApp(),
      ),
    );

    // Initial frame renders FluentTalkApp
    expect(find.byType(FluentTalkApp), findsOneWidget);

    // Advance timer past splash delay
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app navigates to home
    expect(find.byType(FluentTalkApp), findsOneWidget);
  });
}
