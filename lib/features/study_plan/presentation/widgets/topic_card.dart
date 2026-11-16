import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/study_session_form_sheet.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/topic_form_sheet.dart';

class TopicCard extends ConsumerWidget {
  const TopicCard({
    super.key,
    required this.topic,
    required this.workspaceId,
    required this.isReadOnly,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final TopicModel topic;
  final String workspaceId;
  final bool isReadOnly;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  void _cycleStatus(BuildContext context, WidgetRef ref) {
    if (isReadOnly) return;
    final nextStatus = switch (topic.status) {
      TopicStatus.notStarted => TopicStatus.inProgress,
      TopicStatus.inProgress => TopicStatus.completed,
      TopicStatus.completed => TopicStatus.notStarted,
    };
    ref.read(studyPlanControllerProvider.notifier).updateTopic(
          workspaceId: workspaceId,
          topicId: topic.id,
          title: topic.title,
          description: topic.description,
          status: nextStatus,
          orderIndex: topic.orderIndex,
        );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTopicConfirmTitle),
        content: Text(l10n.deleteTopicConfirmBody),
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
      await ref.read(studyPlanControllerProvider.notifier).deleteTopic(
            workspaceId: workspaceId,
            topicId: topic.id,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF);
    final textPrimary =
        isDark ? const Color(0xFFF3F2F7) : const Color(0xFF171522);
    final textSecondary =
        isDark ? const Color(0xFF8E8B9E) : const Color(0xFF5E5B6E);

    final (statusLabel, statusColor) = switch (topic.status) {
      TopicStatus.notStarted => (l10n.topicStatusNotStarted, Colors.blueGrey),
      TopicStatus.inProgress => (
          l10n.topicStatusInProgress,
          Colors.amber.shade800
        ),
      TopicStatus.completed => (l10n.topicStatusCompleted, Colors.green),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: topic.status == TopicStatus.completed
              ? Colors.green.withValues(alpha: 0.3)
              : cardBorder,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order buttons
              if (!isReadOnly) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: isFirst ? null : onMoveUp,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 18,
                          color: isFirst
                              ? textSecondary.withValues(alpha: 0.2)
                              : textSecondary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: isLast ? null : onMoveDown,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isLast
                              ? textSecondary.withValues(alpha: 0.2)
                              : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: topic.status == TopicStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (topic.description != null &&
                        topic.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        topic.description!,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge (clickable to cycle)
              InkWell(
                onTap: isReadOnly ? null : () => _cycleStatus(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
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
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isReadOnly) ...[
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.schedule_rounded, size: 15),
                  label: Text(
                    l10n.planSession,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => StudySessionFormSheet.show(
                    context,
                    workspaceId: workspaceId,
                    preselectedTopicId: topic.id,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: textSecondary,
                  tooltip: l10n.editTopic,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => TopicFormSheet.show(
                    context,
                    workspaceId: workspaceId,
                    existingTopic: topic,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: l10n.deleteTopic,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
