import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';

void main() {
  group('AuthUser Tests', () {
    test('props equality and attributes', () {
      const u1 = AuthUser(
        id: '123',
        email: 'test@example.com',
        displayName: 'John Doe',
        isAnonymous: false,
        isEmailVerified: true,
      );
      const u2 = AuthUser(
        id: '123',
        email: 'test@example.com',
        displayName: 'John Doe',
        isAnonymous: false,
        isEmailVerified: true,
      );
      const u3 = AuthUser(
        id: '456',
        email: 'test@example.com',
        displayName: 'John Doe',
        isAnonymous: false,
        isEmailVerified: true,
      );

      expect(u1, equals(u2));
      expect(u1, isNot(equals(u3)));
      expect(u1.props, [
        '123',
        'test@example.com',
        'John Doe',
        false,
        true,
      ]);
    });
  });

  group('AuthStatus Tests', () {
    const user = AuthUser(
      id: '123',
      email: 'a@b.com',
      displayName: 'Name',
      isAnonymous: false,
      isEmailVerified: false,
    );

    test('AuthInitial equality', () {
      expect(const AuthInitial(), equals(const AuthInitial()));
    });

    test('AuthUnauthenticated equality', () {
      expect(const AuthUnauthenticated(), equals(const AuthUnauthenticated()));
    });

    test('AuthGuest equality', () {
      const guestUser = AuthUser(
        id: 'g1',
        email: null,
        displayName: null,
        isAnonymous: true,
        isEmailVerified: false,
      );
      expect(const AuthGuest(guestUser), equals(const AuthGuest(guestUser)));
    });

    test('AuthUnverified equality', () {
      expect(const AuthUnverified(user), equals(const AuthUnverified(user)));
    });

    test('AuthAuthenticated equality', () {
      const verifiedUser = AuthUser(
        id: '123',
        email: 'a@b.com',
        displayName: 'Name',
        isAnonymous: false,
        isEmailVerified: true,
      );
      expect(
        const AuthAuthenticated(verifiedUser),
        equals(const AuthAuthenticated(verifiedUser)),
      );
    });

    test('AuthError equality', () {
      expect(const AuthError('Network timeout'),
          equals(const AuthError('Network timeout')));
      expect(const AuthError('err1'), isNot(equals(const AuthError('err2'))));
    });
  });
}
