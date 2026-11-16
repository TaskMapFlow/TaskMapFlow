import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';

class TaskItemCard extends StatelessWidget {
  const TaskItemCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleStatus,
  });

  final TaskModel task;
  final VoidCallback? onTap;
  final ValueChanged<TaskStatus>? onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    final isCompleted = task.status == TaskStatus.completed;
    final isInProgress = task.status == TaskStatus.inProgress;
    final isOverdue = task.isOverdue;

    final bg = isDark
        ? (isCompleted ? const Color(0xFF13121C) : const Color(0xFF1A1926))
        : (isCompleted ? const Color(0xFFF7F7FA) : Colors.white);
    final border = isDark
        ? (isCompleted ? const Color(0xFF222030) : const Color(0xFF2E2B3E))
        : (isCompleted ? const Color(0xFFECEAF4) : const Color(0xFFDFDDE8));
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Toggle Button / Checkbox
                GestureDetector(
                  onTap: onToggleStatus == null
                      ? null
                      : () {
                          final nextStatus = isCompleted
                              ? TaskStatus.todo
                              : TaskStatus.completed;
                          onToggleStatus!(nextStatus);
                        },
                  child: Container(
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? purple
                          : (isInProgress
                              ? purple.withValues(alpha: 0.15)
                              : Colors.transparent),
                      border: Border.all(
                        color: isCompleted
                            ? purple
                            : (isInProgress ? purple : textSecondary),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : (isInProgress
                            ? Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: purple,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null),
                  ),
                ),

                // Title, Description & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      Text(
                        task.title,
                        style: TextStyle(
                          color: isCompleted
                              ? textSecondary.withValues(alpha: 0.6)
                              : textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: textSecondary,
                        ),
                      ),

                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textSecondary.withValues(
                                alpha: isCompleted ? 0.5 : 0.8),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Badges: Priority, Status, Due Date
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Status Badge (if in progress)
                          if (isInProgress)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.statusInProgress,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          // Priority Badge
                          _PriorityBadge(priority: task.priority),

                          // Subtasks Badge
                          if (task.subtasks.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF242232)
                                    : const Color(0xFFEEEEF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.checklist_rounded,
                                    size: 11,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${task.completedSubtaskCount}/${task.subtasks.length}',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Due Date Badge
                          if (task.dueDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOverdue
                                    ? const Color(0xFFEF4444)
                                        .withValues(alpha: 0.15)
                                    : (isDark
                                        ? const Color(0xFF242232)
                                        : const Color(0xFFEEEEF5)),
                                borderRadius: BorderRadius.circular(6),
                                border: isOverdue
                                    ? Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.4))
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOverdue
                                        ? Icons.error_outline_rounded
                                        : Icons.calendar_today_outlined,
                                    size: 11,
                                    color: isOverdue
                                        ? const Color(0xFFEF4444)
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat.MMMd(locale)
                                        .format(task.dueDate!),
                                    style: TextStyle(
                                      color: isOverdue
                                          ? const Color(0xFFEF4444)
                                          : textSecondary,
                                      fontSize: 11,
                                      fontWeight: isOverdue
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final (color, label) = switch (priority) {
      TaskPriority.high => (const Color(0xFFF87171), l10n.priorityHigh),
      TaskPriority.medium => (const Color(0xFF818CF8), l10n.priorityMedium),
      TaskPriority.low => (const Color(0xFF94A3B8), l10n.priorityLow),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
