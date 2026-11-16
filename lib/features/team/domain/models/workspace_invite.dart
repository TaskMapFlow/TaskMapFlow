import 'package:equatable/equatable.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';

class WorkspaceInvite extends Equatable {
  const WorkspaceInvite({
    required this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.code,
    required this.role,
    required this.creatorId,
    required this.expiresAt,
    this.isRevoked = false,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
  });

  final String id;
  final String workspaceId;
  final String workspaceName;
  final String code;
  final MemberRole role;
  final String creatorId;
  final DateTime expiresAt;
  final bool isRevoked;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isRevoked && usedBy == null && !isExpired;

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        workspaceName,
        code,
        role,
        creatorId,
        expiresAt,
        isRevoked,
        usedBy,
        usedAt,
        createdAt,
      ];
}
