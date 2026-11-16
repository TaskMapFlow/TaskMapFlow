import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/subtask_model.dart';
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
    bool isTeam = false,
  }) async* {
    final list = _tasksByWorkspace[workspaceId] ?? [];
    yield Success(list);
    yield* _getController(workspaceId).stream;
  }

  @override
  Stream<Result<List<TaskModel>>> watchAssignedTasks(String userId) async* {
    final all = <TaskModel>[];
    for (final tasks in _tasksByWorkspace.values) {
      all.addAll(tasks.where((t) => t.assigneeId == userId));
    }
    yield Success(all);
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
    String? sprintId,
    List<SubtaskModel> subtasks = const [],
    String? assigneeId,
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
      sprintId: sprintId,
      subtasks: subtasks,
      assigneeId: assigneeId,
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
    String? sprintId,
    List<SubtaskModel>? subtasks,
    String? assigneeId,
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
          sprintId: () => sprintId,
          subtasks: subtasks ?? list[index].subtasks,
          assigneeId: () => assigneeId,
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
  Future<Result<void>> toggleSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
    required bool isCompleted,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final current = list[index];
        final updatedSubtasks = current.subtasks.map((s) {
          if (s.id == subtaskId) return s.copyWith(isCompleted: isCompleted);
          return s;
        }).toList();
        list[index] = current.copyWith(
          subtasks: updatedSubtasks,
          updatedAt: DateTime.now(),
        );
        _emit(workspaceId);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> addSubtask({
    required String workspaceId,
    required String taskId,
    required String title,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final current = list[index];
        final newSubtask = SubtaskModel(
          id: 'subtask_${DateTime.now().microsecondsSinceEpoch}',
          title: title.trim(),
          isCompleted: false,
        );
        list[index] = current.copyWith(
          subtasks: [...current.subtasks, newSubtask],
          updatedAt: DateTime.now(),
        );
        _emit(workspaceId);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final current = list[index];
        list[index] = current.copyWith(
          subtasks: current.subtasks.where((s) => s.id != subtaskId).toList(),
          updatedAt: DateTime.now(),
        );
        _emit(workspaceId);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> assignTaskToSprint({
    required String workspaceId,
    required String taskId,
    required String? sprintId,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          sprintId: () => sprintId,
          updatedAt: DateTime.now(),
        );
        _emit(workspaceId);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> moveTasksToBacklog({
    required String workspaceId,
    List<String>? taskIds,
    String? sprintId,
  }) async {
    final list = _tasksByWorkspace[workspaceId];
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        final shouldMove = (taskIds != null && taskIds.contains(list[i].id)) ||
            (sprintId != null && list[i].sprintId == sprintId);
        if (shouldMove) {
          list[i] = list[i].copyWith(
            sprintId: () => null,
            updatedAt: DateTime.now(),
          );
        }
      }
      _emit(workspaceId);
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
