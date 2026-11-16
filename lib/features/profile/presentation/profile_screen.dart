import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/profile/presentation/providers/profile_providers.dart';
import 'package:task_map_flow/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmSignOutButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _confirmRestore(
      BuildContext context, WidgetRef ref, Workspace workspace) async {
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

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(workspaceControllerProvider.notifier)
          .restoreWorkspace(workspace.id);
      if (context.mounted) {
        if (result case Success()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.restoreArea)),
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

  Future<void> _openGithubUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri != null && (uri.scheme == 'https')) {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.invalidGithubUrlError)),
        );
      }
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final status = ref.watch(authStatusProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final profileAsync = ref.watch(userProfileStreamProvider);
    final workspacesAsync = ref.watch(workspacesStreamProvider);

    final isGuest = status is AuthGuest;
    final authUser = switch (status) {
      AuthAuthenticated(:final user) => user,
      AuthGuest(:final user) => user,
      AuthUnverified(:final user) => user,
      _ => null,
    };

    final bg = isDark ? const Color(0xFF0F0E17) : const Color(0xFFF9F9FC);
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          l10n.profileTab,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('profileSignOutIconButton'),
            tooltip: l10n.signOut,
            icon: Icon(Icons.logout_rounded, color: textPrimary, size: 22),
            onPressed: isLoading ? null : () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Details Card
                profileAsync.when(
                  loading: () => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(color: purple),
                    ),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          err.toString(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(userProfileStreamProvider),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                  data: (profile) {
                    final effectiveDisplayName =
                        (profile?.displayName.isNotEmpty == true)
                            ? profile!.displayName
                            : (authUser?.displayName ?? '');
                    final initials = profile != null
                        ? profile.initials
                        : (effectiveDisplayName.isNotEmpty
                            ? (effectiveDisplayName.length >= 2
                                ? effectiveDisplayName
                                    .substring(0, 2)
                                    .toUpperCase()
                                : effectiveDisplayName.toUpperCase())
                            : (isGuest ? '?' : 'U'));

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: purple.withValues(alpha: 0.18),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: purple,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      effectiveDisplayName.isNotEmpty
                                          ? effectiveDisplayName
                                          : (isGuest
                                              ? l10n.guestAccountBadge
                                              : '-'),
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (authUser?.email != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        authUser!.email!,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const Key('editProfileButton'),
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: textSecondary,
                                tooltip: l10n.editProfile,
                                onPressed: () => EditProfileSheet.show(
                                  context: context,
                                  currentProfile: profile,
                                  authDisplayName: authUser?.displayName ?? '',
                                ),
                              ),
                            ],
                          ),
                          if (profile?.bio.isNotEmpty == true) ...[
                            const SizedBox(height: 16),
                            Text(
                              profile!.bio,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (profile != null &&
                              profile.githubUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () =>
                                  _openGithubUrl(context, profile.githubUrl),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.code_rounded,
                                        size: 16, color: purple),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        profile.githubUrl,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: purple,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. Guest Account Card (if guest)
                if (isGuest) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.guestAccountBadge,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.guestAccountNotice,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          key: const Key('profileLinkAccountButton'),
                          onPressed: () => context.push('/link-account'),
                          child: Text(l10n.linkAccount),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Settings Card (Language & Theme)
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
                        l10n.settingsTitle,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.language_rounded,
                                  size: 18, color: textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                l10n.languageSetting,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'tr', label: Text('TR')),
                              ButtonSegment(value: 'en', label: Text('EN')),
                            ],
                            selected: {currentLocale.languageCode},
                            onSelectionChanged: (selected) {
                              final lang = selected.first;
                              ref
                                  .read(localeProvider.notifier)
                                  .setLocale(Locale(lang));
                            },
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                size: 18,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.themeSetting,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(l10n.themeDark),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(l10n.themeLight),
                              ),
                            ],
                            selected: {
                              currentThemeMode == ThemeMode.light
                                  ? ThemeMode.light
                                  : ThemeMode.dark
                            },
                            onSelectionChanged: (_) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Archive Section
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
                        children: [
                          Icon(Icons.archive_outlined, size: 18, color: purple),
                          const SizedBox(width: 8),
                          Text(
                            l10n.archivedAreasTitle,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      workspacesAsync.when(
                        loading: () => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: purple),
                          ),
                        ),
                        error: (err, _) => Column(
                          children: [
                            Text(
                              err.toString(),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () =>
                                  ref.invalidate(workspacesStreamProvider),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                        data: (workspaces) {
                          final archived =
                              workspaces.where((w) => w.isArchived).toList();

                          if (archived.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.noArchivedAreasYet,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.noArchivedAreasSubtitle,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: archived.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final ws = archived[index];
                              final accentColor = _parseHex(ws.color);
                              final typeName = switch (ws.type) {
                                WorkspaceType.project => l10n.typeProject,
                                WorkspaceType.lesson => l10n.typeLesson,
                                WorkspaceType.freeform => l10n.typeFreeform,
                              };
                              final archivedDateStr = ws.archivedAt != null
                                  ? DateFormat.yMMMMd(locale)
                                      .format(ws.archivedAt!)
                                  : '-';

                              return InkWell(
                                onTap: () =>
                                    context.push('/workspaces/${ws.id}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ws.name,
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$typeName • ${l10n.archivedAtLabel}: $archivedDateStr',
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(
                                            Icons.unarchive_outlined,
                                            size: 16),
                                        label: Text(
                                          l10n.restoreArea,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: purple,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () =>
                                            _confirmRestore(context, ref, ws),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Sign Out Button
                OutlinedButton.icon(
                  key: const Key('profileSignOutButton'),
                  onPressed:
                      isLoading ? null : () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.signOut),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
