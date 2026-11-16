import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';

/// Screen displayed while initial authentication session check is underway.
class AuthLoadingScreen extends ConsumerWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(authStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purpleAccent =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status is AuthError) ...[
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  status.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(authStateStreamProvider),
                  child: Text(l10n.retry),
                ),
              ] else ...[
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: purpleAccent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.sessionLoading,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
