import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/kanban_board_view.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/l10n/app_localizations.dart';

import '../../../helpers/fake_task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeTaskRepository fakeTaskRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeTaskRepo = FakeTaskRepository();
  });

  tearDown(() {
    fakeTaskRepo.dispose();
  });

  final testWorkspace = Workspace(
    id: 'ws_kanban',
    ownerId: 'user_1',
    name: 'Kanban Workspace',
    color: '#7C5CE8',
    type: WorkspaceType.project,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('TaskDisplayModeNotifier defaults to list and persists board mode',
      () async {
    final notifier = TaskDisplayModeNotifier(prefs);
    expect(notifier.state, TaskDisplayMode.list);

    await notifier.setMode(TaskDisplayMode.board);
    expect(notifier.state, TaskDisplayMode.board);
    expect(prefs.getString('taskmapflow_task_display_mode'), 'board');

    // Load with new instance
    final loaded = TaskDisplayModeNotifier(prefs);
    expect(loaded.state, TaskDisplayMode.board);
  });

  testWidgets('KanbanBoardView renders all 3 columns with task counts',
      (tester) async {
    final now = DateTime.now();
    final tasks = [
      TaskModel(
        id: 't1',
        workspaceId: testWorkspace.id,
        ownerId: 'user_1',
        title: 'Task 1 in Todo',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: 't2',
        workspaceId: testWorkspace.id,
        ownerId: 'user_1',
        title: 'Task 2 In Progress',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: 't3',
        workspaceId: testWorkspace.id,
        ownerId: 'user_1',
        title: 'Task 3 Completed',
        status: TaskStatus.completed,
        priority: TaskPriority.low,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: KanbanBoardView(
              workspace: testWorkspace,
              tasks: tasks,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 3 columns exist
    expect(find.text('Yapılacak'), findsOneWidget);
    expect(find.text('Devam Ediyor'), findsOneWidget);
    expect(find.text('Tamamlandı'), findsOneWidget);

    // Verify tasks are displayed in their columns
    expect(find.text('Task 1 in Todo'), findsOneWidget);
    expect(find.text('Task 2 In Progress'), findsOneWidget);
    expect(find.text('Task 3 Completed'), findsOneWidget);

    // Verify task count badges
    expect(find.text('1'), findsNWidgets(3));
  });

  testWidgets(
      'KanbanBoardView shows empty column placeholder when a column has 0 tasks',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: KanbanBoardView(
              workspace: testWorkspace,
              tasks: const [],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 3 columns are visible even when empty
    expect(find.text('Yapılacak'), findsOneWidget);
    expect(find.text('Devam Ediyor'), findsOneWidget);
    expect(find.text('Tamamlandı'), findsOneWidget);

    // Verify 'Görev yok' placeholder in each column
    expect(find.text('Görev yok'), findsNWidgets(3));
    expect(find.text('0'), findsNWidgets(3));
  });
}
