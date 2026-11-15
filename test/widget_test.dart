// Smoke test: app boots without Firebase (firebaseReady: false).
import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders setup-required screen when Firebase not ready',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TaskMapFlowApp(firebaseReady: false),
      ),
    );
    expect(find.text('Firebase Setup Required'), findsOneWidget);
  });
}
