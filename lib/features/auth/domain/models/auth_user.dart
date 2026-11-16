import 'package:equatable/equatable.dart';

/// Pure domain entity representing an authenticated user.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isAnonymous,
    required this.isEmailVerified,
  });

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  final bool isEmailVerified;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        isAnonymous,
        isEmailVerified,
      ];
}
