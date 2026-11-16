import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';

abstract class SprintRepository {
  Stream<Result<List<SprintModel>>> watchSprints({
    required String workspaceId,
    required String ownerId,
  });

  Future<Result<SprintModel>> createSprint({
    required String workspaceId,
    required String ownerId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    SprintStatus status = SprintStatus.planned,
  });

  Future<Result<void>> updateSprint({
    required String workspaceId,
    required String sprintId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    required SprintStatus status,
  });

  Future<Result<void>> updateSprintStatus({
    required String workspaceId,
    required String sprintId,
    required SprintStatus status,
  });

  Future<Result<void>> deleteSprint({
    required String workspaceId,
    required String sprintId,
  });

  Future<Result<bool>> hasSprints({
    required String workspaceId,
    required String ownerId,
  });
}
