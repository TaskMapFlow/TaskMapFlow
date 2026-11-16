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

  Future<void> navigateToRegister(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final registerBtn = find.byKey(const Key('goToRegisterButton'));
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();
  }

  group('RegisterScreen Tests', () {
    testWidgets('navigates to register screen and renders all fields',
        (tester) async {
      await navigateToRegister(tester);

      expect(find.byKey(const Key('registerFirstNameField')), findsOneWidget);
      expect(find.byKey(const Key('registerLastNameField')), findsOneWidget);
      expect(find.byKey(const Key('registerEmailField')), findsOneWidget);
      expect(find.byKey(const Key('registerPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('registerConfirmPasswordField')),
          findsOneWidget);
      expect(find.byKey(const Key('registerSubmitButton')), findsOneWidget);
    });

    testWidgets('validates required fields and password length',
        (tester) async {
      await navigateToRegister(tester);

      final submitBtn = find.byKey(const Key('registerSubmitButton'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your first name'), findsOneWidget);
      expect(find.text('Please enter your last name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsNWidgets(2));
    });

    testWidgets('validates password mismatch and length < 6', (tester) async {
      await navigateToRegister(tester);

      await tester.enterText(
          find.byKey(const Key('registerFirstNameField')), 'John');
      await tester.enterText(
          find.byKey(const Key('registerLastNameField')), 'Doe');
      await tester.enterText(
          find.byKey(const Key('registerEmailField')), 'john@example.com');
      await tester.enterText(
          find.byKey(const Key('registerPasswordField')), '123');
      await tester.enterText(
          find.byKey(const Key('registerConfirmPasswordField')), '123456');

      final submitBtn = find.byKey(const Key('registerSubmitButton'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('successful registration invokes sign up', (tester) async {
      await navigateToRegister(tester);

      await tester.enterText(
          find.byKey(const Key('registerFirstNameField')), 'John');
      await tester.enterText(
          find.byKey(const Key('registerLastNameField')), 'Doe');
      await tester.enterText(
          find.byKey(const Key('registerEmailField')), 'john@example.com');
      await tester.enterText(
          find.byKey(const Key('registerPasswordField')), 'password123');
      await tester.enterText(
          find.byKey(const Key('registerConfirmPasswordField')), 'password123');

      final submitBtn = find.byKey(const Key('registerSubmitButton'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.signUpCallCount, 1);
    });

    testWidgets('shows email already in use error', (tester) async {
      fakeRepo.signUpResult = const Err<AuthUser>(EmailAlreadyInUseFailure());

      await navigateToRegister(tester);

      await tester.enterText(
          find.byKey(const Key('registerFirstNameField')), 'John');
      await tester.enterText(
          find.byKey(const Key('registerLastNameField')), 'Doe');
      await tester.enterText(
          find.byKey(const Key('registerEmailField')), 'existing@example.com');
      await tester.enterText(
          find.byKey(const Key('registerPasswordField')), 'password123');
      await tester.enterText(
          find.byKey(const Key('registerConfirmPasswordField')), 'password123');

      final submitBtn = find.byKey(const Key('registerSubmitButton'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('This email address is already in use'), findsOneWidget);
    });
  });
}
