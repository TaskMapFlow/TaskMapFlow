import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/abstract_spheres_header.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/auth_form_components.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final purpleAccent =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    final email = switch (status) {
      AuthUnverified(:final user) => user.email ?? '',
      _ => '',
    };

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AbstractSpheresHeader(
                height: 210,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: purpleAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mark_email_unread_outlined,
                              size: 36,
                              color: purpleAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.verifyEmailTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.verifyEmailBody(email),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        AuthPrimaryButton(
                          buttonKey: const Key('checkVerificationStatusButton'),
                          text: l10n.checkVerificationStatus,
                          isLoading: isLoading,
                          onPressed: _refreshStatus,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            key: const Key('resendVerificationButton'),
                            onPressed: (isLoading || _cooldownSeconds > 0)
                                ? null
                                : _resendEmail,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkInputBorder
                                    : AppColors.lightInputBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: textSecondary,
                            ),
                            child: Text(
                              _cooldownSeconds > 0
                                  ? l10n.resendCooldown(_cooldownSeconds)
                                  : l10n.resendVerificationEmail,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            key: const Key('verifyEmailSignOutButton'),
                            onPressed: isLoading ? null : _signOut,
                            style: TextButton.styleFrom(
                              foregroundColor: textSecondary,
                            ),
                            child: Text(
                              l10n.signOut,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
