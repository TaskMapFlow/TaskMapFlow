import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/screens/create_workspace_sheet.dart';
import 'package:task_map_flow/features/workspaces/presentation/widgets/workspace_card.dart';

class ManageScreen extends ConsumerStatefulWidget {
  const ManageScreen({super.key});

  @override
  ConsumerState<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends ConsumerState<ManageScreen> {
  WorkspaceType? _filterType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspacesAsync = ref.watch(workspacesStreamProvider);

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.manageTab,
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('manageAddAreaButton'),
            icon: Icon(Icons.add_rounded, color: purple),
            tooltip: l10n.createAreaButton,
            onPressed: () {
              CreateWorkspaceSheet.show(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: workspacesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: purple),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(workspacesStreamProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (workspaces) {
          if (workspaces.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
                        Icons.dashboard_outlined,
                        size: 36,
                        color: purple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.noWorkspacesYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noWorkspacesSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        height: 1.4,
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
                      onPressed: () => CreateWorkspaceSheet.show(context),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredWorkspaces = _filterType == null
              ? workspaces
              : workspaces.where((w) => w.type == _filterType).toList();

          return Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.allFilter,
                      isSelected: _filterType == null,
                      onTap: () => setState(() => _filterType = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.typeProject,
                      isSelected: _filterType == WorkspaceType.project,
                      onTap: () =>
                          setState(() => _filterType = WorkspaceType.project),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.typeLesson,
                      isSelected: _filterType == WorkspaceType.lesson,
                      onTap: () =>
                          setState(() => _filterType = WorkspaceType.lesson),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.typeFreeform,
                      isSelected: _filterType == WorkspaceType.freeform,
                      onTap: () =>
                          setState(() => _filterType = WorkspaceType.freeform),
                    ),
                  ],
                ),
              ),

              // Workspaces List
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredWorkspaces.length,
                  itemBuilder: (context, index) {
                    final ws = filteredWorkspaces[index];
                    return WorkspaceCard(
                      key: ValueKey(ws.id),
                      workspace: ws,
                      onTap: () {
                        context.push('/workspace/${ws.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? purple.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF191724) : const Color(0xFFEDEDF5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? purple
                : (isDark ? const Color(0xFF2C293C) : const Color(0xFFDFDDE8)),
          ),
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
