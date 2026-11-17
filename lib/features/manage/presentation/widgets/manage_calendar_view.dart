import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/manage/presentation/providers/manage_view_providers.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/complete_session_dialog.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/study_session_form_sheet.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

/// Month calendar view paired with selected day's agenda.
class ManageCalendarView extends ConsumerWidget {
  const ManageCalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    final dateState = ref.watch(manageCalendarDateProvider);
    final summary = ref.watch(manageCalendarSummaryProvider);

    if (summary.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: purple),
      );
    }

    if (summary.errorMessage != null && summary.allItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: Theme.of(context).colorScheme.error),
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
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Partial results / failed workspaces banner
        if (summary.failedWorkspaces.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.partialCalendarWarning(
                        summary.failedWorkspaces.length),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    for (final ws in summary.failedWorkspaces) {
                      ref.invalidate(tasksStreamProvider(ws.id));
                      ref.invalidate(studySessionsStreamProvider(ws.id));
                    }
                  },
                  child: Text(l10n.retry, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],

        // Month Calendar Container
        _MonthCalendarCard(
          dateState: dateState,
          summary: summary,
          isDark: isDark,
          purple: purple,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        const SizedBox(height: 16),

        // Selected Day Agenda Header
        _AgendaHeader(
          dateState: dateState,
          itemCount: summary.selectedDayItems.length,
          isDark: isDark,
          purple: purple,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        const SizedBox(height: 8),

        // Agenda Items or Empty State
        if (summary.selectedDayItems.isEmpty)
          _EmptyAgendaCard(
            isDark: isDark,
            purple: purple,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          )
        else
          for (final item in summary.selectedDayItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AgendaItemCard(
                key: ValueKey('${item.type.name}_${item.id}'),
                item: item,
                isDark: isDark,
                purple: purple,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
      ],
    );
  }
}

class _MonthCalendarCard extends ConsumerWidget {
  const _MonthCalendarCard({
    required this.dateState,
    required this.summary,
    required this.isDark,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
  });

  final CalendarDateState dateState;
  final ManageCalendarSummary summary;
  final bool isDark;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262438) : const Color(0xFFE2E0EE);

    final displayedMonth = dateState.displayedMonth;
    final monthTitle = DateFormat.yMMMM(locale).format(displayedMonth);

    // Days in current displayed month
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    // Weekday of 1st day (1: Mon, 7: Sun in standard Dart DateTime)
    final firstWeekday =
        DateTime(displayedMonth.year, displayedMonth.month, 1).weekday;
    final leadingEmptyCount = (firstWeekday - 1) % 7;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Month navigation bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: textPrimary,
                tooltip: 'Önceki Ay',
                onPressed: () {
                  ref.read(manageCalendarDateProvider.notifier).previousMonth();
                },
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: textPrimary,
                tooltip: 'Sonraki Ay',
                onPressed: () {
                  ref.read(manageCalendarDateProvider.notifier).nextMonth();
                },
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                icon: const Icon(Icons.today_rounded, size: 14),
                label: Text(
                  l10n.jumpToToday,
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  ref.read(manageCalendarDateProvider.notifier).jumpToToday();
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Weekday Labels (Mon - Sun)
          Row(
            children: [
              for (int i = 1; i <= 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabel(i, locale),
                      style: TextStyle(
                        color: textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Days Grid
          _buildDaysGrid(
            context: context,
            ref: ref,
            leadingCount: leadingEmptyCount,
            daysInMonth: daysInMonth,
            displayedMonth: displayedMonth,
            today: today,
            selectedDay: dateState.selectedDay,
            itemsByDay: summary.itemsByDay,
          ),
        ],
      ),
    );
  }

  static String _weekdayLabel(int weekday, String locale) {
    if (locale == 'tr') {
      return switch (weekday) {
        1 => 'Pzt',
        2 => 'Sal',
        3 => 'Çar',
        4 => 'Per',
        5 => 'Cum',
        6 => 'Cmt',
        _ => 'Paz',
      };
    }
    return switch (weekday) {
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
      _ => 'Sun',
    };
  }

  Widget _buildDaysGrid({
    required BuildContext context,
    required WidgetRef ref,
    required int leadingCount,
    required int daysInMonth,
    required DateTime displayedMonth,
    required DateTime today,
    required DateTime selectedDay,
    required Map<DateTime, List<CalendarItem>> itemsByDay,
  }) {
    final totalCells = leadingCount + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: [
        for (int row = 0; row < rowCount; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: _buildDayCell(
                      index: row * 7 + col,
                      leadingCount: leadingCount,
                      daysInMonth: daysInMonth,
                      displayedMonth: displayedMonth,
                      today: today,
                      selectedDay: selectedDay,
                      itemsByDay: itemsByDay,
                      onTapDay: (day) {
                        ref
                            .read(manageCalendarDateProvider.notifier)
                            .selectDay(day);
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell({
    required int index,
    required int leadingCount,
    required int daysInMonth,
    required DateTime displayedMonth,
    required DateTime today,
    required DateTime selectedDay,
    required Map<DateTime, List<CalendarItem>> itemsByDay,
    required ValueChanged<DateTime> onTapDay,
  }) {
    final dayNum = index - leadingCount + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 38);
    }

    final date = DateTime(displayedMonth.year, displayedMonth.month, dayNum);
    final isSelected = date.isAtSameMomentAs(selectedDay);
    final isToday = date.isAtSameMomentAs(today);

    final entries = itemsByDay[date] ?? const [];
    final taskCount =
        entries.where((e) => e.type == CalendarEntryType.task).length;
    final sessionCount =
        entries.where((e) => e.type == CalendarEntryType.studySession).length;
    final totalCount = entries.length;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTapDay(date),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? purple
              : (isToday ? purple.withValues(alpha: 0.15) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: purple.withValues(alpha: 0.6), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNum',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isToday ? purple : textPrimary),
                fontSize: 13,
                fontWeight:
                    isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),

            // Indicators row (tasks vs sessions)
            if (totalCount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (totalCount <= 3) ...[
                    if (taskCount > 0)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF818CF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (sessionCount > 0)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ] else ...[
                    // Crowded day indicator: 2 dots + count badge
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '$totalCount',
                      style: TextStyle(
                        color: isSelected ? Colors.white : textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

class _AgendaHeader extends ConsumerWidget {
  const _AgendaHeader({
    required this.dateState,
    required this.itemCount,
    required this.isDark,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
  });

  final CalendarDateState dateState;
  final int itemCount;
  final bool isDark;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dayTitle = DateFormat.MMMMEEEEd(locale).format(dateState.selectedDay);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Agenda Date Title
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  dayTitle,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$itemCount',
                  style: TextStyle(
                    color: purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Show/Hide Completed Filter Toggle
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ref.read(manageCalendarDateProvider.notifier).toggleShowCompleted();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  dateState.showCompleted
                      ? Icons.check_circle_outline_rounded
                      : Icons.visibility_off_outlined,
                  size: 14,
                  color: purple,
                ),
                const SizedBox(width: 4),
                Text(
                  dateState.showCompleted
                      ? l10n.hideCompleted
                      : l10n.showCompleted,
                  style: TextStyle(
                    color: purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAgendaCard extends StatelessWidget {
  const _EmptyAgendaCard({
    required this.isDark,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
  });

  final bool isDark;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262438) : const Color(0xFFE2E0EE);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: purple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.event_available_outlined, color: purple, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noCalendarEventsTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.noCalendarEventsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaItemCard extends ConsumerWidget {
  const _AgendaItemCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
  });

  final CalendarItem item;
  final bool isDark;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return purple;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262438) : const Color(0xFFE2E0EE);

    final isTask = item.type == CalendarEntryType.task;
    final isCompleted = item.isCompleted;

    final typeColor =
        isTask ? const Color(0xFF818CF8) : const Color(0xFF38BDF8);
    final typeIcon = isTask ? Icons.checklist_rounded : Icons.school_outlined;
    final typeLabel = isTask ? l10n.entryTypeTask : l10n.entryTypeStudySession;

    final wsColor = _parseHex(item.workspace.color);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (isTask) {
              TaskFormSheet.show(
                context: context,
                workspaceId: item.workspace.id,
                workspaceType: item.workspace.type,
                initialTask: item.task,
              );
            } else {
              StudySessionFormSheet.show(
                context,
                workspaceId: item.workspace.id,
                existingSession: item.session,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Checkbox Toggle
                GestureDetector(
                  onTap: () async {
                    if (isTask) {
                      final newStatus =
                          isCompleted ? TaskStatus.todo : TaskStatus.completed;
                      await ref
                          .read(taskControllerProvider.notifier)
                          .updateTaskStatus(
                            workspaceId: item.workspace.id,
                            taskId: item.task!.id,
                            status: newStatus,
                          );
                    } else {
                      if (item.session!.isCompleted) {
                        await ref
                            .read(studyPlanControllerProvider.notifier)
                            .uncompleteStudySession(
                              workspaceId: item.workspace.id,
                              sessionId: item.session!.id,
                            );
                      } else {
                        final result = await CompleteSessionDialog.show(
                          context,
                          session: item.session!,
                        );
                        if (result != null) {
                          await ref
                              .read(studyPlanControllerProvider.notifier)
                              .completeStudySession(
                                workspaceId: item.workspace.id,
                                sessionId: item.session!.id,
                                actualDurationMinutes: result.actualDuration,
                                reflectionNotes: result.notes,
                              );
                        }
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 2, right: 10),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? purple : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? purple : textSecondary,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),

                // Card details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Type badge & Workspace chip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcon, size: 11, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  typeLabel,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: wsColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.workspace.name,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isCompleted
                              ? textSecondary.withValues(alpha: 0.6)
                              : textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: textSecondary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Footer: Time / Due Date / Duration
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (isTask && item.task!.dueDate != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.task!.isOverdue && !isCompleted
                                      ? Icons.warning_amber_rounded
                                      : Icons.calendar_today_outlined,
                                  size: 11,
                                  color: item.task!.isOverdue && !isCompleted
                                      ? const Color(0xFFEF4444)
                                      : textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${l10n.dueDatePrefix}: ${DateFormat.MMMd(locale).format(item.task!.dueDate!)}',
                                  style: TextStyle(
                                    color: item.task!.isOverdue && !isCompleted
                                        ? const Color(0xFFEF4444)
                                        : textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (item.task!.priority != TaskPriority.medium) ...[
                              Text(
                                '•',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 11),
                              ),
                              Text(
                                switch (item.task!.priority) {
                                  TaskPriority.high => l10n.priorityHigh,
                                  TaskPriority.low => l10n.priorityLow,
                                  _ => '',
                                },
                                style: TextStyle(
                                  color:
                                      item.task!.priority == TaskPriority.high
                                          ? const Color(0xFFEF4444)
                                          : textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ] else if (!isTask && item.session != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 11, color: textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  '${l10n.startTimePrefix}: ${DateFormat.Hm(locale).format(item.localScheduledAt!)}',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '•',
                              style:
                                  TextStyle(color: textSecondary, fontSize: 11),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 11, color: textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  l10n.durationMinutes(
                                      item.session!.plannedDurationMinutes),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
