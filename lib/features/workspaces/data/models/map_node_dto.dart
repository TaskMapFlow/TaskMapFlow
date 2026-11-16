import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';

class MapNodeDto {
  static MapNode fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return MapNode(
      id: doc.id,
      workspaceId: data['workspaceId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      positionX: (data['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (data['positionY'] as num?)?.toDouble() ?? 0.0,
      width: (data['width'] as num?)?.toDouble() ?? 160.0,
      height: (data['height'] as num?)?.toDouble() ?? 100.0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toFirestore(MapNode node) {
    return {
      'id': node.id,
      'workspaceId': node.workspaceId,
      'ownerId': node.ownerId,
      'positionX': node.positionX,
      'positionY': node.positionY,
      'width': node.width,
      'height': node.height,
      'createdAt': Timestamp.fromDate(node.createdAt),
      'updatedAt': Timestamp.fromDate(node.updatedAt),
    };
  }
}
