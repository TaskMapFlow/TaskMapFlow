import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/map_connection_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/widgets/map_connections_layer.dart';
import 'package:task_map_flow/features/workspaces/presentation/widgets/workspace_box_widget.dart';

const double kMapCanvasWidth = 2400.0;
const double kMapCanvasHeight = 2400.0;

class MapCanvas extends ConsumerStatefulWidget {
  const MapCanvas({
    super.key,
    required this.workspaces,
    required this.nodes,
    required this.onOpenDetail,
    this.isFullscreen = false,
  });

  final List<Workspace> workspaces;
  final List<MapNode> nodes;
  final void Function(Workspace workspace) onOpenDetail;
  final bool isFullscreen;

  @override
  ConsumerState<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends ConsumerState<MapCanvas> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _centerView() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final viewWidth = size.width;
    final viewHeight = size.height * (widget.isFullscreen ? 1.0 : 0.7);

    double targetX = kMapCanvasWidth / 2;
    double targetY = kMapCanvasHeight / 2;

    if (widget.nodes.isNotEmpty) {
      double sumX = 0;
      double sumY = 0;
      for (final n in widget.nodes) {
        sumX += n.positionX + n.width / 2;
        sumY += n.positionY + n.height / 2;
      }
      targetX = sumX / widget.nodes.length;
      targetY = sumY / widget.nodes.length;
    }

    const double scale = 0.85;
    final double tx = -targetX * scale + viewWidth / 2;
    final double ty = -targetY * scale + viewHeight / 2;

    final translation = Matrix4.translationValues(tx, ty, 0.0);
    final scaleMatrix = Matrix4.diagonal3Values(scale, scale, 1.0);
    _transformationController.value = translation.multiplied(scaleMatrix);
  }

  void _zoom(double factor) {
    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.4, 2.2);
    final ratio = newScale / currentScale;

    final size = MediaQuery.of(context).size;
    final focalPoint = Offset(size.width / 2, size.height / 2);

    final translateToFocal =
        Matrix4.translationValues(focalPoint.dx, focalPoint.dy, 0.0);
    final scaleMatrix = Matrix4.diagonal3Values(ratio, ratio, 1.0);
    final translateBack =
        Matrix4.translationValues(-focalPoint.dx, -focalPoint.dy, 0.0);

    _transformationController.value = translateToFocal
        .multiplied(scaleMatrix)
        .multiplied(translateBack)
        .multiplied(matrix);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditMode = ref.watch(isEditModeProvider);
    final isConnectingMode = ref.watch(isConnectingModeProvider);
    final connectingSourceId = ref.watch(connectingSourceWorkspaceIdProvider);
    final l10n = context.l10n;

    final nodeMap = {for (final n in widget.nodes) n.workspaceId: n};
    final wsMap = {for (final w in widget.workspaces) w.id: w};

    final connectionsAsync = ref.watch(mapConnectionsStreamProvider);
    final allConnections = connectionsAsync.valueOrNull ?? [];
    final activeWsIds = widget.workspaces.map((w) => w.id).toSet();
    final connections = allConnections
        .where((c) =>
            activeWsIds.contains(c.sourceWorkspaceId) &&
            activeWsIds.contains(c.targetWorkspaceId))
        .toList();

    final gridBg = isDark ? const Color(0xFF0C0B10) : const Color(0xFFF7F6FC);
    final dotColor = isDark
        ? const Color(0xFF262436).withValues(alpha: 0.7)
        : const Color(0xFFDDD9EE).withValues(alpha: 0.8);

    return Stack(
      children: [
        // Interactive zoomable/pannable map canvas
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(800),
            minScale: 0.35,
            maxScale: 2.2,
            panEnabled:
                !isEditMode, // Dragging boxes in edit mode takes priority
            child: Container(
              width: kMapCanvasWidth,
              height: kMapCanvasHeight,
              color: gridBg,
              child: CustomPaint(
                painter: _GridPatternPainter(dotColor: dotColor),
                child: Stack(
                  children: [
                    // Behind boxes: Connection lines
                    CustomPaint(
                      size: const Size(kMapCanvasWidth, kMapCanvasHeight),
                      painter: MapConnectionsPainter(
                        connections: connections,
                        nodeMap: nodeMap,
                        isDark: isDark,
                      ),
                    ),

                    // Connection midpoint interaction badges
                    for (final conn in connections)
                      if (nodeMap.containsKey(conn.sourceWorkspaceId) &&
                          nodeMap.containsKey(conn.targetWorkspaceId))
                        ConnectionMidpointBadge(
                          key: ValueKey(conn.id),
                          connection: conn,
                          sourceNode: nodeMap[conn.sourceWorkspaceId]!,
                          targetNode: nodeMap[conn.targetWorkspaceId]!,
                          sourceName: wsMap[conn.sourceWorkspaceId]?.name ?? '',
                          targetName: wsMap[conn.targetWorkspaceId]?.name ?? '',
                        ),

                    // Workspaces boxes
                    for (final ws in widget.workspaces)
                      if (nodeMap.containsKey(ws.id))
                        WorkspaceBoxWidget(
                          key: ValueKey(ws.id),
                          workspace: ws,
                          node: nodeMap[ws.id]!,
                          isEditMode: isEditMode,
                          onTap: () => widget.onOpenDetail(ws),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Edit Mode / Connecting Mode Banner
        if (isEditMode)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF251A40).withValues(alpha: 0.95)
                      : const Color(0xFFEDE8FF).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkPrimaryPurple
                        : AppColors.lightPrimaryPurple,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnectingMode
                          ? Icons.alt_route_rounded
                          : Icons.edit_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkPrimaryPurple
                          : AppColors.lightPrimaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isConnectingMode
                            ? (connectingSourceId == null
                                ? l10n.connectAreas
                                : l10n.connectingModeHint)
                            : l10n.editModeBanner,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Connect button / Cancel connect button
                    InkWell(
                      onTap: () {
                        if (isConnectingMode) {
                          ref.read(isConnectingModeProvider.notifier).state =
                              false;
                          ref
                              .read(
                                  connectingSourceWorkspaceIdProvider.notifier)
                              .state = null;
                        } else {
                          ref.read(isConnectingModeProvider.notifier).state =
                              true;
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnectingMode
                              ? Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: 0.2)
                              : (isDark
                                  ? AppColors.darkPrimaryPurple
                                  : AppColors.lightPrimaryPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isConnectingMode ? l10n.cancel : l10n.connectAreas,
                          style: TextStyle(
                            color: isConnectingMode
                                ? Theme.of(context).colorScheme.error
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Floating Map Controls (Center, Zoom +, Zoom -)
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlButton(
                icon: Icons.filter_center_focus_rounded,
                tooltip: l10n.centerView,
                onPressed: _centerView,
              ),
              const SizedBox(height: 8),
              _ControlButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom In',
                onPressed: () => _zoom(1.25),
              ),
              const SizedBox(height: 8),
              _ControlButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom Out',
                onPressed: () => _zoom(0.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF1E1C29).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9);
    final border = isDark ? const Color(0xFF2C293C) : const Color(0xFFE2E0EE);
    final iconColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: iconColor),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  const _GridPatternPainter({required this.dotColor});
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}
