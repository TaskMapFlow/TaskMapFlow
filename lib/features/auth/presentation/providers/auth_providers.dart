import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_user.dart';
import 'package:task_map_flow/features/auth/domain/repositories/auth_repository.dart';

/// Provider for [AuthRepository]. Can be overridden in tests or composition root.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Stream of auth status changes.
final authStateStreamProvider = StreamProvider<AuthStatus>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current authentication status synchronously derived from the stream.
final authStatusProvider = Provider<AuthStatus>((ref) {
  final asyncState = ref.watch(authStateStreamProvider);
  return asyncState.valueOrNull ?? const AuthInitial();
});

/// Provider for SharedPreferences, initialized before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Persisted locale provider (defaults to English or Turkish).
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_loadInitialLocale(_prefs));

  final SharedPreferences _prefs;
  static const _kLocaleKey = 'taskmapflow_preferred_locale';

  static Locale _loadInitialLocale(SharedPreferences prefs) {
    final code = prefs.getString(_kLocaleKey);
    if (code == 'tr' || code == 'en') {
      return Locale(code!);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state.languageCode == newLocale.languageCode) return;
    state = newLocale;
    await _prefs.setString(_kLocaleKey, newLocale.languageCode);
  }
}

/// Persisted theme mode provider (dark / light / system).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_loadInitialTheme(_prefs));

  final SharedPreferences _prefs;
  static const _kThemeKey = 'taskmapflow_preferred_theme';

  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final mode = prefs.getString(_kThemeKey);
    return switch (mode) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.dark, // Default to sleek dark mode
    };
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await _prefs.setString(_kThemeKey, next.name);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeKey, mode.name);
  }
}

/// Controller managing async actions (login, signup, guest, link, etc.) and loading states.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository) : super(const AsyncValue.data(null));

  final AuthRepository _repository;

  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (result is Err<AuthUser>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.signUpWithEmailAndPassword(
      name: name,
      surname: surname,
      email: email,
      password: password,
    );
    if (result is Err<AuthUser>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<Result<AuthUser>> signInAnonymously() async {
    state = const AsyncValue.loading();
    final result = await _repository.signInAnonymously();
    if (result is Err<AuthUser>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    final result = await _repository.sendPasswordResetEmail(email: email);
    if (result is Err<void>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<Result<void>> sendEmailVerification() async {
    state = const AsyncValue.loading();
    final result = await _repository.sendEmailVerification();
    if (result is Err<void>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<Result<AuthUser>> reloadUser() async {
    state = const AsyncValue.loading();
    final result = await _repository.reloadUser();
    if (result is Err<AuthUser>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<Result<AuthUser>> linkGuestWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.linkGuestWithEmailAndPassword(
      name: name,
      surname: surname,
      email: email,
      password: password,
    );
    if (result is Err<AuthUser>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<Result<void>> signOut() async {
    state = const AsyncValue.loading();
    final result = await _repository.signOut();
    if (result is Err<void>) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }
}

/// Helper to map domain Failure to localized user string.
String mapAuthFailureToMessage(BuildContext context, Failure failure) {
  final l10n = context.l10n;
  return switch (failure) {
    InvalidCredentialsFailure() => l10n.authErrorInvalidCredentials,
    EmailAlreadyInUseFailure() => l10n.authErrorEmailInUse,
    WeakPasswordFailure() => l10n.authErrorWeakPassword,
    TooManyRequestsFailure() => l10n.authErrorTooManyRequests,
    CredentialAlreadyInUseFailure() => l10n.linkAccountConflict,
    NetworkFailure() => l10n.authErrorNetwork,
    _ => l10n.authErrorUnknown,
  };
}
