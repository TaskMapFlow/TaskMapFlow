import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/subtask_model.dart';
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
    String? sprintId,
    List<SubtaskModel> subtasks = const [],
  });

  Future<Result<void>> updateTask({
    required String workspaceId,
    required String taskId,
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
    String? sprintId,
    List<SubtaskModel>? subtasks,
  });

  Future<Result<void>> updateTaskStatus({
    required String workspaceId,
    required String taskId,
    required TaskStatus status,
  });

  Future<Result<void>> toggleSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
    required bool isCompleted,
  });

  Future<Result<void>> addSubtask({
    required String workspaceId,
    required String taskId,
    required String title,
  });

  Future<Result<void>> deleteSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
  });

  Future<Result<void>> assignTaskToSprint({
    required String workspaceId,
    required String taskId,
    required String? sprintId,
  });

  Future<Result<void>> moveTasksToBacklog({
    required String workspaceId,
    List<String>? taskIds,
    String? sprintId,
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
