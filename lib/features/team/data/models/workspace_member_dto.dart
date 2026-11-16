import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';

class WorkspaceMemberDto {
  static WorkspaceMember fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, [
    String? workspaceId,
  ]) {
    final data = doc.data() ?? {};
    final joinedAt =
        (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? joinedAt;
    final wsId = workspaceId ??
        (data['workspaceId'] as String?) ??
        doc.reference.parent.parent?.id ??
        '';

    return WorkspaceMember(
      id: doc.id,
      workspaceId: wsId,
      displayName: data['displayName'] as String? ?? '',
      role: MemberRole.fromString(data['role'] as String?),
      joinedAt: joinedAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(WorkspaceMember member) {
    return {
      'uid': member.id,
      'displayName': member.displayName,
      'role': member.role.toFirestoreString(),
      'joinedAt': Timestamp.fromDate(member.joinedAt),
      'updatedAt': Timestamp.fromDate(member.updatedAt),
    };
  }
}
