import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(authStatusProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    final isGuest = status is AuthGuest;
    final user = switch (status) {
      AuthAuthenticated(:final user) => user,
      AuthGuest(:final user) => user,
      AuthUnverified(:final user) => user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTab),
        actions: [
          IconButton(
            key: const Key('profileSignOutIconButton'),
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: isLoading ? null : () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    isGuest ? Icons.person_outline : Icons.person,
                    size: 44,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                if (user?.displayName != null &&
                    user!.displayName!.isNotEmpty) ...[
                  Text(
                    user.displayName!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (user?.email != null) ...[
                  Text(
                    user!.email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (isGuest) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.guestAccountBadge,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.guestAccountNotice,
                          style: Theme.of(context).textTheme.bodySmall,
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
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.profileScreenPlaceholder,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  key: const Key('profileSignOutButton'),
                  onPressed:
                      isLoading ? null : () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
