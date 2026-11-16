import 'package:equatable/equatable.dart';
import 'package:task_map_flow/features/workspaces/domain/models/resource_link.dart';

enum WorkspaceType {
  project,
  lesson,
  freeform;

  static WorkspaceType fromString(String value) {
    return switch (value) {
      'project' => WorkspaceType.project,
      'lesson' => WorkspaceType.lesson,
      'freeform' => WorkspaceType.freeform,
      _ => WorkspaceType.freeform,
    };
  }

  String toFirestoreString() => name;
}

class Workspace extends Equatable {
  const Workspace({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.color,
    required this.ownerId,
    this.tags = const [],
    this.resources = const [],
    this.isArchived = false,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final WorkspaceType type;
  final String color;
  final String ownerId;
  final List<String> tags;
  final List<ResourceLink> resources;
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workspace copyWith({
    String? id,
    String? name,
    String? description,
    WorkspaceType? type,
    String? color,
    String? ownerId,
    List<String>? tags,
    List<ResourceLink>? resources,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
      tags: tags ?? this.tags,
      resources: resources ?? this.resources,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        color,
        ownerId,
        tags,
        resources,
        isArchived,
        archivedAt,
        createdAt,
        updatedAt,
      ];
}
