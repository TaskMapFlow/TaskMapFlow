import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_connection.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/map_connection_providers.dart';
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

  Future<void> _handleConnect(
    BuildContext context,
    String sourceId,
    String targetId,
  ) async {
    final l10n = context.l10n;
    final uid = ref.read(currentUserIdProvider) ?? '';
    final allWs = ref.read(workspacesStreamProvider).valueOrNull ?? [];
    final sourceWs = allWs.firstWhere((w) => w.id == sourceId);
    final targetWs = allWs.firstWhere((w) => w.id == targetId);

    var selectedType = ConnectionType.related;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDState) {
            return AlertDialog(
              title: Text(l10n.connectAreas),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sourceWs.name} ➔ ${targetWs.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () =>
                        setDState(() => selectedType = ConnectionType.related),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            selectedType == ConnectionType.related
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selectedType == ConnectionType.related
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
                    onTap: () =>
                        setDState(() => selectedType = ConnectionType.blocks),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            selectedType == ConnectionType.blocks
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selectedType == ConnectionType.blocks
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
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.connectAreas),
                ),
              ],
            );
          },
        );
      },
    );

    // Reset connecting mode
    ref.read(isConnectingModeProvider.notifier).state = false;
    ref.read(connectingSourceWorkspaceIdProvider.notifier).state = null;

    if (shouldCreate == true && context.mounted) {
      final result = await ref
          .read(mapConnectionControllerProvider.notifier)
          .createConnection(
            ownerId: uid,
            sourceWorkspaceId: sourceId,
            targetWorkspaceId: targetId,
            type: selectedType,
          );

      if (context.mounted) {
        if (result case Err(:final failure)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _parseHex(widget.workspace.color);
    final stats = ref.watch(taskStatsProvider(widget.workspace.id));

    final isConnectingMode = ref.watch(isConnectingModeProvider);
    final connectingSourceId = ref.watch(connectingSourceWorkspaceIdProvider);
    final isSelectedAsSource = connectingSourceId == widget.workspace.id;

    // Check for blocking dependencies: target == this workspace, type == blocks
    final connections =
        ref.watch(mapConnectionsStreamProvider).valueOrNull ?? [];
    final incomingBlocks = connections
        .where((c) =>
            c.targetWorkspaceId == widget.workspace.id &&
            c.type == ConnectionType.blocks)
        .toList();

    String? blockingWorkspaceName;
    for (final conn in incomingBlocks) {
      final sourceStats = ref.watch(taskStatsProvider(conn.sourceWorkspaceId));
      // Completed criterion: has >= 1 task and all completed
      final isSourceCompleted =
          sourceStats.total > 0 && sourceStats.completed == sourceStats.total;
      if (!isSourceCompleted) {
        final allWs = ref.watch(workspacesStreamProvider).valueOrNull ?? [];
        for (final w in allWs) {
          if (w.id == conn.sourceWorkspaceId) {
            blockingWorkspaceName = w.name;
            break;
          }
        }
        if (blockingWorkspaceName != null) break;
      }
    }

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
        onTap: () {
          if (isConnectingMode) {
            if (connectingSourceId == null) {
              ref.read(connectingSourceWorkspaceIdProvider.notifier).state =
                  widget.workspace.id;
            } else if (connectingSourceId == widget.workspace.id) {
              ref.read(connectingSourceWorkspaceIdProvider.notifier).state =
                  null;
            } else {
              _handleConnect(context, connectingSourceId, widget.workspace.id);
            }
            return;
          }
          if (!widget.isEditMode) {
            widget.onTap();
          }
        },
        onPanStart: (widget.isEditMode && !isConnectingMode)
            ? (details) {
                setState(() => _isDragging = true);
              }
            : null,
        onPanUpdate: (widget.isEditMode && !isConnectingMode)
            ? (details) {
                setState(() {
                  _posX += details.delta.dx;
                  _posY += details.delta.dy;
                  if (_posX < 0) _posX = 0;
                  if (_posY < 0) _posY = 0;
                });
              }
            : null,
        onPanEnd: (widget.isEditMode && !isConnectingMode)
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
                  color: isSelectedAsSource
                      ? AppColors.darkPrimaryPurple
                      : (widget.isEditMode
                          ? accentColor
                          : (isDark
                              ? const Color(0xFF2C293C)
                              : const Color(0xFFE2E0EE))),
                  width: isSelectedAsSource
                      ? 3.0
                      : (widget.isEditMode ? 2.0 : 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelectedAsSource
                        ? AppColors.darkPrimaryPurple.withValues(alpha: 0.4)
                        : accentColor.withValues(
                            alpha: widget.isEditMode ? 0.25 : 0.08),
                    blurRadius:
                        isSelectedAsSource ? 16 : (widget.isEditMode ? 14 : 8),
                    spreadRadius:
                        isSelectedAsSource ? 3 : (widget.isEditMode ? 2 : 0),
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

            // Dependency Warning Badge (if blocked by incomplete workspace)
            if (blockingWorkspaceName != null)
              Positioned(
                top: -10,
                left: 10,
                right: 10,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.blockedByDependencyWarning(
                                blockingWorkspaceName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Resize handle in edit mode (bottom-right)
            if (widget.isEditMode && !isConnectingMode)
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
