import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';

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
    final currentLocale = ref.watch(localeProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // Language selector
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'tr',
                  label: Text('TR', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 'en',
                  label: Text('EN', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {currentLocale.languageCode},
              onSelectionChanged: (newSelection) {
                final selected = newSelection.first;
                ref.read(localeProvider.notifier).setLocale(Locale(selected));
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.signIn,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('loginEmailField'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
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
                  TextFormField(
                    key: const Key('loginPasswordField'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitSignIn(),
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('forgotPasswordButton'),
                      onPressed: isLoading
                          ? null
                          : () => context.push('/forgot-password'),
                      child: Text(l10n.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('signInSubmitButton'),
                    onPressed: isLoading ? null : _submitSignIn,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.signIn),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('guestSignInButton'),
                    onPressed: isLoading ? null : _continueAsGuest,
                    child: Text(l10n.continueAsGuest),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l10n.noAccountPrompt),
                      TextButton(
                        key: const Key('goToRegisterButton'),
                        onPressed:
                            isLoading ? null : () => context.push('/register'),
                        child: Text(l10n.signUp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
