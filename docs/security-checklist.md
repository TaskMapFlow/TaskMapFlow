# Security Checklist – TaskMapFlow

> This checklist references MASVS v2 controls. "Applied" means the control is in place for Phase 1. "Planned" means it will be implemented in a future phase. This checklist does NOT constitute a security audit or MASVS compliance claim.

## MASVS Controls

| MASVS Control | Description | Planned Control | Test Evidence | Status |
|---|---|---|---|---|
| MASVS-STORAGE-1 | No sensitive data in app bundle | No API keys, secrets, or user data in source; GoogleService-Info.plist excluded from git; .gitignore enforced | .gitignore review; CI scan (future) | **Partial – Phase 1** |
| MASVS-STORAGE-2 | Sensitive data not in logs | `debugPrint` removed in release builds; no PII logged | Code review (future) | **Planned** |
| MASVS-STORAGE-3 | No sensitive data in backups | iOS backup exclusion for sensitive files TBD | iOS config review (future) | **Planned** |
| MASVS-AUTH-1 | Appropriate authentication | Firebase Auth: email/password, Google, Apple, Guest | Phase 2 | **Planned** |
| MASVS-AUTH-2 | Session management | Firebase ID token refresh; short-lived tokens (Firebase default) | Phase 2 | **Planned** |
| MASVS-AUTH-3 | Biometric / step-up auth | Optional biometric for private note access | Future phase | **Planned** |
| MASVS-NETWORK-1 | Secure TLS | All Firebase connections use TLS by default | Firebase documentation | **Applied** |
| MASVS-NETWORK-2 | Certificate pinning | Not implemented; Firebase handles TLS | — | **Not planned** |
| MASVS-PLATFORM-1 | WebView not used | No WebView in Phase 1 | Code review | **Applied** |
| MASVS-PLATFORM-2 | IPC security | No IPC or URL scheme handlers in Phase 1 | Code review | **Applied** |
| MASVS-CODE-1 | Security testing | Flutter analyze + Firestore rules emulator tests | CI output | **Partial – Phase 1** |
| MASVS-CODE-2 | No debug symbols in release | `flutter build --release` strips debug info | Build config | **Planned** |
| MASVS-CODE-4 | No debug code in release | Confirm `kDebugMode` guards before release | Build config review | **Planned** |
| MASVS-RESILIENCE-1 | App integrity / tampering | Firebase App Check (DeviceCheck on iOS) | Phase 3 | **Planned** |
| MASVS-RESILIENCE-2 | Anti-reverse engineering | Not in scope (not a high-value target for RE) | — | **Not planned** |

## Important Notes

**App Check is NOT a substitute for authentication or authorisation.**
App Check attests that the app binary is legitimate and unmodified. It does NOT:
- Authenticate individual users
- Replace Firestore Security Rules
- Prevent authorised users from abusing the API

App Check must be combined with Firebase Auth and Firestore rules — not used instead of them.

**Security Rules tests (Phase 1):**
- Unauthenticated client cannot read/write users, workspaces, tasks, notes, map nodes, performance notes
- Authenticated non-member cannot read another workspace's content
- Authenticated user can read/write their own profile
- Authenticated user can read their own performance notes
- Authenticated user cannot read another user's performance notes

**Not claimed:** "MASVS compliant", "fully secure", or "App Store ready". Controls are being incrementally implemented and tested.
