import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_connection.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/map_connection_providers.dart';

Offset getRectEdgePoint(Rect rect, Offset target) {
  final center = rect.center;
  final dx = target.dx - center.dx;
  final dy = target.dy - center.dy;
  if (dx == 0 && dy == 0) return center;

  final halfW = rect.width / 2;
  final halfH = rect.height / 2;

  final scaleX = halfW / dx.abs();
  final scaleY = halfH / dy.abs();
  final scale = scaleX < scaleY ? scaleX : scaleY;

  return Offset(center.dx + dx * scale, center.dy + dy * scale);
}

class MapConnectionsPainter extends CustomPainter {
  MapConnectionsPainter({
    required this.connections,
    required this.nodeMap,
    required this.isDark,
  });

  final List<MapConnection> connections;
  final Map<String, MapNode> nodeMap;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      final source = nodeMap[conn.sourceWorkspaceId];
      final target = nodeMap[conn.targetWorkspaceId];
      if (source == null || target == null) continue;

      final sourceRect = Rect.fromLTWH(
        source.positionX,
        source.positionY,
        source.width,
        source.height,
      );
      final targetRect = Rect.fromLTWH(
        target.positionX,
        target.positionY,
        target.width,
        target.height,
      );

      final start = getRectEdgePoint(sourceRect, targetRect.center);
      final end = getRectEdgePoint(targetRect, sourceRect.center);

      final isBlocks = conn.type == ConnectionType.blocks;
      final strokeColor = isBlocks
          ? const Color(0xFFF59E0B) // Amber for blocking dependency
          : (isDark
              ? const Color(0xFF9381FF).withValues(alpha: 0.8)
              : const Color(0xFF6366F1).withValues(alpha: 0.85));

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = isBlocks ? 2.8 : 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (!isBlocks) {
        // Draw dotted/dashed style or clean curve for related
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
      } else {
        // Draw solid line
        canvas.drawLine(start, end, paint);

        // Draw directed arrow head at `end`
        final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
        const arrowSize = 12.0;
        const arrowAngle = math.pi / 6;

        final arrowPath = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx - arrowSize * math.cos(angle - arrowAngle),
            end.dy - arrowSize * math.sin(angle - arrowAngle),
          )
          ..lineTo(
            end.dx - arrowSize * math.cos(angle + arrowAngle),
            end.dy - arrowSize * math.sin(angle + arrowAngle),
          )
          ..close();

        final arrowPaint = Paint()
          ..color = strokeColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapConnectionsPainter oldDelegate) => true;
}

class ConnectionMidpointBadge extends ConsumerWidget {
  const ConnectionMidpointBadge({
    super.key,
    required this.connection,
    required this.sourceNode,
    required this.targetNode,
    required this.sourceName,
    required this.targetName,
  });

  final MapConnection connection;
  final MapNode sourceNode;
  final MapNode targetNode;
  final String sourceName;
  final String targetName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlocks = connection.type == ConnectionType.blocks;

    final sourceRect = Rect.fromLTWH(
      sourceNode.positionX,
      sourceNode.positionY,
      sourceNode.width,
      sourceNode.height,
    );
    final targetRect = Rect.fromLTWH(
      targetNode.positionX,
      targetNode.positionY,
      targetNode.width,
      targetNode.height,
    );

    final start = getRectEdgePoint(sourceRect, targetRect.center);
    final end = getRectEdgePoint(targetRect, sourceRect.center);
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    final badgeColor = isBlocks
        ? const Color(0xFFF59E0B)
        : (isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple);

    return Positioned(
      left: midX - 16,
      top: midY - 16,
      child: GestureDetector(
        onTap: () => _showConnectionDialog(context, ref),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1829) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isBlocks ? Icons.arrow_forward_rounded : Icons.link_rounded,
            size: 16,
            color: badgeColor,
          ),
        ),
      ),
    );
  }

  void _showConnectionDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        var currentType = connection.type;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1B1829) : Colors.white,
              title: Text(
                l10n.connectionType,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sourceName ➔ $targetName',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => setDialogState(
                        () => currentType = ConnectionType.related),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            currentType == ConnectionType.related
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: currentType == ConnectionType.related
                                ? AppColors.darkPrimaryPurple
                                : null,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.connectionRelated,
                                    style: const TextStyle(fontSize: 14)),
                                Text(
                                  l10n.connectionRelatedDesc,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setDialogState(
                        () => currentType = ConnectionType.blocks),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            currentType == ConnectionType.blocks
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: currentType == ConnectionType.blocks
                                ? const Color(0xFFF59E0B)
                                : null,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.connectionBlocks,
                                    style: const TextStyle(fontSize: 14)),
                                Text(
                                  l10n.connectionBlocksDesc,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error,
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    _confirmDelete(context, ref);
                  },
                  child: Text(l10n.deleteConnection),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    if (currentType != connection.type) {
                      await ref
                          .read(mapConnectionControllerProvider.notifier)
                          .updateConnectionType(
                            connectionId: connection.id,
                            type: currentType,
                          );
                    }
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConnection),
        content: Text(l10n.deleteConnectionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(mapConnectionControllerProvider.notifier)
                  .deleteConnection(connection.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
