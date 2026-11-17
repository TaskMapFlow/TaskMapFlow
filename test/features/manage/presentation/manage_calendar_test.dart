import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/features/manage/presentation/providers/manage_view_providers.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final testWorkspace = Workspace(
    id: 'ws_cal',
    ownerId: 'u1',
    name: 'Cal Space',
    color: '#7C5CE8',
    type: WorkspaceType.lesson,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('ManageViewModeNotifier Tests', () {
    test('defaults to workspaces and persists calendar mode', () async {
      final notifier = ManageViewModeNotifier(prefs);
      expect(notifier.state, ManageViewMode.workspaces);

      await notifier.setViewMode(ManageViewMode.calendar);
      expect(notifier.state, ManageViewMode.calendar);
      expect(prefs.getString('taskmapflow_manage_view_mode'), 'calendar');

      // Reload with fresh instance
      final reloaded = ManageViewModeNotifier(prefs);
      expect(reloaded.state, ManageViewMode.calendar);
    });
  });

  group('CalendarDateNotifier Tests', () {
    test('month navigation and jumpToToday', () {
      final notifier = CalendarDateNotifier();
      final initialMonth = notifier.state.displayedMonth;

      notifier.nextMonth();
      final nextMonth = DateTime(initialMonth.year, initialMonth.month + 1, 1);
      expect(notifier.state.displayedMonth.year, nextMonth.year);
      expect(notifier.state.displayedMonth.month, nextMonth.month);

      notifier.previousMonth();
      expect(notifier.state.displayedMonth.year, initialMonth.year);
      expect(notifier.state.displayedMonth.month, initialMonth.month);

      // Select arbitrary day
      final targetDay = DateTime(2027, 5, 20);
      notifier.selectDay(targetDay);
      expect(notifier.state.selectedDay, targetDay);
      expect(notifier.state.displayedMonth, DateTime(2027, 5, 1));

      // Jump to today
      notifier.jumpToToday();
      final now = DateTime.now();
      expect(notifier.state.selectedDay.year, now.year);
      expect(notifier.state.selectedDay.month, now.month);
      expect(notifier.state.selectedDay.day, now.day);

      // Show completed toggle
      expect(notifier.state.showCompleted, isTrue);
      notifier.toggleShowCompleted();
      expect(notifier.state.showCompleted, isFalse);

      notifier.dispose();
    });

    test('December to January and January to December year transitions', () {
      final notifier = CalendarDateNotifier();

      // Go to December 2026
      notifier.selectDay(DateTime(2026, 12, 15));
      expect(notifier.state.displayedMonth, DateTime(2026, 12, 1));

      // Next month -> January 2027
      notifier.nextMonth();
      expect(notifier.state.displayedMonth, DateTime(2027, 1, 1));

      // Prev month -> December 2026
      notifier.previousMonth();
      expect(notifier.state.displayedMonth, DateTime(2026, 12, 1));

      notifier.dispose();
    });
  });

  group('CalendarItem Date Handling Tests', () {
    test('Task uses registered calendar day while session uses local time', () {
      final now = DateTime.now();
      // Date-based task: stored as UTC date
      final utcDueDate = DateTime.utc(2026, 11, 20);
      final taskDay =
          DateTime(utcDueDate.year, utcDueDate.month, utcDueDate.day);

      final task = TaskModel(
        id: 't_1',
        workspaceId: testWorkspace.id,
        ownerId: 'u1',
        title: 'Task Due Nov 20',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        dueDate: utcDueDate,
        createdAt: now,
        updatedAt: now,
      );

      final taskItem = CalendarItem.task(
        task: task,
        workspace: testWorkspace,
        calendarDay: taskDay,
      );

      expect(taskItem.calendarDay, DateTime(2026, 11, 20));
      expect(taskItem.type, CalendarEntryType.task);
      expect(taskItem.isCompleted, isFalse);

      // Time-based study session
      final scheduledUtc = DateTime.utc(2026, 11, 20, 14, 30);
      final localTime = scheduledUtc.toLocal();
      final sessionDay =
          DateTime(localTime.year, localTime.month, localTime.day);

      final session = StudySessionModel(
        id: 's_1',
        workspaceId: testWorkspace.id,
        ownerId: 'u1',
        title: 'Study Session',
        scheduledAt: scheduledUtc,
        plannedDurationMinutes: 45,
        createdAt: now,
        updatedAt: now,
      );

      final sessionItem = CalendarItem.studySession(
        session: session,
        workspace: testWorkspace,
        calendarDay: sessionDay,
        localScheduledAt: localTime,
      );

      expect(sessionItem.type, CalendarEntryType.studySession);
      expect(sessionItem.localScheduledAt, localTime);
      expect(sessionItem.calendarDay, sessionDay);
    });
  });
}
