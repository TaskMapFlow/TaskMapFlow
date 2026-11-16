import 'package:equatable/equatable.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';

class WorkspaceMember extends Equatable {
  const WorkspaceMember({
    required this.id,
    required this.workspaceId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    required this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String displayName;
  final MemberRole role;
  final DateTime joinedAt;
  final DateTime updatedAt;

  String get userId => id;

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

  WorkspaceMember copyWith({
    String? id,
    String? workspaceId,
    String? displayName,
    MemberRole? role,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return WorkspaceMember(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        displayName,
        role,
        joinedAt,
        updatedAt,
      ];
}
