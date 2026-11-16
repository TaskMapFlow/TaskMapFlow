import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

/// Available view modes for the Home screen.
enum HomeViewMode { map, overview }

/// Persisted view mode notifier.
class HomeViewModeNotifier extends StateNotifier<HomeViewMode> {
  HomeViewModeNotifier(this._prefs) : super(_loadInitialMode(_prefs));

  final SharedPreferences _prefs;
  static const _prefKey = 'taskmapflow_home_view_mode';

  static HomeViewMode _loadInitialMode(SharedPreferences prefs) {
    final saved = prefs.getString(_prefKey);
    if (saved == 'overview') {
      return HomeViewMode.overview;
    }
    return HomeViewMode.map;
  }

  Future<void> setViewMode(HomeViewMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.setString(_prefKey, mode.name);
  }
}

final homeViewModeProvider =
    StateNotifierProvider<HomeViewModeNotifier, HomeViewMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HomeViewModeNotifier(prefs);
});

/// Date anchor that emits today's calendar date in local timezone,
/// refreshing whenever the app is resumed from background or crosses midnight.
class OverviewDateAnchorNotifier extends StateNotifier<DateTime>
    with WidgetsBindingObserver {
  OverviewDateAnchorNotifier() : super(_todayDate()) {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _checkDate());
  }

  Timer? _timer;

  static DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _checkDate() {
    final today = _todayDate();
    if (!state.isAtSameMomentAs(today)) {
      state = today;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final overviewDateAnchorProvider =
    StateNotifierProvider.autoDispose<OverviewDateAnchorNotifier, DateTime>(
        (ref) {
  return OverviewDateAnchorNotifier();
});

/// Pairs a task with its parent workspace.
class TaskWithWorkspace {
  const TaskWithWorkspace({
    required this.task,
    required this.workspace,
  });

  final TaskModel task;
  final Workspace workspace;
}

/// Workspace with calculated task completion progress.
class WorkspaceProgress {
  const WorkspaceProgress({
    required this.workspace,
    required this.totalTasks,
    required this.completedTasks,
  });

  final Workspace workspace;
  final int totalTasks;
  final int completedTasks;

  double get progress => totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
}

/// Aggregate model holding the daily work summary.
class DailyWorkSummary {
  const DailyWorkSummary({
    this.todayTasks = const [],
    this.overdueTasks = const [],
    this.upcomingTasks = const [],
    this.inProgressTasks = const [],
    this.activeWorkspaces = const [],
    this.failedWorkspaces = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isPartial = false,
    this.totalActiveWorkspacesCount = 0,
  });

  final List<TaskWithWorkspace> todayTasks;
  final List<TaskWithWorkspace> overdueTasks;
  final List<TaskWithWorkspace> upcomingTasks;
  final List<TaskWithWorkspace> inProgressTasks;
  final List<WorkspaceProgress> activeWorkspaces;
  final List<Workspace> failedWorkspaces;
  final bool isLoading;
  final String? errorMessage;
  final bool isPartial;
  final int totalActiveWorkspacesCount;

  bool get isEmpty =>
      activeWorkspaces.isEmpty &&
      failedWorkspaces.isEmpty &&
      todayTasks.isEmpty &&
      overdueTasks.isEmpty &&
      upcomingTasks.isEmpty &&
      inProgressTasks.isEmpty;
}

/// Helper to convert a stored UTC due date into a local calendar-only DateTime.
DateTime _toCalendarDay(DateTime dueDate) {
  // Due dates are stored as UTC year, month, day
  return DateTime(dueDate.year, dueDate.month, dueDate.day);
}

/// Auto-disposable provider for daily work summary.
/// When Overview is not rendered, it auto-disposes and cancels all underlying subscriptions.
final dailyWorkSummaryProvider = Provider.autoDispose<DailyWorkSummary>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    return const DailyWorkSummary();
  }

  final today = ref.watch(overviewDateAnchorProvider);
  final sevenDaysAhead = today.add(const Duration(days: 8)); // exclusive bound

  final workspacesAsync = ref.watch(workspacesStreamProvider);
  if (workspacesAsync.isLoading && !workspacesAsync.hasValue) {
    return const DailyWorkSummary(isLoading: true);
  }
  if (workspacesAsync.hasError && !workspacesAsync.hasValue) {
    debugPrint(
        '[DailyWorkSummary] workspacesStreamProvider error: ${workspacesAsync.error}');
    return DailyWorkSummary(
      isLoading: false,
      errorMessage: workspacesAsync.error.toString(),
    );
  }

  final allWorkspaces = workspacesAsync.value ?? [];
  // Strictly owned active workspaces only, matching personal access rules
  final ownedActiveWorkspaces =
      allWorkspaces.where((w) => !w.isArchived && w.ownerId == uid).toList();

  if (ownedActiveWorkspaces.isEmpty) {
    return const DailyWorkSummary(isLoading: false);
  }

  // To prevent unbounded loading with dozens of workspaces, limit to the most recent 25 active spaces
  final isPartial = ownedActiveWorkspaces.length > 25;
  final targetWorkspaces = ownedActiveWorkspaces.take(25).toList();

  final taskAsyncList = [
    for (final ws in targetWorkspaces) ref.watch(tasksStreamProvider(ws.id))
  ];

  final anyInitialLoading =
      taskAsyncList.any((a) => a.isLoading && !a.hasValue);
  if (anyInitialLoading) {
    return const DailyWorkSummary(isLoading: true);
  }

  // If ALL target workspaces failed with error and none succeeded
  final allFailed = taskAsyncList.isNotEmpty &&
      taskAsyncList.every((a) => a.hasError && !a.hasValue);
  if (allFailed) {
    final firstErr = taskAsyncList.first.error;
    debugPrint(
        '[DailyWorkSummary] All ${targetWorkspaces.length} workspaces failed to load tasks: $firstErr');
    return DailyWorkSummary(
      isLoading: false,
      errorMessage: firstErr.toString(),
      failedWorkspaces: targetWorkspaces,
      isPartial: isPartial,
      totalActiveWorkspacesCount: ownedActiveWorkspaces.length,
    );
  }

  final failedWorkspaces = <Workspace>[];
  final todayTasks = <TaskWithWorkspace>[];
  final overdueTasks = <TaskWithWorkspace>[];
  final upcomingTasks = <TaskWithWorkspace>[];
  final inProgressTasks = <TaskWithWorkspace>[];
  final progressList = <WorkspaceProgress>[];

  for (int i = 0; i < targetWorkspaces.length; i++) {
    final ws = targetWorkspaces[i];
    final asyncTasks = taskAsyncList[i];

    if (asyncTasks.hasError && !asyncTasks.hasValue) {
      debugPrint(
          '[DailyWorkSummary] Failed to load tasks for workspace=${ws.id}: ${asyncTasks.error}');
      failedWorkspaces.add(ws);
      continue;
    }

    final tasks = asyncTasks.valueOrNull ?? [];

    final total = tasks.length;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    progressList.add(WorkspaceProgress(
      workspace: ws,
      totalTasks: total,
      completedTasks: completed,
    ));

    for (final task in tasks) {
      final pair = TaskWithWorkspace(task: task, workspace: ws);

      // In Progress tasks
      if (task.status == TaskStatus.inProgress) {
        inProgressTasks.add(pair);
      }

      // Incompleted tasks with due date
      if (task.status != TaskStatus.completed && task.dueDate != null) {
        final taskDay = _toCalendarDay(task.dueDate!);

        if (taskDay.isAtSameMomentAs(today)) {
          todayTasks.add(pair);
        } else if (taskDay.isBefore(today)) {
          overdueTasks.add(pair);
        } else if (taskDay.isAfter(today) && taskDay.isBefore(sevenDaysAhead)) {
          upcomingTasks.add(pair);
        }
      }
    }
  }

  // Sort tasks in each bucket
  // Overdue: most overdue first
  overdueTasks.sort((a, b) => a.task.dueDate!.compareTo(b.task.dueDate!));
  // Today: priority high -> low
  todayTasks
      .sort((a, b) => b.task.priority.index.compareTo(a.task.priority.index));
  // Upcoming: earliest due first
  upcomingTasks.sort((a, b) => a.task.dueDate!.compareTo(b.task.dueDate!));
  // In progress: priority or latest update
  inProgressTasks.sort((a, b) => b.task.updatedAt.compareTo(a.task.updatedAt));

  return DailyWorkSummary(
    todayTasks: todayTasks,
    overdueTasks: overdueTasks,
    upcomingTasks: upcomingTasks,
    inProgressTasks: inProgressTasks,
    activeWorkspaces: progressList,
    failedWorkspaces: failedWorkspaces,
    isLoading: false,
    isPartial: isPartial,
    totalActiveWorkspacesCount: ownedActiveWorkspaces.length,
  );
});
