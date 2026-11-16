import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/study_session_card.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/study_session_form_sheet.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/topic_card.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/topic_form_sheet.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

enum _StudyPlanSubTab {
  topics,
  sessions,
}

class StudyPlanSection extends ConsumerStatefulWidget {
  const StudyPlanSection({
    super.key,
    required this.workspace,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    required this.isReadOnly,
  });

  final Workspace workspace;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color purple;
  final Color inputBg;
  final bool isReadOnly;

  @override
  ConsumerState<StudyPlanSection> createState() => _StudyPlanSectionState();
}

class _StudyPlanSectionState extends ConsumerState<StudyPlanSection> {
  _StudyPlanSubTab _selectedSubTab = _StudyPlanSubTab.topics;

  Future<void> _moveTopic(
      List<TopicModel> topics, int currentIndex, int targetIndex) async {
    if (widget.isReadOnly) return;
    if (targetIndex < 0 || targetIndex >= topics.length) return;

    final reordered = List<TopicModel>.from(topics);
    final moved = reordered.removeAt(currentIndex);
    reordered.insert(targetIndex, moved);

    final uid = ref.read(currentUserIdProvider) ?? '';
    await ref.read(studyPlanControllerProvider.notifier).reorderTopics(
          workspaceId: widget.workspace.id,
          ownerId: uid,
          topicIds: reordered.map((t) => t.id).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topicsAsync = ref.watch(topicsStreamProvider(widget.workspace.id));
    final sessionsAsync =
        ref.watch(studySessionsStreamProvider(widget.workspace.id));
    final topicProgress = ref.watch(topicProgressProvider(widget.workspace.id));

    final topics = topicsAsync.valueOrNull ?? [];
    final sessions = sessionsAsync.valueOrNull ?? [];

    final percentInt = (topicProgress.progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Topic Progress Card (Separated from tasks, calculated from real data)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_rounded,
                          size: 16, color: widget.purple),
                      const SizedBox(width: 8),
                      Text(
                        l10n.topicProgress,
                        style: TextStyle(
                          color: widget.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percentInt%',
                    style: TextStyle(
                      color: widget.purple,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: topicProgress.total > 0 ? topicProgress.progress : 0.0,
                  backgroundColor: widget.purple.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.purple),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.completedTopicsCount(
                  topicProgress.completed,
                  topicProgress.total,
                  percentInt,
                ),
                style: TextStyle(
                  color: widget.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Sub-tab switcher: Topics / Study Sessions
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SubTabButton(
                  title: '${l10n.topicsTitle} (${topics.length})',
                  icon: Icons.format_list_bulleted_rounded,
                  isSelected: _selectedSubTab == _StudyPlanSubTab.topics,
                  purple: widget.purple,
                  textPrimary: widget.textPrimary,
                  textSecondary: widget.textSecondary,
                  onTap: () =>
                      setState(() => _selectedSubTab = _StudyPlanSubTab.topics),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SubTabButton(
                  title: '${l10n.studySessionsTitle} (${sessions.length})',
                  icon: Icons.calendar_month_rounded,
                  isSelected: _selectedSubTab == _StudyPlanSubTab.sessions,
                  purple: widget.purple,
                  textPrimary: widget.textPrimary,
                  textSecondary: widget.textSecondary,
                  onTap: () => setState(
                      () => _selectedSubTab = _StudyPlanSubTab.sessions),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Tab Content
        switch (_selectedSubTab) {
          _StudyPlanSubTab.topics => _buildTopicsTab(context, topicsAsync),
          _StudyPlanSubTab.sessions =>
            _buildSessionsTab(context, sessionsAsync, topics),
        },
      ],
    );
  }

  Widget _buildTopicsTab(
    BuildContext context,
    AsyncValue<List<TopicModel>> topicsAsync,
  ) {
    final l10n = context.l10n;

    return topicsAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: widget.purple),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              err.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  ref.invalidate(topicsStreamProvider(widget.workspace.id)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (topics) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Add Topic button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.topicsTitle,
                  style: TextStyle(
                    color: widget.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!widget.isReadOnly)
                  FilledButton.icon(
                    key: const Key('addTopicButton'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.purple,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      l10n.addTopic,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => TopicFormSheet.show(
                      context,
                      workspaceId: widget.workspace.id,
                      nextOrderIndex: topics.length,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (topics.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                decoration: BoxDecoration(
                  color: widget.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 44,
                      color: widget.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.emptyTopics,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (!widget.isReadOnly) ...[
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(l10n.addTopic),
                        onPressed: () => TopicFormSheet.show(
                          context,
                          workspaceId: widget.workspace.id,
                          nextOrderIndex: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                itemBuilder: (ctx, index) {
                  final topic = topics[index];
                  return TopicCard(
                    key: ValueKey(topic.id),
                    topic: topic,
                    workspaceId: widget.workspace.id,
                    isReadOnly: widget.isReadOnly,
                    isFirst: index == 0,
                    isLast: index == topics.length - 1,
                    onMoveUp: () => _moveTopic(topics, index, index - 1),
                    onMoveDown: () => _moveTopic(topics, index, index + 1),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSessionsTab(
    BuildContext context,
    AsyncValue<List<StudySessionModel>> sessionsAsync,
    List<TopicModel> topics,
  ) {
    final l10n = context.l10n;

    return sessionsAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: widget.purple),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              err.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref
                  .invalidate(studySessionsStreamProvider(widget.workspace.id)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (sessions) {
        // Separate upcoming and past sessions
        final now = DateTime.now();
        final upcomingSessions = sessions
            .where((s) =>
                s.scheduledAt.isAfter(now) ||
                s.scheduledAt.isAtSameMomentAs(now))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        final pastSessions = sessions
            .where((s) => s.scheduledAt.isBefore(now))
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Plan Session button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.studySessionsTitle,
                  style: TextStyle(
                    color: widget.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!widget.isReadOnly)
                  FilledButton.icon(
                    key: const Key('addTopicButton'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.purple,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      l10n.planSession,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => StudySessionFormSheet.show(
                      context,
                      workspaceId: widget.workspace.id,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (sessions.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                decoration: BoxDecoration(
                  color: widget.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 44,
                      color: widget.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.emptySessions,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (!widget.isReadOnly) ...[
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(l10n.planSession),
                        onPressed: () => StudySessionFormSheet.show(
                          context,
                          workspaceId: widget.workspace.id,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else ...[
              // Upcoming Sessions
              if (upcomingSessions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${l10n.upcomingSessions} (${upcomingSessions.length})',
                    style: TextStyle(
                      color: widget.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...upcomingSessions.map(
                  (session) => StudySessionCard(
                    key: ValueKey(session.id),
                    session: session,
                    workspaceId: widget.workspace.id,
                    topics: topics,
                    isReadOnly: widget.isReadOnly,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Past Sessions
              if (pastSessions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${l10n.pastSessions} (${pastSessions.length})',
                    style: TextStyle(
                      color: widget.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...pastSessions.map(
                  (session) => StudySessionCard(
                    key: ValueKey(session.id),
                    session: session,
                    workspaceId: widget.workspace.id,
                    topics: topics,
                    isReadOnly: widget.isReadOnly,
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _SubTabButton extends StatelessWidget {
  const _SubTabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? purple.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? purple.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? purple : textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? purple : textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
