import 'package:equatable/equatable.dart';

class MapNode extends Equatable {
  const MapNode({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String ownerId;
  final double positionX;
  final double positionY;
  final double width;
  final double height;
  final DateTime createdAt;
  final DateTime updatedAt;

  MapNode copyWith({
    String? id,
    String? workspaceId,
    String? ownerId,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MapNode(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      ownerId: ownerId ?? this.ownerId,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        ownerId,
        positionX,
        positionY,
        width,
        height,
        createdAt,
        updatedAt,
      ];
}
