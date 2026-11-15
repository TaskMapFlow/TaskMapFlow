# Firebase Setup – TaskMapFlow

> **Status**: Firebase project NOT yet created. This document describes the steps to create and configure it.

## Bundle ID

**Candidate**: `com.taskmapflow.app`

This has NOT been registered in Apple Developer or Firebase yet. Finalise the bundle ID before creating the Firebase project — changing it afterwards requires re-registering the iOS app.

## Firebase Project

**Display name**: taskmapflow
**Project ID**: Unknown — chosen at project creation time (must be globally unique across all Firebase projects).
**Current plan**: Spark (free tier)

## Steps to Create and Configure Firebase for iOS

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** → name it "taskmapflow"
3. Note the generated project ID (you cannot change it after creation)
4. Enable Google Analytics if desired (optional)
5. In Project Settings → Your apps → **Add app** → iOS
6. Enter Bundle ID: `com.taskmapflow.app`
7. Enter App nickname: "TaskMapFlow iOS"
8. Download `GoogleService-Info.plist`
9. **In Xcode**: drag `GoogleService-Info.plist` into the `Runner` group (not just the file system). Ensure "Copy items if needed" is checked and the target is `Runner`.
10. Do NOT commit `GoogleService-Info.plist` to git (it is in `.gitignore`)

## Developer Distribution

- Each developer adds their own `GoogleService-Info.plist` manually per machine
- For CI/CD: add `GoogleService-Info.plist` as a GitHub Actions secret and write it to disk before the build step
- Never commit the plist to source control

## Firebase Services Needed

| Service | Plan | Notes |
|---|---|---|
| Authentication | Spark | Available on free tier |
| Firestore | Spark | 1 GiB storage, 50k reads/day, 20k writes/day |
| Storage | Spark | 5 GB storage, 1 GB/day download — NOT sufficient for file/CV/photo hosting at scale |
| Cloud Functions | **Blaze required** | Push notifications (FCM triggers), signed URLs for private files, server-side rate limiting |
| App Check | Spark (basic) | Blaze required for Cloud Functions enforcement |

## Spark Plan Limitations

The current Spark (free) plan has the following hard limits:

- Firestore: 1 GiB storage, 50,000 reads/day, 20,000 writes/day, 20,000 deletes/day
- Storage: 5 GB total, 1 GB/day download
- **Cloud Functions: NOT available** on Spark plan

**This means the following features cannot be shipped on the Spark plan:**
- Push notification triggers (require Cloud Functions)
- Signed URL generation for private file access (require Cloud Functions)
- Server-side invitation rate limiting (require Cloud Functions)
- Admin SDK operations with custom authorisation logic (require Cloud Functions)
- File and CV hosting at any meaningful scale

**A Blaze (pay-as-you-go) plan upgrade is required before these features go to production.** Do not declare the product "ready for production" without resolving this.

## Emulator Setup (Phase 1, no real Firebase project needed)

The Firebase Emulator is used for local development and CI security rules testing.

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools@14

# Start emulators (from project root)
firebase emulators:start --only firestore,auth --project taskmapflow-test

# Run rules tests
cd test-rules && npm install && npm test
```

The `--project taskmapflow-test` flag uses a local dummy project ID. No real Firebase connection is made.
