import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import '../../../helpers/fake_auth_repository.dart';

void main() {
  late SharedPreferences prefs;
  late FakeAuthRepository fakeRepo;

  const unverifiedUser = AuthUser(
    id: 'u1',
    email: 'unverified@example.com',
    displayName: 'Test User',
    isAnonymous: false,
    isEmailVerified: false,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRepo = FakeAuthRepository(
      initialStatus: const AuthUnverified(unverifiedUser),
    );
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const TaskMapFlowApp(
        firebaseReady: true,
        locale: Locale('en'),
      ),
    );
  }

  group('VerifyEmailScreen Tests', () {
    testWidgets('renders verify email content with user email', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Email'), findsNWidgets(2));
      expect(
        find.textContaining('unverified@example.com'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('checkVerificationStatusButton')),
          findsOneWidget);
      expect(find.byKey(const Key('resendVerificationButton')), findsOneWidget);
      expect(find.byKey(const Key('verifyEmailSignOutButton')), findsOneWidget);
    });

    testWidgets(
        'refresh status calls reloadUser and transitions to home when verified',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkVerificationStatusButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.reloadCallCount, 1);
      // Once verified, router redirects to Home
      expect(find.text('TaskMapFlow'), findsOneWidget);
    });

    testWidgets('resend button triggers cooldown timer', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('resendVerificationButton')));
      await tester.pump();

      expect(fakeRepo.verificationCallCount, 1);
      expect(find.textContaining('Resend in'), findsOneWidget);

      // Fast forward timer
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Resend Verification Email'), findsOneWidget);
    });

    testWidgets('sign out button calls signOut and redirects to login',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('verifyEmailSignOutButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.signOutCallCount, 1);
      expect(find.byKey(const Key('signInSubmitButton')), findsOneWidget);
    });
  });
}
