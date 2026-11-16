import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';

abstract class TaskRepository {
  Stream<Result<List<TaskModel>>> watchTasks({
    required String workspaceId,
    required String ownerId,
  });

  Future<Result<TaskModel>> createTask({
    required String workspaceId,
    required String ownerId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  });

  Future<Result<void>> updateTask({
    required String workspaceId,
    required String taskId,
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
  });

  Future<Result<void>> updateTaskStatus({
    required String workspaceId,
    required String taskId,
    required TaskStatus status,
  });

  Future<Result<void>> deleteTask({
    required String workspaceId,
    required String taskId,
  });

  Future<Result<bool>> hasTasks({
    required String workspaceId,
    required String ownerId,
  });
}
