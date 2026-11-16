import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_invite.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';

abstract class TeamRepository {
  Stream<Result<List<WorkspaceMember>>> watchMembers(String workspaceId);

  Future<Result<List<WorkspaceMember>>> getMembers(String workspaceId);

  Stream<Result<WorkspaceMember?>> watchUserMember(
      String workspaceId, String uid);

  Future<Result<void>> enableTeamWork({
    required String workspaceId,
    required String ownerUid,
    required String ownerDisplayName,
  });

  Future<Result<WorkspaceInvite>> createInvite({
    required String workspaceId,
    required String creatorUid,
  });

  Future<Result<String>> acceptInvite({
    required String code,
    required String userUid,
    required String userDisplayName,
  });

  Future<Result<void>> revokeInvite({
    required String workspaceId,
    required String inviteId,
  });

  Future<Result<void>> updateMemberRole({
    required String workspaceId,
    required String targetUid,
    required MemberRole newRole,
  });

  Future<Result<void>> removeMember({
    required String workspaceId,
    required String targetUid,
  });

  Future<Result<void>> leaveTeam({
    required String workspaceId,
    required String userUid,
  });
}
