import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    setState(() {
      _cooldownSeconds = seconds;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _cooldownSeconds = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cooldownSeconds--;
          });
        }
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0) return;
    setState(() {
      _errorMessage = null;
    });

    final result =
        await ref.read(authControllerProvider.notifier).sendEmailVerification();

    if (mounted) {
      if (result case Err(:final failure)) {
        setState(() {
          _errorMessage = mapAuthFailureToMessage(context, failure);
        });
      } else {
        _startCooldown(60);
      }
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _errorMessage = null;
    });

    final result = await ref.read(authControllerProvider.notifier).reloadUser();
    if (mounted) {
      if (result case Err(:final failure)) {
        setState(() {
          _errorMessage = mapAuthFailureToMessage(context, failure);
        });
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(authStatusProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    final email = switch (status) {
      AuthUnverified(:final user) => user.email ?? '',
      _ => '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyEmailTitle),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: isLoading ? null : _signOut,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.verifyEmailTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.verifyEmailBody(email),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  key: const Key('checkVerificationStatusButton'),
                  onPressed: isLoading ? null : _refreshStatus,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.checkVerificationStatus),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('resendVerificationButton'),
                  onPressed:
                      (isLoading || _cooldownSeconds > 0) ? null : _resendEmail,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    _cooldownSeconds > 0
                        ? l10n.resendCooldown(_cooldownSeconds)
                        : l10n.resendVerificationEmail,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  key: const Key('verifyEmailSignOutButton'),
                  onPressed: isLoading ? null : _signOut,
                  child: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
