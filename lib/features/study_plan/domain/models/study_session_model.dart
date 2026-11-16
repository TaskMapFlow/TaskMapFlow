import 'package:equatable/equatable.dart';

class StudySessionModel extends Equatable {
  const StudySessionModel({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.title,
    required this.scheduledAt,
    required this.plannedDurationMinutes,
    this.topicId,
    this.isCompleted = false,
    this.completedAt,
    this.actualDurationMinutes,
    this.reflectionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String ownerId;
  final String title;
  final DateTime scheduledAt;
  final int plannedDurationMinutes;
  final String? topicId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? actualDurationMinutes;
  final String? reflectionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  StudySessionModel copyWith({
    String? id,
    String? workspaceId,
    String? ownerId,
    String? title,
    DateTime? scheduledAt,
    int? plannedDurationMinutes,
    String? topicId,
    bool? isCompleted,
    DateTime? completedAt,
    int? actualDurationMinutes,
    String? reflectionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearTopicId = false,
    bool clearCompletedAt = false,
    bool clearActualDuration = false,
    bool clearReflectionNotes = false,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      actualDurationMinutes: clearActualDuration
          ? null
          : (actualDurationMinutes ?? this.actualDurationMinutes),
      reflectionNotes: clearReflectionNotes
          ? null
          : (reflectionNotes ?? this.reflectionNotes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        ownerId,
        title,
        scheduledAt,
        plannedDurationMinutes,
        topicId,
        isCompleted,
        completedAt,
        actualDurationMinutes,
        reflectionNotes,
        createdAt,
        updatedAt,
      ];
}
