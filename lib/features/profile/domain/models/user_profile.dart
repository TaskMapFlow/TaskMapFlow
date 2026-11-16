import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.bio = '',
    this.githubUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String bio;
  final String githubUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  static bool isValidGithubUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return true;
    if (!trimmed.startsWith('https://')) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host != 'github.com' && host != 'www.github.com') return false;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;
    final username = segments.first;
    final githubUserRegex =
        RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$');
    return githubUserRegex.hasMatch(username);
  }

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    final parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? bio,
    String? githubUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      githubUrl: githubUrl ?? this.githubUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        bio,
        githubUrl,
        createdAt,
        updatedAt,
      ];
}
