import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/notes/data/models/note_dto.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';
import 'package:task_map_flow/features/notes/domain/repositories/note_repository.dart';

class FirebaseNoteRepository implements NoteRepository {
  FirebaseNoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notesCol(String workspaceId) =>
      _firestore.collection('workspaces').doc(workspaceId).collection('notes');

  @override
  Future<Result<PaginatedNotes>> getNotes({
    required String workspaceId,
    required String ownerId,
    int limit = 10,
    Object? cursor,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _notesCol(workspaceId)
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('updatedAt', descending: true)
          .limit(limit + 1);

      if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final resultDocs = hasMore ? docs.sublist(0, limit) : docs;
      final notes = resultDocs
          .map((doc) => NoteDto.fromFirestore(doc, workspaceId))
          .toList();
      final newCursor = resultDocs.isNotEmpty ? resultDocs.last : null;

      return Success(
        PaginatedNotes(
          notes: notes,
          hasMore: hasMore,
          cursor: newCursor,
        ),
      );
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> hasNotes({
    required String workspaceId,
    required String ownerId,
  }) async {
    try {
      final snapshot = await _notesCol(workspaceId)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      return Success(snapshot.docs.isNotEmpty);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<NoteModel>> createNote({
    required String workspaceId,
    required String ownerId,
    String? title,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      final doc = _notesCol(workspaceId).doc();
      final note = NoteModel(
        id: doc.id,
        workspaceId: workspaceId,
        ownerId: ownerId,
        title: title?.trim() ?? '',
        content: content.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await doc.set(NoteDto.toFirestore(note));
      return Success(note);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateNote({
    required String workspaceId,
    required String noteId,
    String? title,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      await _notesCol(workspaceId).doc(noteId).update({
        'title': title?.trim() ?? '',
        'content': content.trim(),
        'updatedAt': Timestamp.fromDate(now),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteNote({
    required String workspaceId,
    required String noteId,
  }) async {
    try {
      await _notesCol(workspaceId).doc(noteId).delete();
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  Failure _mapException(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          const PermissionFailure('Erişim reddedildi. Yetkiniz bulunmuyor.'),
        'unavailable' || 'network-request-failed' => const NetworkFailure(
            'Bağlantı hatası. İnternet bağlantınızı kontrol edin.'),
        'not-found' => const NotFoundFailure('Kayıt bulunamadı.'),
        _ =>
          UnknownFailure(error.message ?? 'Veritabanı işlemi başarısız oldu.'),
      };
    }
    return UnknownFailure(error.toString());
  }
}
