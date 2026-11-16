import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';

class WorkspaceDto {
  static Workspace fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Workspace(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      type: WorkspaceType.fromString(data['type'] as String? ?? ''),
      color: data['color'] as String? ?? '#7C5CE8',
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(Workspace workspace) {
    return {
      'id': workspace.id,
      'name': workspace.name,
      'description': workspace.description ?? '',
      'type': workspace.type.toFirestoreString(),
      'color': workspace.color,
      'ownerId': workspace.ownerId,
      'createdAt': Timestamp.fromDate(workspace.createdAt),
      'updatedAt': Timestamp.fromDate(workspace.updatedAt),
    };
  }
}
