import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';
import 'package:task_map_flow/features/notes/domain/repositories/note_repository.dart';
import 'package:task_map_flow/features/workspaces/domain/models/resource_link.dart';

void main() {
  group('NoteModel and ResourceLink Tests', () {
    test('NoteModel props equality and copyWith', () {
      final now = DateTime.now();
      final note1 = NoteModel(
        id: 'note_1',
        workspaceId: 'ws_1',
        ownerId: 'user_1',
        title: 'Meeting Notes',
        content: 'Discuss sprint backlog and release dates.',
        createdAt: now,
        updatedAt: now,
      );

      final note2 = NoteModel(
        id: 'note_1',
        workspaceId: 'ws_1',
        ownerId: 'user_1',
        title: 'Meeting Notes',
        content: 'Discuss sprint backlog and release dates.',
        createdAt: now,
        updatedAt: now,
      );

      expect(note1, equals(note2));

      final updated = note1.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.id, 'note_1');
    });

    test('PaginatedNotes props equality', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'note_1',
        workspaceId: 'ws_1',
        ownerId: 'user_1',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      final page1 = PaginatedNotes(
        notes: [note],
        hasMore: true,
        cursor: 1,
      );

      final page2 = PaginatedNotes(
        notes: [note],
        hasMore: true,
        cursor: 1,
      );

      expect(page1, equals(page2));
    });

    test('ResourceLink isValidUrl validates http and https only', () {
      expect(ResourceLink.isValidUrl('https://github.com/flutter/flutter'),
          isTrue);
      expect(ResourceLink.isValidUrl('http://localhost:8080'), isTrue);
      expect(
          ResourceLink.isValidUrl('https://example.com/notes?page=1'), isTrue);

      expect(ResourceLink.isValidUrl('javascript:alert(1)'), isFalse);
      expect(ResourceLink.isValidUrl('file:///etc/passwd'), isFalse);
      expect(ResourceLink.isValidUrl('ftp://example.com'), isFalse);
      expect(
          ResourceLink.isValidUrl('data:text/plain;base64,SGVsbG8='), isFalse);
      expect(ResourceLink.isValidUrl('not a url'), isFalse);
      expect(ResourceLink.isValidUrl(''), isFalse);
    });

    test('ResourceLink toMap and fromMap serialization', () {
      const link = ResourceLink(
        id: 'res_1',
        title: 'API Docs',
        url: 'https://docs.example.com',
      );

      final map = link.toMap();
      final fromMap = ResourceLink.fromMap(map);

      expect(fromMap, equals(link));
    });
  });
}
