import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/complete_session_dialog.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/study_session_form_sheet.dart';

class StudySessionCard extends ConsumerWidget {
  const StudySessionCard({
    super.key,
    required this.session,
    required this.workspaceId,
    required this.topics,
    required this.isReadOnly,
  });

  final StudySessionModel session;
  final String workspaceId;
  final List<TopicModel> topics;
  final bool isReadOnly;

  Future<void> _handleCompleteToggle(
      BuildContext context, WidgetRef ref) async {
    if (isReadOnly) return;

    if (session.isCompleted) {
      // Toggle back to uncompleted
      await ref
          .read(studyPlanControllerProvider.notifier)
          .uncompleteStudySession(
            workspaceId: workspaceId,
            sessionId: session.id,
          );
    } else {
      // Open complete dialog to optionally record actual duration and notes
      final result =
          await CompleteSessionDialog.show(context, session: session);
      if (result != null) {
        await ref
            .read(studyPlanControllerProvider.notifier)
            .completeStudySession(
              workspaceId: workspaceId,
              sessionId: session.id,
              actualDurationMinutes: result.actualDuration,
              reflectionNotes: result.notes,
            );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSessionConfirmTitle),
        content: Text(l10n.deleteSessionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(studyPlanControllerProvider.notifier).deleteStudySession(
            workspaceId: workspaceId,
            sessionId: session.id,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF);
    final textPrimary =
        isDark ? const Color(0xFFF3F2F7) : const Color(0xFF171522);
    final textSecondary =
        isDark ? const Color(0xFF8E8B9E) : const Color(0xFF5E5B6E);
    final purple = isDark ? const Color(0xFFB49BFF) : const Color(0xFF7C5CE8);

    // Resolve topic
    final bool hasTopicId =
        session.topicId != null && session.topicId!.isNotEmpty;
    final TopicModel? matchedTopic = hasTopicId
        ? topics.cast<TopicModel?>().firstWhere(
              (t) => t?.id == session.topicId,
              orElse: () => null,
            )
        : null;
    final bool isTopicDeleted = hasTopicId && matchedTopic == null;

    final formattedDateTime =
        DateFormat('d MMMM y, HH:mm', locale).format(session.scheduledAt);

    // Status styling: completed vs past-planned vs upcoming-planned
    final (statusLabel, statusColor, statusIcon) =
        switch (session.isCompleted) {
      true => (
          l10n.sessionCompletedStatus,
          Colors.green,
          Icons.check_circle_rounded
        ),
      false when session.isPast => (
          l10n.sessionPastPlannedStatus,
          Colors.amber.shade800,
          Icons.history_rounded,
        ),
      false => (l10n.sessionPlannedStatus, purple, Icons.schedule_rounded),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: session.isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : cardBorder,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status badge & Topic chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (matchedTopic != null) ...[
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      matchedTopic.title,
                      style: TextStyle(
                        color: purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ] else if (isTopicDeleted) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 11, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        l10n.deletedTopic,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            session.title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration:
                  session.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),
          // Date & Time row
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                formattedDateTime,
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Durations row (Planned vs Actual)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222030)
                      : const Color(0xFFF0EEF8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.plannedDurationText(session.plannedDurationMinutes),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (session.actualDurationMinutes != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    l10n.actualDurationText(session.actualDurationMinutes!),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Reflection notes
          if (session.reflectionNotes != null &&
              session.reflectionNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1B1928) : const Color(0xFFF7F6FC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A273D)
                      : const Color(0xFFE8E5F3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reflectionNotesLabel,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    session.reflectionNotes!,
                    style: TextStyle(color: textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Complete / Uncomplete toggle
              if (!isReadOnly)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor:
                        session.isCompleted ? Colors.blueGrey : Colors.green,
                  ),
                  icon: Icon(
                    session.isCompleted
                        ? Icons.replay_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    session.isCompleted
                        ? l10n.markSessionUncompleted
                        : l10n.markSessionCompleted,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _handleCompleteToggle(context, ref),
                )
              else
                const SizedBox.shrink(),
              if (!isReadOnly) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: textSecondary,
                      tooltip: l10n.editSession,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => StudySessionFormSheet.show(
                        context,
                        workspaceId: workspaceId,
                        existingSession: session,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: l10n.deleteSession,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
