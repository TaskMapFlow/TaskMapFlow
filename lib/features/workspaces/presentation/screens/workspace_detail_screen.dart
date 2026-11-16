import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_item_card.dart';
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
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(l10n.authErrorUnknown),
          content: Text(l10n.deleteAreaTaskCheckFailed),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (hasTasksResult case Success(:final value) when value == true) {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(l10n.deleteConfirmTitle),
          content: Text(l10n.deleteAreaHasTasksError),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result =
          await ref.read(workspaceControllerProvider.notifier).deleteWorkspace(
                workspaceId: widget.workspaceId,
                mapNodeId: mapNodeId,
              );

      if (!mounted) return;
      if (result case Success()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspacesAsync = ref.watch(workspacesStreamProvider);
    final nodesAsync = ref.watch(mapNodesStreamProvider);

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? const Color(0xFF161521) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262438) : const Color(0xFFE2E0EE);
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.areaDetailTitle,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editArea,
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: workspacesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (workspaces) {
          final workspace =
              workspaces.where((w) => w.id == widget.workspaceId).firstOrNull;

          if (workspace == null) {
            return Center(
              child: Text(
                'Alan bulunamadı.',
                style: TextStyle(color: textSecondary),
              ),
            );
          }

          _populateFields(workspace);

          final node = nodesAsync.valueOrNull
              ?.where((n) => n.workspaceId == workspace.id)
              .firstOrNull;
          final accentColor =
              _parseHex(_isEditing ? _selectedColor : workspace.color);

          final typeName = switch (workspace.type) {
            WorkspaceType.project => l10n.typeProject,
            WorkspaceType.lesson => l10n.typeLesson,
            WorkspaceType.freeform => l10n.typeFreeform,
          };

          final typeIcon = switch (workspace.type) {
            WorkspaceType.project => Icons.rocket_launch_outlined,
            WorkspaceType.lesson => Icons.school_outlined,
            WorkspaceType.freeform => Icons.bubble_chart_outlined,
          };

          final formattedDate =
              DateFormat.yMMMMd(Localizations.localeOf(context).languageCode)
                  .format(workspace.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card with Color Accent
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcon, size: 16, color: accentColor),
                                const SizedBox(width: 6),
                                Text(
                                  typeName,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                          style: TextStyle(color: textPrimary, fontSize: 18),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputBg,
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.areaColorLabel,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: kWorkspacePalette.map((hex) {
                            final c = _parseHex(hex);
                            final isSelected = _selectedColor == hex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = hex),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 20, color: Colors.white)
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
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.areaDescriptionLabel,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isEditing)
                        TextField(
                          controller: _descController,
                          maxLines: 4,
                          maxLength: 500,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputBg,
                            counterText: '',
                            hintText: l10n.areaDescriptionPlaceholder,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Metadata Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        '${l10n.createdAtLabel}: ',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Tasks Section
                _TasksSection(
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
                const SizedBox(height: 32),

                // Edit Mode Actions or Delete Action
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _populateFields(workspace);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _saveChanges,
                          style: FilledButton.styleFrom(
                            backgroundColor: purple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    key: const Key('deleteWorkspaceButton'),
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error),
                    label: Text(
                      l10n.deleteArea,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _confirmDelete(node?.id ?? ''),
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

class _TasksSection extends ConsumerWidget {
  const _TasksSection({
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
    final sectionTitle = isLesson ? l10n.studyStepsTitle : l10n.tasksTitle;
    final addActionLabel = isLesson ? l10n.addStep : l10n.addTask;

    final tasksAsync = ref.watch(tasksStreamProvider(workspace.id));
    final stats = ref.watch(taskStatsProvider(workspace.id));
    final activeFilter = ref.watch(taskFilterProvider(workspace.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header: Title & "Görev / Adım Ekle" Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

        // Progress Bar & Stats (calculated from real data)
        if (stats.total > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.total > 0 ? stats.completed / stats.total : 0,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF262335)
                        : const Color(0xFFE8E6F2),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips
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
          const SizedBox(height: 14),
        ],

        // Task Items List
        tasksAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: purple),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(tasksStreamProvider(workspace.id)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
          data: (tasks) {
            final filtered = tasks.where(activeFilter.matches).toList();

            if (tasks.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLesson
                            ? Icons.fact_check_outlined
                            : Icons.checklist_rounded,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isLesson ? l10n.noStepsYet : l10n.noTasksYet,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLesson ? l10n.noStepsSubtitle : l10n.noTasksSubtitle,
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

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? purple
              : (isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF1F0F7)),
          borderRadius: BorderRadius.circular(16),
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
