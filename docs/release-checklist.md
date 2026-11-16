# Release Checklist – TaskMapFlow

> This checklist is NOT exhaustive. Refer to the current [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) and Apple Developer documentation at submission time, as requirements change.

## Phase 2A Authentication Status

- [x] Email/Password Sign-In & Sign-Up with Clean Architecture (Domain pure Dart, FirebaseAuth adapter only).
- [x] Guest (Anonymous) session support with UID preservation via `linkWithCredential`.
- [x] Conflict handling on guest account linking (reject automatic data merging; prompt clear user choice).
- [x] Email verification flow: initial delivery, resend with client cooldown, and status reload.
- [x] Password reset request flow with email enumeration mitigation.
- [x] Language selector (TR/EN) on login screen with persistent user preference across app restarts.
- [x] Session state management from Firebase Auth stream without screen flashing.
- [x] Denial-of-access (Deny-All) maintained on Firestore and Storage rules regardless of auth status.
- [ ] Social logins (Sign in with Apple, Google Sign-In) intentionally excluded from Phase 2A and scheduled for subsequent phases. Non-functional placeholder buttons are omitted from the UI.
- [ ] **Release Readiness**: This build is a Phase 2A milestone build and is **NOT** declared production/App Store release-ready until full account deletion, App Check enforcement, and App Store review compliance are finalized.

## Sign in with Apple & Social Logins (Phase 2B - Next Phase)

Apple requires Sign in with Apple if any third-party login (Google, etc.) is offered.

- [ ] Register App ID in Apple Developer portal with Sign in with Apple capability
- [ ] Configure Firebase Auth for Apple provider (Service ID, private key)
- [ ] Handle both real name disclosure and private email relay
- [ ] Test Apple sign-in on a real device (simulator has limitations)
- [ ] Implement token revocation on account deletion (required by Apple)
- [ ] Google Sign-In integration and credential linking

## Account Deletion (Mandatory Blocker for App Store Submission)

Apple requires apps to offer in-app account deletion (App Store Review Guideline 5.1.1(v), effective June 2022). **The app cannot be submitted to App Store until this section is completely implemented.**

- [ ] Implement "Delete Account" accessible from within the app (not just via email/support)
- [ ] Account deletion must remove or anonymise:
  - User profile (`users/{uid}`)
  - All workspace memberships (`workspaces/*/members/{uid}`)
  - Owned workspaces (transfer or dissolve — transfer mechanism must be designed)
  - Tasks, notes, performance notes created by the user
  - Files uploaded by the user
  - Archive items
- [ ] Revoke Apple Sign in token on deletion
- [ ] Revoke Firebase Auth session on deletion
- [ ] Data deletion must be permanent (not just hidden)

## App Check Enforcement (Phase 3)

App Check must NOT be silently assumed active.

- [ ] Register iOS App Attest / DeviceCheck in Firebase Console
- [ ] Register debug tokens for simulator / CI environments
- [ ] Verify App Check token exchange on real physical device
- [ ] Set App Check mode to "Monitor" (Audit) before strict "Enforce"
- [ ] Plan and verify production enforcement rollout for Firestore and Storage

## Privacy

- [ ] Add Privacy Nutrition Labels in App Store Connect matching actual data collected
- [ ] Privacy policy URL required before submission (must be accessible without login)
- [ ] Privacy policy must accurately describe:
  - Data collected: email, display name
  - Third-party services: Firebase (Google) — full SDK list
  - Data retention and deletion policy
  - Contact information for privacy requests

## App Store Requirements

- [ ] No fake engagement, test data, or placeholder content visible to App Store reviewers
- [ ] All buttons and navigation must be functional (or clearly marked as "coming soon")
- [ ] App must work in demo mode if login is required for review

## Pre-Submission Testing

- [ ] TestFlight internal testing (team members)
- [ ] TestFlight external testing (beta users, diverse devices)
- [ ] Real device testing on current iOS version(s)
- [ ] Real device testing on at least one older supported iOS version
- [ ] Accessibility testing:
  - [ ] Dynamic Type (all text scales correctly)
  - [ ] VoiceOver (all interactive elements have labels)
  - [ ] Minimum tap target size (44x44 pt)
  - [ ] Colour contrast (WCAG AA minimum)

## Public Content Moderation (Required Before Public Sharing Feature)

The following must be designed and implemented before the "public" visibility option is enabled:

- [ ] Reporting mechanism for public workspace content
- [ ] Blocking mechanism (user-to-user)
- [ ] Moderation workflow (manual or automated)
- [ ] Response policy for reported content

## Google Sign-In / Android (Future)

- [ ] SHA-1 fingerprint registration in Firebase for Android builds
- [ ] Play Store app signing configuration
- [ ] Google Play Developer Policy compliance review

## Shared Workspace Ownership

- [ ] Ownership transfer mechanism designed and implemented before account deletion is released
- [ ] Document what happens to workspace content when owner deletes their account

## Infrastructure

- [ ] Blaze plan upgrade completed (required for Cloud Functions, Storage at scale)
- [ ] Cloud Functions deployed: FCM push notification triggers, signed URL generation
- [ ] App Check enabled and enforced (Phase 3)
- [ ] Firebase usage alerts configured (cost protection)
