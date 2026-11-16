// Failure value objects returned from repository implementations.
import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication required']);
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure(
      [super.message = 'Invalid email or password']);
}

final class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([super.message = 'Email is already in use']);
}

final class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure([super.message = 'Password is too weak']);
}

final class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure(
      [super.message = 'Too many requests. Please try again later.']);
}

final class CredentialAlreadyInUseFailure extends Failure {
  const CredentialAlreadyInUseFailure(
      [super.message = 'Credential already in use']);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
