import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/home/presentation/providers/home_view_providers.dart';
import 'package:task_map_flow/features/home/presentation/widgets/home_overview_view.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/screens/create_workspace_sheet.dart';
import 'package:task_map_flow/features/workspaces/presentation/widgets/map_canvas.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeViewMode = ref.watch(homeViewModeProvider);
    final isEditMode = ref.watch(isEditModeProvider);
    final workspacesAsync = ref.watch(workspacesStreamProvider);
    final nodesAsync = ref.watch(mapNodesStreamProvider);
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;
    final topBarBg = isDark ? const Color(0xFF100F17) : Colors.white;
    final topBarBorder =
        isDark ? const Color(0xFF232133) : const Color(0xFFE6E4F0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with View Mode switcher, settings, language/theme, and action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: topBarBg,
                border: Border(bottom: BorderSide(color: topBarBorder)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // View Mode Toggle (Harita / Genel Bakış)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF191724)
                            : const Color(0xFFEDEDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2B283A)
                              : const Color(0xFFDFDDE8),
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ViewToggleButton(
                            label: l10n.mapView,
                            icon: Icons.map_outlined,
                            isSelected: homeViewMode == HomeViewMode.map,
                            purple: purple,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => ref
                                .read(homeViewModeProvider.notifier)
                                .setViewMode(HomeViewMode.map),
                          ),
                          _ViewToggleButton(
                            label: l10n.overviewView,
                            icon: Icons.view_agenda_outlined,
                            isSelected: homeViewMode == HomeViewMode.overview,
                            purple: purple,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => ref
                                .read(homeViewModeProvider.notifier)
                                .setViewMode(HomeViewMode.overview),
                          ),
                        ],
                      ),
                    ),

                    // Map Edit Mode Toggle (only when Map view is active)
                    if (homeViewMode == HomeViewMode.map) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: isEditMode ? l10n.viewMode : l10n.editMode,
                        child: OutlinedButton.icon(
                          key: const Key('mapEditModeToggle'),
                          icon: Icon(
                            isEditMode
                                ? Icons.check_rounded
                                : Icons.edit_outlined,
                            size: 14,
                          ),
                          label: Text(
                            isEditMode ? l10n.viewMode : l10n.editMode,
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: isEditMode
                                  ? purple
                                  : (isDark
                                      ? const Color(0xFF2C293C)
                                      : const Color(0xFFDCD9EB)),
                            ),
                            backgroundColor: isEditMode
                                ? purple.withValues(alpha: 0.15)
                                : Colors.transparent,
                            foregroundColor:
                                isEditMode ? purple : textSecondary,
                          ),
                          onPressed: () {
                            ref.read(isEditModeProvider.notifier).state =
                                !isEditMode;
                          },
                        ),
                      ),
                    ],

                    const SizedBox(width: 12),

                    // Language / Theme Pill
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF191724)
                            : const Color(0xFFEDEDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2B283A)
                              : const Color(0xFFDFDDE8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TR / EN switcher
                          GestureDetector(
                            onTap: () {
                              final next = currentLocale.languageCode == 'tr'
                                  ? const Locale('en')
                                  : const Locale('tr');
                              ref.read(localeProvider.notifier).setLocale(next);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C293C)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentLocale.languageCode.toUpperCase(),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          // Dark / Light theme toggle
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                currentThemeMode == ThemeMode.dark ||
                                        (currentThemeMode == ThemeMode.system &&
                                            isDark)
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                size: 15,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // "+ Alan Ekle" Primary Button
                    FilledButton.icon(
                      key: const Key('homeAddAreaButton'),
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: Text(
                        l10n.createAreaButton,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openCreateSheet(context, ref),
                    ),
                  ],
                ),
              ),
            ),

            // Content Body: Overview or Map
            Expanded(
              child: homeViewMode == HomeViewMode.overview
                  ? const HomeOverviewView()
                  : () {
                      if (workspacesAsync.hasError || nodesAsync.hasError) {
                        final err = workspacesAsync.error ?? nodesAsync.error;
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.error),
                                const SizedBox(height: 12),
                                Text(
                                  err.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: textSecondary),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    ref.invalidate(workspacesStreamProvider);
                                    ref.invalidate(mapNodesStreamProvider);
                                  },
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (workspacesAsync.isLoading || nodesAsync.isLoading) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: purple),
                              const SizedBox(height: 16),
                              Text(
                                l10n.sessionLoading,
                                style: TextStyle(
                                    color: textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      final allWorkspaces = workspacesAsync.value ?? [];
                      final nodes = nodesAsync.value ?? [];
                      final workspaces =
                          allWorkspaces.where((w) => !w.isArchived).toList();
                      final activeIds = workspaces.map((w) => w.id).toSet();
                      final activeNodes = nodes
                          .where((n) => activeIds.contains(n.workspaceId))
                          .toList();

                      if (workspaces.isEmpty) {
                        return _EmptyMapState(
                          onAddArea: () => _openCreateSheet(context, ref),
                        );
                      }

                      return MapCanvas(
                        workspaces: workspaces,
                        nodes: activeNodes,
                        onOpenDetail: (ws) => _openDetail(context, ws),
                      );
                    }(),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateSheet(BuildContext context, WidgetRef ref) {
    final nodes = ref.read(mapNodesStreamProvider).valueOrNull ?? [];
    double initialX = 1100;
    double initialY = 1100;

    if (nodes.isNotEmpty) {
      final last = nodes.last;
      initialX = (last.positionX + 220) % 2000;
      initialY = last.positionY;
      if (initialX < 200) initialX = 1100;
    }

    CreateWorkspaceSheet.show(
      context,
      initialX: initialX,
      initialY: initialY,
    );
  }

  void _openDetail(BuildContext context, Workspace ws) {
    context.push('/workspace/${ws.id}');
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C293C) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
              size: 13,
              color: isSelected ? purple : textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? textPrimary : textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMapState extends StatelessWidget {
  const _EmptyMapState({required this.onAddArea});
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: purple.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: purple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.createFirstAreaTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.createFirstAreaSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                key: const Key('emptyMapAddAreaButton'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  l10n.createAreaButton,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
