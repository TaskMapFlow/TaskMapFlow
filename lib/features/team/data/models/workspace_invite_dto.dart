import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_invite.dart';

class WorkspaceInviteDto {
  static WorkspaceInvite fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final expiresAt =
        (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final usedAt = (data['usedAt'] as Timestamp?)?.toDate();

    return WorkspaceInvite(
      id: doc.id,
      workspaceId: data['workspaceId'] as String? ?? '',
      workspaceName: data['workspaceName'] as String? ?? '',
      code: data['code'] as String? ?? '',
      role: MemberRole.fromString(data['role'] as String?),
      creatorId: data['creatorId'] as String? ?? '',
      expiresAt: expiresAt,
      isRevoked: data['isRevoked'] as bool? ?? false,
      usedBy: data['usedBy'] as String?,
      usedAt: usedAt,
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic> toFirestore(WorkspaceInvite invite) {
    return {
      'id': invite.id,
      'workspaceId': invite.workspaceId,
      'workspaceName': invite.workspaceName,
      'code': invite.code,
      'role': invite.role.toFirestoreString(),
      'creatorId': invite.creatorId,
      'expiresAt': Timestamp.fromDate(invite.expiresAt),
      'isRevoked': invite.isRevoked,
      'usedBy': invite.usedBy,
      'usedAt':
          invite.usedAt != null ? Timestamp.fromDate(invite.usedAt!) : null,
      'createdAt': Timestamp.fromDate(invite.createdAt),
    };
  }
}
