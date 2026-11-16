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
import '../../../helpers/fake_auth_repository.dart';

void main() {
  late SharedPreferences prefs;
  late FakeAuthRepository fakeRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRepo = FakeAuthRepository(initialStatus: const AuthUnauthenticated());
  });

  Widget buildTestApp({Locale? locale}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: TaskMapFlowApp(
        firebaseReady: true,
        locale: locale,
      ),
    );
  }

  group('LoginScreen Tests', () {
    testWidgets('renders all login elements', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loginEmailField')), findsOneWidget);
      expect(find.byKey(const Key('loginPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('signInSubmitButton')), findsOneWidget);
      expect(find.byKey(const Key('guestSignInButton')), findsOneWidget);
      expect(find.byKey(const Key('forgotPasswordButton')), findsOneWidget);
      expect(find.byKey(const Key('goToRegisterButton')), findsOneWidget);
      expect(find.text('TR'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('validates empty email and password', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('signInSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(fakeRepo.signInCallCount, 0);
    });

    testWidgets('validates invalid email format', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('signInSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(fakeRepo.signInCallCount, 0);
    });

    testWidgets('successful sign-in submits email and password',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'securePassword123',
      );
      await tester.tap(find.byKey(const Key('signInSubmitButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.signInCallCount, 1);
    });

    testWidgets('failed sign-in displays localized error message',
        (tester) async {
      fakeRepo.signInResult = const Err<AuthUser>(InvalidCredentialsFailure());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'wrongpassword',
      );
      await tester.tap(find.byKey(const Key('signInSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password'), findsOneWidget);
    });

    testWidgets('guest sign in button signs in anonymously', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guestSignInButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.guestCallCount, 1);
    });

    testWidgets('language switcher updates locale between TR and EN',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsWidgets);

      // Switch to TR
      await tester.tap(find.text('TR'));
      await tester.pumpAndSettle();

      expect(find.text('Giriş Yap'), findsWidgets);

      // Switch back to EN
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsWidgets);
    });
  });
}
