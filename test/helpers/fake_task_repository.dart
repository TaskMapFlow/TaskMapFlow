import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/domain/repositories/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  final Map<String, List<TaskModel>> _tasksByWorkspace = {};
  final Map<String, StreamController<Result<List<TaskModel>>>> _controllers =
      {};

  StreamController<Result<List<TaskModel>>> _getController(String workspaceId) {
    return _controllers.putIfAbsent(
      workspaceId,
      () => StreamController<Result<List<TaskModel>>>.broadcast(),
    );
  }

  void _emit(String workspaceId) {
    final list = _tasksByWorkspace[workspaceId] ?? [];
    final sorted = List<TaskModel>.from(list);
    sorted.sort((a, b) {
      if (a.status == TaskStatus.completed &&
          b.status != TaskStatus.completed) {
        return 1;
      }
      if (a.status != TaskStatus.completed &&
          b.status == TaskStatus.completed) {
        return -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    _getController(workspaceId).add(Success(sorted));
  }

  @override
  Stream<Result<List<TaskModel>>> watchTasks({
    required String workspaceId,
    required String ownerId,
  }) async* {
    final list = _tasksByWorkspace[workspaceId] ?? [];
    yield Success(list.where((t) => t.ownerId == ownerId).toList());
    yield* _getController(workspaceId).stream.map((result) {
      if (result case Success(:final value)) {
        return Success(value.where((t) => t.ownerId == ownerId).toList());
      }
      return result;
    });
  }

  @override
  Future<Result<TaskModel>> createTask({
    required String workspaceId,
    required String ownerId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    final task = TaskModel(
      id: 'task_${now.microsecondsSinceEpoch}',
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title.trim(),
      description: description?.trim() ?? '',
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );

    _tasksByWorkspace.putIfAbsent(workspaceId, () => []).add(task);
    _emit(workspaceId);
    return Success(task);
  }

  @override
  Future<Result<void>> updateTask({
    required String workspaceId,
    required String taskId,
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          title: title.trim(),
          description: description?.trim() ?? '',
          status: status,
          priority: priority,
          dueDate: () => dueDate,
          updatedAt: DateTime.now(),
        );
        _emit(workspaceId);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> updateTaskStatus({
    required String workspaceId,
    required String taskId,
    required TaskStatus status,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        _emit(workspaceId);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteTask({
    required String workspaceId,
    required String taskId,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      list.removeWhere((t) => t.id == taskId);
      _emit(workspaceId);
    }
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasTasks({
    required String workspaceId,
    required String ownerId,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    return Success(list != null && list.any((t) => t.ownerId == ownerId));
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }
}
