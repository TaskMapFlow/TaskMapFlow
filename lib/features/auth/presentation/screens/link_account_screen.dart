import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/abstract_spheres_header.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/auth_form_components.dart';

class LinkAccountScreen extends ConsumerStatefulWidget {
  const LinkAccountScreen({super.key});

  @override
  ConsumerState<LinkAccountScreen> createState() => _LinkAccountScreenState();
}

class _LinkAccountScreenState extends ConsumerState<LinkAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isConflict = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _isConflict = false;
    });

    final result = await ref
        .read(authControllerProvider.notifier)
        .linkGuestWithEmailAndPassword(
          name: _firstNameController.text.trim(),
          surname: _lastNameController.text.trim(),
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (mounted) {
      if (result case Err(:final failure)) {
        setState(() {
          _errorMessage = mapAuthFailureToMessage(context, failure);
          _isConflict = failure is EmailAlreadyInUseFailure ||
              failure is CredentialAlreadyInUseFailure;
        });
      }
    }
  }

  Future<void> _switchToExistingAccount() async {
    await ref.read(authControllerProvider.notifier).signOut();
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            l10n.linkAccountTitle,
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
                            l10n.linkAccountDescription,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
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
                                  if (_isConflict) ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed: isLoading
                                          ? null
                                          : _switchToExistingAccount,
                                      child: Text(l10n.signIn),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AuthInputField(
                                  fieldKey: const Key('linkFirstNameField'),
                                  controller: _firstNameController,
                                  label: l10n.firstName,
                                  hintText: l10n.firstNamePlaceholder,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.firstNameRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: AuthInputField(
                                  fieldKey: const Key('linkLastNameField'),
                                  controller: _lastNameController,
                                  label: l10n.lastName,
                                  hintText: l10n.lastNamePlaceholder,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.lastNameRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AuthInputField(
                            fieldKey: const Key('linkEmailField'),
                            controller: _emailController,
                            label: l10n.email,
                            hintText: l10n.emailPlaceholder,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.emailRequired;
                              }
                              final emailRegex =
                                  RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return l10n.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthInputField(
                            fieldKey: const Key('linkPasswordField'),
                            controller: _passwordController,
                            label: l10n.password,
                            hintText: l10n.passwordPlaceholder,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.passwordRequired;
                              }
                              if (value.length < 6) {
                                return l10n.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthInputField(
                            fieldKey: const Key('linkConfirmPasswordField'),
                            controller: _confirmPasswordController,
                            label: l10n.confirmPassword,
                            hintText: l10n.confirmPasswordPlaceholder,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitLink(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.passwordRequired;
                              }
                              if (value != _passwordController.text) {
                                return l10n.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          AuthPrimaryButton(
                            buttonKey: const Key('linkAccountSubmitButton'),
                            text: l10n.linkAccount,
                            isLoading: isLoading,
                            onPressed: _submitLink,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: isLoading ? null : () => context.pop(),
                              child: Text(
                                l10n.cancel,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
