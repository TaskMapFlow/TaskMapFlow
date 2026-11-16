import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';

abstract interface class WorkspaceRepository {
  Stream<Result<List<Workspace>>> watchWorkspaces(String ownerId);

  Stream<Result<List<MapNode>>> watchMapNodes(String ownerId);

  Future<Result<Workspace>> createWorkspaceWithMapNode({
    required String name,
    String? description,
    required WorkspaceType type,
    required String color,
    required String ownerId,
    required double initialX,
    required double initialY,
    required double width,
    required double height,
  });

  Future<Result<void>> updateWorkspace({
    required String workspaceId,
    required String name,
    String? description,
    required String color,
  });

  Future<Result<void>> updateMapNodeLayout({
    required String nodeId,
    required double positionX,
    required double positionY,
    required double width,
    required double height,
  });

  Future<Result<void>> deleteWorkspaceAndMapNode({
    required String workspaceId,
    required String mapNodeId,
  });
}
