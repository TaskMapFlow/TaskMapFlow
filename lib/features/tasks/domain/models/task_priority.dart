enum TaskPriority {
  low,
  medium,
  high;

  static TaskPriority fromString(String val) => switch (val) {
        'low' => TaskPriority.low,
        'high' => TaskPriority.high,
        _ => TaskPriority.medium,
      };

  String toFirestoreString() => switch (this) {
        TaskPriority.low => 'low',
        TaskPriority.medium => 'medium',
        TaskPriority.high => 'high',
      };
}
