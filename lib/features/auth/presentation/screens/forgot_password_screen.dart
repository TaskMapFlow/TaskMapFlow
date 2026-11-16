import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/abstract_spheres_header.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/auth_form_components.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
    });

    final email = _emailController.text;
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: email);

    if (mounted) {
      if (result case Err(:final failure)) {
        setState(() {
          _errorMessage = mapAuthFailureToMessage(context, failure);
        });
      } else {
        setState(() {
          _submitted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AbstractSpheresHeader(
                showBackButton: true,
                onBack: () => context.pop(),
                height: 210,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _submitted
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 24),
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppColors.darkPrimaryPurple
                                          : AppColors.lightPrimaryPurple)
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 40,
                                  color: isDark
                                      ? AppColors.darkPrimaryPurple
                                      : AppColors.lightPrimaryPurple,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                l10n.resetLinkSent,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 32),
                              AuthPrimaryButton(
                                text: l10n.signIn,
                                onPressed: () => context.pop(),
                              ),
                            ],
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  l10n.forgotPasswordTitle,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.6,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.forgotPasswordDescription,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onErrorContainer,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                AuthInputField(
                                  fieldKey:
                                      const Key('forgotPasswordEmailField'),
                                  controller: _emailController,
                                  label: l10n.email,
                                  hintText: l10n.emailPlaceholder,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submitReset(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.emailRequired;
                                    }
                                    final emailRegex = RegExp(
                                        r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return l10n.invalidEmail;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                AuthPrimaryButton(
                                  buttonKey:
                                      const Key('forgotPasswordSubmitButton'),
                                  text: l10n.sendResetLink,
                                  isLoading: isLoading,
                                  onPressed: _submitReset,
                                ),
                              ],
                            ),
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
