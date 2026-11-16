import 'package:equatable/equatable.dart';

enum SprintStatus {
  planned,
  active,
  completed;

  static SprintStatus fromString(String val) => switch (val) {
        'active' => SprintStatus.active,
        'completed' => SprintStatus.completed,
        _ => SprintStatus.planned,
      };

  String toFirestoreString() => switch (this) {
        SprintStatus.planned => 'planned',
        SprintStatus.active => 'active',
        SprintStatus.completed => 'completed',
      };
}

class SprintModel extends Equatable {
  const SprintModel({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.name,
    this.goal = '',
    required this.startDate,
    required this.endDate,
    this.status = SprintStatus.planned,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String ownerId;
  final String name;
  final String goal;
  final DateTime startDate;
  final DateTime endDate;
  final SprintStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPlanned => status == SprintStatus.planned;
  bool get isActive => status == SprintStatus.active;
  bool get isCompleted => status == SprintStatus.completed;

  SprintModel copyWith({
    String? id,
    String? workspaceId,
    String? ownerId,
    String? name,
    String? goal,
    DateTime? startDate,
    DateTime? endDate,
    SprintStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SprintModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        ownerId,
        name,
        goal,
        startDate,
        endDate,
        status,
        createdAt,
        updatedAt,
      ];
}
