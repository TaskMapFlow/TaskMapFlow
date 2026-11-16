import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';
import 'package:task_map_flow/features/study_plan/domain/repositories/study_plan_repository.dart';

class FakeStudyPlanRepository implements StudyPlanRepository {
  FakeStudyPlanRepository({
    List<TopicModel> initialTopics = const [],
    List<StudySessionModel> initialSessions = const [],
  }) {
    for (final t in initialTopics) {
      _topics.putIfAbsent(t.workspaceId, () => []).add(t);
    }
    for (final s in initialSessions) {
      _sessions.putIfAbsent(s.workspaceId, () => []).add(s);
    }
  }

  final Map<String, List<TopicModel>> _topics = {};
  final Map<String, List<StudySessionModel>> _sessions = {};
  final Map<String, StreamController<Result<List<TopicModel>>>>
      _topicControllers = {};
  final Map<String, StreamController<Result<List<StudySessionModel>>>>
      _sessionControllers = {};

  StreamController<Result<List<TopicModel>>> _getTopicController(
      String workspaceId) {
    return _topicControllers.putIfAbsent(
      workspaceId,
      () => StreamController<Result<List<TopicModel>>>.broadcast(),
    );
  }

  StreamController<Result<List<StudySessionModel>>> _getSessionController(
      String workspaceId) {
    return _sessionControllers.putIfAbsent(
      workspaceId,
      () => StreamController<Result<List<StudySessionModel>>>.broadcast(),
    );
  }

  void _notifyTopics(String workspaceId) {
    final list = _topics[workspaceId] ?? [];
    final sorted = List<TopicModel>.from(list)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    _getTopicController(workspaceId).add(Success(sorted));
  }

  void _notifySessions(String workspaceId) {
    final list = _sessions[workspaceId] ?? [];
    final sorted = List<StudySessionModel>.from(list)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    _getSessionController(workspaceId).add(Success(sorted));
  }

  @override
  Stream<Result<List<TopicModel>>> watchTopics({
    required String workspaceId,
    required String ownerId,
  }) async* {
    final list = _topics[workspaceId] ?? [];
    final sorted = List<TopicModel>.from(list)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    yield Success(sorted);
    yield* _getTopicController(workspaceId).stream;
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
    final now = DateTime.now();
    final topic = TopicModel(
      id: 'topic_${now.millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title,
      description: description,
      status: status,
      orderIndex: orderIndex,
      createdAt: now,
      updatedAt: now,
    );
    _topics.putIfAbsent(workspaceId, () => []).add(topic);
    _notifyTopics(workspaceId);
    return Success(topic);
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
    final list = _topics[workspaceId] ?? [];
    final idx = list.indexWhere((t) => t.id == topicId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        title: title,
        description: description,
        status: status,
        orderIndex: orderIndex,
        updatedAt: DateTime.now(),
      );
      _notifyTopics(workspaceId);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> reorderTopics({
    required String workspaceId,
    required String ownerId,
    required List<String> topicIds,
  }) async {
    final list = _topics[workspaceId] ?? [];
    final reordered = <TopicModel>[];
    for (int i = 0; i < topicIds.length; i++) {
      final found = list.firstWhere((t) => t.id == topicIds[i]);
      reordered.add(found.copyWith(orderIndex: i, updatedAt: DateTime.now()));
    }
    _topics[workspaceId] = reordered;
    _notifyTopics(workspaceId);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteTopic({
    required String workspaceId,
    required String topicId,
  }) async {
    _topics[workspaceId]?.removeWhere((t) => t.id == topicId);
    _notifyTopics(workspaceId);
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasTopics({
    required String workspaceId,
    required String ownerId,
  }) async {
    final list = _topics[workspaceId] ?? [];
    return Success(list.any((t) => t.ownerId == ownerId));
  }

  @override
  Stream<Result<List<StudySessionModel>>> watchStudySessions({
    required String workspaceId,
    required String ownerId,
  }) async* {
    final list = _sessions[workspaceId] ?? [];
    final sorted = List<StudySessionModel>.from(list)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    yield Success(sorted);
    yield* _getSessionController(workspaceId).stream;
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
    final now = DateTime.now();
    final session = StudySessionModel(
      id: 'session_${now.millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title,
      scheduledAt: scheduledAt,
      plannedDurationMinutes: plannedDurationMinutes,
      topicId: topicId,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    _sessions.putIfAbsent(workspaceId, () => []).add(session);
    _notifySessions(workspaceId);
    return Success(session);
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
    final list = _sessions[workspaceId] ?? [];
    final idx = list.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        title: title,
        scheduledAt: scheduledAt,
        plannedDurationMinutes: plannedDurationMinutes,
        topicId: topicId,
        isCompleted: isCompleted,
        completedAt: completedAt,
        actualDurationMinutes: actualDurationMinutes,
        reflectionNotes: reflectionNotes,
        updatedAt: DateTime.now(),
      );
      _notifySessions(workspaceId);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> completeStudySession({
    required String workspaceId,
    required String sessionId,
    int? actualDurationMinutes,
    String? reflectionNotes,
  }) async {
    final list = _sessions[workspaceId] ?? [];
    final idx = list.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        actualDurationMinutes: actualDurationMinutes,
        reflectionNotes: reflectionNotes,
        updatedAt: DateTime.now(),
      );
      _notifySessions(workspaceId);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> uncompleteStudySession({
    required String workspaceId,
    required String sessionId,
  }) async {
    final list = _sessions[workspaceId] ?? [];
    final idx = list.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        isCompleted: false,
        clearCompletedAt: true,
        updatedAt: DateTime.now(),
      );
      _notifySessions(workspaceId);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteStudySession({
    required String workspaceId,
    required String sessionId,
  }) async {
    _sessions[workspaceId]?.removeWhere((s) => s.id == sessionId);
    _notifySessions(workspaceId);
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasStudySessions({
    required String workspaceId,
    required String ownerId,
  }) async {
    final list = _sessions[workspaceId] ?? [];
    return Success(list.any((s) => s.ownerId == ownerId));
  }
}
