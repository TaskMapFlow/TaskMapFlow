enum TaskStatus {
  todo,
  inProgress,
  completed;

  static TaskStatus fromString(String val) => switch (val) {
        'in_progress' || 'inProgress' => TaskStatus.inProgress,
        'completed' || 'done' => TaskStatus.completed,
        _ => TaskStatus.todo,
      };

  String toFirestoreString() => switch (this) {
        TaskStatus.todo => 'todo',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.completed => 'completed',
      };
}
