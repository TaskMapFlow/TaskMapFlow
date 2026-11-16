import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';
import 'package:task_map_flow/features/notes/domain/repositories/note_repository.dart';

class FakeNoteRepository implements NoteRepository {
  final Map<String, List<NoteModel>> _notesByWorkspace = {};

  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<Result<PaginatedNotes>> getNotes({
    required String workspaceId,
    required String ownerId,
    int limit = 10,
    Object? cursor,
  }) async {
    final list = _notesByWorkspace[workspaceId] ?? [];
    final userNotes = list.where((n) => n.ownerId == ownerId).toList();
    userNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    int startIndex = 0;
    if (cursor is int) {
      startIndex = cursor;
    }

    final endIndex = (startIndex + limit).clamp(0, userNotes.length);
    final pagedNotes = userNotes.sublist(startIndex, endIndex);
    final hasMore = endIndex < userNotes.length;

    return Success(
      PaginatedNotes(
        notes: pagedNotes,
        hasMore: hasMore,
        cursor: hasMore ? endIndex : null,
      ),
    );
  }

  @override
  Future<Result<bool>> hasNotes({
    required String workspaceId,
    required String ownerId,
  }) async {
    final list = _notesByWorkspace[workspaceId] ?? [];
    final count = list.where((n) => n.ownerId == ownerId).length;
    return Success(count > 0);
  }

  @override
  Future<Result<NoteModel>> createNote({
    required String workspaceId,
    required String ownerId,
    String? title,
    required String content,
  }) async {
    createCallCount++;
    final now = DateTime.now();
    final list = _notesByWorkspace.putIfAbsent(workspaceId, () => []);
    final note = NoteModel(
      id: 'note_${list.length + 1}',
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title ?? '',
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    list.insert(0, note);
    return Success(note);
  }

  @override
  Future<Result<void>> updateNote({
    required String workspaceId,
    required String noteId,
    String? title,
    required String content,
  }) async {
    updateCallCount++;
    final list = _notesByWorkspace[workspaceId] ?? [];
    final idx = list.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        title: title ?? list[idx].title,
        content: content,
        updatedAt: DateTime.now(),
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteNote({
    required String workspaceId,
    required String noteId,
  }) async {
    deleteCallCount++;
    final list = _notesByWorkspace[workspaceId];
    if (list != null) {
      list.removeWhere((n) => n.id == noteId);
    }
    return const Success(null);
  }
}
