// Root application widget with localization, theme, and routing.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/router.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/l10n/app_localizations.dart';

class TaskMapFlowApp extends ConsumerWidget {
  const TaskMapFlowApp({
    super.key,
    required this.firebaseReady,
    this.locale,
    this.routerConfig,
  });

  final bool firebaseReady;
  final Locale? locale;
  final RouterConfig<Object>? routerConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If locale is explicitly provided (e.g. In tests), use it; otherwise use the persisted locale.
    Locale? effectiveLocale = locale;
    if (effectiveLocale == null) {
      try {
        effectiveLocale = ref.watch(localeProvider);
      } catch (_) {
        // Fallback if sharedPreferencesProvider is not overridden
        effectiveLocale = const Locale('en');
      }
    }

    if (!firebaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        locale: effectiveLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _SetupRequiredScreen(),
      );
    }

    final effectiveRouter = routerConfig ?? ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: effectiveRouter,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: effectiveLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.setupRequired,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.setupRequiredBody,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
