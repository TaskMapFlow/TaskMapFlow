import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/notes/presentation/providers/note_providers.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/sprint_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/team/presentation/providers/team_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_note_repository.dart';
import '../../../helpers/fake_sprint_repository.dart';
import '../../../helpers/fake_task_repository.dart';
import '../../../helpers/fake_team_repository.dart';
import '../../../helpers/fake_workspace_repository.dart';

void main() {
  late SharedPreferences prefs;
  late FakeAuthRepository fakeAuth;
  late FakeWorkspaceRepository fakeWorkspace;
  late FakeTaskRepository fakeTask;
  late FakeSprintRepository fakeSprint;
  late FakeNoteRepository fakeNote;
  late FakeTeamRepository fakeTeam;

  const testUser = AuthUser(
    id: 'user_123',
    email: 'user@example.com',
    displayName: 'Daily Worker',
    isAnonymous: false,
    isEmailVerified: true,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'taskmapflow_preferred_locale': 'tr',
    });
    prefs = await SharedPreferences.getInstance();
    fakeAuth = FakeAuthRepository(
      initialStatus: const AuthAuthenticated(testUser),
    );
    fakeWorkspace = FakeWorkspaceRepository();
    fakeTask = FakeTaskRepository();
    fakeSprint = FakeSprintRepository();
    fakeNote = FakeNoteRepository();
    fakeTeam = FakeTeamRepository();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(fakeAuth),
        workspaceRepositoryProvider.overrideWithValue(fakeWorkspace),
        taskRepositoryProvider.overrideWithValue(fakeTask),
        sprintRepositoryProvider.overrideWithValue(fakeSprint),
        noteRepositoryProvider.overrideWithValue(fakeNote),
        teamRepositoryProvider.overrideWithValue(fakeTeam),
      ],
      child: const TaskMapFlowApp(firebaseReady: true),
    );
  }

  testWidgets(
      'HomeScreen view toggle between Map and Overview and renders daily summary',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    // Seed 1 active workspace with tasks
    final wsResult = await fakeWorkspace.createWorkspaceWithMapNode(
      name: 'Mobile App Project',
      type: WorkspaceType.project,
      color: '#8A2BE2',
      ownerId: testUser.id,
      initialX: 1000,
      initialY: 1000,
      width: 200,
      height: 120,
    );
    final ws = wsResult.valueOrNull!;

    // Seed: 1 overdue task, 1 today task, 1 in-progress task, 1 upcoming task
    await fakeTask.createTask(
      workspaceId: ws.id,
      ownerId: testUser.id,
      title: 'Fix critical bug',
      dueDate: yesterday,
      status: TaskStatus.todo,
      priority: TaskPriority.high,
    );

    await fakeTask.createTask(
      workspaceId: ws.id,
      ownerId: testUser.id,
      title: 'Release v1.0',
      dueDate: today,
      status: TaskStatus.todo,
      priority: TaskPriority.high,
    );

    await fakeTask.createTask(
      workspaceId: ws.id,
      ownerId: testUser.id,
      title: 'Refactor engine',
      status: TaskStatus.inProgress,
      priority: TaskPriority.medium,
    );

    await fakeTask.createTask(
      workspaceId: ws.id,
      ownerId: testUser.id,
      title: 'Write docs',
      dueDate: tomorrow,
      status: TaskStatus.todo,
      priority: TaskPriority.low,
    );

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Default view: Map view is active
    expect(find.text('Harita'), findsOneWidget);
    expect(find.text('Genel Bakış'), findsOneWidget);

    // Switch to Overview
    await tester.tap(find.text('Genel Bakış'));
    await tester.pumpAndSettle();

    // Overview screen headers should be rendered with counts
    expect(find.text('Günlük Çalışma Özeti'), findsOneWidget);
    expect(find.text('Gecikmiş'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);

    // Initial tasks at top should be visible
    expect(find.text('Fix critical bug'), findsOneWidget);
    expect(find.text('Release v1.0'), findsOneWidget);

    // Scroll down to see Devam Eden, Önümüzdeki 7 Gün and Aktif Alanlar
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Devam Eden'), findsOneWidget);
    expect(find.text('Refactor engine'), findsOneWidget);
    expect(find.text('Aktif Alanlar'), findsOneWidget);
    expect(find.text('Mobile App Project'), findsWidgets);

    // Verify preference is remembered
    expect(prefs.getString('taskmapflow_home_view_mode'), 'overview');
  });

  testWidgets('ManageScreen workspace title search filters workspaces',
      (tester) async {
    // Seed 2 workspaces
    await fakeWorkspace.createWorkspaceWithMapNode(
      name: 'Flutter Client',
      type: WorkspaceType.project,
      color: '#8A2BE2',
      ownerId: testUser.id,
      initialX: 1000,
      initialY: 1000,
      width: 200,
      height: 120,
    );

    await fakeWorkspace.createWorkspaceWithMapNode(
      name: 'Math 101',
      type: WorkspaceType.lesson,
      color: '#3B82F6',
      ownerId: testUser.id,
      initialX: 1300,
      initialY: 1000,
      width: 200,
      height: 120,
    );

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Navigate to Manage tab
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Client'), findsOneWidget);
    expect(find.text('Math 101'), findsOneWidget);

    // Search for "Flutter"
    await tester.enterText(find.byType(TextField).first, 'Flutter');
    await tester.pumpAndSettle();

    expect(find.text('Flutter Client'), findsOneWidget);
    expect(find.text('Math 101'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    expect(find.text('Flutter Client'), findsOneWidget);
    expect(find.text('Math 101'), findsOneWidget);
  });

  testWidgets('DailyWorkSummary handles partial failures gracefully',
      (tester) async {
    // Seed 2 workspaces: one with valid tasks, one where tasks throw error
    final ws1Res = await fakeWorkspace.createWorkspaceWithMapNode(
      name: 'Stable Area',
      type: WorkspaceType.project,
      color: '#8A2BE2',
      ownerId: testUser.id,
      initialX: 1000,
      initialY: 1000,
      width: 200,
      height: 120,
    );
    final ws1 = (ws1Res as Success<Workspace>).value;

    await fakeWorkspace.createWorkspaceWithMapNode(
      name: 'Failing Area',
      type: WorkspaceType.lesson,
      color: '#3B82F6',
      ownerId: testUser.id,
      initialX: 1300,
      initialY: 1000,
      width: 200,
      height: 120,
    );

    await fakeTask.createTask(
      workspaceId: ws1.id,
      ownerId: testUser.id,
      title: 'Stable Task',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
    );

    // Override tasksStreamProvider so that 'Failing Area' throws permission-denied error
    final failingOverrideApp = ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(fakeAuth),
        workspaceRepositoryProvider.overrideWithValue(fakeWorkspace),
        taskRepositoryProvider.overrideWithValue(fakeTask),
        sprintRepositoryProvider.overrideWithValue(fakeSprint),
        noteRepositoryProvider.overrideWithValue(fakeNote),
        teamRepositoryProvider.overrideWithValue(fakeTeam),
        tasksStreamProvider.overrideWith((ref, workspaceId) {
          if (workspaceId != ws1.id) {
            return Stream.error('Erişim reddedildi. Yetkiniz bulunmuyor.');
          }
          return ref
              .watch(taskRepositoryProvider)
              .watchTasks(workspaceId: workspaceId, ownerId: testUser.id)
              .map((r) =>
                  r.isSuccess ? (r as Success<List<TaskModel>>).value : []);
        }),
      ],
      child: const TaskMapFlowApp(
        firebaseReady: true,
        locale: Locale('tr'),
      ),
    );

    await tester.pumpWidget(failingOverrideApp);
    await tester.pumpAndSettle();

    // Switch to Overview
    await tester.tap(find.text('Genel Bakış'));
    await tester.pumpAndSettle();

    // Should NOT show a full screen error! Should show the accessible workspace tasks
    expect(find.text('Günlük Çalışma Özeti'), findsOneWidget);
    expect(find.text('Stable Task'), findsOneWidget);

    // Should show the partial failed warning banner with retry button
    expect(find.text('1 alanın görevleri yüklenemedi.'), findsOneWidget);
    expect(find.text('Yeniden dene'), findsOneWidget);
  });
}
