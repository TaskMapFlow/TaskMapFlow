import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';

class NoteDto {
  static NoteModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String workspaceId,
  ) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return NoteModel(
      id: doc.id,
      workspaceId: workspaceId,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(NoteModel note) {
    return {
      'id': note.id,
      'workspaceId': note.workspaceId,
      'ownerId': note.ownerId,
      'title': note.title,
      'content': note.content,
      'createdAt': Timestamp.fromDate(note.createdAt),
      'updatedAt': Timestamp.fromDate(note.updatedAt),
    };
  }
}
