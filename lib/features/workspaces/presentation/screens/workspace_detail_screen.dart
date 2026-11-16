import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/notes/presentation/providers/note_providers.dart';
import 'package:task_map_flow/features/notes/presentation/widgets/note_card.dart';
import 'package:task_map_flow/features/notes/presentation/widgets/note_form_sheet.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/study_plan/presentation/widgets/study_plan_section.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/sprint_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/kanban_board_view.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/sprint_detail_sheet.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/sprint_form_sheet.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/presentation/providers/team_providers.dart';
import 'package:task_map_flow/features/team/presentation/widgets/workspace_team_section.dart';
import 'package:task_map_flow/features/workspaces/domain/models/resource_link.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/screens/create_workspace_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

enum _WorkspaceDetailTab {
  work,
  studyPlan,
  notes,
  info,
  team,
}

class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  const WorkspaceDetailScreen({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  ConsumerState<WorkspaceDetailScreen> createState() =>
      _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> {
  bool _isEditing = false;
  _WorkspaceDetailTab _selectedTab = _WorkspaceDetailTab.work;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedColor;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _selectedColor = kWorkspacePalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _populateFields(Workspace ws) {
    if (!_isEditing) {
      _nameController.text = ws.name;
      _descController.text = ws.description ?? '';
      _selectedColor = ws.color;
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

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);

    final result =
        await ref.read(workspaceControllerProvider.notifier).updateWorkspace(
              workspaceId: widget.workspaceId,
              name: name,
              description: _descController.text.trim(),
              color: _selectedColor,
            );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (result case Success()) {
          _isEditing = false;
        }
      });
    }
  }

  Future<void> _confirmArchive() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.archiveAreaConfirmTitle),
        content: Text(l10n.archiveAreaConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CE8),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.archiveArea),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ref
          .read(workspaceControllerProvider.notifier)
          .archiveWorkspace(widget.workspaceId);
      if (mounted) {
        if (result case Success()) {
          context.pop();
        } else if (result case Err(:final failure)) {
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

  Future<void> _confirmRestore() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreArea),
        content: Text(l10n.restoreAreaConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CE8),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.restoreArea),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ref
          .read(workspaceControllerProvider.notifier)
          .restoreWorkspace(widget.workspaceId);
      if (mounted) {
        if (result case Success()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreArea),
            ),
          );
        } else if (result case Err(:final failure)) {
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

  Future<void> _confirmDelete(String mapNodeId) async {
    final l10n = context.l10n;
    final uid = ref.read(currentUserIdProvider) ?? '';

    // Check if tasks, sprints, notes, topics, or study sessions exist in workspace
    final hasTasksResult = await ref.read(taskRepositoryProvider).hasTasks(
          workspaceId: widget.workspaceId,
          ownerId: uid,
        );
    final hasSprintsResult =
        await ref.read(sprintRepositoryProvider).hasSprints(
              workspaceId: widget.workspaceId,
              ownerId: uid,
            );
    final hasNotesResult = await ref.read(noteRepositoryProvider).hasNotes(
          workspaceId: widget.workspaceId,
          ownerId: uid,
        );
    final hasTopicsResult =
        await ref.read(studyPlanRepositoryProvider).hasTopics(
              workspaceId: widget.workspaceId,
              ownerId: uid,
            );
    final hasStudySessionsResult =
        await ref.read(studyPlanRepositoryProvider).hasStudySessions(
              workspaceId: widget.workspaceId,
              ownerId: uid,
            );

    if (!mounted) return;

    if (hasTasksResult case Err()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteAreaTaskCheckFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final hasTasks = (hasTasksResult as Success<bool>).value;
    final hasSprints =
        (hasSprintsResult is Success<bool>) && hasSprintsResult.value;
    final hasNotes = (hasNotesResult is Success<bool>) && hasNotesResult.value;
    final hasTopics =
        (hasTopicsResult is Success<bool>) && hasTopicsResult.value;
    final hasStudySessions = (hasStudySessionsResult is Success<bool>) &&
        hasStudySessionsResult.value;

    if (hasTasks || hasSprints || hasNotes || hasTopics || hasStudySessions) {
      final message = (hasSprints || hasNotes || hasTopics || hasStudySessions)
          ? l10n.deleteAreaHasContentError
          : l10n.deleteAreaHasTasksError;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteConfirmTitle),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody),
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

    if (confirmed == true && mounted) {
      final deleteResult =
          await ref.read(workspaceControllerProvider.notifier).deleteWorkspace(
                workspaceId: widget.workspaceId,
                mapNodeId: mapNodeId,
              );

      if (mounted) {
        if (deleteResult case Success()) {
          context.pop();
        } else if (deleteResult case Err(:final failure)) {
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
    final locale = Localizations.localeOf(context).languageCode;

    final workspacesAsync = ref.watch(workspacesStreamProvider);
    final nodesAsync = ref.watch(mapNodesStreamProvider);

    final workspaces = workspacesAsync.valueOrNull ?? [];
    final currentWorkspace = workspaces.cast<Workspace?>().firstWhere(
          (w) => w?.id == widget.workspaceId,
          orElse: () => null,
        );
    final isArchived = currentWorkspace?.isArchived ?? false;

    final bg = isDark ? const Color(0xFF0F0E17) : const Color(0xFFF9F9FC);
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          l10n.areaDetailTitle,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: textPrimary,
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!isArchived)
            IconButton(
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_outlined,
                  size: 22),
              color: textPrimary,
              tooltip: _isEditing ? l10n.cancel : l10n.editArea,
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: workspacesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: purple)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                err.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(workspacesStreamProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (workspaces) {
          final workspace = workspaces.cast<Workspace?>().firstWhere(
                (w) => w?.id == widget.workspaceId,
                orElse: () => null,
              );

          if (workspace == null) {
            return Center(
              child: Text(
                l10n.noWorkspacesYet,
                style: TextStyle(color: textSecondary),
              ),
            );
          }

          _populateFields(workspace);
          final accentColor = _parseHex(workspace.color);
          final typeName = switch (workspace.type) {
            WorkspaceType.project => l10n.typeProject,
            WorkspaceType.lesson => l10n.typeLesson,
            WorkspaceType.freeform => l10n.typeFreeform,
          };
          final formattedDate =
              DateFormat.yMMMMd(locale).format(workspace.createdAt);

          final nodes = nodesAsync.valueOrNull ?? [];
          final node = nodes.firstWhere(
            (n) => n.workspaceId == workspace.id,
            orElse: () => MapNode(
              id: '',
              workspaceId: workspace.id,
              ownerId: workspace.ownerId,
              positionX: 0,
              positionY: 0,
              width: 180,
              height: 110,
              createdAt: workspace.createdAt,
              updatedAt: workspace.updatedAt,
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (workspace.isArchived) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CE8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7C5CE8).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.archive_outlined,
                            color: Color(0xFF7C5CE8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.areaArchivedNotice,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (workspace.archivedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${l10n.archivedAtLabel}: ${DateFormat.yMMMMd(locale).format(workspace.archivedAt!)}',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                          onPressed: _confirmRestore,
                          child: Text(l10n.restoreArea,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Header Area Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      switch (workspace.type) {
                                        WorkspaceType.project =>
                                          Icons.rocket_launch_outlined,
                                        WorkspaceType.lesson =>
                                          Icons.school_outlined,
                                        WorkspaceType.freeform =>
                                          Icons.bubble_chart_outlined,
                                      },
                                      size: 13,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      typeName,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (workspace.isArchived) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.amber
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    l10n.areaArchivedBadge,
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing) ...[
                        Text(
                          l10n.areaNameLabel,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          maxLength: 100,
                          style: TextStyle(color: textPrimary, fontSize: 16),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputBg,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.areaColorLabel,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: kWorkspacePalette.map((hex) {
                            final c = _parseHex(hex);
                            final isSelected = _selectedColor == hex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = hex),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2.0,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        Text(
                          workspace.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Description Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.areaDescriptionLabel,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isEditing)
                        TextField(
                          controller: _descController,
                          maxLines: 3,
                          maxLength: 500,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputBg,
                            counterText: '',
                            hintText: l10n.areaDescriptionPlaceholder,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      else
                        Text(
                          (workspace.description != null &&
                                  workspace.description!.isNotEmpty)
                              ? workspace.description!
                              : l10n.noDescription,
                          style: TextStyle(
                            color: (workspace.description != null &&
                                    workspace.description!.isNotEmpty)
                                ? textPrimary
                                : textSecondary.withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Created date row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.createdAtLabel}: $formattedDate',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Segmented control: [ Çalışma | Çalışma Planı (Lesson only) | Notlar | Bilgiler | Ekip ]
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TabButton(
                          title: l10n.tabWork,
                          icon: Icons.checklist_rounded,
                          isSelected: _selectedTab == _WorkspaceDetailTab.work,
                          purple: purple,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () => setState(
                              () => _selectedTab = _WorkspaceDetailTab.work),
                        ),
                        if (workspace.type == WorkspaceType.lesson) ...[
                          const SizedBox(width: 4),
                          _TabButton(
                            title: l10n.tabStudyPlan,
                            icon: Icons.school_outlined,
                            isSelected:
                                _selectedTab == _WorkspaceDetailTab.studyPlan,
                            purple: purple,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => setState(() =>
                                _selectedTab = _WorkspaceDetailTab.studyPlan),
                          ),
                        ],
                        const SizedBox(width: 4),
                        _TabButton(
                          title: l10n.tabNotes,
                          icon: Icons.note_alt_outlined,
                          isSelected: _selectedTab == _WorkspaceDetailTab.notes,
                          purple: purple,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () => setState(
                              () => _selectedTab = _WorkspaceDetailTab.notes),
                        ),
                        const SizedBox(width: 4),
                        _TabButton(
                          title: l10n.tabInfo,
                          icon: Icons.info_outline_rounded,
                          isSelected: _selectedTab == _WorkspaceDetailTab.info,
                          purple: purple,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () => setState(
                              () => _selectedTab = _WorkspaceDetailTab.info),
                        ),
                        const SizedBox(width: 4),
                        _TabButton(
                          title: l10n.teamSectionTitle,
                          icon: Icons.groups_rounded,
                          isSelected: _selectedTab == _WorkspaceDetailTab.team,
                          purple: purple,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () => setState(
                              () => _selectedTab = _WorkspaceDetailTab.team),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                switch (_selectedTab) {
                  _WorkspaceDetailTab.work => _WorkSection(
                      workspace: workspace,
                      accentColor: accentColor,
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      purple: purple,
                      inputBg: inputBg,
                      isReadOnly: workspace.isArchived,
                    ),
                  _WorkspaceDetailTab.studyPlan =>
                    workspace.type == WorkspaceType.lesson
                        ? StudyPlanSection(
                            workspace: workspace,
                            isDark: isDark,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            purple: purple,
                            inputBg: inputBg,
                            isReadOnly: workspace.isArchived,
                          )
                        : _WorkSection(
                            workspace: workspace,
                            accentColor: accentColor,
                            isDark: isDark,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            purple: purple,
                            inputBg: inputBg,
                            isReadOnly: workspace.isArchived,
                          ),
                  _WorkspaceDetailTab.notes => _NotesSection(
                      workspace: workspace,
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      purple: purple,
                      inputBg: inputBg,
                      isReadOnly: workspace.isArchived,
                    ),
                  _WorkspaceDetailTab.info => _InfoSection(
                      workspace: workspace,
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      purple: purple,
                      inputBg: inputBg,
                      isReadOnly: workspace.isArchived,
                    ),
                  _WorkspaceDetailTab.team => WorkspaceTeamSection(
                      workspace: workspace,
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      purple: purple,
                      inputBg: inputBg,
                      isReadOnly: workspace.isArchived,
                    ),
                },
                const SizedBox(height: 20),

                // Bottom Actions: Restore if archived, else Edit/Archive/Delete
                if (workspace.isArchived) ...[
                  FilledButton.icon(
                    key: const Key('restoreWorkspaceButton'),
                    icon: const Icon(Icons.unarchive_outlined, size: 18),
                    label: Text(l10n.restoreArea),
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _confirmRestore,
                  ),
                ] else ...[
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => setState(() => _isEditing = false),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: purple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _saveChanges,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l10n.save),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    key: const Key('archiveWorkspaceButton'),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: Text(
                      l10n.archiveArea,
                      style: TextStyle(color: purple),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: purple.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _confirmArchive,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('deleteWorkspaceButton'),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      l10n.deleteArea,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _confirmDelete(node.id),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkSection extends ConsumerWidget {
  const _WorkSection({
    required this.workspace,
    required this.accentColor,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    this.isReadOnly = false,
  });

  final Workspace workspace;
  final Color accentColor;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color purple;
  final Color inputBg;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final viewMode = ref.watch(workspaceViewModeProvider(workspace.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Segmented Tab Switch: Görevler / Backlog / Sprintler
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161423) : const Color(0xFFEDEBF5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentTab(
                  label: l10n.viewTasks,
                  isSelected: viewMode == WorkspaceViewMode.tasks,
                  onTap: () => ref
                      .read(workspaceViewModeProvider(workspace.id).notifier)
                      .state = WorkspaceViewMode.tasks,
                  purple: purple,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _SegmentTab(
                  label: l10n.viewBacklog,
                  isSelected: viewMode == WorkspaceViewMode.backlog,
                  onTap: () => ref
                      .read(workspaceViewModeProvider(workspace.id).notifier)
                      .state = WorkspaceViewMode.backlog,
                  purple: purple,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _SegmentTab(
                  label: l10n.viewSprints,
                  isSelected: viewMode == WorkspaceViewMode.sprints,
                  onTap: () => ref
                      .read(workspaceViewModeProvider(workspace.id).notifier)
                      .state = WorkspaceViewMode.sprints,
                  purple: purple,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Body based on active view mode
        switch (viewMode) {
          WorkspaceViewMode.tasks => _TasksView(
              workspace: workspace,
              accentColor: accentColor,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              purple: purple,
              inputBg: inputBg,
              isReadOnly: isReadOnly,
            ),
          WorkspaceViewMode.backlog => _BacklogView(
              workspace: workspace,
              accentColor: accentColor,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              purple: purple,
              inputBg: inputBg,
              isReadOnly: isReadOnly,
            ),
          WorkspaceViewMode.sprints => _SprintsView(
              workspace: workspace,
              accentColor: accentColor,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              purple: purple,
              inputBg: inputBg,
              isReadOnly: isReadOnly,
            ),
        },
      ],
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.purple,
    required this.textSecondary,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color purple;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF262238) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? purple : textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TasksView extends ConsumerWidget {
  const _TasksView({
    required this.workspace,
    required this.accentColor,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    this.isReadOnly = false,
  });

  final Workspace workspace;
  final Color accentColor;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color purple;
  final Color inputBg;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isLesson = workspace.type == WorkspaceType.lesson;
    final addActionLabel = isLesson ? l10n.addStep : l10n.addTask;

    final tasksAsync = ref.watch(tasksStreamProvider(workspace.id));
    final stats = ref.watch(taskStatsProvider(workspace.id));
    final activeFilter = ref.watch(taskFilterProvider(workspace.id));
    final displayMode = ref.watch(taskDisplayModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isLesson ? l10n.studyStepsTitle : l10n.tasksTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DisplayModeToggle(
                  displayMode: displayMode,
                  onChanged: (mode) =>
                      ref.read(taskDisplayModeProvider.notifier).setMode(mode),
                  purple: purple,
                  isDark: isDark,
                  textSecondary: textSecondary,
                ),
                if (!isReadOnly) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('addTaskButton'),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      addActionLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => TaskFormSheet.show(
                      context: context,
                      workspaceId: workspace.id,
                      workspaceType: workspace.type,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress Bar
        if (stats.total > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.taskProgress(
                          stats.completed, stats.total, stats.percent),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '%${stats.percent}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: stats.total > 0 ? stats.completed / stats.total : 0,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? const Color(0xFF262335)
                        : const Color(0xFFE8E6F2),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Filters (only in list mode)
          if (displayMode == TaskDisplayMode.list) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: '${l10n.filterAll} (${stats.total})',
                    isSelected: activeFilter == TaskFilter.all,
                    onTap: () => ref
                        .read(taskFilterProvider(workspace.id).notifier)
                        .state = TaskFilter.all,
                    purple: purple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: '${l10n.filterTodo} (${stats.todo})',
                    isSelected: activeFilter == TaskFilter.todo,
                    onTap: () => ref
                        .read(taskFilterProvider(workspace.id).notifier)
                        .state = TaskFilter.todo,
                    purple: purple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: '${l10n.filterInProgress} (${stats.inProgress})',
                    isSelected: activeFilter == TaskFilter.inProgress,
                    onTap: () => ref
                        .read(taskFilterProvider(workspace.id).notifier)
                        .state = TaskFilter.inProgress,
                    purple: purple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: '${l10n.filterCompleted} (${stats.completed})',
                    isSelected: activeFilter == TaskFilter.completed,
                    onTap: () => ref
                        .read(taskFilterProvider(workspace.id).notifier)
                        .state = TaskFilter.completed,
                    purple: purple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  if (workspace.isTeamEnabled) ...[
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: l10n.filterAssignedToMe,
                      isSelected: activeFilter == TaskFilter.assignedToMe,
                      onTap: () => ref
                          .read(taskFilterProvider(workspace.id).notifier)
                          .state = TaskFilter.assignedToMe,
                      purple: purple,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],

        // Task Items List or Kanban Board
        tasksAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: purple),
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              err.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (tasks) {
            if (displayMode == TaskDisplayMode.board) {
              if (tasks.isEmpty) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLesson
                            ? Icons.fact_check_outlined
                            : Icons.checklist_rounded,
                        color: accentColor,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLesson ? l10n.noStepsYet : l10n.noTasksYet,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLesson ? l10n.noStepsSubtitle : l10n.noTasksSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return KanbanBoardView(
                workspace: workspace,
                tasks: tasks,
                isReadOnly: isReadOnly,
              );
            }

            final uid = ref.watch(currentUserIdProvider) ?? '';
            final filtered =
                tasks.where((t) => activeFilter.matches(t, uid)).toList();

            final members = ref
                    .watch(workspaceMembersStreamProvider(workspace.id))
                    .valueOrNull ??
                [];
            final callerRole = ref
                    .watch(currentUserMemberRoleProvider(workspace.id))
                    .valueOrNull ??
                (workspace.ownerId == uid
                    ? MemberRole.owner
                    : MemberRole.member);

            if (tasks.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLesson
                          ? Icons.fact_check_outlined
                          : Icons.checklist_rounded,
                      color: accentColor,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLesson ? l10n.noStepsYet : l10n.noTasksYet,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLesson ? l10n.noStepsSubtitle : l10n.noTasksSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  l10n.noDescription,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              );
            }

            return Column(
              children: filtered.map((task) {
                final member = task.assigneeId != null
                    ? members
                        .where((m) => m.userId == task.assigneeId)
                        .firstOrNull
                    : null;
                final isNoLonger = task.assigneeId != null &&
                    member == null &&
                    workspace.isTeamEnabled;
                final canEditTask = !isReadOnly &&
                    (callerRole == MemberRole.owner ||
                        callerRole == MemberRole.admin ||
                        task.ownerId == uid);

                return TaskItemCard(
                  key: ValueKey(task.id),
                  task: task,
                  assigneeName: member?.displayName,
                  isAssigneeNoLongerOnTeam: isNoLonger,
                  onTap: canEditTask
                      ? () => TaskFormSheet.show(
                            context: context,
                            workspaceId: workspace.id,
                            workspaceType: workspace.type,
                            initialTask: task,
                          )
                      : null,
                  onToggleStatus: isReadOnly
                      ? null
                      : (newStatus) {
                          ref
                              .read(taskControllerProvider.notifier)
                              .updateTaskStatus(
                                workspaceId: workspace.id,
                                taskId: task.id,
                                status: newStatus,
                              );
                        },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BacklogView extends ConsumerWidget {
  const _BacklogView({
    required this.workspace,
    required this.accentColor,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    this.isReadOnly = false,
  });

  final Workspace workspace;
  final Color accentColor;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color purple;
  final Color inputBg;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tasksAsync = ref.watch(tasksStreamProvider(workspace.id));
    final sprintsAsync = ref.watch(sprintsStreamProvider(workspace.id));
    final sprints = sprintsAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.viewBacklog,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isReadOnly)
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  l10n.addTask,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => TaskFormSheet.show(
                  context: context,
                  workspaceId: workspace.id,
                  workspaceType: workspace.type,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: purple),
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              err.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (tasks) {
            final backlogTasks = tasks.where((t) => t.isBacklog).toList();

            if (backlogTasks.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, color: accentColor, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noBacklogTasks,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.noBacklogTasksSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            final uid = ref.watch(currentUserIdProvider) ?? '';
            final members = ref
                    .watch(workspaceMembersStreamProvider(workspace.id))
                    .valueOrNull ??
                [];
            final callerRole = ref
                    .watch(currentUserMemberRoleProvider(workspace.id))
                    .valueOrNull ??
                (workspace.ownerId == uid
                    ? MemberRole.owner
                    : MemberRole.member);

            return Column(
              children: backlogTasks.map((task) {
                final member = task.assigneeId != null
                    ? members
                        .where((m) => m.userId == task.assigneeId)
                        .firstOrNull
                    : null;
                final isNoLonger = task.assigneeId != null &&
                    member == null &&
                    workspace.isTeamEnabled;
                final canEditTask = !isReadOnly &&
                    (callerRole == MemberRole.owner ||
                        callerRole == MemberRole.admin ||
                        task.ownerId == uid);

                return Stack(
                  children: [
                    TaskItemCard(
                      key: ValueKey(task.id),
                      task: task,
                      assigneeName: member?.displayName,
                      isAssigneeNoLongerOnTeam: isNoLonger,
                      onTap: canEditTask
                          ? () => TaskFormSheet.show(
                                context: context,
                                workspaceId: workspace.id,
                                workspaceType: workspace.type,
                                initialTask: task,
                              )
                          : null,
                      onToggleStatus: isReadOnly
                          ? null
                          : (newStatus) {
                              ref
                                  .read(taskControllerProvider.notifier)
                                  .updateTaskStatus(
                                    workspaceId: workspace.id,
                                    taskId: task.id,
                                    status: newStatus,
                                  );
                            },
                    ),
                    if (sprints.isNotEmpty && !isReadOnly)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              size: 16, color: textSecondary),
                          tooltip: l10n.assignToSprint,
                          onSelected: (sprintId) {
                            ref
                                .read(taskControllerProvider.notifier)
                                .assignTaskToSprint(
                                  workspaceId: workspace.id,
                                  taskId: task.id,
                                  sprintId: sprintId,
                                );
                          },
                          itemBuilder: (ctx) => sprints.map((sp) {
                            return PopupMenuItem<String>(
                              value: sp.id,
                              child: Text(sp.name),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SprintsView extends ConsumerWidget {
  const _SprintsView({
    required this.workspace,
    required this.accentColor,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    this.isReadOnly = false,
  });

  final Workspace workspace;
  final Color accentColor;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color purple;
  final Color inputBg;
  final bool isReadOnly;

  Future<void> _handleCompleteSprint(
    BuildContext context,
    WidgetRef ref,
    SprintModel sprint,
    List<TaskModel> sprintTasks,
  ) async {
    final l10n = context.l10n;
    final incompleteCount =
        sprintTasks.where((t) => t.status != TaskStatus.completed).length;

    if (incompleteCount > 0) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.completeSprintConfirmTitle),
          content: Text(l10n.completeSprintPrompt(incompleteCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('keep'),
              child: Text(l10n.keepInSprint),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('move'),
              child: Text(l10n.moveIncompleteToBacklog),
            ),
          ],
        ),
      );

      if (action == null || action == 'cancel') return;

      if (action == 'move') {
        await ref.read(taskControllerProvider.notifier).moveTasksToBacklog(
              workspaceId: workspace.id,
              sprintId: sprint.id,
            );
      }
    }

    await ref.read(sprintControllerProvider.notifier).updateSprintStatus(
          workspaceId: workspace.id,
          sprintId: sprint.id,
          status: SprintStatus.completed,
        );
  }

  Future<void> _handleDeleteSprint(
    BuildContext context,
    WidgetRef ref,
    SprintModel sprint,
    List<TaskModel> sprintTasks,
  ) async {
    final l10n = context.l10n;

    if (sprintTasks.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteSprint),
          content: Text(l10n.deleteSprintWithTasksConfirm(sprintTasks.length)),
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
              child: Text(l10n.moveTasksToBacklogAndDelete),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(taskControllerProvider.notifier).moveTasksToBacklog(
              workspaceId: workspace.id,
              sprintId: sprint.id,
            );
        await ref.read(sprintControllerProvider.notifier).deleteSprint(
              workspaceId: workspace.id,
              sprintId: sprint.id,
            );
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteSprint),
          content: const Text('Bu sprinti silmek istediğinize emin misiniz?'),
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
        await ref.read(sprintControllerProvider.notifier).deleteSprint(
              workspaceId: workspace.id,
              sprintId: sprint.id,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final sprintsAsync = ref.watch(sprintsStreamProvider(workspace.id));
    final tasksAsync = ref.watch(tasksStreamProvider(workspace.id));
    final allTasks = tasksAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.viewSprints,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isReadOnly)
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  l10n.createSprint,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => SprintFormSheet.show(
                  context: context,
                  workspaceId: workspace.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        sprintsAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: purple),
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              err.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (sprints) {
            if (sprints.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: accentColor, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noSprintsYet,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.noSprintsSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: sprints.map((sprint) {
                final sprintTasks =
                    allTasks.where((t) => t.sprintId == sprint.id).toList();
                final completedCount = sprintTasks
                    .where((t) => t.status == TaskStatus.completed)
                    .length;
                final totalCount = sprintTasks.length;
                final percent =
                    totalCount > 0 ? (completedCount * 100 ~/ totalCount) : 0;

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

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sprint.status == SprintStatus.active
                          ? statusColor
                          : cardBorder,
                      width: sprint.status == SprintStatus.active ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Name & Status Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sprint.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
                      const SizedBox(height: 6),

                      // Dates
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 13, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            dateText,
                            style:
                                TextStyle(color: textSecondary, fontSize: 11),
                          ),
                        ],
                      ),

                      if (sprint.goal.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          sprint.goal,
                          style: TextStyle(
                            color: textSecondary.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],

                      // Task progress
                      if (totalCount > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedCount / $totalCount tamamlandı',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '%$percent',
                              style: TextStyle(
                                color: purple,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: completedCount / totalCount,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? const Color(0xFF262335)
                                : const Color(0xFFE8E6F2),
                            valueColor: AlwaysStoppedAnimation<Color>(purple),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      // Action buttons: Pano, Start / Complete, Edit, Delete
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.view_kanban_outlined,
                                size: 14),
                            label: Text(
                              l10n.viewSprintBoard,
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => SprintDetailSheet.show(
                              context: context,
                              workspace: workspace,
                              sprint: sprint,
                              isReadOnly: isReadOnly,
                            ),
                          ),
                          if (!isReadOnly) ...[
                            const SizedBox(width: 8),
                            if (sprint.status == SprintStatus.planned)
                              FilledButton.icon(
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 14),
                                label: Text(
                                  l10n.startSprint,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  ref
                                      .read(sprintControllerProvider.notifier)
                                      .updateSprintStatus(
                                        workspaceId: workspace.id,
                                        sprintId: sprint.id,
                                        status: SprintStatus.active,
                                      );
                                },
                              )
                            else if (sprint.status == SprintStatus.active)
                              FilledButton.icon(
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 14),
                                label: Text(
                                  l10n.completeSprint,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: purple,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _handleCompleteSprint(
                                    context, ref, sprint, sprintTasks),
                              ),
                          ],
                          const Spacer(),
                          if (!isReadOnly) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              color: textSecondary,
                              tooltip: l10n.editSprint,
                              onPressed: () => SprintFormSheet.show(
                                context: context,
                                workspaceId: workspace.id,
                                initialSprint: sprint,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16),
                              color: Theme.of(context).colorScheme.error,
                              tooltip: l10n.deleteSprint,
                              onPressed: () => _handleDeleteSprint(
                                  context, ref, sprint, sprintTasks),
                            ),
                          ],
                        ],
                      ),

                      // Display tasks assigned to this sprint
                      if (sprintTasks.isNotEmpty) ...[
                        const Divider(height: 16),
                        for (final task in sprintTasks)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  task.status == TaskStatus.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: task.status == TaskStatus.completed
                                      ? purple
                                      : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: task.status == TaskStatus.completed
                                          ? textSecondary
                                          : textPrimary,
                                      decoration:
                                          task.status == TaskStatus.completed
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.purple,
    required this.textSecondary,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color purple;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? purple
              : (isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF1F0F7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? purple
                : (isDark ? const Color(0xFF2C293C) : const Color(0xFFDFDDE8)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            Text(
              title,
              style: TextStyle(
                color: isSelected ? purple : textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesSection extends ConsumerWidget {
  const _NotesSection({
    required this.workspace,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    this.isReadOnly = false,
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

  Future<void> _deleteNote(
      BuildContext context, WidgetRef ref, String noteId) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNoteConfirmTitle),
        content: Text(l10n.deleteNoteConfirmMessage),
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

    if (confirmed == true && context.mounted) {
      final result = await ref.read(noteControllerProvider.notifier).deleteNote(
            workspaceId: workspace.id,
            noteId: noteId,
          );
      if (!context.mounted) return;
      if (result case Success()) {
        ref.read(noteListProvider(workspace.id).notifier).onNoteDeleted(noteId);
      } else if (result case Err(:final failure)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notesState = ref.watch(noteListProvider(workspace.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.quickNotesTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isReadOnly)
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.addNote),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => NoteFormSheet.show(
                  context,
                  workspaceId: workspace.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (notesState.isLoading && notesState.notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: purple)),
          )
        else if (notesState.errorMessage != null && notesState.notes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  notesState.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref
                      .read(noteListProvider(workspace.id).notifier)
                      .loadInitial(),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          )
        else if (notesState.notes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 40,
                  color: textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noNotesYet,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noNotesSub,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isReadOnly) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(l10n.addNote),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: purple,
                      side: BorderSide(color: purple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => NoteFormSheet.show(
                      context,
                      workspaceId: workspace.id,
                    ),
                  ),
                ],
              ],
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notesState.notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final note = notesState.notes[idx];
              return NoteCard(
                note: note,
                isDark: isDark,
                accentColor: purple,
                onTap: () => NoteDetailSheet.show(
                  context,
                  note: note,
                  isDark: isDark,
                  accentColor: purple,
                  onEdit: isReadOnly
                      ? null
                      : () => NoteFormSheet.show(
                            context,
                            workspaceId: workspace.id,
                            existingNote: note,
                          ),
                  onDelete: isReadOnly
                      ? null
                      : () => _deleteNote(context, ref, note.id),
                ),
                onEdit: isReadOnly
                    ? null
                    : () => NoteFormSheet.show(
                          context,
                          workspaceId: workspace.id,
                          existingNote: note,
                        ),
                onDelete: isReadOnly
                    ? null
                    : () => _deleteNote(context, ref, note.id),
              );
            },
          ),
          if (notesState.hasMore) ...[
            const SizedBox(height: 14),
            Center(
              child: notesState.isLoadingMore
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: purple,
                      ),
                    )
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: purple,
                        side: BorderSide(color: purple.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => ref
                          .read(noteListProvider(workspace.id).notifier)
                          .loadMore(),
                      child: Text(l10n.loadMore),
                    ),
            ),
          ],
        ],
      ],
    );
  }
}

class _InfoSection extends ConsumerStatefulWidget {
  const _InfoSection({
    required this.workspace,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    this.isReadOnly = false,
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
  ConsumerState<_InfoSection> createState() => _InfoSectionState();
}

class _InfoSectionState extends ConsumerState<_InfoSection> {
  late TextEditingController _descController;
  bool _isSavingDesc = false;

  @override
  void initState() {
    super.initState();
    _descController =
        TextEditingController(text: widget.workspace.description ?? '');
  }

  @override
  void didUpdateWidget(covariant _InfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workspace.description != oldWidget.workspace.description &&
        !_isSavingDesc) {
      _descController.text = widget.workspace.description ?? '';
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveDescription() async {
    setState(() => _isSavingDesc = true);
    final result = await ref
        .read(workspaceControllerProvider.notifier)
        .updateWorkspaceInfo(
          workspaceId: widget.workspace.id,
          description: _descController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSavingDesc = false);

    if (result case Success()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.infoSavedSuccess),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } else if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteTag(String tag) async {
    final updatedTags = List<String>.from(widget.workspace.tags)..remove(tag);
    final result = await ref
        .read(workspaceControllerProvider.notifier)
        .updateWorkspaceInfo(
          workspaceId: widget.workspace.id,
          tags: updatedTags,
        );

    if (!mounted) return;
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showAddTagDialog() async {
    final l10n = context.l10n;
    if (widget.workspace.tags.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tagLimitReached),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final tagController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final addedTag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.cardBorder),
        ),
        title: Text(
          l10n.addTag,
          style: TextStyle(
            color: widget.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: tagController,
            maxLength: 30,
            autofocus: true,
            style: TextStyle(color: widget.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.tagPlaceholder,
              hintStyle: TextStyle(
                  color: widget.textSecondary.withValues(alpha: 0.5),
                  fontSize: 13),
              counterText: '',
              filled: true,
              fillColor: widget.inputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.cardBorder),
              ),
            ),
            validator: (val) {
              final trimmed = val?.trim() ?? '';
              if (trimmed.isEmpty) return l10n.tagPlaceholder;
              if (trimmed.length > 30) return l10n.tagLengthExceeded;
              if (widget.workspace.tags.contains(trimmed)) {
                return l10n.tagPlaceholder;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.purple),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(tagController.text.trim());
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (addedTag != null && addedTag.isNotEmpty && mounted) {
      final updatedTags = [...widget.workspace.tags, addedTag];
      final result = await ref
          .read(workspaceControllerProvider.notifier)
          .updateWorkspaceInfo(
            workspaceId: widget.workspace.id,
            tags: updatedTags,
          );

      if (!mounted) return;
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

  Future<void> _launchSafeUrl(String urlString) async {
    final l10n = context.l10n;
    final trimmed = urlString.trim();
    if (!ResourceLink.isValidUrl(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidUrlError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final uri = Uri.parse(trimmed);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.urlLaunchError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.urlLaunchError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteResource(String resourceId) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteResourceConfirmTitle),
        content: Text(l10n.deleteResourceConfirmMessage),
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

    if (confirmed == true && mounted) {
      final updatedResources =
          widget.workspace.resources.where((r) => r.id != resourceId).toList();
      final result = await ref
          .read(workspaceControllerProvider.notifier)
          .updateWorkspaceInfo(
            workspaceId: widget.workspace.id,
            resources: updatedResources,
          );

      if (!mounted) return;
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

  Future<void> _showResourceDialog({ResourceLink? existingResource}) async {
    final l10n = context.l10n;
    final isEditing = existingResource != null;

    if (!isEditing && widget.workspace.resources.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tagLimitReached),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final titleController =
        TextEditingController(text: existingResource?.title ?? '');
    final urlController =
        TextEditingController(text: existingResource?.url ?? '');
    final formKey = GlobalKey<FormState>();

    final savedResource = await showDialog<ResourceLink>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.cardBorder),
        ),
        title: Text(
          isEditing ? l10n.editResource : l10n.addResource,
          style: TextStyle(
            color: widget.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.resourceTitleLabel} *',
                style: TextStyle(
                    color: widget.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: titleController,
                maxLength: 100,
                style: TextStyle(color: widget.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.resourceTitlePlaceholder,
                  hintStyle: TextStyle(
                      color: widget.textSecondary.withValues(alpha: 0.5),
                      fontSize: 13),
                  counterText: '',
                  filled: true,
                  fillColor: widget.inputBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.cardBorder),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isEmpty) return l10n.resourceTitlePlaceholder;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text(
                '${l10n.resourceUrlLabel} *',
                style: TextStyle(
                    color: widget.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: urlController,
                maxLength: 500,
                keyboardType: TextInputType.url,
                style: TextStyle(color: widget.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.resourceUrlPlaceholder,
                  hintStyle: TextStyle(
                      color: widget.textSecondary.withValues(alpha: 0.5),
                      fontSize: 13),
                  counterText: '',
                  filled: true,
                  fillColor: widget.inputBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.cardBorder),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (!ResourceLink.isValidUrl(trimmed)) {
                    return l10n.invalidUrlError;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.purple),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final id = existingResource?.id ??
                    'res_${DateTime.now().millisecondsSinceEpoch}';
                Navigator.of(ctx).pop(
                  ResourceLink(
                    id: id,
                    title: titleController.text.trim(),
                    url: urlController.text.trim(),
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (savedResource != null && mounted) {
      List<ResourceLink> updatedList;
      if (isEditing) {
        updatedList = widget.workspace.resources.map((r) {
          return r.id == savedResource.id ? savedResource : r;
        }).toList();
      } else {
        updatedList = [...widget.workspace.resources, savedResource];
      }

      final result = await ref
          .read(workspaceControllerProvider.notifier)
          .updateWorkspaceInfo(
            workspaceId: widget.workspace.id,
            resources: updatedList,
          );

      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Description Card
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
                  Text(
                    l10n.areaDescriptionLabel,
                    style: TextStyle(
                      color: widget.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!widget.isReadOnly)
                    TextButton.icon(
                      icon: _isSavingDesc
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.purple,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: Text(l10n.save),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.purple,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _isSavingDesc ? null : _saveDescription,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                readOnly: widget.isReadOnly,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(color: widget.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.inputBg,
                  counterText: '',
                  hintText: l10n.areaDescriptionPlaceholder,
                  hintStyle: TextStyle(
                    color: widget.textSecondary.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.purple, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tags Card
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
                      Text(
                        l10n.tagsTitle,
                        style: TextStyle(
                          color: widget.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${widget.workspace.tags.length}/20)',
                        style: TextStyle(
                          color: widget.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isReadOnly && widget.workspace.tags.length < 20)
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(l10n.addTag),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.purple,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _showAddTagDialog,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.workspace.tags.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    l10n.tagPlaceholder,
                    style: TextStyle(
                      color: widget.textSecondary.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.workspace.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.purple.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#$tag',
                            style: TextStyle(
                              color: widget.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!widget.isReadOnly) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _deleteTag(tag),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: widget.purple,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Resources Card
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
                      Text(
                        l10n.resourcesTitle,
                        style: TextStyle(
                          color: widget.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${widget.workspace.resources.length}/20)',
                        style: TextStyle(
                          color: widget.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isReadOnly &&
                      widget.workspace.resources.length < 20)
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(l10n.addResource),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.purple,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showResourceDialog(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.workspace.resources.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    l10n.noResourcesYet,
                    style: TextStyle(
                      color: widget.textSecondary.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.workspace.resources.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final res = widget.workspace.resources[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded,
                              size: 18, color: widget.purple),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => _launchSafeUrl(res.url),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.title,
                                    style: TextStyle(
                                      color: widget.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    res.url,
                                    style: TextStyle(
                                      color: widget.purple,
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                      decorationColor: widget.purple,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 16),
                            color: widget.textSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: res.url,
                            onPressed: () => _launchSafeUrl(res.url),
                          ),
                          if (!widget.isReadOnly) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              color: widget.textSecondary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: l10n.editResource,
                              onPressed: () =>
                                  _showResourceDialog(existingResource: res),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16),
                              color: Theme.of(context).colorScheme.error,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: l10n.delete,
                              onPressed: () => _deleteResource(res.id),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisplayModeToggle extends StatelessWidget {
  const _DisplayModeToggle({
    required this.displayMode,
    required this.onChanged,
    required this.purple,
    required this.isDark,
    required this.textSecondary,
  });

  final TaskDisplayMode displayMode;
  final ValueChanged<TaskDisplayMode> onChanged;
  final Color purple;
  final bool isDark;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1928) : const Color(0xFFEDEBF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleItem(
            icon: Icons.format_list_bulleted_rounded,
            label: l10n.taskViewList,
            isSelected: displayMode == TaskDisplayMode.list,
            onTap: () => onChanged(TaskDisplayMode.list),
            purple: purple,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          _ToggleItem(
            icon: Icons.view_kanban_outlined,
            label: l10n.taskViewBoard,
            isSelected: displayMode == TaskDisplayMode.board,
            onTap: () => onChanged(TaskDisplayMode.board),
            purple: purple,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.purple,
    required this.textSecondary,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color purple;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C2842) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? purple : textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? purple : textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
