import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/study_plan/data/models/study_session_dto.dart';
import 'package:task_map_flow/features/study_plan/data/models/topic_dto.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';
import 'package:task_map_flow/features/study_plan/domain/repositories/study_plan_repository.dart';

class FirebaseStudyPlanRepository implements StudyPlanRepository {
  FirebaseStudyPlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _topicsCol(String workspaceId) =>
      _firestore.collection('workspaces').doc(workspaceId).collection('topics');

  CollectionReference<Map<String, dynamic>> _studySessionsCol(
          String workspaceId) =>
      _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('study_sessions');

  @override
  Stream<Result<List<TopicModel>>> watchTopics({
    required String workspaceId,
    required String ownerId,
  }) async* {
    if (workspaceId.isEmpty || ownerId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      final query =
          _topicsCol(workspaceId).where('ownerId', isEqualTo: ownerId);

      await for (final snapshot in query.snapshots()) {
        try {
          final topics = snapshot.docs.map(TopicDto.fromFirestore).toList();
          topics.sort((a, b) {
            final orderComp = a.orderIndex.compareTo(b.orderIndex);
            if (orderComp != 0) return orderComp;
            return a.createdAt.compareTo(b.createdAt);
          });
          yield Success(topics);
        } catch (e) {
          debugPrint(
              '[FirebaseStudyPlanRepository] Error mapping topics for workspace=$workspaceId: $e');
          yield const Err(
              UnknownFailure('Konular işlenirken bir hata oluştu.'));
        }
      }
    } on FirebaseException catch (e) {
      debugPrint(
          '[FirebaseStudyPlanRepository] Firestore error in watchTopics for workspace=$workspaceId: ${e.code}');
      yield Err(_mapFirebaseException(e));
    } catch (e) {
      yield const Err(UnknownFailure('Konular yüklenemedi.'));
    }
  }

  @override
  Future<Result<TopicModel>> createTopic({
    required String workspaceId,
    required String ownerId,
    required String title,
    String? description,
    TopicStatus status = TopicStatus.notStarted,
    int orderIndex = 0,
  }) async {
    try {
      final docRef = _topicsCol(workspaceId).doc();
      final now = DateTime.now();
      final topic = TopicModel(
        id: docRef.id,
        workspaceId: workspaceId,
        ownerId: ownerId,
        title: title.trim(),
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        status: status,
        orderIndex: orderIndex,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(TopicDto.toFirestore(topic));
      return Success(topic);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Konu oluşturulamadı.'));
    }
  }

  @override
  Future<Result<void>> updateTopic({
    required String workspaceId,
    required String topicId,
    required String title,
    String? description,
    required TopicStatus status,
    required int orderIndex,
  }) async {
    try {
      await _topicsCol(workspaceId).doc(topicId).update({
        'title': title.trim(),
        'description':
            description?.trim().isEmpty == true ? null : description?.trim(),
        'status': status.toFirestoreString(),
        'orderIndex': orderIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Konu güncellenemedi.'));
    }
  }

  @override
  Future<Result<void>> reorderTopics({
    required String workspaceId,
    required String ownerId,
    required List<String> topicIds,
  }) async {
    try {
      final batch = _firestore.batch();
      for (int i = 0; i < topicIds.length; i++) {
        final docRef = _topicsCol(workspaceId).doc(topicIds[i]);
        batch.update(docRef, {
          'orderIndex': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Konu sıralaması kaydedilemedi.'));
    }
  }

  @override
  Future<Result<void>> deleteTopic({
    required String workspaceId,
    required String topicId,
  }) async {
    try {
      await _topicsCol(workspaceId).doc(topicId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Konu silinemedi.'));
    }
  }

  @override
  Future<Result<bool>> hasTopics({
    required String workspaceId,
    required String ownerId,
  }) async {
    try {
      final snap = await _topicsCol(workspaceId)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      return Success(snap.docs.isNotEmpty);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Konu kontrolü yapılamadı.'));
    }
  }

  @override
  Stream<Result<List<StudySessionModel>>> watchStudySessions({
    required String workspaceId,
    required String ownerId,
  }) async* {
    if (workspaceId.isEmpty || ownerId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      final query =
          _studySessionsCol(workspaceId).where('ownerId', isEqualTo: ownerId);

      await for (final snapshot in query.snapshots()) {
        try {
          final sessions =
              snapshot.docs.map(StudySessionDto.fromFirestore).toList();
          sessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          yield Success(sessions);
        } catch (e) {
          debugPrint(
              '[FirebaseStudyPlanRepository] Error mapping study sessions for workspace=$workspaceId: $e');
          yield const Err(
              UnknownFailure('Çalışma oturumları işlenirken bir hata oluştu.'));
        }
      }
    } on FirebaseException catch (e) {
      debugPrint(
          '[FirebaseStudyPlanRepository] Firestore error in watchStudySessions for workspace=$workspaceId: ${e.code}');
      yield Err(_mapFirebaseException(e));
    } catch (e) {
      yield const Err(UnknownFailure('Çalışma oturumları yüklenemedi.'));
    }
  }

  @override
  Future<Result<StudySessionModel>> createStudySession({
    required String workspaceId,
    required String ownerId,
    required String title,
    required DateTime scheduledAt,
    required int plannedDurationMinutes,
    String? topicId,
  }) async {
    try {
      final docRef = _studySessionsCol(workspaceId).doc();
      final now = DateTime.now();
      final session = StudySessionModel(
        id: docRef.id,
        workspaceId: workspaceId,
        ownerId: ownerId,
        title: title.trim(),
        scheduledAt: scheduledAt,
        plannedDurationMinutes: plannedDurationMinutes,
        topicId: (topicId == null || topicId.isEmpty) ? null : topicId,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(StudySessionDto.toFirestore(session));
      return Success(session);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Çalışma oturumu oluşturulamadı.'));
    }
  }

  @override
  Future<Result<void>> updateStudySession({
    required String workspaceId,
    required String sessionId,
    required String title,
    required DateTime scheduledAt,
    required int plannedDurationMinutes,
    String? topicId,
    bool? isCompleted,
    DateTime? completedAt,
    int? actualDurationMinutes,
    String? reflectionNotes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'title': title.trim(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'plannedDurationMinutes': plannedDurationMinutes,
        'topicId': (topicId == null || topicId.isEmpty) ? null : topicId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isCompleted != null) {
        updates['isCompleted'] = isCompleted;
      }
      if (completedAt != null) {
        updates['completedAt'] = Timestamp.fromDate(completedAt);
      } else if (isCompleted == false) {
        updates['completedAt'] = null;
      }
      if (actualDurationMinutes != null) {
        updates['actualDurationMinutes'] = actualDurationMinutes;
      }
      if (reflectionNotes != null) {
        updates['reflectionNotes'] =
            reflectionNotes.trim().isEmpty ? null : reflectionNotes.trim();
      }

      await _studySessionsCol(workspaceId).doc(sessionId).update(updates);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Çalışma oturumu güncellenemedi.'));
    }
  }

  @override
  Future<Result<void>> completeStudySession({
    required String workspaceId,
    required String sessionId,
    int? actualDurationMinutes,
    String? reflectionNotes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (actualDurationMinutes != null) {
        updates['actualDurationMinutes'] = actualDurationMinutes;
      }
      if (reflectionNotes != null && reflectionNotes.trim().isNotEmpty) {
        updates['reflectionNotes'] = reflectionNotes.trim();
      }

      await _studySessionsCol(workspaceId).doc(sessionId).update(updates);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Çalışma oturumu tamamlanamadı.'));
    }
  }

  @override
  Future<Result<void>> uncompleteStudySession({
    required String workspaceId,
    required String sessionId,
  }) async {
    try {
      await _studySessionsCol(workspaceId).doc(sessionId).update({
        'isCompleted': false,
        'completedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(
          UnknownFailure('Çalışma oturumu durumu güncellenemedi.'));
    }
  }

  @override
  Future<Result<void>> deleteStudySession({
    required String workspaceId,
    required String sessionId,
  }) async {
    try {
      await _studySessionsCol(workspaceId).doc(sessionId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Çalışma oturumu silinemedi.'));
    }
  }

  @override
  Future<Result<bool>> hasStudySessions({
    required String workspaceId,
    required String ownerId,
  }) async {
    try {
      final snap = await _studySessionsCol(workspaceId)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      return Success(snap.docs.isNotEmpty);
    } on FirebaseException catch (e) {
      return Err(_mapFirebaseException(e));
    } catch (e) {
      return const Err(UnknownFailure('Çalışma oturumu kontrolü yapılamadı.'));
    }
  }

  Failure _mapFirebaseException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' =>
        const PermissionFailure('Erişim reddedildi. Yetkiniz bulunmuyor.'),
      'not-found' => const NotFoundFailure('Kayıt bulunamadı.'),
      'unavailable' || 'network-request-failed' => const NetworkFailure(
          'Bağlantı kurulamadı. İnternetinizi kontrol edin.'),
      _ => UnknownFailure(e.message ?? 'Veritabanı işlemi başarısız oldu.'),
    };
  }
}
