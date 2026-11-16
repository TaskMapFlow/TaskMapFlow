import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/sprint_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/sprint_form_sheet.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/screens/create_workspace_sheet.dart';

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

  Future<void> _confirmDelete(String mapNodeId) async {
    final l10n = context.l10n;
    final uid = ref.read(currentUserIdProvider) ?? '';

    // Check if tasks exist in workspace
    final hasTasksResult = await ref.read(taskRepositoryProvider).hasTasks(
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
    if (hasTasks) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteConfirmTitle),
          content: Text(l10n.deleteAreaHasTasksError),
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

                // Tasks / Backlog / Sprints Work Section
                _WorkSection(
                  workspace: workspace,
                  accentColor: accentColor,
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  purple: purple,
                  inputBg: inputBg,
                ),
                const SizedBox(height: 20),

                // Edit Mode Actions or Delete Action
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isLesson = workspace.type == WorkspaceType.lesson;
    final addActionLabel = isLesson ? l10n.addStep : l10n.addTask;

    final tasksAsync = ref.watch(tasksStreamProvider(workspace.id));
    final stats = ref.watch(taskStatsProvider(workspace.id));
    final activeFilter = ref.watch(taskFilterProvider(workspace.id));

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
            FilledButton.icon(
              key: const Key('addTaskButton'),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                addActionLabel,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

          // Filters
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
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Task Items List
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
            final filtered = tasks.where(activeFilter.matches).toList();

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
                return TaskItemCard(
                  key: ValueKey(task.id),
                  task: task,
                  onTap: () => TaskFormSheet.show(
                    context: context,
                    workspaceId: workspace.id,
                    workspaceType: workspace.type,
                    initialTask: task,
                  ),
                  onToggleStatus: (newStatus) {
                    ref.read(taskControllerProvider.notifier).updateTaskStatus(
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
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                l10n.addTask,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

            return Column(
              children: backlogTasks.map((task) {
                return Stack(
                  children: [
                    TaskItemCard(
                      key: ValueKey(task.id),
                      task: task,
                      onTap: () => TaskFormSheet.show(
                        context: context,
                        workspaceId: workspace.id,
                        workspaceType: workspace.type,
                        initialTask: task,
                      ),
                      onToggleStatus: (newStatus) {
                        ref
                            .read(taskControllerProvider.notifier)
                            .updateTaskStatus(
                              workspaceId: workspace.id,
                              taskId: task.id,
                              status: newStatus,
                            );
                      },
                    ),
                    if (sprints.isNotEmpty)
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
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                l10n.createSprint,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                      // Action buttons: Start / Complete, Edit, Delete
                      Row(
                        children: [
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _handleCompleteSprint(
                                  context, ref, sprint, sprintTasks),
                            ),
                          const Spacer(),
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
