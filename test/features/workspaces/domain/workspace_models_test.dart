import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';

void main() {
  group('Workspace Domain Models Tests', () {
    test('WorkspaceType enum mapping and serialization', () {
      expect(WorkspaceType.fromString('project'), WorkspaceType.project);
      expect(WorkspaceType.fromString('lesson'), WorkspaceType.lesson);
      expect(WorkspaceType.fromString('freeform'), WorkspaceType.freeform);
      expect(WorkspaceType.fromString('unknown'), WorkspaceType.freeform);

      expect(WorkspaceType.project.toFirestoreString(), 'project');
      expect(WorkspaceType.lesson.toFirestoreString(), 'lesson');
      expect(WorkspaceType.freeform.toFirestoreString(), 'freeform');
    });

    test('Workspace equality and copyWith', () {
      final now = DateTime(2026, 11, 16);
      final ws1 = Workspace(
        id: 'ws1',
        name: 'Math 101',
        description: 'Calculus',
        type: WorkspaceType.lesson,
        color: '#7C5CE8',
        ownerId: 'u1',
        createdAt: now,
        updatedAt: now,
      );

      final ws2 = Workspace(
        id: 'ws1',
        name: 'Math 101',
        description: 'Calculus',
        type: WorkspaceType.lesson,
        color: '#7C5CE8',
        ownerId: 'u1',
        createdAt: now,
        updatedAt: now,
      );

      expect(ws1, ws2);

      final updated = ws1.copyWith(name: 'Math 102');
      expect(updated.name, 'Math 102');
      expect(updated.description, 'Calculus');
      expect(updated.id, 'ws1');
      expect(updated == ws1, isFalse);
    });

    test('MapNode equality and copyWith', () {
      final now = DateTime(2026, 11, 16);
      final node1 = MapNode(
        id: 'n1',
        workspaceId: 'ws1',
        ownerId: 'u1',
        positionX: 100,
        positionY: 200,
        width: 180,
        height: 110,
        createdAt: now,
        updatedAt: now,
      );

      final node2 = MapNode(
        id: 'n1',
        workspaceId: 'ws1',
        ownerId: 'u1',
        positionX: 100,
        positionY: 200,
        width: 180,
        height: 110,
        createdAt: now,
        updatedAt: now,
      );

      expect(node1, node2);

      final moved = node1.copyWith(positionX: 150, positionY: 250);
      expect(moved.positionX, 150);
      expect(moved.positionY, 250);
      expect(moved.width, 180);
      expect(moved.id, 'n1');
      expect(moved == node1, isFalse);
    });
  });
}
