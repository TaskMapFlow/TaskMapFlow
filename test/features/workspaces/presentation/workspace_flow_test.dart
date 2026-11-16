import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/notes/presentation/providers/note_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/sprint_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/team/presentation/providers/team_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
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
    displayName: 'Map Explorer',
    isAnonymous: false,
    isEmailVerified: true,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
      child: const TaskMapFlowApp(
        firebaseReady: true,
        locale: Locale('tr'),
      ),
    );
  }

  group('Workspace & Map Presentation Flow Tests', () {
    testWidgets('shows empty map state initially, opens sheet and creates area',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Empty state visible on Home screen
      expect(find.text('İlk alanını oluştur'), findsOneWidget);
      expect(find.byKey(const Key('emptyMapAddAreaButton')), findsOneWidget);

      // Tap create area button
      await tester.tap(find.byKey(const Key('emptyMapAddAreaButton')));
      await tester.pumpAndSettle();

      // Create sheet opens
      expect(find.text('Yeni Alan Oluştur'), findsOneWidget);
      expect(find.byKey(const Key('workspaceNameInput')), findsOneWidget);

      // Enter name and submit
      await tester.enterText(
          find.byKey(const Key('workspaceNameInput')), 'Bitirme Projesi');
      await tester.enterText(find.byKey(const Key('workspaceDescriptionInput')),
          'Mobil uygulama mimarisi');

      final submitBtn = find.byKey(const Key('createWorkspaceSubmitButton'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verified creation call
      expect(fakeWorkspace.createCallCount, 1);

      // Area is now on canvas
      expect(find.text('Bitirme Projesi'), findsOneWidget);
    });

    testWidgets('toggle edit mode activates layout editing banner',
        (tester) async {
      final now = DateTime.now();
      fakeWorkspace = FakeWorkspaceRepository(
        initialWorkspaces: [
          Workspace(
            id: 'ws_demo',
            name: 'Yapay Zeka Dersi',
            description: 'Makine öğrenmesi',
            type: WorkspaceType.lesson,
            color: '#7C5CE8',
            ownerId: 'user_123',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        initialNodes: [
          MapNode(
            id: 'node_demo',
            workspaceId: 'ws_demo',
            ownerId: 'user_123',
            positionX: 500,
            positionY: 500,
            width: 180,
            height: 110,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Yapay Zeka Dersi'), findsOneWidget);

      // Tap edit mode button
      final editToggle = find.byKey(const Key('mapEditModeToggle'));
      await tester.tap(editToggle);
      await tester.pumpAndSettle();

      // Edit mode banner appears
      expect(
        find.textContaining('Düzenleme Modu'),
        findsOneWidget,
      );

      // Tap again to exit edit mode
      await tester.tap(editToggle);
      await tester.pumpAndSettle();
      expect(find.textContaining('Düzenleme Modu:'), findsNothing);
    });

    testWidgets(
        'Manage tab lists workspaces, opens detail, and deletes workspace',
        (tester) async {
      final now = DateTime.now();
      fakeWorkspace = FakeWorkspaceRepository(
        initialWorkspaces: [
          Workspace(
            id: 'ws_del',
            name: 'Silinecek Proje',
            description: 'Geçici çalışma alanı',
            type: WorkspaceType.project,
            color: '#F472B6',
            ownerId: 'user_123',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        initialNodes: [
          MapNode(
            id: 'node_del',
            workspaceId: 'ws_del',
            ownerId: 'user_123',
            positionX: 600,
            positionY: 600,
            width: 180,
            height: 110,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to Yönet tab
      await tester.tap(find.text('Yönet'));
      await tester.pumpAndSettle();

      // Workspace card visible
      expect(find.text('Silinecek Proje'), findsOneWidget);
      expect(find.text('Geçici çalışma alanı'), findsOneWidget);

      // Tap on card to open Detail Screen
      await tester.tap(find.text('Silinecek Proje'));
      await tester.pumpAndSettle();

      // Detail Screen renders
      expect(find.text('Alan Ayrıntısı'), findsOneWidget);
      expect(find.byKey(const Key('deleteWorkspaceButton')), findsOneWidget);

      // Tap delete
      final deleteBtn = find.byKey(const Key('deleteWorkspaceButton'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(
          find.text('Alanı Silmek İstediğinize Emin Misiniz?'), findsOneWidget);
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(fakeWorkspace.deleteCallCount, 1);
    });

    testWidgets(
        'task management: create task, toggle status, and guard area deletion',
        (tester) async {
      final now = DateTime.now();
      fakeWorkspace = FakeWorkspaceRepository(
        initialWorkspaces: [
          Workspace(
            id: 'ws_tasks',
            name: 'Yazılım Mimarisi',
            description: 'Ders alanı',
            type: WorkspaceType.lesson,
            color: '#818CF8',
            ownerId: 'user_123',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        initialNodes: [
          MapNode(
            id: 'node_tasks',
            workspaceId: 'ws_tasks',
            ownerId: 'user_123',
            positionX: 400,
            positionY: 400,
            width: 180,
            height: 110,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to Yönet tab
      await tester.tap(find.text('Yönet'));
      await tester.pumpAndSettle();

      // Tap on workspace card
      await tester.tap(find.text('Yazılım Mimarisi'));
      await tester.pumpAndSettle();

      // For lesson, should display 'Çalışma Adımları' and 'Adım Ekle'
      expect(find.text('Çalışma Adımları'), findsOneWidget);
      expect(find.text('Adım Ekle'), findsOneWidget);
      expect(find.text('Henüz çalışma adımı eklenmedi'), findsOneWidget);

      // Open Add Task Sheet
      await tester.tap(find.byKey(const Key('addTaskButton')));
      await tester.pumpAndSettle();

      // Enter task title
      await tester.enterText(
          find.byType(TextFormField).first, 'Clean Architecture Oku');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Adım Ekle'));
      await tester.pumpAndSettle();

      // Task card is now rendered in list
      expect(find.text('Clean Architecture Oku'), findsOneWidget);
      // Progress is visible: 0 / 1 tamamlandı (%0)
      expect(find.text('0 / 1 tamamlandı (%0)'), findsOneWidget);

      // Try to delete workspace while it has a task
      final deleteBtn = find.byKey(const Key('deleteWorkspaceButton'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Should block deletion with error dialog
      expect(
        find.text(
            'Bu alanda görevler bulunuyor. Alanı silmeden önce lütfen tüm görevleri silin.'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Workspace was NOT deleted
      expect(fakeWorkspace.deleteCallCount, 0);

      // Toggle task status
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
    });
  });
}
