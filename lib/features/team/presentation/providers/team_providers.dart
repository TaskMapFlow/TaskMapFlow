import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/team/data/repositories/firebase_team_repository.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';
import 'package:task_map_flow/features/team/domain/repositories/team_repository.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return FirebaseTeamRepository();
});

final workspaceMembersStreamProvider =
    StreamProvider.family<List<WorkspaceMember>, String>((ref, workspaceId) {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.watchMembers(workspaceId).map((result) => switch (result) {
        Success(:final value) => value,
        Err(:final failure) => throw failure,
      });
});

final currentUserMemberRoleProvider =
    StreamProvider.family<MemberRole?, String>((ref, workspaceId) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    return Stream.value(null);
  }
  final repo = ref.watch(teamRepositoryProvider);
  return repo
      .watchUserMember(workspaceId, uid)
      .map((result) => switch (result) {
            Success(:final value) => value?.role,
            Err(:final failure) => throw failure,
          });
});
