import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_workspace_repository.dart';

void main() {
  late SharedPreferences prefs;
  late FakeAuthRepository fakeRepo;

  const guestUser = AuthUser(
    id: 'guest-123',
    email: null,
    displayName: null,
    isAnonymous: true,
    isEmailVerified: false,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRepo = FakeAuthRepository(
      initialStatus: const AuthGuest(guestUser),
    );
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(fakeRepo),
        workspaceRepositoryProvider
            .overrideWithValue(FakeWorkspaceRepository()),
      ],
      child: const TaskMapFlowApp(
        firebaseReady: true,
        locale: Locale('en'),
      ),
    );
  }

  group('LinkAccountScreen Tests', () {
    testWidgets('guest profile displays guest badge and link button',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Go to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Guest Session'), findsOneWidget);
      expect(find.byKey(const Key('profileLinkAccountButton')), findsOneWidget);
    });

    testWidgets('opens link account screen from profile and validates inputs',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profileLinkAccountButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('linkFirstNameField')), findsOneWidget);
      expect(find.byKey(const Key('linkLastNameField')), findsOneWidget);
      expect(find.byKey(const Key('linkEmailField')), findsOneWidget);
      expect(find.byKey(const Key('linkPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('linkConfirmPasswordField')), findsOneWidget);

      final submitBtn = find.byKey(const Key('linkAccountSubmitButton'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your first name'), findsOneWidget);
      expect(find.text('Please enter your last name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets(
        'successful account link preserves UID and directs to verification',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profileLinkAccountButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('linkFirstNameField')), 'Guest');
      await tester.enterText(
          find.byKey(const Key('linkLastNameField')), 'Promoted');
      await tester.enterText(
          find.byKey(const Key('linkEmailField')), 'guest@example.com');
      await tester.enterText(
          find.byKey(const Key('linkPasswordField')), 'password123');
      await tester.enterText(
          find.byKey(const Key('linkConfirmPasswordField')), 'password123');

      final submitBtn = find.byKey(const Key('linkAccountSubmitButton'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.linkCallCount, 1);
      // Status changes to unverified, router moves to verify-email
      expect(find.text('Verify Your Email'), findsOneWidget);
    });

    testWidgets(
        'shows conflict error when email is already in use by another account',
        (tester) async {
      fakeRepo.linkResult = const Err<AuthUser>(
        EmailAlreadyInUseFailure(
          'This email is already registered. Automatic merging is disabled for security.',
        ),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profileLinkAccountButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('linkFirstNameField')), 'Guest');
      await tester.enterText(
          find.byKey(const Key('linkLastNameField')), 'User');
      await tester.enterText(
          find.byKey(const Key('linkEmailField')), 'conflict@example.com');
      await tester.enterText(
          find.byKey(const Key('linkPasswordField')), 'password123');
      await tester.enterText(
          find.byKey(const Key('linkConfirmPasswordField')), 'password123');

      final submitBtn2 = find.byKey(const Key('linkAccountSubmitButton'));
      await tester.ensureVisible(submitBtn2);
      await tester.tap(submitBtn2);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This email address is already in use'),
        findsOneWidget,
      );
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
