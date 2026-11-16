import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';

/// Pure domain contract for authentication operations.
abstract interface class AuthRepository {
  /// Stream emitting changes to the current authentication status.
  Stream<AuthStatus> get authStateChanges;

  /// Current user snapshot if available.
  AuthUser? get currentUser;

  /// Sign in with email and password.
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Create a new account with email, password, and initial name.
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  });

  /// Send password reset email to the specified address.
  Future<Result<void>> sendPasswordResetEmail({
    required String email,
  });

  /// Send email verification to the currently logged in user.
  Future<Result<void>> sendEmailVerification();

  /// Reload the current user to refresh fields such as emailVerified.
  Future<Result<AuthUser>> reloadUser();

  /// Sign in anonymously as a guest.
  Future<Result<AuthUser>> signInAnonymously();

  /// Link an existing guest user to email and password credentials,
  /// preserving the same user ID (UID).
  Future<Result<AuthUser>> linkGuestWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  });

  /// Sign out the current user session.
  Future<Result<void>> signOut();
}
