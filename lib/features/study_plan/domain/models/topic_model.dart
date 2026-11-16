import 'package:equatable/equatable.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';

class TopicModel extends Equatable {
  const TopicModel({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.title,
    this.description,
    this.status = TopicStatus.notStarted,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String ownerId;
  final String title;
  final String? description;
  final TopicStatus status;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  TopicModel copyWith({
    String? id,
    String? workspaceId,
    String? ownerId,
    String? title,
    String? description,
    TopicStatus? status,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
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
        description,
        status,
        orderIndex,
        createdAt,
        updatedAt,
      ];
}
