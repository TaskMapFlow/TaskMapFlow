import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/kanban_board_view.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';

/// Bottom sheet displaying a specific sprint's details and dedicated Kanban board.
class SprintDetailSheet extends ConsumerWidget {
  const SprintDetailSheet({
    super.key,
    required this.workspace,
    required this.sprint,
    this.isReadOnly = false,
  });

  final Workspace workspace;
  final SprintModel sprint;
  final bool isReadOnly;

  static Future<void> show({
    required BuildContext context,
    required Workspace workspace,
    required SprintModel sprint,
    bool isReadOnly = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SprintDetailSheet(
        workspace: workspace,
        sprint: sprint,
        isReadOnly: isReadOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF13121C) : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    // Stream all tasks to ensure real-time updates of the sprint's tasks
    final allTasks =
        ref.watch(tasksStreamProvider(workspace.id)).valueOrNull ?? [];
    final sprintTasks = allTasks.where((t) => t.sprintId == sprint.id).toList();

    final completedCount =
        sprintTasks.where((t) => t.status == TaskStatus.completed).length;
    final totalCount = sprintTasks.length;
    final percent = totalCount > 0 ? (completedCount * 100 ~/ totalCount) : 0;

    final statusLabel = switch (sprint.status) {
      SprintStatus.planned => l10n.sprintStatusPlanned,
      SprintStatus.active => l10n.sprintStatusActive,
      SprintStatus.completed => l10n.sprintStatusCompleted,
    };

    final statusColor = switch (sprint.status) {
      SprintStatus.planned => const Color(0xFF818CF8),
      SprintStatus.active => const Color(0xFF10B981),
      SprintStatus.completed => const Color(0xFF6B7280),
    };

    final dateText =
        '${DateFormat.MMMd(locale).format(sprint.startDate)} - ${DateFormat.MMMd(locale).format(sprint.endDate)}';

    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.88,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2E2C3D) : const Color(0xFFD4D2E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sprint.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 13, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            dateText,
                            style:
                                TextStyle(color: textSecondary, fontSize: 12),
                          ),
                          if (totalCount > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              '$completedCount / $totalCount (%$percent)',
                              style: TextStyle(
                                color: purple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          if (sprint.goal.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                sprint.goal,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const Divider(height: 16),

          // Sprint Kanban Board
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KanbanBoardView(
                workspace: workspace,
                tasks: sprintTasks,
                isReadOnly: isReadOnly,
                sprintId: sprint.id,
                boardHeight: screenHeight * 0.72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
