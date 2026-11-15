// Domain-layer exception hierarchy. No Firebase types leak here.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

final class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error']);
}

final class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}

final class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation failed']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred']);
}
