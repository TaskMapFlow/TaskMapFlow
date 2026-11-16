import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_connection.dart';

class MapConnectionDto {
  static MapConnection fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return MapConnection(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      sourceWorkspaceId: data['sourceWorkspaceId'] as String? ?? '',
      targetWorkspaceId: data['targetWorkspaceId'] as String? ?? '',
      type: ConnectionType.fromString(data['type'] as String? ?? ''),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(MapConnection connection) {
    return {
      'id': connection.id,
      'ownerId': connection.ownerId,
      'sourceWorkspaceId': connection.sourceWorkspaceId,
      'targetWorkspaceId': connection.targetWorkspaceId,
      'type': connection.type.toFirestoreString(),
      'createdAt': Timestamp.fromDate(connection.createdAt),
      'updatedAt': Timestamp.fromDate(connection.updatedAt),
    };
  }
}
