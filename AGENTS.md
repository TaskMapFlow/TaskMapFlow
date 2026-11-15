# AGENTS.md – TaskMapFlow Project Rules

This file defines architectural and security rules for AI coding agents working
on this repository. These rules apply to ALL modifications in this codebase.

> **Note on automatic loading**: This file follows the AGENTS.md convention.
> Verify that your agent loads it automatically; do not assume it does
> without confirmation from your agent's documentation.

## Architecture Rules

### Clean Architecture Layers

- `lib/features/*/domain/`: pure Dart only. No Flutter widgets, no Firebase
  imports, no Riverpod imports.
- `lib/features/*/presentation/`: widgets and Riverpod providers only.
  No direct Firestore or Storage calls.
- `lib/features/*/data/`: Firebase adapters, DTOs, repository implementations.
  Implements domain interfaces.
- `lib/app/` and `lib/main.dart`: composition root. Wires dependencies.
- `lib/core/`: shared utilities (errors, result types, constants, extensions).
  No feature-specific logic.

### Dependency Direction

```
presentation → domain ← data
         ↑
       core/
```

Never import `data` from `presentation` directly.
Never import `presentation` from `data`.
Never import Firebase types in `domain`.

### Module Isolation

- Feature modules must not import each other's internal implementation.
- Shared contracts live in `core/` or the feature's own `domain/`.
- Map position/size data (`positionX`, `positionY`, `width`, `height`) lives in
  `map_nodes`, separated from task and lesson business rules.
- Task infrastructure is shared; lesson and project features do not couple to
  each other.

### State Management

- Use Riverpod (`flutter_riverpod 2.x`).
- No global mutable state outside of Riverpod providers.
- Providers are defined in `presentation/` or `app/`; domain has no providers.

### Navigation

- Use `go_router` with `StatefulShellRoute` for the 3-tab shell.
- Tab order: Profile (left) / Home (center, default) / Manage (right).
- Route definitions live in `lib/app/router.dart`.

### Error Handling

- Repository methods return `Result<T>` (`Success<T>` or `Err<Failure>`).
- Firebase exception types must NOT appear outside the `data/` layer.
- Presentation maps `Failure` subtypes to localised user messages.
- Never display raw Firebase error codes or stack traces to the user.

### Localisation

- All user-facing strings use Flutter gen-l10n ARB files (`l10n.yaml` configured).
- ARB files: `lib/l10n/app_en.arb` (English), `lib/l10n/app_tr.arb` (Turkish).
- Generated classes live in `lib/l10n/app_localizations.dart`.
- No hardcoded user-facing strings in widget files.

### Code Quality

- Run `dart format` and `flutter analyze --fatal-infos` before every commit.
- Use explicit package imports (`package:task_map_flow/...`) in `lib/`.
- No empty classes or placeholder files that make the project appear complete.
- No fake data, success rates, or placeholder statistics visible in production
  builds.
- Do not create unnecessary use cases or abstractions for simple operations.

## Security Rules

### Credentials & Secrets

- NEVER commit `GoogleService-Info.plist`, `google-services.json`, signing
  certificates (`.p12`, `.p8`, `.jks`), APNs keys, or any server secret to this repo.
- Firebase client config (`GoogleService-Info.plist`, `google-services.json`) is
  client configuration containing public project identifiers, NOT a server secret.
  However, it is excluded from git (`.gitignore`) to keep environments decoupled.
  Real access control is enforced by Firestore/Storage Security Rules and
  Firebase App Check — not by keeping client identifiers secret.
- Server secrets (Admin SDK service account keys) must NEVER appear in this repo.

### Firebase Configuration

- Do not create fake API keys in source.
- Firebase project was created by the user; pending step is confirming project ID
  and adding the iOS app configuration.
- If Firebase is not configured or initialization fails, the app safely displays
  a localized setup-required screen (`_SetupRequiredScreen`).
- Never silently fall back to a fake backend.

### Firestore & Storage Rules

- Default posture: deny all (`allow read, write: if false;`).
- Rules are expanded incrementally with each feature.
- Every rule relaxation must be accompanied by targeted tests in `test-rules/`.
- Firebase Storage rules CAN access Firestore via `firestore.get()` and `firestore.exists()`.
- Queries must be aligned with the security model; rules are NOT query filters.
- Performance notes (`users/{uid}/performance_notes/`) are strictly owner-only.
- Private tasks (`isPrivate: true`) are readable only by the creator.
- Owning a workspace does NOT grant access to other users' personal data.

### Production Data

- No fake users, tasks, or success statistics in production builds.
- Test data is isolated to the Firebase Emulator environment.
- Emulator tests use `--project demo-taskmapflow` (a local dummy project ID).

### App Check

- App Check is planned for Phase 3. It attests app integrity; it does NOT
  replace authentication or Firestore Security Rules.

## Development Workflow

### Before Each Commit

1. `dart format lib/ test/`
2. `flutter analyze --fatal-infos`
3. `flutter test`
4. If Firestore/Storage rules changed: run rules tests against emulator

### CI

- GitHub Actions runs format, analyze, Flutter tests, and rules tests on every
  push and pull request to `main`.
- CI uses pinned Flutter version (`3.38.1`), pinned Firebase CLI (`14.26.0`),
  Temurin JDK 21 for the emulator, and `npm ci` for dependencies.
- CI does not use real Firebase credentials. Emulator-only (`demo-taskmapflow`).

### Branching

- Use feature branches; pull requests to `main`.
- No force pushes to `main`.
- No rewriting of published history.

## Phase Boundaries

### Phase 1 (current)

- Flutter project skeleton with Clean Architecture structure
- 3-tab app shell (Profile, Home, Manage) with Home selected by default
- Firestore + Storage deny-all security rules (baseline)
- Firebase Emulator security rules tests (Firestore & Storage, unauthed, anon, authed)
- Architecture and security documentation (`docs/`)
- GitHub Actions CI with lockfiles and pinned tools

### Not in Phase 1

- Login flows, authentication UI
- Task CRUD operations
- Map canvas and node/edge interactions
- Animations and visual design (space/planet login)
- Real Firebase project deployment
- App Store submission
- Cloud Functions (requires Blaze plan)

## Open Decisions & Technical Debt

- Real Firebase project ID to be confirmed and iOS app added
- Bundle ID finalisation (candidate: `com.taskmapflow.app`)
- Exact lesson/course feature set (not confirmed)
- Moderation workflow for public content (not designed)
- Blaze plan upgrade timeline
- Shared workspace ownership transfer on account deletion
