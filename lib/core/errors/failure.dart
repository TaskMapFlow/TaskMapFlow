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
