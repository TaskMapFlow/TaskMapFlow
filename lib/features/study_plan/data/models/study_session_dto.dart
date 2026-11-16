import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';

class StudySessionDto {
  static StudySessionModel fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final scheduledAt =
        (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return StudySessionModel(
      id: doc.id,
      workspaceId: data['workspaceId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      scheduledAt: scheduledAt,
      plannedDurationMinutes:
          (data['plannedDurationMinutes'] as num?)?.toInt() ?? 30,
      topicId: data['topicId'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedAt: completedAt,
      actualDurationMinutes: (data['actualDurationMinutes'] as num?)?.toInt(),
      reflectionNotes: data['reflectionNotes'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(StudySessionModel session) {
    return {
      'id': session.id,
      'workspaceId': session.workspaceId,
      'ownerId': session.ownerId,
      'title': session.title,
      'scheduledAt': Timestamp.fromDate(session.scheduledAt),
      'plannedDurationMinutes': session.plannedDurationMinutes,
      'topicId': session.topicId,
      'isCompleted': session.isCompleted,
      'completedAt': session.completedAt != null
          ? Timestamp.fromDate(session.completedAt!)
          : null,
      'actualDurationMinutes': session.actualDurationMinutes,
      'reflectionNotes': session.reflectionNotes,
      'createdAt': Timestamp.fromDate(session.createdAt),
      'updatedAt': Timestamp.fromDate(session.updatedAt),
    };
  }
}
