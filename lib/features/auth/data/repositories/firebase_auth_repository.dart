import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] backed by Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _firebaseAuth;

  AuthUser _mapFirebaseUser(fb.User user) {
    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
    );
  }

  Failure _mapAuthException(
    fb.FirebaseAuthException e, {
    bool isSignInOrReset = false,
  }) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'credential-already-in-use':
        return const CredentialAlreadyInUseFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return AuthFailure(e.message ?? 'Authentication error');
    }
  }

  @override
  Stream<AuthStatus> get authStateChanges {
    return _firebaseAuth.userChanges().map<AuthStatus>((fb.User? user) {
      if (user == null) {
        return const AuthUnauthenticated();
      }
      final domainUser = _mapFirebaseUser(user);
      if (user.isAnonymous) {
        return AuthGuest(domainUser);
      }
      if (!user.emailVerified) {
        return AuthUnverified(domainUser);
      }
      return AuthAuthenticated(domainUser);
    }).handleError((Object error) {
      return AuthError(error.toString());
    });
  }

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Err(InvalidCredentialsFailure());
      }
      return Success(_mapFirebaseUser(user));
    } on fb.FirebaseAuthException catch (e) {
      return Err(_mapAuthException(e, isSignInOrReset: true));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Err(AuthFailure('Failed to create account'));
      }

      final fullName = '$name $surname'.trim();
      if (fullName.isNotEmpty) {
        try {
          await user.updateDisplayName(fullName);
        } catch (e) {
          debugPrint(
            '[AuthRepository] Failed to update displayName during signup: $e',
          );
        }
      }

      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint(
          '[AuthRepository] Failed to send email verification during signup: $e',
        );
      }

      return Success(_mapFirebaseUser(user));
    } on fb.FirebaseAuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _firebaseAuth.sendPasswordResetEmail(email: normalizedEmail);
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Prevent email enumeration
        return const Success(null);
      }
      return Err(_mapAuthException(e, isSignInOrReset: true));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const Err(AuthFailure('No active user'));
    }
    try {
      await user.sendEmailVerification();
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser>> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const Err(AuthFailure('No active user'));
    }
    try {
      await user.reload();
      final updated = _firebaseAuth.currentUser ?? user;
      return Success(_mapFirebaseUser(updated));
    } on fb.FirebaseAuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        return const Err(AuthFailure('Failed to start guest session'));
      }
      return Success(_mapFirebaseUser(user));
    } on fb.FirebaseAuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser>> linkGuestWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return const Err(AuthFailure('No active user session to link'));
    }
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = fb.EmailAuthProvider.credential(
        email: normalizedEmail,
        password: password,
      );
      final userCredential = await currentUser.linkWithCredential(credential);
      final linkedUser = userCredential.user ?? currentUser;

      final fullName = '$name $surname'.trim();
      if (fullName.isNotEmpty) {
        try {
          await linkedUser.updateDisplayName(fullName);
        } catch (e) {
          debugPrint(
            '[AuthRepository] Failed to update displayName during link: $e',
          );
        }
      }

      try {
        await linkedUser.sendEmailVerification();
      } catch (e) {
        debugPrint(
          '[AuthRepository] Failed to send email verification during link: $e',
        );
      }

      return Success(_mapFirebaseUser(linkedUser));
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use') {
        return const Err(
          EmailAlreadyInUseFailure(
            'This email is already registered. Automatic merging is disabled for security.',
          ),
        );
      }
      return Err(_mapAuthException(e));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
