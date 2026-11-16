import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/study_plan/data/repositories/firebase_study_plan_repository.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';
import 'package:task_map_flow/features/study_plan/domain/repositories/study_plan_repository.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

final studyPlanRepositoryProvider = Provider<StudyPlanRepository>((ref) {
  return FirebaseStudyPlanRepository();
});

final topicsStreamProvider = StreamProvider.autoDispose
    .family<List<TopicModel>, String>((ref, workspaceId) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty || workspaceId.isEmpty) {
    yield const [];
    return;
  }

  final repo = ref.watch(studyPlanRepositoryProvider);
  final stream = repo.watchTopics(workspaceId: workspaceId, ownerId: uid);

  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

final studySessionsStreamProvider = StreamProvider.autoDispose
    .family<List<StudySessionModel>, String>((ref, workspaceId) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty || workspaceId.isEmpty) {
    yield const [];
    return;
  }

  final repo = ref.watch(studyPlanRepositoryProvider);
  final stream =
      repo.watchStudySessions(workspaceId: workspaceId, ownerId: uid);

  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

final topicProgressProvider = Provider.autoDispose
    .family<({int completed, int total, double progress}), String>(
        (ref, workspaceId) {
  final topicsAsync = ref.watch(topicsStreamProvider(workspaceId));
  final topics = topicsAsync.valueOrNull ?? [];
  final total = topics.length;
  if (total == 0) {
    return (completed: 0, total: 0, progress: 0.0);
  }
  final completed =
      topics.where((t) => t.status == TopicStatus.completed).length;
  return (
    completed: completed,
    total: total,
    progress: completed / total,
  );
});

final studyPlanControllerProvider =
    StateNotifierProvider<StudyPlanController, AsyncValue<void>>((ref) {
  final repo = ref.watch(studyPlanRepositoryProvider);
  return StudyPlanController(repo);
});

class StudyPlanController extends StateNotifier<AsyncValue<void>> {
  StudyPlanController(this._repository) : super(const AsyncData(null));

  final StudyPlanRepository _repository;

  Future<Result<TopicModel>> createTopic({
    required String workspaceId,
    required String ownerId,
    required String title,
    String? description,
    TopicStatus status = TopicStatus.notStarted,
    int orderIndex = 0,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createTopic(
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title,
      description: description,
      status: status,
      orderIndex: orderIndex,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

  Future<Result<void>> updateTopic({
    required String workspaceId,
    required String topicId,
    required String title,
    String? description,
    required TopicStatus status,
    required int orderIndex,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateTopic(
      workspaceId: workspaceId,
      topicId: topicId,
      title: title,
      description: description,
      status: status,
      orderIndex: orderIndex,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

  Future<Result<void>> reorderTopics({
    required String workspaceId,
    required String ownerId,
    required List<String> topicIds,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.reorderTopics(
      workspaceId: workspaceId,
      ownerId: ownerId,
      topicIds: topicIds,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

  Future<Result<void>> deleteTopic({
    required String workspaceId,
    required String topicId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.deleteTopic(
      workspaceId: workspaceId,
      topicId: topicId,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

  Future<Result<StudySessionModel>> createStudySession({
    required String workspaceId,
    required String ownerId,
    required String title,
    required DateTime scheduledAt,
    required int plannedDurationMinutes,
    String? topicId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createStudySession(
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title,
      scheduledAt: scheduledAt,
      plannedDurationMinutes: plannedDurationMinutes,
      topicId: topicId,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

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
    state = const AsyncLoading();
    final result = await _repository.updateStudySession(
      workspaceId: workspaceId,
      sessionId: sessionId,
      title: title,
      scheduledAt: scheduledAt,
      plannedDurationMinutes: plannedDurationMinutes,
      topicId: topicId,
      isCompleted: isCompleted,
      completedAt: completedAt,
      actualDurationMinutes: actualDurationMinutes,
      reflectionNotes: reflectionNotes,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

  Future<Result<void>> completeStudySession({
    required String workspaceId,
    required String sessionId,
    int? actualDurationMinutes,
    String? reflectionNotes,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.completeStudySession(
      workspaceId: workspaceId,
      sessionId: sessionId,
      actualDurationMinutes: actualDurationMinutes,
      reflectionNotes: reflectionNotes,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

  Future<Result<void>> uncompleteStudySession({
    required String workspaceId,
    required String sessionId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.uncompleteStudySession(
      workspaceId: workspaceId,
      sessionId: sessionId,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }

  Future<Result<void>> deleteStudySession({
    required String workspaceId,
    required String sessionId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.deleteStudySession(
      workspaceId: workspaceId,
      sessionId: sessionId,
    );
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure.message, StackTrace.current),
    };
    return result;
  }
}
