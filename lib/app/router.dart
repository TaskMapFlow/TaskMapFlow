import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/auth/presentation/screens/auth_loading_screen.dart';
import 'package:task_map_flow/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:task_map_flow/features/auth/presentation/screens/link_account_screen.dart';
import 'package:task_map_flow/features/auth/presentation/screens/login_screen.dart';
import 'package:task_map_flow/features/auth/presentation/screens/register_screen.dart';
import 'package:task_map_flow/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:task_map_flow/features/home/presentation/home_screen.dart';
import 'package:task_map_flow/features/manage/presentation/manage_screen.dart';
import 'package:task_map_flow/features/profile/presentation/profile_screen.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthStatus>(authStatusProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
  AuthStatus get status => _ref.read(authStatusProvider);
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/link-account',
        builder: (context, state) => const LinkAccountScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/manage',
                builder: (context, state) => const ManageScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final status = notifier.status;
      final location = state.uri.path;

      // While checking session initially or on error
      if (status is AuthInitial || status is AuthError) {
        return location == '/splash' ? null : '/splash';
      }

      // No user session
      if (status is AuthUnauthenticated) {
        final isAuthRoute = location == '/login' ||
            location == '/register' ||
            location == '/forgot-password';
        return isAuthRoute ? null : '/login';
      }

      // Permanent account but email not yet verified
      if (status is AuthUnverified) {
        return location == '/verify-email' ? null : '/verify-email';
      }

      // Anonymous guest user
      if (status is AuthGuest) {
        final isAllowed = location == '/home' ||
            location == '/manage' ||
            location == '/profile' ||
            location == '/link-account';
        return isAllowed ? null : '/home';
      }

      // Permanent account with verified email
      if (status is AuthAuthenticated) {
        final isAllowed = location == '/home' ||
            location == '/manage' ||
            location == '/profile';
        return isAllowed ? null : '/home';
      }

      return null;
    },
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profileTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.manageTab,
          ),
        ],
      ),
    );
  }
}
