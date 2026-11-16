import 'package:equatable/equatable.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';

/// Sealed hierarchy representing the authentication status.
sealed class AuthStatus extends Equatable {
  const AuthStatus();

  @override
  List<Object?> get props => [];
}

/// Initial state while determining the session from the stream.
final class AuthInitial extends AuthStatus {
  const AuthInitial();
}

/// No active user session.
final class AuthUnauthenticated extends AuthStatus {
  const AuthUnauthenticated();
}

/// Active session as an anonymous guest.
final class AuthGuest extends AuthStatus {
  const AuthGuest(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// Permanent email account whose email has not yet been verified.
final class AuthUnverified extends AuthStatus {
  const AuthUnverified(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// Permanent email account with verified email.
final class AuthAuthenticated extends AuthStatus {
  const AuthAuthenticated(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// An error occurred during initialization or session check.
final class AuthError extends AuthStatus {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
