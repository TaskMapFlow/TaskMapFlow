import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthStatus initialStatus = const AuthUnauthenticated(),
    this.signInResult,
    this.signUpResult,
    this.guestResult,
    this.linkResult,
    this.resetResult,
    this.verificationResult,
    this.reloadResult,
    this.signOutResult,
  }) : _currentStatus = initialStatus {
    _controller = StreamController<AuthStatus>.broadcast();
  }

  AuthStatus _currentStatus;
  late final StreamController<AuthStatus> _controller;
  AuthUser? _user;

  Result<AuthUser>? signInResult;
  Result<AuthUser>? signUpResult;
  Result<AuthUser>? guestResult;
  Result<AuthUser>? linkResult;
  Result<void>? resetResult;
  Result<void>? verificationResult;
  Result<AuthUser>? reloadResult;
  Result<void>? signOutResult;

  int signInCallCount = 0;
  int signUpCallCount = 0;
  int guestCallCount = 0;
  int linkCallCount = 0;
  int resetCallCount = 0;
  int verificationCallCount = 0;
  int reloadCallCount = 0;
  int signOutCallCount = 0;

  void setStatus(AuthStatus status) {
    _currentStatus = status;
    _controller.add(status);
  }

  @override
  Stream<AuthStatus> get authStateChanges async* {
    yield _currentStatus;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    final res = signInResult ??
        Success(AuthUser(
          id: 'test-user-id',
          email: email,
          displayName: 'Test User',
          isAnonymous: false,
          isEmailVerified: true,
        ));
    if (res is Success<AuthUser>) {
      _user = res.value;
      setStatus(AuthAuthenticated(res.value));
    }
    return res;
  }

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    signUpCallCount++;
    final res = signUpResult ??
        Success(AuthUser(
          id: 'new-user-id',
          email: email,
          displayName: '$name $surname'.trim(),
          isAnonymous: false,
          isEmailVerified: false,
        ));
    if (res is Success<AuthUser>) {
      _user = res.value;
      setStatus(AuthUnverified(res.value));
    }
    return res;
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    guestCallCount++;
    final res = guestResult ??
        const Success(AuthUser(
          id: 'guest-uid',
          email: null,
          displayName: null,
          isAnonymous: true,
          isEmailVerified: false,
        ));
    if (res is Success<AuthUser>) {
      _user = res.value;
      setStatus(AuthGuest(res.value));
    }
    return res;
  }

  @override
  Future<Result<AuthUser>> linkGuestWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    linkCallCount++;
    final res = linkResult ??
        Success(AuthUser(
          id: _user?.id ?? 'guest-uid',
          email: email,
          displayName: '$name $surname'.trim(),
          isAnonymous: false,
          isEmailVerified: false,
        ));
    if (res is Success<AuthUser>) {
      _user = res.value;
      setStatus(AuthUnverified(res.value));
    }
    return res;
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    resetCallCount++;
    return resetResult ?? const Success(null);
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    verificationCallCount++;
    return verificationResult ?? const Success(null);
  }

  @override
  Future<Result<AuthUser>> reloadUser() async {
    reloadCallCount++;
    final res = reloadResult ??
        Success(AuthUser(
          id: _user?.id ?? 'test-uid',
          email: _user?.email ?? 'test@example.com',
          displayName: _user?.displayName ?? 'Test User',
          isAnonymous: false,
          isEmailVerified: true,
        ));
    if (res is Success<AuthUser>) {
      _user = res.value;
      if (res.value.isEmailVerified) {
        setStatus(AuthAuthenticated(res.value));
      }
    }
    return res;
  }

  @override
  Future<Result<void>> signOut() async {
    signOutCallCount++;
    final res = signOutResult ?? const Success(null);
    if (res is Success<void>) {
      _user = null;
      setStatus(const AuthUnauthenticated());
    }
    return res;
  }
}
