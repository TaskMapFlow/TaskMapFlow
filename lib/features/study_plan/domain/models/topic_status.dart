enum TopicStatus {
  notStarted,
  inProgress,
  completed;

  static TopicStatus fromString(String value) => switch (value) {
        'in_progress' => TopicStatus.inProgress,
        'completed' => TopicStatus.completed,
        _ => TopicStatus.notStarted,
      };

  String toFirestoreString() => switch (this) {
        TopicStatus.notStarted => 'not_started',
        TopicStatus.inProgress => 'in_progress',
        TopicStatus.completed => 'completed',
      };
}
