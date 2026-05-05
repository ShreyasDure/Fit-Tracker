import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_tracker/main.dart';

void main() {
  testWidgets('FitTracker app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FitTrackerApp()),
    );
    await tester.pumpAndSettle();

    // Verify login screen is shown
    expect(find.text('FitTracker'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
