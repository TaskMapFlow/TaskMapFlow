import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_invite.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';
import 'package:task_map_flow/features/team/domain/repositories/team_repository.dart';

class FakeTeamRepository implements TeamRepository {
  final Map<String, List<WorkspaceMember>> _membersByWorkspace = {};
  final Map<String, StreamController<Result<List<WorkspaceMember>>>>
      _controllers = {};

  StreamController<Result<List<WorkspaceMember>>> _getController(
      String workspaceId) {
    return _controllers.putIfAbsent(
      workspaceId,
      () => StreamController<Result<List<WorkspaceMember>>>.broadcast(),
    );
  }

  void _emit(String workspaceId) {
    final list = _membersByWorkspace[workspaceId] ?? [];
    _getController(workspaceId).add(Success(List.unmodifiable(list)));
  }

  @override
  Stream<Result<List<WorkspaceMember>>> watchMembers(
      String workspaceId) async* {
    yield Success(_membersByWorkspace[workspaceId] ?? []);
    yield* _getController(workspaceId).stream;
  }

  @override
  Future<Result<List<WorkspaceMember>>> getMembers(String workspaceId) async {
    return Success(_membersByWorkspace[workspaceId] ?? []);
  }

  @override
  Stream<Result<WorkspaceMember?>> watchUserMember(
      String workspaceId, String uid) async* {
    final list = _membersByWorkspace[workspaceId] ?? [];
    yield Success(list.where((m) => m.userId == uid).firstOrNull);
    yield* _getController(workspaceId).stream.map((res) {
      if (res case Success(:final value)) {
        return Success(value.where((m) => m.userId == uid).firstOrNull);
      }
      return const Success(null);
    });
  }

  @override
  Future<Result<void>> enableTeamWork({
    required String workspaceId,
    required String ownerUid,
    required String ownerDisplayName,
  }) async {
    final now = DateTime.now();
    final member = WorkspaceMember(
      id: ownerUid,
      workspaceId: workspaceId,
      displayName: ownerDisplayName,
      role: MemberRole.owner,
      joinedAt: now,
      updatedAt: now,
    );
    _membersByWorkspace.putIfAbsent(workspaceId, () => []).add(member);
    _emit(workspaceId);
    return const Success(null);
  }

  @override
  Future<Result<WorkspaceInvite>> createInvite({
    required String workspaceId,
    required String creatorUid,
  }) async {
    final now = DateTime.now();
    final invite = WorkspaceInvite(
      id: 'inv_12345678',
      workspaceId: workspaceId,
      workspaceName: 'Test Area',
      code: 'TESTCODE',
      role: MemberRole.member,
      creatorId: creatorUid,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
    return Success(invite);
  }

  @override
  Future<Result<String>> acceptInvite({
    required String code,
    required String userUid,
    required String userDisplayName,
  }) async {
    return const Success('ws_1');
  }

  @override
  Future<Result<void>> revokeInvite({
    required String workspaceId,
    required String inviteId,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> updateMemberRole({
    required String workspaceId,
    required String targetUid,
    required MemberRole newRole,
  }) async {
    final list = _membersByWorkspace[workspaceId];
    if (list != null) {
      final index = list.indexWhere((m) => m.userId == targetUid);
      if (index != -1) {
        list[index] = list[index].copyWith(role: newRole);
        _emit(workspaceId);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> removeMember({
    required String workspaceId,
    required String targetUid,
  }) async {
    final list = _membersByWorkspace[workspaceId];
    if (list != null) {
      list.removeWhere((m) => m.userId == targetUid);
      _emit(workspaceId);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> leaveTeam({
    required String workspaceId,
    required String userUid,
  }) async {
    return removeMember(workspaceId: workspaceId, targetUid: userUid);
  }
}
