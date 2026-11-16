import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/notes/presentation/providers/note_providers.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/sprint_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/team/presentation/providers/team_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_note_repository.dart';
import '../../../helpers/fake_sprint_repository.dart';
import '../../../helpers/fake_study_plan_repository.dart';
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
  late FakeStudyPlanRepository fakeStudyPlan;

  const testUser = AuthUser(
    id: 'user_123',
    email: 'user@example.com',
    displayName: 'Student Explorer',
    isAnonymous: false,
    isEmailVerified: true,
  );

  final now = DateTime.now();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeAuth = FakeAuthRepository(
      initialStatus: const AuthAuthenticated(testUser),
    );
    fakeTask = FakeTaskRepository();
    fakeSprint = FakeSprintRepository();
    fakeNote = FakeNoteRepository();
    fakeTeam = FakeTeamRepository();
    fakeStudyPlan = FakeStudyPlanRepository();

    fakeWorkspace = FakeWorkspaceRepository(
      initialWorkspaces: [
        Workspace(
          id: 'ws_lesson',
          name: 'Matematik 101',
          description: 'Ders alanı',
          type: WorkspaceType.lesson,
          color: '#818CF8',
          ownerId: 'user_123',
          createdAt: now,
          updatedAt: now,
        ),
        Workspace(
          id: 'ws_project',
          name: 'Mobil Uygulama Projesi',
          description: 'Proje alanı',
          type: WorkspaceType.project,
          color: '#34D399',
          ownerId: 'user_123',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      initialNodes: [
        MapNode(
          id: 'node_1',
          workspaceId: 'ws_lesson',
          ownerId: 'user_123',
          positionX: 100,
          positionY: 100,
          width: 180,
          height: 110,
          createdAt: now,
          updatedAt: now,
        ),
        MapNode(
          id: 'node_2',
          workspaceId: 'ws_project',
          ownerId: 'user_123',
          positionX: 300,
          positionY: 100,
          width: 180,
          height: 110,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
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
        studyPlanRepositoryProvider.overrideWithValue(fakeStudyPlan),
      ],
      child: const TaskMapFlowApp(
        firebaseReady: true,
        locale: Locale('tr'),
      ),
    );
  }

  group('Study Plan Presentation Flow Tests', () {
    testWidgets(
        'Study Plan tab is shown ONLY for lesson workspaces and allows adding topic',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Go to Yönet tab
      await tester.tap(find.text('Yönet'));
      await tester.pumpAndSettle();

      // 1. Open Project workspace -> Study Plan tab should NOT be visible
      await tester.tap(find.text('Mobil Uygulama Projesi'));
      await tester.pumpAndSettle();

      expect(find.text('Çalışma Planı'), findsNothing);

      // Back to Yönet
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // 2. Open Lesson workspace -> Study Plan tab MUST be visible
      await tester.tap(find.text('Matematik 101'));
      await tester.pumpAndSettle();

      expect(find.text('Çalışma Planı'), findsOneWidget);

      // Tap on 'Çalışma Planı' tab
      await tester.tap(find.text('Çalışma Planı'));
      await tester.pumpAndSettle();

      // Check Topic Progress header
      expect(find.text('Konu İlerlemesi'), findsOneWidget);
      expect(find.text('0 / 0 konu tamamlandı (%0)'), findsOneWidget);
      expect(
          find.text(
              'Henüz konu eklenmedi. Konuları ekleyerek ders çalışma planınızı oluşturun.'),
          findsOneWidget);

      // Tap 'Konu Ekle' button to open sheet
      await tester.tap(find.byKey(const Key('addTopicButton')));
      await tester.pumpAndSettle();

      // Enter topic title
      await tester.enterText(
          find.byType(TextFormField).first, 'Limit ve Süreklilik');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('submitTopicButton')));
      await tester.pumpAndSettle();

      // Verify topic is rendered
      expect(find.text('Limit ve Süreklilik'), findsOneWidget);
      expect(find.text('0 / 1 konu tamamlandı (%0)'), findsOneWidget);
    });
  });
}
