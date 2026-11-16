import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/domain/repositories/workspace_repository.dart';

class FakeWorkspaceRepository implements WorkspaceRepository {
  FakeWorkspaceRepository({
    List<Workspace>? initialWorkspaces,
    List<MapNode>? initialNodes,
  })  : _workspaces = initialWorkspaces ?? [],
        _nodes = initialNodes ?? [];

  final List<Workspace> _workspaces;
  final List<MapNode> _nodes;

  final _wsStreamController =
      StreamController<Result<List<Workspace>>>.broadcast();
  final _nodesStreamController =
      StreamController<Result<List<MapNode>>>.broadcast();

  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;

  @override
  Stream<Result<List<Workspace>>> watchWorkspaces(String ownerId) {
    scheduleMicrotask(() {
      _wsStreamController.add(Success(List.unmodifiable(_workspaces)));
    });
    return _wsStreamController.stream;
  }

  @override
  Stream<Result<List<MapNode>>> watchMapNodes(String ownerId) {
    scheduleMicrotask(() {
      _nodesStreamController.add(Success(List.unmodifiable(_nodes)));
    });
    return _nodesStreamController.stream;
  }

  @override
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
  }) async {
    createCallCount++;
    final now = DateTime.now();
    final ws = Workspace(
      id: 'ws_${_workspaces.length + 1}',
      name: name,
      description: description,
      type: type,
      color: color,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
    );
    final node = MapNode(
      id: 'node_${_nodes.length + 1}',
      workspaceId: ws.id,
      ownerId: ownerId,
      positionX: initialX,
      positionY: initialY,
      width: width,
      height: height,
      createdAt: now,
      updatedAt: now,
    );

    _workspaces.add(ws);
    _nodes.add(node);

    _wsStreamController.add(Success(List.unmodifiable(_workspaces)));
    _nodesStreamController.add(Success(List.unmodifiable(_nodes)));

    return Success(ws);
  }

  @override
  Future<Result<void>> updateWorkspace({
    required String workspaceId,
    required String name,
    String? description,
    required String color,
  }) async {
    updateCallCount++;
    final idx = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (idx != -1) {
      _workspaces[idx] = _workspaces[idx].copyWith(
        name: name,
        description: description,
        color: color,
        updatedAt: DateTime.now(),
      );
      _wsStreamController.add(Success(List.unmodifiable(_workspaces)));
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> updateMapNodeLayout({
    required String nodeId,
    required double positionX,
    required double positionY,
    required double width,
    required double height,
  }) async {
    updateCallCount++;
    final idx = _nodes.indexWhere((n) => n.id == nodeId);
    if (idx != -1) {
      _nodes[idx] = _nodes[idx].copyWith(
        positionX: positionX,
        positionY: positionY,
        width: width,
        height: height,
        updatedAt: DateTime.now(),
      );
      _nodesStreamController.add(Success(List.unmodifiable(_nodes)));
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteWorkspaceAndMapNode({
    required String workspaceId,
    required String mapNodeId,
  }) async {
    deleteCallCount++;
    _workspaces.removeWhere((w) => w.id == workspaceId);
    _nodes
        .removeWhere((n) => n.id == mapNodeId || n.workspaceId == workspaceId);

    _wsStreamController.add(Success(List.unmodifiable(_workspaces)));
    _nodesStreamController.add(Success(List.unmodifiable(_nodes)));

    return const Success(null);
  }

  void dispose() {
    _wsStreamController.close();
    _nodesStreamController.close();
  }
}
