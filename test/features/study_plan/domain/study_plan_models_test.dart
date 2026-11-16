import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';

void main() {
  group('TopicStatus Tests', () {
    test('converts correctly between string and enum', () {
      expect(TopicStatus.fromString('not_started'), TopicStatus.notStarted);
      expect(TopicStatus.fromString('in_progress'), TopicStatus.inProgress);
      expect(TopicStatus.fromString('completed'), TopicStatus.completed);
      expect(TopicStatus.fromString('unknown'), TopicStatus.notStarted);

      expect(TopicStatus.notStarted.toFirestoreString(), 'not_started');
      expect(TopicStatus.inProgress.toFirestoreString(), 'in_progress');
      expect(TopicStatus.completed.toFirestoreString(), 'completed');
    });
  });

  group('TopicModel Tests', () {
    final now = DateTime.now();
    test('props equality and copyWith', () {
      final topic1 = TopicModel(
        id: 't1',
        workspaceId: 'ws1',
        ownerId: 'u1',
        title: 'Türev',
        description: 'Türev kuralları',
        status: TopicStatus.inProgress,
        orderIndex: 0,
        createdAt: now,
        updatedAt: now,
      );

      final topic2 = topic1.copyWith(status: TopicStatus.completed);

      expect(topic1.status, TopicStatus.inProgress);
      expect(topic2.status, TopicStatus.completed);
      expect(topic1.title, topic2.title);
      expect(topic1 == topic2, isFalse);
    });
  });

  group('StudySessionModel Tests', () {
    final past = DateTime.now().subtract(const Duration(hours: 2));
    final future = DateTime.now().add(const Duration(hours: 2));
    final now = DateTime.now();

    test('isPast correctly checks scheduled time', () {
      final pastSession = StudySessionModel(
        id: 's1',
        workspaceId: 'ws1',
        ownerId: 'u1',
        title: 'Limit Soru Çözümü',
        scheduledAt: past,
        plannedDurationMinutes: 45,
        createdAt: now,
        updatedAt: now,
      );

      final futureSession = StudySessionModel(
        id: 's2',
        workspaceId: 'ws1',
        ownerId: 'u1',
        title: 'İntegral Soru Çözümü',
        scheduledAt: future,
        plannedDurationMinutes: 60,
        createdAt: now,
        updatedAt: now,
      );

      expect(pastSession.isPast, isTrue);
      expect(futureSession.isPast, isFalse);
    });

    test('copyWith clears fields correctly', () {
      final session = StudySessionModel(
        id: 's1',
        workspaceId: 'ws1',
        ownerId: 'u1',
        title: 'Oturum 1',
        scheduledAt: past,
        plannedDurationMinutes: 45,
        topicId: 't1',
        isCompleted: true,
        completedAt: now,
        actualDurationMinutes: 50,
        reflectionNotes: 'İyi geçti',
        createdAt: now,
        updatedAt: now,
      );

      final uncompleted = session.copyWith(
        isCompleted: false,
        clearCompletedAt: true,
        clearActualDuration: true,
        clearReflectionNotes: true,
      );

      expect(uncompleted.isCompleted, isFalse);
      expect(uncompleted.completedAt, isNull);
      expect(uncompleted.actualDurationMinutes, isNull);
      expect(uncompleted.reflectionNotes, isNull);
    });
  });
}
