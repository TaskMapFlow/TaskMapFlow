import 'package:equatable/equatable.dart';
import 'package:task_map_flow/features/tasks/domain/models/subtask_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';

class TaskModel extends Equatable {
  const TaskModel({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.sprintId,
    this.assigneeId,
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String ownerId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? sprintId;
  final String? assigneeId;
  final List<SubtaskModel> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isBacklog => sprintId == null || sprintId!.isEmpty;

  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;

  bool get isOverdue {
    if (status == TaskStatus.completed || dueDate == null) return false;
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final dueUtc = DateTime.utc(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueUtc.isBefore(todayUtc);
  }

  TaskModel copyWith({
    String? id,
    String? workspaceId,
    String? ownerId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? Function()? dueDate,
    String? Function()? sprintId,
    String? Function()? assigneeId,
    List<SubtaskModel>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      sprintId: sprintId != null ? sprintId() : this.sprintId,
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
      subtasks: subtasks ?? this.subtasks,
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
        priority,
        dueDate,
        sprintId,
        assigneeId,
        subtasks,
        createdAt,
        updatedAt,
      ];
}
