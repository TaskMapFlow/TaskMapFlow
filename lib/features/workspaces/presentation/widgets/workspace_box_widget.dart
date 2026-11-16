import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class WorkspaceBoxWidget extends ConsumerStatefulWidget {
  const WorkspaceBoxWidget({
    super.key,
    required this.workspace,
    required this.node,
    required this.isEditMode,
    required this.onTap,
  });

  final Workspace workspace;
  final MapNode node;
  final bool isEditMode;
  final VoidCallback onTap;

  @override
  ConsumerState<WorkspaceBoxWidget> createState() => _WorkspaceBoxWidgetState();
}

class _WorkspaceBoxWidgetState extends ConsumerState<WorkspaceBoxWidget> {
  late double _posX;
  late double _posY;
  late double _width;
  late double _height;
  bool _isDragging = false;
  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    _posX = widget.node.positionX;
    _posY = widget.node.positionY;
    _width = widget.node.width;
    _height = widget.node.height;
  }

  @override
  void didUpdateWidget(covariant WorkspaceBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && !_isResizing) {
      _posX = widget.node.positionX;
      _posY = widget.node.positionY;
      _width = widget.node.width;
      _height = widget.node.height;
    }
  }

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF7C5CE8);
    }
  }

  void _saveLayout() {
    ref.read(workspaceControllerProvider.notifier).updateMapNodeLayout(
          nodeId: widget.node.id,
          positionX: _posX,
          positionY: _posY,
          width: _width,
          height: _height,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _parseHex(widget.workspace.color);
    final stats = ref.watch(taskStatsProvider(widget.workspace.id));

    final bg = isDark
        ? const Color(0xFF161520).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final typeIcon = switch (widget.workspace.type) {
      WorkspaceType.project => Icons.rocket_launch_outlined,
      WorkspaceType.lesson => Icons.school_outlined,
      WorkspaceType.freeform => Icons.bubble_chart_outlined,
    };

    return Positioned(
      left: _posX,
      top: _posY,
      width: _width,
      height: _height,
      child: GestureDetector(
        onTap: widget.isEditMode ? null : widget.onTap,
        onPanStart: widget.isEditMode
            ? (details) {
                setState(() => _isDragging = true);
              }
            : null,
        onPanUpdate: widget.isEditMode
            ? (details) {
                setState(() {
                  _posX += details.delta.dx;
                  _posY += details.delta.dy;
                  if (_posX < 0) _posX = 0;
                  if (_posY < 0) _posY = 0;
                });
              }
            : null,
        onPanEnd: widget.isEditMode
            ? (details) {
                setState(() => _isDragging = false);
                _saveLayout();
              }
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isEditMode
                      ? accentColor
                      : (isDark
                          ? const Color(0xFF2C293C)
                          : const Color(0xFFE2E0EE)),
                  width: widget.isEditMode ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                        alpha: widget.isEditMode ? 0.25 : 0.08),
                    blurRadius: widget.isEditMode ? 14 : 8,
                    spreadRadius: widget.isEditMode ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top colored bar
                    Container(
                      height: 4,
                      color: accentColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(typeIcon,
                                      size: 15, color: accentColor),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.workspace.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.workspace.description != null &&
                                widget.workspace.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  widget.workspace.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                            if (stats.total > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 11, color: accentColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats.completed}/${stats.total}',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: stats.completed / stats.total,
                                        minHeight: 3,
                                        backgroundColor: isDark
                                            ? const Color(0xFF262335)
                                            : const Color(0xFFE8E6F2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                accentColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Resize handle in edit mode (bottom-right)
            if (widget.isEditMode)
              Positioned(
                right: -8,
                bottom: -8,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() => _isResizing = true);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _width = (_width + details.delta.dx).clamp(130.0, 400.0);
                      _height = (_height + details.delta.dy).clamp(80.0, 300.0);
                    });
                  },
                  onPanEnd: (details) {
                    setState(() => _isResizing = false);
                    _saveLayout();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.aspect_ratio_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
