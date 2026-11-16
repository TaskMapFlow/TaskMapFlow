import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/workspaces/data/models/map_connection_dto.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_connection.dart';
import 'package:task_map_flow/features/workspaces/domain/repositories/map_connection_repository.dart';

class FirebaseMapConnectionRepository implements MapConnectionRepository {
  FirebaseMapConnectionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _connectionsCol =>
      _firestore.collection('map_connections');

  @override
  Stream<Result<List<MapConnection>>> watchConnections(String ownerId) async* {
    if (ownerId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      await for (final snapshot
          in _connectionsCol.where('ownerId', isEqualTo: ownerId).snapshots()) {
        try {
          final connections =
              snapshot.docs.map(MapConnectionDto.fromFirestore).toList();
          yield Success(connections);
        } catch (e) {
          yield Err(_mapException(e));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
  }

  @override
  Future<Result<MapConnection>> createConnection({
    required String ownerId,
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required ConnectionType type,
  }) async {
    if (sourceWorkspaceId == targetWorkspaceId) {
      return const Err(
        ValidationFailure('Bir alan kendisine bağlanamaz.'),
      );
    }

    try {
      // Check for duplicate connection in same direction
      final existing = await _connectionsCol
          .where('ownerId', isEqualTo: ownerId)
          .where('sourceWorkspaceId', isEqualTo: sourceWorkspaceId)
          .where('targetWorkspaceId', isEqualTo: targetWorkspaceId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return const Err(
          ValidationFailure('Bu alanlar arasında zaten bir bağlantı mevcut.'),
        );
      }

      final docRef = _connectionsCol.doc();
      final now = DateTime.now();

      final connection = MapConnection(
        id: docRef.id,
        ownerId: ownerId,
        sourceWorkspaceId: sourceWorkspaceId,
        targetWorkspaceId: targetWorkspaceId,
        type: type,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(MapConnectionDto.toFirestore(connection));
      return Success(connection);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateConnectionType({
    required String connectionId,
    required ConnectionType type,
  }) async {
    try {
      await _connectionsCol.doc(connectionId).update({
        'type': type.toFirestoreString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteConnection(String connectionId) async {
    try {
      await _connectionsCol.doc(connectionId).delete();
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteConnectionsForWorkspace(String workspaceId) async {
    try {
      final batch = _firestore.batch();

      final sourceMatches = await _connectionsCol
          .where('sourceWorkspaceId', isEqualTo: workspaceId)
          .get();
      for (final doc in sourceMatches.docs) {
        batch.delete(doc.reference);
      }

      final targetMatches = await _connectionsCol
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

  Failure _mapException(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return const PermissionFailure(
            'Bu bağlantı işlemine yetkiniz bulunmuyor.',
          );
        case 'not-found':
          return const NotFoundFailure('Bağlantı bulunamadı.');
        case 'unavailable':
          return const NetworkFailure('Bağlantı hatası. Tekrar deneyin.');
        default:
          return UnknownFailure(
            e.message ?? 'Bağlantı işlemi sırasında bir hata oluştu.',
          );
      }
    }
    return UnknownFailure(e.toString());
  }
}
