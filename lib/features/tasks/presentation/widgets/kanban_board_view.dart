import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';
import 'package:task_map_flow/features/team/presentation/providers/team_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';

/// Interactive Kanban board displaying tasks organized in 3 status columns:
/// [TaskStatus.todo], [TaskStatus.inProgress], [TaskStatus.completed].
/// Supports long-press drag-and-drop and popup menu status changing.
class KanbanBoardView extends ConsumerStatefulWidget {
  const KanbanBoardView({
    super.key,
    required this.workspace,
    required this.tasks,
    this.isReadOnly = false,
    this.sprintId,
    this.boardHeight,
  });

  final Workspace workspace;
  final List<TaskModel> tasks;
  final bool isReadOnly;
  final String? sprintId;
  final double? boardHeight;

  @override
  ConsumerState<KanbanBoardView> createState() => _KanbanBoardViewState();
}

class _KanbanBoardViewState extends ConsumerState<KanbanBoardView> {
  final Set<String> _inFlightTaskIds = {};

  Future<void> _updateTaskStatus(TaskModel task, TaskStatus newStatus) async {
    if (task.status == newStatus) return;
    if (widget.isReadOnly) return;
    if (_inFlightTaskIds.contains(task.id)) return;

    setState(() {
      _inFlightTaskIds.add(task.id);
    });

    final result =
        await ref.read(taskControllerProvider.notifier).updateTaskStatus(
              workspaceId: widget.workspace.id,
              taskId: task.id,
              status: newStatus,
            );

    if (!mounted) return;

    setState(() {
      _inFlightTaskIds.remove(task.id);
    });

    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    final members = ref
            .watch(workspaceMembersStreamProvider(widget.workspace.id))
            .valueOrNull ??
        [];

    final todoTasks =
        widget.tasks.where((t) => t.status == TaskStatus.todo).toList();
    final inProgressTasks =
        widget.tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final completedTasks =
        widget.tasks.where((t) => t.status == TaskStatus.completed).toList();

    final screenHeight = MediaQuery.sizeOf(context).height;
    final calculatedHeight =
        widget.boardHeight ?? (screenHeight * 0.62).clamp(420.0, 680.0);

    return SizedBox(
      height: calculatedHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KanbanColumn(
              title: l10n.kanbanColumnTodo,
              status: TaskStatus.todo,
              tasks: todoTasks,
              headerColor:
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              accentColor: purple,
              isDark: isDark,
              isReadOnly: widget.isReadOnly,
              inFlightTaskIds: _inFlightTaskIds,
              workspace: widget.workspace,
              members: members,
              onTaskStatusChanged: _updateTaskStatus,
            ),
            const SizedBox(width: 12),
            _KanbanColumn(
              title: l10n.kanbanColumnInProgress,
              status: TaskStatus.inProgress,
              tasks: inProgressTasks,
              headerColor: const Color(0xFF38BDF8),
              accentColor: purple,
              isDark: isDark,
              isReadOnly: widget.isReadOnly,
              inFlightTaskIds: _inFlightTaskIds,
              workspace: widget.workspace,
              members: members,
              onTaskStatusChanged: _updateTaskStatus,
            ),
            const SizedBox(width: 12),
            _KanbanColumn(
              title: l10n.kanbanColumnCompleted,
              status: TaskStatus.completed,
              tasks: completedTasks,
              headerColor: const Color(0xFF10B981),
              accentColor: purple,
              isDark: isDark,
              isReadOnly: widget.isReadOnly,
              inFlightTaskIds: _inFlightTaskIds,
              workspace: widget.workspace,
              members: members,
              onTaskStatusChanged: _updateTaskStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.title,
    required this.status,
    required this.tasks,
    required this.headerColor,
    required this.accentColor,
    required this.isDark,
    required this.isReadOnly,
    required this.inFlightTaskIds,
    required this.workspace,
    required this.members,
    required this.onTaskStatusChanged,
  });

  final String title;
  final TaskStatus status;
  final List<TaskModel> tasks;
  final Color headerColor;
  final Color accentColor;
  final bool isDark;
  final bool isReadOnly;
  final Set<String> inFlightTaskIds;
  final Workspace workspace;
  final List<WorkspaceMember> members;
  final void Function(TaskModel task, TaskStatus newStatus) onTaskStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final columnBg = isDark ? const Color(0xFF13121C) : const Color(0xFFF6F5FA);
    final columnBorder =
        isDark ? const Color(0xFF232132) : const Color(0xFFE4E2EE);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) {
        if (isReadOnly) return false;
        final task = details.data;
        if (task.status == status) return false;
        if (inFlightTaskIds.contains(task.id)) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        onTaskStatusChanged(details.data, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          decoration: BoxDecoration(
            color: isDropTarget
                ? accentColor.withValues(alpha: isDark ? 0.16 : 0.08)
                : columnBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDropTarget ? accentColor : columnBorder,
              width: isDropTarget ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: headerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: headerColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          color: headerColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // Tasks Scrollable List / Empty State
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 30,
                                color: textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.emptyKanbanColumn,
                                style: TextStyle(
                                  color: textSecondary.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        itemCount: tasks.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final isInFlight = inFlightTaskIds.contains(task.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _DraggableKanbanCard(
                              key: ValueKey(task.id),
                              task: task,
                              workspace: workspace,
                              isDark: isDark,
                              isReadOnly: isReadOnly,
                              isInFlight: isInFlight,
                              members: members,
                              accentColor: accentColor,
                              onTaskStatusChanged: onTaskStatusChanged,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableKanbanCard extends StatelessWidget {
  const _DraggableKanbanCard({
    super.key,
    required this.task,
    required this.workspace,
    required this.isDark,
    required this.isReadOnly,
    required this.isInFlight,
    required this.members,
    required this.accentColor,
    required this.onTaskStatusChanged,
  });

  final TaskModel task;
  final Workspace workspace;
  final bool isDark;
  final bool isReadOnly;
  final bool isInFlight;
  final List<WorkspaceMember> members;
  final Color accentColor;
  final void Function(TaskModel task, TaskStatus newStatus) onTaskStatusChanged;

  @override
  Widget build(BuildContext context) {
    final canDrag = !isReadOnly && !isInFlight;

    final cardWidget = _KanbanTaskCard(
      task: task,
      workspace: workspace,
      isDark: isDark,
      isReadOnly: isReadOnly,
      isInFlight: isInFlight,
      members: members,
      accentColor: accentColor,
      onTaskStatusChanged: onTaskStatusChanged,
    );

    if (!canDrag) {
      return cardWidget;
    }

    return LongPressDraggable<TaskModel>(
      data: task,
      delay: const Duration(milliseconds: 250),
      hapticFeedbackOnStart: true,
      maxSimultaneousDrags: 1,
      feedback: SizedBox(
        width: 260,
        child: Material(
          type: MaterialType.transparency,
          child: Transform.rotate(
            angle: 0.03,
            child: Opacity(
              opacity: 0.92,
              child: _KanbanTaskCard(
                task: task,
                workspace: workspace,
                isDark: isDark,
                isReadOnly: true,
                isInFlight: false,
                members: members,
                accentColor: accentColor,
                isElevated: true,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: cardWidget,
      ),
      child: cardWidget,
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  const _KanbanTaskCard({
    required this.task,
    required this.workspace,
    required this.isDark,
    required this.isReadOnly,
    required this.isInFlight,
    required this.members,
    required this.accentColor,
    this.onTaskStatusChanged,
    this.isElevated = false,
  });

  final TaskModel task;
  final Workspace workspace;
  final bool isDark;
  final bool isReadOnly;
  final bool isInFlight;
  final List<WorkspaceMember> members;
  final Color accentColor;
  final void Function(TaskModel task, TaskStatus newStatus)?
      onTaskStatusChanged;
  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    final cardBg = isDark ? const Color(0xFF1B1928) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF2A283C) : const Color(0xFFE2E0EC);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.isOverdue && !isCompleted;

    // Resolve assignee
    final matchedMember = task.assigneeId != null
        ? members.where((m) => m.userId == task.assigneeId).firstOrNull
        : null;
    final assigneeName = matchedMember?.displayName;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: isElevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            TaskFormSheet.show(
              context: context,
              workspaceId: workspace.id,
              workspaceType: workspace.type,
              initialTask: task,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Priority & Status Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PriorityBadge(priority: task.priority),
                    if (isInFlight)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    else if (!isReadOnly && onTaskStatusChanged != null)
                      PopupMenuButton<TaskStatus>(
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 16,
                          color: textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: l10n.changeStatus,
                        onSelected: (newStatus) {
                          onTaskStatusChanged!(task, newStatus);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: TaskStatus.todo,
                            child: Row(
                              children: [
                                Icon(
                                  task.status == TaskStatus.todo
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: task.status == TaskStatus.todo
                                      ? accentColor
                                      : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(l10n.statusTodo),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: TaskStatus.inProgress,
                            child: Row(
                              children: [
                                Icon(
                                  task.status == TaskStatus.inProgress
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: task.status == TaskStatus.inProgress
                                      ? const Color(0xFF38BDF8)
                                      : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(l10n.statusInProgress),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: TaskStatus.completed,
                            child: Row(
                              children: [
                                Icon(
                                  task.status == TaskStatus.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: task.status == TaskStatus.completed
                                      ? const Color(0xFF10B981)
                                      : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(l10n.statusCompleted),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Title
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCompleted
                        ? textSecondary.withValues(alpha: 0.6)
                        : textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: textSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                // Footer metadata: Subtasks, Due Date, Assignee
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Subtasks progress
                    if (task.subtasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                            const SizedBox(width: 3),
                            Text(
                              '${task.completedSubtaskCount}/${task.subtasks.length}',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Due date
                    if (task.dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : (isDark
                                  ? const Color(0xFF242232)
                                  : const Color(0xFFEEEEF5)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.calendar_today_outlined,
                              size: 10,
                              color: isOverdue
                                  ? const Color(0xFFEF4444)
                                  : textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat.MMMd(locale).format(task.dueDate!),
                              style: TextStyle(
                                color: isOverdue
                                    ? const Color(0xFFEF4444)
                                    : textSecondary,
                                fontSize: 10,
                                fontWeight: isOverdue
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Assignee chip
                    if (task.assigneeId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 10,
                              color: accentColor,
                            ),
                            const SizedBox(width: 3),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                assigneeName ?? l10n.assignee,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
