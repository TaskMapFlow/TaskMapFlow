import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/data/models/sprint_dto.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';
import 'package:task_map_flow/features/tasks/domain/repositories/sprint_repository.dart';

class FirebaseSprintRepository implements SprintRepository {
  FirebaseSprintRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sprintsCol(String workspaceId) =>
      _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('sprints');

  @override
  Stream<Result<List<SprintModel>>> watchSprints({
    required String workspaceId,
    required String ownerId,
  }) async* {
    if (workspaceId.isEmpty || ownerId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      await for (final snapshot in _sprintsCol(workspaceId)
          .where('ownerId', isEqualTo: ownerId)
          .snapshots()) {
        try {
          final sprints = snapshot.docs.map(SprintDto.fromFirestore).toList();
          sprints.sort((a, b) {
            // Sort active first, then planned, then completed
            final statusOrder = {
              SprintStatus.active: 0,
              SprintStatus.planned: 1,
              SprintStatus.completed: 2,
            };
            final orderDiff = (statusOrder[a.status] ?? 3)
                .compareTo(statusOrder[b.status] ?? 3);
            if (orderDiff != 0) return orderDiff;
            return a.startDate.compareTo(b.startDate);
          });
          yield Success(sprints);
        } catch (e) {
          yield Err(_mapException(e));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
  }

  @override
  Future<Result<SprintModel>> createSprint({
    required String workspaceId,
    required String ownerId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    SprintStatus status = SprintStatus.planned,
  }) async {
    try {
      final docRef = _sprintsCol(workspaceId).doc();
      final now = DateTime.now();

      final sprint = SprintModel(
        id: docRef.id,
        workspaceId: workspaceId,
        ownerId: ownerId,
        name: name.trim(),
        goal: goal?.trim() ?? '',
        startDate: DateTime.utc(startDate.year, startDate.month, startDate.day),
        endDate: DateTime.utc(endDate.year, endDate.month, endDate.day),
        status: status,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(SprintDto.toFirestore(sprint));
      return Success(sprint);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateSprint({
    required String workspaceId,
    required String sprintId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    required SprintStatus status,
  }) async {
    try {
      final docRef = _sprintsCol(workspaceId).doc(sprintId);
      final now = DateTime.now();

      await docRef.update({
        'name': name.trim(),
        'goal': goal?.trim() ?? '',
        'startDate': Timestamp.fromDate(
          DateTime.utc(startDate.year, startDate.month, startDate.day),
        ),
        'endDate': Timestamp.fromDate(
          DateTime.utc(endDate.year, endDate.month, endDate.day),
        ),
        'status': status.toFirestoreString(),
        'updatedAt': Timestamp.fromDate(now),
      });

      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateSprintStatus({
    required String workspaceId,
    required String sprintId,
    required SprintStatus status,
  }) async {
    try {
      final docRef = _sprintsCol(workspaceId).doc(sprintId);
      await docRef.update({
        'status': status.toFirestoreString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteSprint({
    required String workspaceId,
    required String sprintId,
  }) async {
    try {
      await _sprintsCol(workspaceId).doc(sprintId).delete();
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> hasSprints({
    required String workspaceId,
    required String ownerId,
  }) async {
    try {
      final snapshot = await _sprintsCol(workspaceId)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      return Success(snapshot.docs.isNotEmpty);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  Failure _mapException(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return const PermissionFailure(
            'Bu sprint işlemine yetkiniz bulunmuyor.',
          );
        case 'not-found':
          return const NotFoundFailure('Sprint bulunamadı.');
        case 'unavailable':
          return const NetworkFailure('Bağlantı hatası. Tekrar deneyin.');
        default:
          return UnknownFailure(
            e.message ?? 'Sprint işlemi sırasında beklenmeyen bir hata oluştu.',
          );
      }
    }
    return UnknownFailure(e.toString());
  }
}
