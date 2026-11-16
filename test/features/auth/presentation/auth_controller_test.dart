import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import '../../../helpers/fake_auth_repository.dart';

void main() {
  group('AuthController Tests', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is data(null)', () {
      final state = container.read(authControllerProvider);
      expect(state, const AsyncValue<void>.data(null));
    });

    test('signInWithEmailAndPassword success transitions state to data(null)',
        () async {
      final controller = container.read(authControllerProvider.notifier);

      final result = await controller.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeRepo.signInCallCount, 1);
      expect(
        container.read(authControllerProvider),
        const AsyncValue<void>.data(null),
      );
    });

    test('signInWithEmailAndPassword failure sets error state', () async {
      fakeRepo.signInResult = const Err<AuthUser>(InvalidCredentialsFailure());
      final controller = container.read(authControllerProvider.notifier);

      final result = await controller.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(result.isError, isTrue);
      expect(container.read(authControllerProvider).hasError, isTrue);
    });

    test('signUpWithEmailAndPassword success and error handling', () async {
      final controller = container.read(authControllerProvider.notifier);

      final res1 = await controller.signUpWithEmailAndPassword(
        name: 'Jane',
        surname: 'Doe',
        email: 'jane@example.com',
        password: 'secretpassword',
      );

      expect(res1.isSuccess, isTrue);
      expect(fakeRepo.signUpCallCount, 1);

      fakeRepo.signUpResult = const Err<AuthUser>(EmailAlreadyInUseFailure());
      final res2 = await controller.signUpWithEmailAndPassword(
        name: 'Jane',
        surname: 'Doe',
        email: 'jane@example.com',
        password: 'secretpassword',
      );

      expect(res2.isError, isTrue);
      expect(container.read(authControllerProvider).hasError, isTrue);
    });

    test('signInAnonymously sets guest session', () async {
      final controller = container.read(authControllerProvider.notifier);

      final result = await controller.signInAnonymously();

      expect(result.isSuccess, isTrue);
      expect(fakeRepo.guestCallCount, 1);
    });

    test('linkGuestWithEmailAndPassword preserves UID on success', () async {
      final controller = container.read(authControllerProvider.notifier);

      final result = await controller.linkGuestWithEmailAndPassword(
        name: 'Guest',
        surname: 'User',
        email: 'guest@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeRepo.linkCallCount, 1);
    });

    test('linkGuestWithEmailAndPassword sets error on conflict', () async {
      fakeRepo.linkResult = const Err<AuthUser>(EmailAlreadyInUseFailure());
      final controller = container.read(authControllerProvider.notifier);

      final result = await controller.linkGuestWithEmailAndPassword(
        name: 'Guest',
        surname: 'User',
        email: 'alreadyused@example.com',
        password: 'password123',
      );

      expect(result.isError, isTrue);
      expect(container.read(authControllerProvider).hasError, isTrue);
    });

    test('sendPasswordResetEmail and sendEmailVerification', () async {
      final controller = container.read(authControllerProvider.notifier);

      final resetRes = await controller.sendPasswordResetEmail(
        email: 'test@example.com',
      );
      expect(resetRes.isSuccess, isTrue);
      expect(fakeRepo.resetCallCount, 1);

      final verifyRes = await controller.sendEmailVerification();
      expect(verifyRes.isSuccess, isTrue);
      expect(fakeRepo.verificationCallCount, 1);
    });

    test('reloadUser and signOut', () async {
      final controller = container.read(authControllerProvider.notifier);

      final reloadRes = await controller.reloadUser();
      expect(reloadRes.isSuccess, isTrue);
      expect(fakeRepo.reloadCallCount, 1);

      final signOutRes = await controller.signOut();
      expect(signOutRes.isSuccess, isTrue);
      expect(fakeRepo.signOutCallCount, 1);
    });
  });
}
