import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/home/presentation/providers/home_view_providers.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/screens/create_workspace_sheet.dart';

class HomeOverviewView extends ConsumerStatefulWidget {
  const HomeOverviewView({super.key});

  @override
  ConsumerState<HomeOverviewView> createState() => _HomeOverviewViewState();
}

class _HomeOverviewViewState extends ConsumerState<HomeOverviewView> {
  // Track expanded state for each section
  bool _expandOverdue = false;
  bool _expandToday = false;
  bool _expandUpcoming = false;
  bool _expandInProgress = false;

  static const int _previewLimit = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final summary = ref.watch(dailyWorkSummaryProvider);
    final today = ref.watch(overviewDateAnchorProvider);

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    if (summary.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: purple),
            const SizedBox(height: 16),
            Text(
              l10n.sessionLoading,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (summary.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                summary.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(workspacesStreamProvider);
                  for (final ws in summary.failedWorkspaces) {
                    ref.invalidate(tasksStreamProvider(ws.id));
                  }
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (summary.isEmpty) {
      return _EmptyOverviewState(
        onAddArea: () => CreateWorkspaceSheet.show(context),
      );
    }

    final dateFormatted = DateFormat.yMMMMEEEEd(locale).format(today);

    return RefreshIndicator(
      color: purple,
      onRefresh: () async {
        ref.invalidate(workspacesStreamProvider);
        for (final ws in summary.failedWorkspaces) {
          ref.invalidate(tasksStreamProvider(ws.id));
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Date & Summary Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatted,
                      style: TextStyle(
                        color: purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.dailySummaryTitle,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Warning for workspaces that failed to load
          if (summary.failedWorkspaces.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.partialFailedAreasWarning(
                          summary.failedWorkspaces.length),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: purple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label:
                        Text(l10n.retry, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      for (final ws in summary.failedWorkspaces) {
                        ref.invalidate(tasksStreamProvider(ws.id));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Notice if summary is capped at 25 active workspaces
          if (summary.isPartial) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: purple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.partialSummaryNotice(
                        summary.activeWorkspaces.length,
                        summary.totalActiveWorkspacesCount,
                      ),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 1. Overdue Tasks Section (Gecikmiş)
          if (summary.overdueTasks.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.overdueTasks,
              count: summary.overdueTasks.length,
              accentColor: Theme.of(context).colorScheme.error,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 8),
            ..._renderTaskList(
              summary.overdueTasks,
              _expandOverdue,
              onToggleExpand: () =>
                  setState(() => _expandOverdue = !_expandOverdue),
              isOverdueSection: true,
            ),
            const SizedBox(height: 20),
          ],

          // 2. Today's Due Tasks Section (Bugün)
          if (summary.todayTasks.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.todayTasks,
              count: summary.todayTasks.length,
              accentColor: purple,
              icon: Icons.today_rounded,
            ),
            const SizedBox(height: 8),
            ..._renderTaskList(
              summary.todayTasks,
              _expandToday,
              onToggleExpand: () =>
                  setState(() => _expandToday = !_expandToday),
            ),
            const SizedBox(height: 20),
          ],

          // 3. In Progress Tasks Section (Devam Eden)
          if (summary.inProgressTasks.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.inProgressTasks,
              count: summary.inProgressTasks.length,
              accentColor: const Color(0xFFF59E0B),
              icon: Icons.timelapse_rounded,
            ),
            const SizedBox(height: 8),
            ..._renderTaskList(
              summary.inProgressTasks,
              _expandInProgress,
              onToggleExpand: () =>
                  setState(() => _expandInProgress = !_expandInProgress),
            ),
            const SizedBox(height: 20),
          ],

          // 4. Upcoming Tasks Section (Önümüzdeki 7 Gün)
          if (summary.upcomingTasks.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.upcomingTasks,
              count: summary.upcomingTasks.length,
              accentColor: const Color(0xFF3B82F6),
              icon: Icons.date_range_rounded,
            ),
            const SizedBox(height: 8),
            ..._renderTaskList(
              summary.upcomingTasks,
              _expandUpcoming,
              onToggleExpand: () =>
                  setState(() => _expandUpcoming = !_expandUpcoming),
            ),
            const SizedBox(height: 20),
          ],

          // All clear notice if no urgent tasks
          if (summary.overdueTasks.isEmpty &&
              summary.todayTasks.isEmpty &&
              summary.inProgressTasks.isEmpty &&
              summary.upcomingTasks.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1B1A28) : const Color(0xFFF3F2F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C293F)
                      : const Color(0xFFE2E0EE),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.allClearTitle,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.allClearSubtitle,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 5. Active Areas Progress Section (Aktif Alanlar)
          if (summary.activeWorkspaces.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.activeWorkspaces,
              count: summary.activeWorkspaces.length,
              accentColor: textSecondary,
              icon: Icons.dashboard_outlined,
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summary.activeWorkspaces.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final wp = summary.activeWorkspaces[index];
                return _WorkspaceProgressCard(
                  key: ValueKey(wp.workspace.id),
                  progress: wp,
                  onTap: () => context.push('/workspace/${wp.workspace.id}'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _renderTaskList(
    List<TaskWithWorkspace> tasks,
    bool isExpanded, {
    required VoidCallback onToggleExpand,
    bool isOverdueSection = false,
  }) {
    final l10n = context.l10n;
    final displayedTasks =
        isExpanded ? tasks : tasks.take(_previewLimit).toList();

    return [
      for (final pair in displayedTasks)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _OverviewTaskCard(
            key: ValueKey(pair.task.id),
            task: pair.task,
            workspace: pair.workspace,
            isOverdue: isOverdueSection,
            onTap: () {
              TaskFormSheet.show(
                context: context,
                workspaceId: pair.workspace.id,
                workspaceType: pair.workspace.type,
                initialTask: pair.task,
              );
            },
            onStatusChanged: (newStatus) async {
              final result = await ref
                  .read(taskControllerProvider.notifier)
                  .updateTaskStatus(
                    workspaceId: pair.workspace.id,
                    taskId: pair.task.id,
                    status: newStatus,
                  );
              if (result case Err(:final failure)) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              }
            },
          ),
        ),
      if (tasks.length > _previewLimit)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
            ),
            label: Text(
              isExpanded ? l10n.showLess : l10n.seeAll(tasks.length),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: onToggleExpand,
          ),
        ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final int count;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewTaskCard extends StatelessWidget {
  const _OverviewTaskCard({
    super.key,
    required this.task,
    required this.workspace,
    required this.onTap,
    required this.onStatusChanged,
    this.isOverdue = false,
  });

  final TaskModel task;
  final Workspace workspace;
  final VoidCallback onTap;
  final ValueChanged<TaskStatus> onStatusChanged;
  final bool isOverdue;

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF8A2BE2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    final wsColor = _hexToColor(workspace.color);
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder = isOverdue
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.35)
        : (isDark ? const Color(0xFF262335) : const Color(0xFFE5E3F0));

    final isCompleted = task.status == TaskStatus.completed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Toggle Button / Checkbox
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : (task.status == TaskStatus.inProgress
                          ? Icons.timelapse_rounded
                          : Icons.radio_button_unchecked_rounded),
                  color: isCompleted
                      ? purple
                      : (task.status == TaskStatus.inProgress
                          ? const Color(0xFFF59E0B)
                          : textSecondary),
                  size: 20,
                ),
                onPressed: () {
                  final nextStatus = switch (task.status) {
                    TaskStatus.todo => TaskStatus.inProgress,
                    TaskStatus.inProgress => TaskStatus.completed,
                    TaskStatus.completed => TaskStatus.todo,
                  };
                  onStatusChanged(nextStatus);
                },
              ),
              const SizedBox(width: 8),

              // Title, Area Name & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCompleted ? textSecondary : textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Workspace Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: wsColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: wsColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  workspace.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : wsColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Priority Tag
                        if (task.priority != TaskPriority.medium)
                          _PriorityBadge(priority: task.priority),

                        // Due Date
                        if (task.dueDate != null)
                          _DueDateBadge(
                            dueDate: task.dueDate!,
                            isOverdue: isOverdue,
                            locale: locale,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textSecondary.withValues(alpha: 0.5),
              ),
            ],
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
      TaskPriority.high => (
          const Color(0xFFEF4444),
          l10n.priorityHigh,
        ),
      TaskPriority.medium => (
          const Color(0xFF818CF8),
          l10n.priorityMedium,
        ),
      TaskPriority.low => (
          const Color(0xFF94A3B8),
          l10n.priorityLow,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
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

class _DueDateBadge extends StatelessWidget {
  const _DueDateBadge({
    required this.dueDate,
    required this.isOverdue,
    required this.locale,
  });

  final DateTime dueDate;
  final bool isOverdue;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isOverdue
        ? Theme.of(context).colorScheme.error
        : (isDark ? const Color(0xFFA5A0B8) : const Color(0xFF6A657D));

    final dateFormatted = DateFormat.MMMd(locale).format(dueDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isOverdue ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            dateFormatted,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceProgressCard extends StatelessWidget {
  const _WorkspaceProgressCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  final WorkspaceProgress progress;
  final VoidCallback onTap;

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF8A2BE2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ws = progress.workspace;
    final color = _hexToColor(ws.color);

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262335) : const Color(0xFFE5E3F0);

    final typeLabel = switch (ws.type) {
      WorkspaceType.project => l10n.typeProject,
      WorkspaceType.lesson => l10n.typeLesson,
      WorkspaceType.freeform => l10n.typeFreeform,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ws.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: isDark ? Colors.white : color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 5,
                  backgroundColor: isDark
                      ? const Color(0xFF262338)
                      : const Color(0xFFE8E6F2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 6),

              // Task counts: e.g. "4/7 görev tamamlandı (%57)"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.completedTasks} / ${progress.totalTasks} ${l10n.tasksTitle}',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${(progress.progress * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOverviewState extends StatelessWidget {
  const _EmptyOverviewState({required this.onAddArea});
  final VoidCallback onAddArea;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 36,
                  color: purple,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.dailySummaryEmptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dailySummaryEmptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.createAreaButton),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAddArea,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
