# Architecture – TaskMapFlow

## Overview

TaskMapFlow uses feature-based modular Clean Architecture within a single Flutter application.

```
┌──────────────────────────────────────────────────┐
│                  Presentation                     │
│  (Widgets, Riverpod providers, go_router screens) │
│                                                   │
│          imports domain interfaces only           │
└───────────────────┬──────────────────────────────┘
                    │ depends on
                    ▼
┌──────────────────────────────────────────────────┐
│                    Domain                         │
│  (Entities, Value Objects, Repository interfaces, │
│   Use cases only where complexity warrants them)  │
│                                                   │
│   Pure Dart. NO Flutter, Firebase, or Riverpod.  │
└───────────────────▲──────────────────────────────┘
                    │ implements
┌──────────────────────────────────────────────────┐
│                     Data                          │
│  (Firebase adapters, DTOs, Repository impls,      │
│   Firestore/Storage calls)                        │
└──────────────────────────────────────────────────┘
                    │ all layers use
┌──────────────────────────────────────────────────┐
│                    core/                          │
│  (AppException, Failure, Result<T>, constants,    │
│   extensions — no feature-specific logic)         │
└──────────────────────────────────────────────────┘
```

## Dependency Rules

1. **Domain** imports nothing outside Dart's core libraries and `core/`.
2. **Data** imports domain interfaces and `core/`. Never imports `presentation/`.
3. **Presentation** imports domain interfaces and `core/`. Never imports `data/` directly.
4. **Composition root** (`main.dart` + `ProviderScope`) wires data implementations to domain interfaces via Riverpod providers.
5. Feature modules do NOT import each other's internal implementation. Shared contracts live in `core/` or the feature's own `domain/`.

## Directory Structure

```
lib/
  main.dart               # Composition root, Firebase init guard
  app/
    app.dart              # Root MaterialApp widget
    router.dart           # go_router with StatefulShellRoute
    theme.dart            # AppTheme (light + dark, Material 3)
  core/
    constants/
      app_constants.dart
    errors/
      app_exception.dart  # Sealed AppException hierarchy
      failure.dart        # Sealed Failure value objects
    extensions/
      context_extensions.dart
    result/
      result.dart         # Result<T> = Success<T> | Err<T>
  features/
    home/
      presentation/       # HomeScreen, future map providers
      domain/             # Map node/edge domain types (future)
      data/               # Firestore adapters (future)
    manage/
      presentation/       # ManageScreen, sprint/backlog UI (future)
      domain/             # Workspace, sprint, task domain (future)
      data/               # Firestore adapters (future)
    profile/
      presentation/       # ProfileScreen, archive UI (future)
      domain/             # Profile domain types (future)
      data/               # Firestore adapters (future)
  l10n/
    app_en.arb            # English strings
    app_tr.arb            # Turkish strings
```

## Future Feature Modules (not in Phase 1)
- `features/auth/` – login, registration, Apple/Google sign-in
- `features/workspace/` – workspace CRUD, member management
- `features/task/` – task CRUD, subtasks, sprint assignment
- `features/map/` – canvas, node/edge editing mode
- `features/notes/` – quick notes, @mentions
- `features/notifications/` – notification centre

## State Management
- **flutter_riverpod 2.x** with **riverpod_generator** for code generation.
- Providers defined in `presentation/` layer or `app/`.
- Domain layer has no Riverpod dependency.
- No global mutable state outside of Riverpod providers.

## Navigation
- **go_router** with `StatefulShellRoute.indexedStack` for the 3-tab shell.
- Route definitions in `lib/app/router.dart`.
- Deep linking will be added with the auth feature.

## Error Handling
- Repository methods return `Result<T>` (`Success<T>` or `Err<Failure>`).
- Firebase exception types are caught in `data/` layer and mapped to `Failure` subtypes.
- `Failure` subtypes never expose Firebase error codes or stack traces.
- Presentation maps `Failure` to localised user-facing messages.

## Localisation
- **Flutter gen-l10n** with ARB files (`lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb`).
- `generate: true` in `pubspec.yaml` enables automatic ARB-to-Dart code generation.
- All user-facing strings use `AppLocalizations`; no hardcoded strings in widgets.

## Themes
- Material 3 with `ColorScheme.fromSeed`.
- `AppTheme.light` and `AppTheme.dark` defined in `lib/app/theme.dart`.
- `ThemeMode.system` by default.

## Code Generation
- **build_runner** orchestrates: `freezed` (domain models), `json_serializable` (DTOs), `riverpod_generator` (providers).
- Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis and committed to source control.

## Architecture Boundaries (Enforced)
- Widgets and controllers must NOT call Firestore or Storage directly.
- Map position/size data is separated from task and lesson business rules (separate domain types).
- Task infrastructure is shared; lesson and project features do not couple to each other.
- Each feature uses only its own domain interfaces and `core/`; no cross-feature internal imports.

## Composition Root
`main.dart` initialises Firebase (with failure guard), wraps the app in `ProviderScope`, and passes `firebaseReady` to `TaskMapFlowApp`. Riverpod providers override data implementations in this root; test code can override providers for unit tests without touching widgets.
