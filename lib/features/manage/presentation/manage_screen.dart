import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:task_map_flow/features/team/presentation/providers/team_providers.dart';
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
  int _selectedSection = 0; // 0: My Areas, 1: Joined, 2: Assigned to Me
  WorkspaceType? _filterType;

  Future<void> _showJoinWithCodeDialog() async {
    final l10n = context.l10n;
    final authState = ref.read(authStatusProvider);

    // Guest users cannot accept invites
    if (authState is AuthGuest) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.joinWithCode),
          content: Text(l10n.guestJoinWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/profile');
              },
              child: Text(l10n.profileTab),
            ),
          ],
        ),
      );
      return;
    }

    final codeController = TextEditingController();
    String? localError;
    bool isSubmitting = false;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.enterInviteCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: l10n.inviteCodePlaceholder,
                  errorText: localError,
                  counterText: '',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) {
                        setDialogState(() => localError = l10n.enterInviteCode);
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        localError = null;
                      });

                      final uid = ref.read(currentUserIdProvider) ?? '';
                      final authStatus = ref.read(authStatusProvider);
                      final displayName = switch (authStatus) {
                        AuthAuthenticated(:final user) => user.displayName ??
                            (user.email != null && user.email!.isNotEmpty
                                ? user.email!.split('@').first
                                : 'Kullanıcı'),
                        AuthGuest(:final user) => user.displayName ?? 'Misafir',
                        AuthUnverified(:final user) => user.displayName ??
                            (user.email != null && user.email!.isNotEmpty
                                ? user.email!.split('@').first
                                : 'Kullanıcı'),
                        _ => 'Ekip Üyesi',
                      };

                      final repo = ref.read(teamRepositoryProvider);
                      final result = await repo.acceptInvite(
                        code: code,
                        userUid: uid,
                        userDisplayName: displayName,
                      );

                      if (!ctx.mounted) return;

                      if (result case Success(:final value)) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.joinSuccess)),
                          );
                          if (value.isNotEmpty) {
                            unawaited(context.push('/workspace/$value'));
                          }
                        }
                      } else if (result case Err(:final failure)) {
                        setDialogState(() {
                          isSubmitting = false;
                          localError = failure.message;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.joinButton),
            ),
          ],
        ),
      ),
    );
  }

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
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF2A2838) : const Color(0xFFE2E0EE);

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
            key: const Key('manageJoinCodeButton'),
            icon: Icon(Icons.group_add_rounded, color: purple),
            tooltip: l10n.joinWithCode,
            onPressed: _showJoinWithCodeDialog,
          ),
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
      body: Column(
        children: [
          // Section Selector: Alanlarım / Katıldığım Alanlar / Bana Atananlar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _SectionTabButton(
                      title: l10n.myWorkspaces,
                      isSelected: _selectedSection == 0,
                      purple: purple,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => setState(() => _selectedSection = 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _SectionTabButton(
                      title: l10n.joinedWorkspaces,
                      isSelected: _selectedSection == 1,
                      purple: purple,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => setState(() => _selectedSection = 1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _SectionTabButton(
                      title: l10n.assignedToMe,
                      isSelected: _selectedSection == 2,
                      purple: purple,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => setState(() => _selectedSection = 2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content body
          Expanded(
            child: switch (_selectedSection) {
              0 => _MyWorkspacesView(
                  filterType: _filterType,
                  onFilterChanged: (t) => setState(() => _filterType = t),
                  onJoinCode: _showJoinWithCodeDialog,
                ),
              1 => _JoinedWorkspacesView(
                  onJoinCode: _showJoinWithCodeDialog,
                ),
              2 => const _AssignedTasksView(),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTabButton extends StatelessWidget {
  const _SectionTabButton({
    required this.title,
    required this.isSelected,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? purple.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: purple.withValues(alpha: 0.4))
              : null,
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? purple : textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyWorkspacesView extends ConsumerStatefulWidget {
  const _MyWorkspacesView({
    required this.filterType,
    required this.onFilterChanged,
    required this.onJoinCode,
  });

  final WorkspaceType? filterType;
  final ValueChanged<WorkspaceType?> onFilterChanged;
  final VoidCallback onJoinCode;

  @override
  ConsumerState<_MyWorkspacesView> createState() => _MyWorkspacesViewState();
}

class _MyWorkspacesViewState extends ConsumerState<_MyWorkspacesView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    return workspacesAsync.when(
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
      data: (allWorkspaces) {
        final workspaces = allWorkspaces.where((w) => !w.isArchived).toList();
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

        final query = _searchQuery.toLowerCase();
        final filteredWorkspaces = workspaces.where((w) {
          if (widget.filterType != null && w.type != widget.filterType) {
            return false;
          }
          if (query.isNotEmpty && !w.name.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n.searchWorkspacesPlaceholder,
                  hintStyle: TextStyle(
                    color: textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          color: textSecondary,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF161522)
                      : const Color(0xFFF3F2F8),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF262335)
                          : const Color(0xFFE2E0EE),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF262335)
                          : const Color(0xFFE2E0EE),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: purple, width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.allFilter,
                    isSelected: widget.filterType == null,
                    onTap: () => widget.onFilterChanged(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.typeProject,
                    isSelected: widget.filterType == WorkspaceType.project,
                    onTap: () => widget.onFilterChanged(WorkspaceType.project),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.typeLesson,
                    isSelected: widget.filterType == WorkspaceType.lesson,
                    onTap: () => widget.onFilterChanged(WorkspaceType.lesson),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.typeFreeform,
                    isSelected: widget.filterType == WorkspaceType.freeform,
                    onTap: () => widget.onFilterChanged(WorkspaceType.freeform),
                  ),
                ],
              ),
            ),

            // Workspaces List or Empty Search
            Expanded(
              child: filteredWorkspaces.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 36, color: textSecondary),
                            const SizedBox(height: 10),
                            Text(
                              l10n.noMatchingWorkspaces,
                              style:
                                  TextStyle(color: textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
    );
  }
}

class _JoinedWorkspacesView extends ConsumerWidget {
  const _JoinedWorkspacesView({required this.onJoinCode});

  final VoidCallback onJoinCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final joinedAsync = ref.watch(joinedWorkspacesStreamProvider);

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return joinedAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: purple),
      ),
      error: (err, _) => Center(
        child: Text(
          err.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (workspaces) {
        final activeWorkspaces =
            workspaces.where((w) => !w.isArchived).toList();

        if (activeWorkspaces.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.groups_outlined,
                      size: 32,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noJoinedWorkspaces,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.group_add_rounded, size: 16),
                    label: Text(l10n.joinWithCode),
                    style: FilledButton.styleFrom(backgroundColor: purple),
                    onPressed: onJoinCode,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: activeWorkspaces.length,
          itemBuilder: (context, index) {
            final ws = activeWorkspaces[index];
            return WorkspaceCard(
              key: ValueKey(ws.id),
              workspace: ws,
              onTap: () {
                context.push('/workspace/${ws.id}');
              },
            );
          },
        );
      },
    );
  }
}

class _AssignedTasksView extends ConsumerWidget {
  const _AssignedTasksView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksAsync = ref.watch(assignedTasksStreamProvider);

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return tasksAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: purple),
      ),
      error: (err, _) => Center(
        child: Text(
          err.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      size: 32,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noAssignedTasks,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskItemCard(
              key: ValueKey(task.id),
              task: task,
              onTap: () {
                context.push('/workspace/${task.workspaceId}');
              },
              onToggleStatus: (newStatus) {
                ref.read(taskControllerProvider.notifier).updateTaskStatus(
                      workspaceId: task.workspaceId,
                      taskId: task.id,
                      status: newStatus,
                    );
              },
            );
          },
        );
      },
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
