import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/tasks/data/repositories/firebase_task_repository.dart';
import 'package:task_map_flow/features/tasks/domain/models/subtask_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

enum TaskDisplayMode {
  list,
  board,
}

class TaskDisplayModeNotifier extends StateNotifier<TaskDisplayMode> {
  TaskDisplayModeNotifier(this._prefs) : super(_loadInitialMode(_prefs));

  final SharedPreferences _prefs;
  static const _prefKey = 'taskmapflow_task_display_mode';

  static TaskDisplayMode _loadInitialMode(SharedPreferences prefs) {
    final saved = prefs.getString(_prefKey);
    if (saved == 'board') {
      return TaskDisplayMode.board;
    }
    return TaskDisplayMode.list;
  }

  Future<void> setMode(TaskDisplayMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.setString(_prefKey, mode.name);
  }
}

final taskDisplayModeProvider =
    StateNotifierProvider<TaskDisplayModeNotifier, TaskDisplayMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TaskDisplayModeNotifier(prefs);
});

enum TaskFilter {
  all,
  assignedToMe,
  todo,
  inProgress,
  completed;

  bool matches(TaskModel task, [String? currentUid]) => switch (this) {
        TaskFilter.all => true,
        TaskFilter.assignedToMe =>
          currentUid != null && task.assigneeId == currentUid,
        TaskFilter.todo => task.status == TaskStatus.todo,
        TaskFilter.inProgress => task.status == TaskStatus.inProgress,
        TaskFilter.completed => task.status == TaskStatus.completed,
      };
}

enum WorkspaceViewMode {
  tasks,
  backlog,
  sprints,
}

final workspaceViewModeProvider =
    StateProvider.autoDispose.family<WorkspaceViewMode, String>(
  (ref, workspaceId) => WorkspaceViewMode.tasks,
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return FirebaseTaskRepository();
});

final taskFilterProvider =
    StateProvider.autoDispose.family<TaskFilter, String>((ref, workspaceId) {
  return TaskFilter.all;
});

final tasksStreamProvider = StreamProvider.autoDispose
    .family<List<TaskModel>, String>((ref, workspaceId) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty || workspaceId.isEmpty) {
    yield const [];
    return;
  }

  final repo = ref.watch(taskRepositoryProvider);
  final stream = repo.watchTasks(workspaceId: workspaceId, ownerId: uid);

  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

final assignedTasksStreamProvider =
    StreamProvider.autoDispose<List<TaskModel>>((ref) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    yield const [];
    return;
  }

  final repo = ref.watch(taskRepositoryProvider);
  final stream = repo.watchAssignedTasks(uid);

  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

class TaskStats {
  const TaskStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.todo,
    required this.percent,
  });

  final int total;
  final int completed;
  final int inProgress;
  final int todo;
  final int percent;

  bool get isEmpty => total == 0;
}

final taskStatsProvider =
    Provider.autoDispose.family<TaskStats, String>((ref, workspaceId) {
  final tasksAsync = ref.watch(tasksStreamProvider(workspaceId));
  final tasks = tasksAsync.valueOrNull ?? [];

  if (tasks.isEmpty) {
    return const TaskStats(
      total: 0,
      completed: 0,
      inProgress: 0,
      todo: 0,
      percent: 0,
    );
  }

  final total = tasks.length;
  final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
  final inProgress =
      tasks.where((t) => t.status == TaskStatus.inProgress).length;
  final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
  final percent = (completed * 100 ~/ total);

  return TaskStats(
    total: total,
    completed: completed,
    inProgress: inProgress,
    todo: todo,
    percent: percent,
  );
});

final taskControllerProvider =
    StateNotifierProvider<TaskController, AsyncValue<void>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskController(repo);
});

class TaskController extends StateNotifier<AsyncValue<void>> {
  TaskController(this._repository) : super(const AsyncData(null));

  final TaskRepository _repository;

  Future<Result<TaskModel>> createTask({
    required String workspaceId,
    required String ownerId,
    required String title,
    String? description,
    String? sprintId,
    List<SubtaskModel> subtasks = const [],
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String? assigneeId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createTask(
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title,
      description: description,
      sprintId: sprintId,
      subtasks: subtasks,
      status: status,
      priority: priority,
      dueDate: dueDate,
      assigneeId: assigneeId,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateTask({
    required String workspaceId,
    required String taskId,
    required String title,
    String? description,
    String? sprintId,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
    List<SubtaskModel>? subtasks,
    String? assigneeId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateTask(
      workspaceId: workspaceId,
      taskId: taskId,
      title: title,
      description: description,
      sprintId: sprintId,
      status: status,
      priority: priority,
      dueDate: dueDate,
      subtasks: subtasks,
      assigneeId: assigneeId,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateTaskStatus({
    required String workspaceId,
    required String taskId,
    required TaskStatus status,
  }) async {
    final result = await _repository.updateTaskStatus(
      workspaceId: workspaceId,
      taskId: taskId,
      status: status,
    );
    return result;
  }

  Future<Result<void>> deleteTask({
    required String workspaceId,
    required String taskId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.deleteTask(
      workspaceId: workspaceId,
      taskId: taskId,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> assignTaskToSprint({
    required String workspaceId,
    required String taskId,
    required String? sprintId,
  }) async {
    return _repository.assignTaskToSprint(
      workspaceId: workspaceId,
      taskId: taskId,
      sprintId: sprintId,
    );
  }

  Future<Result<void>> moveTasksToBacklog({
    required String workspaceId,
    List<String>? taskIds,
    String? sprintId,
  }) async {
    return _repository.moveTasksToBacklog(
      workspaceId: workspaceId,
      taskIds: taskIds,
      sprintId: sprintId,
    );
  }

  Future<Result<void>> addSubtask({
    required String workspaceId,
    required String taskId,
    required String title,
  }) async {
    return _repository.addSubtask(
      workspaceId: workspaceId,
      taskId: taskId,
      title: title,
    );
  }

  Future<Result<void>> toggleSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
    required bool isCompleted,
  }) async {
    return _repository.toggleSubtask(
      workspaceId: workspaceId,
      taskId: taskId,
      subtaskId: subtaskId,
      isCompleted: isCompleted,
    );
  }

  Future<Result<void>> deleteSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
  }) async {
    return _repository.deleteSubtask(
      workspaceId: workspaceId,
      taskId: taskId,
      subtaskId: subtaskId,
    );
  }
}
