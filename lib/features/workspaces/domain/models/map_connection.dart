import 'package:equatable/equatable.dart';

enum ConnectionType {
  related,
  blocks;

  static ConnectionType fromString(String val) => switch (val) {
        'blocks' || 'dependency' => ConnectionType.blocks,
        _ => ConnectionType.related,
      };

  String toFirestoreString() => switch (this) {
        ConnectionType.related => 'related',
        ConnectionType.blocks => 'blocks',
      };
}

class MapConnection extends Equatable {
  const MapConnection({
    required this.id,
    required this.ownerId,
    required this.sourceWorkspaceId,
    required this.targetWorkspaceId,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String sourceWorkspaceId;
  final String targetWorkspaceId;
  final ConnectionType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDirected => type == ConnectionType.blocks;

  MapConnection copyWith({
    String? id,
    String? ownerId,
    String? sourceWorkspaceId,
    String? targetWorkspaceId,
    ConnectionType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MapConnection(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      sourceWorkspaceId: sourceWorkspaceId ?? this.sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId ?? this.targetWorkspaceId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        sourceWorkspaceId,
        targetWorkspaceId,
        type,
        createdAt,
        updatedAt,
      ];
}
