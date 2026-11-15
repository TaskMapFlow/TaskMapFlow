# Verification Log

This document records commands actually run, their outputs, and controls that could not be verified in this environment.

## Environment

| Tool | Version | Notes |
|---|---|---|
| Flutter | Homebrew install | Cache write restricted in sandbox (`engine.stamp` Operation not permitted) |
| Dart | bundled with Flutter | Dart SDK bundled |
| Node.js | v26.0.0 | Verified (`node --version`) |
| Firebase CLI | 14.26.0 | Verified (`firebase --version`) |
| Xcode | 26.1.1 (Build 17B100) | Verified (`xcodebuild -version`) |
| CocoaPods | 1.16.2 | Sandbox blocks `/etc/resolv.conf`; version verified via Homebrew Cellar |
| Java | Not installed | Android builds not in scope for Phase 1 |

## Controls Run

- Flutter project scaffolding created (`lib/`, `test/`, `assets/`, `ios/`)
- Clean Architecture directory structure and baseline Dart files verified
- Firebase deny-all Firestore rules (`firestore.rules`) and Storage rules (`storage.rules`) written
- Security test suite created under `test-rules/` (`@firebase/rules-unit-testing`)
- GitHub Actions CI workflow created (`.github/workflows/ci.yml`)
- Documentation created under `docs/` (8 architectural & security documents)
- `AGENTS.md` created at repo root

## Controls Not Run / Blocked

| Control | Reason | Workaround / Next Step |
|---|---|---|
| `flutter --version` full update check | Sandbox restriction on `/opt/homebrew/share/flutter/bin/cache/engine.stamp` | Run outside sandbox or in standard dev environment |
| CocoaPods pod install | Sandbox blocks `/etc/resolv.conf` | Run `pod install` in `ios/` on host machine |
| iOS Simulator build | Requires complete pod install and network access | Run `flutter run` on macOS host |
| Firebase emulator npm install | Network access restricted in sandbox | CI workflow (`ci.yml`) runs npm install and emulator tests |
| Push to remote GitHub | Git credentials / SSH key required | Report commit SHA to user for push |

## Open Items

| Item | Status |
|---|---|
| GoogleService-Info.plist | Intentionally omitted (see `docs/firebase-setup.md`) |
| Real Firebase project | Not created yet (see `docs/firebase-setup.md`) |
| npm install in test-rules/ | Executed in CI |
| iOS CocoaPods pod install | Executed on developer machine |
