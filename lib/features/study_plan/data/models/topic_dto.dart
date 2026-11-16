import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';

class TopicDto {
  static TopicModel fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return TopicModel(
      id: doc.id,
      workspaceId: data['workspaceId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      status: TopicStatus.fromString(data['status'] as String? ?? ''),
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(TopicModel topic) {
    return {
      'id': topic.id,
      'workspaceId': topic.workspaceId,
      'ownerId': topic.ownerId,
      'title': topic.title,
      'description': topic.description,
      'status': topic.status.toFirestoreString(),
      'orderIndex': topic.orderIndex,
      'createdAt': Timestamp.fromDate(topic.createdAt),
      'updatedAt': Timestamp.fromDate(topic.updatedAt),
    };
  }
}
