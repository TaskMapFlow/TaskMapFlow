import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/workspaces/data/models/map_node_dto.dart';
import 'package:task_map_flow/features/workspaces/data/models/workspace_dto.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/domain/repositories/workspace_repository.dart';

class FirebaseWorkspaceRepository implements WorkspaceRepository {
  FirebaseWorkspaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _workspacesCol =>
      _firestore.collection('workspaces');

  CollectionReference<Map<String, dynamic>> get _mapNodesCol =>
      _firestore.collection('map_nodes');

  @override
  Stream<Result<List<Workspace>>> watchWorkspaces(String ownerId) async* {
    if (ownerId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      await for (final snapshot
          in _workspacesCol.where('ownerId', isEqualTo: ownerId).snapshots()) {
        try {
          final workspaces =
              snapshot.docs.map(WorkspaceDto.fromFirestore).toList();
          workspaces.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          yield Success(workspaces);
        } catch (e) {
          yield Err(_mapException(e));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
  }

  @override
  Stream<Result<List<MapNode>>> watchMapNodes(String ownerId) async* {
    if (ownerId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      await for (final snapshot
          in _mapNodesCol.where('ownerId', isEqualTo: ownerId).snapshots()) {
        try {
          final nodes = snapshot.docs.map(MapNodeDto.fromFirestore).toList();
          yield Success(nodes);
        } catch (e) {
          yield Err(_mapException(e));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
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
    try {
      final now = DateTime.now();
      final wsDoc = _workspacesCol.doc();
      final nodeDoc = _mapNodesCol.doc();

      final workspace = Workspace(
        id: wsDoc.id,
        name: name.trim(),
        description: description?.trim() ?? '',
        type: type,
        color: color,
        ownerId: ownerId,
        createdAt: now,
        updatedAt: now,
      );

      final mapNode = MapNode(
        id: nodeDoc.id,
        workspaceId: wsDoc.id,
        ownerId: ownerId,
        positionX: initialX,
        positionY: initialY,
        width: width,
        height: height,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(wsDoc, WorkspaceDto.toFirestore(workspace));
      batch.set(nodeDoc, MapNodeDto.toFirestore(mapNode));
      await batch.commit();

      return Success(workspace);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateWorkspace({
    required String workspaceId,
    required String name,
    String? description,
    required String color,
  }) async {
    try {
      final now = DateTime.now();
      await _workspacesCol.doc(workspaceId).update({
        'name': name.trim(),
        'description': description?.trim() ?? '',
        'color': color,
        'updatedAt': Timestamp.fromDate(now),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateMapNodeLayout({
    required String nodeId,
    required double positionX,
    required double positionY,
    required double width,
    required double height,
  }) async {
    try {
      final now = DateTime.now();
      await _mapNodesCol.doc(nodeId).update({
        'positionX': positionX,
        'positionY': positionY,
        'width': width,
        'height': height,
        'updatedAt': Timestamp.fromDate(now),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteWorkspaceAndMapNode({
    required String workspaceId,
    required String mapNodeId,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.delete(_workspacesCol.doc(workspaceId));
      if (mapNodeId.isNotEmpty) {
        batch.delete(_mapNodesCol.doc(mapNodeId));
      }

      // Clean up connections involving this workspace
      final sourceMatches = await _firestore
          .collection('map_connections')
          .where('sourceWorkspaceId', isEqualTo: workspaceId)
          .get();
      for (final doc in sourceMatches.docs) {
        batch.delete(doc.reference);
      }

      final targetMatches = await _firestore
          .collection('map_connections')
          .where('targetWorkspaceId', isEqualTo: workspaceId)
          .get();
      for (final doc in targetMatches.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  Failure _mapException(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          const PermissionFailure('Erişim reddedildi. Yetkiniz bulunmuyor.'),
        'unavailable' || 'network-request-failed' => const NetworkFailure(
            'Bağlantı hatası. İnternet bağlantınızı kontrol edin.'),
        'not-found' => const NotFoundFailure('Kayıt bulunamadı.'),
        _ =>
          UnknownFailure(error.message ?? 'Veritabanı işlemi başarısız oldu.'),
      };
    }
    return UnknownFailure(error.toString());
  }
}
