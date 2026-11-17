import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

/// Available view modes for the Manage screen.
enum ManageViewMode {
  workspaces,
  calendar,
}

/// Persisted Manage screen view mode notifier.
class ManageViewModeNotifier extends StateNotifier<ManageViewMode> {
  ManageViewModeNotifier(this._prefs) : super(_loadInitialMode(_prefs));

  final SharedPreferences _prefs;
  static const _prefKey = 'taskmapflow_manage_view_mode';

  static ManageViewMode _loadInitialMode(SharedPreferences prefs) {
    final saved = prefs.getString(_prefKey);
    if (saved == 'calendar') {
      return ManageViewMode.calendar;
    }
    return ManageViewMode.workspaces;
  }

  Future<void> setViewMode(ManageViewMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.setString(_prefKey, mode.name);
  }
}

final manageViewModeProvider =
    StateNotifierProvider<ManageViewModeNotifier, ManageViewMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ManageViewModeNotifier(prefs);
});

/// Types of entries that appear in the calendar and agenda.
enum CalendarEntryType {
  task,
  studySession,
}

/// Unified entry model for tasks and study sessions in the calendar.
class CalendarItem {
  const CalendarItem.task({
    required this.task,
    required this.workspace,
    required this.calendarDay,
  })  : type = CalendarEntryType.task,
        session = null,
        localScheduledAt = null;

  const CalendarItem.studySession({
    required this.session,
    required this.workspace,
    required this.calendarDay,
    required this.localScheduledAt,
  })  : type = CalendarEntryType.studySession,
        task = null;

  final CalendarEntryType type;
  final TaskModel? task;
  final StudySessionModel? session;
  final Workspace workspace;
  final DateTime calendarDay; // Year, Month, Day only
  final DateTime? localScheduledAt; // Local time for study sessions

  bool get isCompleted => type == CalendarEntryType.task
      ? task!.status == TaskStatus.completed
      : session!.isCompleted;

  String get title =>
      type == CalendarEntryType.task ? task!.title : session!.title;

  String get id => type == CalendarEntryType.task ? task!.id : session!.id;
}

/// State for the calendar navigation (displayed month and selected date).
class CalendarDateState {
  const CalendarDateState({
    required this.displayedMonth,
    required this.selectedDay,
    this.showCompleted = true,
  });

  final DateTime displayedMonth; // Year, Month, 1
  final DateTime selectedDay; // Year, Month, Day
  final bool showCompleted;

  CalendarDateState copyWith({
    DateTime? displayedMonth,
    DateTime? selectedDay,
    bool? showCompleted,
  }) {
    return CalendarDateState(
      displayedMonth: displayedMonth ?? this.displayedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      showCompleted: showCompleted ?? this.showCompleted,
    );
  }
}

/// Manages calendar month navigation and selected day, with lifecycle observation
/// to keep today consistent across midnight transitions.
class CalendarDateNotifier extends StateNotifier<CalendarDateState>
    with WidgetsBindingObserver {
  CalendarDateNotifier() : super(_initialState()) {
    WidgetsBinding.instance.addObserver(this);
    _timer =
        Timer.periodic(const Duration(minutes: 5), (_) => _checkMidnight());
  }

  Timer? _timer;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static CalendarDateState _initialState() {
    final today = _today();
    return CalendarDateState(
      displayedMonth: DateTime(today.year, today.month, 1),
      selectedDay: today,
      showCompleted: true,
    );
  }

  void _checkMidnight() {
    final today = _today();
    // If today changed and the previously selected date was today, advance it
    final currentSelected = state.selectedDay;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (currentSelected.isAtSameMomentAs(yesterday)) {
      state = state.copyWith(selectedDay: today);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMidnight();
    }
  }

  void selectDay(DateTime day) {
    final calendarDay = DateTime(day.year, day.month, day.day);
    final month = DateTime(calendarDay.year, calendarDay.month, 1);
    state = state.copyWith(
      selectedDay: calendarDay,
      displayedMonth: month,
    );
  }

  void previousMonth() {
    final prev =
        DateTime(state.displayedMonth.year, state.displayedMonth.month - 1, 1);
    // Keep selectedDay if it is inside the new month; otherwise select 1st of new month
    DateTime newSelected = state.selectedDay;
    if (newSelected.year != prev.year || newSelected.month != prev.month) {
      newSelected = prev;
    }
    state = state.copyWith(
      displayedMonth: prev,
      selectedDay: newSelected,
    );
  }

  void nextMonth() {
    final next =
        DateTime(state.displayedMonth.year, state.displayedMonth.month + 1, 1);
    DateTime newSelected = state.selectedDay;
    if (newSelected.year != next.year || newSelected.month != next.month) {
      newSelected = next;
    }
    state = state.copyWith(
      displayedMonth: next,
      selectedDay: newSelected,
    );
  }

  void jumpToToday() {
    final today = _today();
    state = state.copyWith(
      displayedMonth: DateTime(today.year, today.month, 1),
      selectedDay: today,
    );
  }

  void toggleShowCompleted() {
    state = state.copyWith(showCompleted: !state.showCompleted);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final manageCalendarDateProvider =
    StateNotifierProvider.autoDispose<CalendarDateNotifier, CalendarDateState>(
        (ref) {
  return CalendarDateNotifier();
});

/// Aggregate summary of calendar entries for the Manage calendar view.
class ManageCalendarSummary {
  const ManageCalendarSummary({
    this.allItems = const [],
    this.itemsByDay = const {},
    this.selectedDayItems = const [],
    this.failedWorkspaces = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isPartial = false,
    this.totalActiveWorkspacesCount = 0,
  });

  final List<CalendarItem> allItems;
  final Map<DateTime, List<CalendarItem>> itemsByDay;
  final List<CalendarItem> selectedDayItems;
  final List<Workspace> failedWorkspaces;
  final bool isLoading;
  final String? errorMessage;
  final bool isPartial;
  final int totalActiveWorkspacesCount;

  bool get isEmpty => allItems.isEmpty && failedWorkspaces.isEmpty;
}

/// Auto-disposed provider aggregating tasks and study sessions for the Calendar view.
/// Subscriptions are cleanly cancelled when Calendar is not rendered.
final manageCalendarSummaryProvider =
    Provider.autoDispose<ManageCalendarSummary>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    return const ManageCalendarSummary();
  }

  final dateState = ref.watch(manageCalendarDateProvider);
  final workspacesAsync = ref.watch(workspacesStreamProvider);

  if (workspacesAsync.isLoading && !workspacesAsync.hasValue) {
    return const ManageCalendarSummary(isLoading: true);
  }
  if (workspacesAsync.hasError && !workspacesAsync.hasValue) {
    debugPrint(
        '[ManageCalendarSummary] workspaces error: ${workspacesAsync.error}');
    return ManageCalendarSummary(
      isLoading: false,
      errorMessage: workspacesAsync.error.toString(),
    );
  }

  final allWorkspaces = workspacesAsync.value ?? [];
  // Strictly owned active workspaces only, matching personal access rules
  final ownedActiveWorkspaces =
      allWorkspaces.where((w) => !w.isArchived && w.ownerId == uid).toList();

  if (ownedActiveWorkspaces.isEmpty) {
    return const ManageCalendarSummary(isLoading: false);
  }

  // To prevent unbounded loading with dozens of workspaces, limit to 25 active spaces
  final isPartial = ownedActiveWorkspaces.length > 25;
  final targetWorkspaces = ownedActiveWorkspaces.take(25).toList();

  // Watch tasks for all target workspaces
  final taskAsyncList = [
    for (final ws in targetWorkspaces) ref.watch(tasksStreamProvider(ws.id))
  ];

  // Watch study sessions for lesson workspaces
  final lessonWorkspaces =
      targetWorkspaces.where((w) => w.type == WorkspaceType.lesson).toList();
  final sessionAsyncList = [
    for (final ws in lessonWorkspaces)
      ref.watch(studySessionsStreamProvider(ws.id))
  ];

  final anyTaskLoading = taskAsyncList.any((a) => a.isLoading && !a.hasValue);
  final anySessionLoading =
      sessionAsyncList.any((a) => a.isLoading && !a.hasValue);

  if (anyTaskLoading || anySessionLoading) {
    return const ManageCalendarSummary(isLoading: true);
  }

  final failedWorkspaces = <Workspace>[];
  final allItems = <CalendarItem>[];
  final itemsByDay = <DateTime, List<CalendarItem>>{};

  // Process tasks
  for (int i = 0; i < targetWorkspaces.length; i++) {
    final ws = targetWorkspaces[i];
    final asyncTasks = taskAsyncList[i];

    if (asyncTasks.hasError && !asyncTasks.hasValue) {
      debugPrint(
          '[ManageCalendarSummary] Failed tasks for ws=${ws.id}: ${asyncTasks.error}');
      if (!failedWorkspaces.contains(ws)) {
        failedWorkspaces.add(ws);
      }
      continue;
    }

    final tasks = asyncTasks.valueOrNull ?? [];
    for (final task in tasks) {
      if (task.dueDate != null) {
        // Date-based task: extract registered calendar day
        final day = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        final item = CalendarItem.task(
          task: task,
          workspace: ws,
          calendarDay: day,
        );
        allItems.add(item);
        itemsByDay.putIfAbsent(day, () => []).add(item);
      }
    }
  }

  // Process study sessions for lesson workspaces
  for (int i = 0; i < lessonWorkspaces.length; i++) {
    final ws = lessonWorkspaces[i];
    final asyncSessions = sessionAsyncList[i];

    if (asyncSessions.hasError && !asyncSessions.hasValue) {
      debugPrint(
          '[ManageCalendarSummary] Failed sessions for ws=${ws.id}: ${asyncSessions.error}');
      if (!failedWorkspaces.contains(ws)) {
        failedWorkspaces.add(ws);
      }
      continue;
    }

    final sessions = asyncSessions.valueOrNull ?? [];
    for (final session in sessions) {
      // Time-based session: convert to local time
      final localScheduled = session.scheduledAt.toLocal();
      final day = DateTime(
        localScheduled.year,
        localScheduled.month,
        localScheduled.day,
      );
      final item = CalendarItem.studySession(
        session: session,
        workspace: ws,
        calendarDay: day,
        localScheduledAt: localScheduled,
      );
      allItems.add(item);
      itemsByDay.putIfAbsent(day, () => []).add(item);
    }
  }

  // Filter items for the selected day
  final selectedDay = dateState.selectedDay;
  final dayEntries = itemsByDay[selectedDay] ?? const [];
  final selectedDayItems = dayEntries.where((item) {
    if (!dateState.showCompleted && item.isCompleted) {
      return false;
    }
    return true;
  }).toList();

  // Sort selected day items:
  // Incomplete first, then study sessions by time, tasks by priority
  selectedDayItems.sort((a, b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    // If both are study sessions, sort by local time
    if (a.type == CalendarEntryType.studySession &&
        b.type == CalendarEntryType.studySession) {
      return a.localScheduledAt!.compareTo(b.localScheduledAt!);
    }
    // Study sessions with specific scheduled time shown before tasks
    if (a.type != b.type) {
      return a.type == CalendarEntryType.studySession ? -1 : 1;
    }
    // Both are tasks: sort by priority high -> low
    return b.task!.priority.index.compareTo(a.task!.priority.index);
  });

  return ManageCalendarSummary(
    allItems: allItems,
    itemsByDay: itemsByDay,
    selectedDayItems: selectedDayItems,
    failedWorkspaces: failedWorkspaces,
    isLoading: false,
    isPartial: isPartial,
    totalActiveWorkspacesCount: ownedActiveWorkspaces.length,
  );
});
