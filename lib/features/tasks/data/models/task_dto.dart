import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';

class TaskDto {
  static TaskModel fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dueTimestamp = data['dueDate'] as Timestamp?;
    final dueDateTime = dueTimestamp?.toDate();
    final dueDate = dueDateTime != null
        ? DateTime.utc(dueDateTime.year, dueDateTime.month, dueDateTime.day)
        : null;

    return TaskModel(
      id: doc.id,
      workspaceId: data['workspaceId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: TaskStatus.fromString(data['status'] as String? ?? ''),
      priority: TaskPriority.fromString(data['priority'] as String? ?? ''),
      dueDate: dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(TaskModel task) {
    return {
      'id': task.id,
      'workspaceId': task.workspaceId,
      'ownerId': task.ownerId,
      'title': task.title,
      'description': task.description,
      'status': task.status.toFirestoreString(),
      'priority': task.priority.toFirestoreString(),
      'dueDate': task.dueDate != null
          ? Timestamp.fromDate(DateTime.utc(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            ))
          : null,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'updatedAt': Timestamp.fromDate(task.updatedAt),
    };
  }
}
