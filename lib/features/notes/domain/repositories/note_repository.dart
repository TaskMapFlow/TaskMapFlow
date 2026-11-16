import 'package:equatable/equatable.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';

class PaginatedNotes extends Equatable {
  const PaginatedNotes({
    required this.notes,
    required this.hasMore,
    this.cursor,
  });

  final List<NoteModel> notes;
  final bool hasMore;
  final Object? cursor;

  @override
  List<Object?> get props => [notes, hasMore, cursor];
}

abstract interface class NoteRepository {
  Future<Result<PaginatedNotes>> getNotes({
    required String workspaceId,
    required String ownerId,
    int limit = 10,
    Object? cursor,
  });

  Future<Result<bool>> hasNotes({
    required String workspaceId,
    required String ownerId,
  });

  Future<Result<NoteModel>> createNote({
    required String workspaceId,
    required String ownerId,
    String? title,
    required String content,
  });

  Future<Result<void>> updateNote({
    required String workspaceId,
    required String noteId,
    String? title,
    required String content,
  });

  Future<Result<void>> deleteNote({
    required String workspaceId,
    required String noteId,
  });
}
