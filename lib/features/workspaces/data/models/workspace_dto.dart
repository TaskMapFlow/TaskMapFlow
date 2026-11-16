import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/features/workspaces/domain/models/resource_link.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';

class WorkspaceDto {
  static Workspace fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final tags =
        (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const <String>[];

    final rawResources = data['resources'] as List<dynamic>? ?? const [];
    final resources = rawResources
        .whereType<Map<String, dynamic>>()
        .map(ResourceLink.fromMap)
        .toList();

    final isArchived = data['isArchived'] as bool? ?? false;
    final archivedAt = (data['archivedAt'] as Timestamp?)?.toDate();
    final isTeamEnabled = data['isTeamEnabled'] as bool? ?? false;
    final memberIds = (data['memberIds'] as List<dynamic>?)?.cast<String>() ??
        (data['ownerId'] != null ? [data['ownerId'] as String] : <String>[]);

    return Workspace(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      type: WorkspaceType.fromString(data['type'] as String? ?? ''),
      color: data['color'] as String? ?? '#7C5CE8',
      ownerId: data['ownerId'] as String? ?? '',
      tags: tags,
      resources: resources,
      isArchived: isArchived,
      archivedAt: archivedAt,
      isTeamEnabled: isTeamEnabled,
      memberIds: memberIds,
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
      'tags': workspace.tags,
      'resources': workspace.resources.map((r) => r.toMap()).toList(),
      'isArchived': workspace.isArchived,
      'archivedAt': workspace.archivedAt != null
          ? Timestamp.fromDate(workspace.archivedAt!)
          : null,
      'isTeamEnabled': workspace.isTeamEnabled,
      'memberIds': workspace.memberIds.isNotEmpty
          ? workspace.memberIds
          : [workspace.ownerId],
      'createdAt': Timestamp.fromDate(workspace.createdAt),
      'updatedAt': Timestamp.fromDate(workspace.updatedAt),
    };
  }
}
