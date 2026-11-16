import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_workspace_repository.dart';

void main() {
  late SharedPreferences prefs;
  late FakeAuthRepository fakeRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRepo = FakeAuthRepository(initialStatus: const AuthInitial());
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

  group('Router Auth Guard Tests', () {
    testWidgets('AuthInitial renders loading screen without flashing home',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('Checking session...'), findsOneWidget);
      expect(find.text('TaskMapFlow'), findsNothing);
    });

    testWidgets('AuthUnauthenticated redirects to LoginScreen', (tester) async {
      fakeRepo.setStatus(const AuthUnauthenticated());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('signInSubmitButton')), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('AuthUnverified redirects to VerifyEmailScreen',
        (tester) async {
      fakeRepo.setStatus(
        const AuthUnverified(
          AuthUser(
            id: 'u-unverified',
            email: 'notverified@example.com',
            displayName: 'Pending',
            isAnonymous: false,
            isEmailVerified: false,
          ),
        ),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('AuthGuest allows 3-tab shell with guest profile',
        (tester) async {
      fakeRepo.setStatus(
        const AuthGuest(
          AuthUser(
            id: 'g-1',
            email: null,
            displayName: null,
            isAnonymous: true,
            isEmailVerified: false,
          ),
        ),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
    });

    testWidgets(
        'signOut redirects from ProfileScreen to LoginScreen immediately',
        (tester) async {
      fakeRepo.setStatus(
        const AuthAuthenticated(
          AuthUser(
            id: 'u-auth',
            email: 'auth@example.com',
            displayName: 'Auth User',
            isAnonymous: false,
            isEmailVerified: true,
          ),
        ),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Go to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profileSignOutButton')), findsOneWidget);

      // Tap Sign Out
      await tester.tap(find.byKey(const Key('profileSignOutButton')));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Confirm Sign Out'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmSignOutButton')));
      await tester.pumpAndSettle();

      // Verify redirected to LoginScreen
      expect(find.byKey(const Key('signInSubmitButton')), findsOneWidget);
      expect(fakeRepo.signOutCallCount, 1);
    });
  });
}
