import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/abstract_spheres_header.dart';
import 'package:task_map_flow/features/auth/presentation/widgets/auth_form_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final email = _emailController.text;
    final password = _passwordController.text;

    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

    if (mounted) {
      if (result case Err(:final failure)) {
        setState(() {
          _errorMessage = mapAuthFailureToMessage(context, failure);
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _errorMessage = null);
    final result =
        await ref.read(authControllerProvider.notifier).signInAnonymously();
    if (mounted) {
      if (result case Err(:final failure)) {
        setState(() {
          _errorMessage = mapAuthFailureToMessage(context, failure);
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
    final purpleAccent =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top abstract 3D spheres header with title and language pill
              AbstractSpheresHeader(
                titleText: l10n.appTitle,
                height: 230,
              ),

              // Form body
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          // Headline
                          Text(
                            l10n.loginHeadline,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            l10n.loginSubtitle,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error banner if any
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

                          // Email field
                          AuthInputField(
                            fieldKey: const Key('loginEmailField'),
                            controller: _emailController,
                            label: l10n.email,
                            hintText: l10n.emailPlaceholder,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
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

                          // Password field
                          AuthInputField(
                            fieldKey: const Key('loginPasswordField'),
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
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitSignIn(),
                            autofillHints: const [AutofillHints.password],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.passwordRequired;
                              }
                              return null;
                            },
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('forgotPasswordButton'),
                              onPressed: isLoading
                                  ? null
                                  : () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                foregroundColor: textSecondary,
                              ),
                              child: Text(
                                l10n.forgotPassword,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sign in button
                          AuthPrimaryButton(
                            buttonKey: const Key('signInSubmitButton'),
                            text: l10n.signIn,
                            isLoading: isLoading,
                            onPressed: _submitSignIn,
                          ),
                          const SizedBox(height: 16),

                          // Continue as guest
                          Center(
                            child: TextButton(
                              key: const Key('guestSignInButton'),
                              onPressed: isLoading ? null : _continueAsGuest,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                foregroundColor: textSecondary,
                              ),
                              child: Text(
                                l10n.continueAsGuest,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Bottom prompt (Don't have an account? Sign up)
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${l10n.noAccountPrompt} ',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  key: const Key('goToRegisterButton'),
                                  onTap: isLoading
                                      ? null
                                      : () => context.push('/register'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      l10n.signUp,
                                      style: TextStyle(
                                        color: purpleAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
