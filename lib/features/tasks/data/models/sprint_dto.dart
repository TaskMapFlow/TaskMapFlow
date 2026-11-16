import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';

class SprintDto {
  static SprintModel fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final startTimestamp = data['startDate'] as Timestamp?;
    final endTimestamp = data['endDate'] as Timestamp?;
    final startDateTime = startTimestamp?.toDate() ?? DateTime.now();
    final endDateTime = endTimestamp?.toDate() ?? DateTime.now();

    final startDate = DateTime.utc(
        startDateTime.year, startDateTime.month, startDateTime.day);
    final endDate =
        DateTime.utc(endDateTime.year, endDateTime.month, endDateTime.day);

    return SprintModel(
      id: doc.id,
      workspaceId: data['workspaceId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      startDate: startDate,
      endDate: endDate,
      status: SprintStatus.fromString(data['status'] as String? ?? ''),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(SprintModel sprint) {
    return {
      'id': sprint.id,
      'workspaceId': sprint.workspaceId,
      'ownerId': sprint.ownerId,
      'name': sprint.name,
      'goal': sprint.goal,
      'startDate': Timestamp.fromDate(DateTime.utc(
        sprint.startDate.year,
        sprint.startDate.month,
        sprint.startDate.day,
      )),
      'endDate': Timestamp.fromDate(DateTime.utc(
        sprint.endDate.year,
        sprint.endDate.month,
        sprint.endDate.day,
      )),
      'status': sprint.status.toFirestoreString(),
      'createdAt': Timestamp.fromDate(sprint.createdAt),
      'updatedAt': Timestamp.fromDate(sprint.updatedAt),
    };
  }
}
