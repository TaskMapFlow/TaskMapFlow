import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';

abstract class StudyPlanRepository {
  Stream<Result<List<TopicModel>>> watchTopics({
    required String workspaceId,
    required String ownerId,
  });

  Future<Result<TopicModel>> createTopic({
    required String workspaceId,
    required String ownerId,
    required String title,
    String? description,
    TopicStatus status = TopicStatus.notStarted,
    int orderIndex = 0,
  });

  Future<Result<void>> updateTopic({
    required String workspaceId,
    required String topicId,
    required String title,
    String? description,
    required TopicStatus status,
    required int orderIndex,
  });

  Future<Result<void>> reorderTopics({
    required String workspaceId,
    required String ownerId,
    required List<String> topicIds,
  });

  Future<Result<void>> deleteTopic({
    required String workspaceId,
    required String topicId,
  });

  Future<Result<bool>> hasTopics({
    required String workspaceId,
    required String ownerId,
  });

  Stream<Result<List<StudySessionModel>>> watchStudySessions({
    required String workspaceId,
    required String ownerId,
  });

  Future<Result<StudySessionModel>> createStudySession({
    required String workspaceId,
    required String ownerId,
    required String title,
    required DateTime scheduledAt,
    required int plannedDurationMinutes,
    String? topicId,
  });

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
  });

  Future<Result<void>> completeStudySession({
    required String workspaceId,
    required String sessionId,
    int? actualDurationMinutes,
    String? reflectionNotes,
  });

  Future<Result<void>> uncompleteStudySession({
    required String workspaceId,
    required String sessionId,
  });

  Future<Result<void>> deleteStudySession({
    required String workspaceId,
    required String sessionId,
  });

  Future<Result<bool>> hasStudySessions({
    required String workspaceId,
    required String ownerId,
  });
}
