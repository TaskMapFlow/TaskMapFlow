import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';
import 'package:task_map_flow/features/tasks/domain/repositories/sprint_repository.dart';

class FakeSprintRepository implements SprintRepository {
  final Map<String, List<SprintModel>> _sprintsByWorkspace = {};

  @override
  Stream<Result<List<SprintModel>>> watchSprints({
    required String workspaceId,
    required String ownerId,
  }) async* {
    final list = _sprintsByWorkspace[workspaceId] ?? [];
    yield Success(list.where((s) => s.ownerId == ownerId).toList());
  }

  @override
  Future<Result<bool>> hasSprints({
    required String workspaceId,
    required String ownerId,
  }) async {
    final list = _sprintsByWorkspace[workspaceId] ?? [];
    return Success(list.where((s) => s.ownerId == ownerId).isNotEmpty);
  }

  @override
  Future<Result<SprintModel>> createSprint({
    required String workspaceId,
    required String ownerId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    SprintStatus status = SprintStatus.planned,
  }) async {
    final now = DateTime.now();
    final list = _sprintsByWorkspace.putIfAbsent(workspaceId, () => []);
    final sprint = SprintModel(
      id: 'sprint_${list.length + 1}',
      workspaceId: workspaceId,
      ownerId: ownerId,
      name: name,
      goal: goal ?? '',
      startDate: startDate,
      endDate: endDate,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    list.add(sprint);
    return Success(sprint);
  }

  @override
  Future<Result<void>> updateSprint({
    required String workspaceId,
    required String sprintId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    required SprintStatus status,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSprintStatus({
    required String workspaceId,
    required String sprintId,
    required SprintStatus status,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteSprint({
    required String workspaceId,
    required String sprintId,
  }) async {
    final list = _sprintsByWorkspace[workspaceId];
    if (list != null) {
      list.removeWhere((s) => s.id == sprintId);
    }
    return const Success(null);
  }
}
