import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';

void main() {
  group('TaskModel Tests', () {
    final now = DateTime.now();

    test(
        'isOverdue returns true only when task is not completed and due date is past',
        () {
      final pastDate = DateTime.utc(2020, 1, 1);
      final futureDate = DateTime.utc(2099, 1, 1);

      final overdueTask = TaskModel(
        id: '1',
        workspaceId: 'ws1',
        ownerId: 'u1',
        title: 'Overdue Task',
        status: TaskStatus.todo,
        dueDate: pastDate,
        createdAt: now,
        updatedAt: now,
      );

      expect(overdueTask.isOverdue, isTrue);

      final completedOverdueTask = overdueTask.copyWith(
        status: TaskStatus.completed,
      );
      expect(completedOverdueTask.isOverdue, isFalse);

      final futureTask = overdueTask.copyWith(
        dueDate: () => futureDate,
      );
      expect(futureTask.isOverdue, isFalse);
    });

    test('TaskStatus string conversions', () {
      expect(TaskStatus.fromString('todo'), TaskStatus.todo);
      expect(TaskStatus.fromString('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.todo.toFirestoreString(), 'todo');
      expect(TaskStatus.inProgress.toFirestoreString(), 'in_progress');
      expect(TaskStatus.completed.toFirestoreString(), 'completed');
    });

    test('TaskPriority string conversions', () {
      expect(TaskPriority.fromString('low'), TaskPriority.low);
      expect(TaskPriority.fromString('medium'), TaskPriority.medium);
      expect(TaskPriority.fromString('high'), TaskPriority.high);
      expect(TaskPriority.low.toFirestoreString(), 'low');
      expect(TaskPriority.medium.toFirestoreString(), 'medium');
      expect(TaskPriority.high.toFirestoreString(), 'high');
    });
  });
}
