# Threat Model – TaskMapFlow

## Protected Assets
- User profile data (email, name, photo, bio, CV)
- Task content (titles, descriptions, private tasks)
- Performance notes (strictly owner-private)
- File attachments (workspace files, user CVs)
- Workspace membership and structure
- Authentication tokens and session credentials
- Firebase project quota (cost protection)

---

## Threats

### 1. Privilege Escalation
**Threat:** A workspace member modifies their own role field in the `members` subcollection.

**Attack path:** Authenticated user calls Firestore SDK to write `workspaces/{wsId}/members/{theirUid}` with `role: 'owner'`.

**Control:** Firestore rules validate that role changes are made only by the workspace owner or admin. Members cannot write their own `members/{theirUid}` document role field. Rule: `isWorkspaceAdmin(workspaceId)` for member writes.

**Test:** `test-rules/firestore.rules.test.js` — member cannot escalate own role (Phase 2 test).

**Residual risk:** Rule complexity errors may create gaps; targeted tests for each role transition are required as the feature is built.

---

### 2. Cross-Workspace Data Access
**Threat:** An authenticated user reads another workspace's tasks by guessing Firestore document paths.

**Attack path:** Attacker calls `db.collection('workspaces').doc('victimWsId').collection('tasks').doc('taskId').get()`.

**Control:** Firestore rules check workspace membership for all workspace sub-collections via `isWorkspaceMember(workspaceId)`.

**Test:** `test-rules/firestore.rules.test.js` — `authenticated non-member cannot read tasks` (Phase 1, implemented).

**Residual risk:** New sub-collections added without corresponding rules will be denied by default (deny-all baseline), but this must be explicitly verified with tests for each new collection.

---

### 3. Invitation Abuse
**Threat:** Attacker generates mass invitations to exhaust Firestore quota or spam users.

**Attack path:** Authenticated user creates many `members` documents with forged `invitedBy` fields.

**Control (planned):** Rate-limit invitations server-side via Cloud Functions (future). Validate `invitedBy == request.auth.uid` in Firestore rules.

**Residual risk:** No server-side rate limiting in Phase 1. Cloud Functions require Blaze plan. Risk is accepted as low-priority for pre-launch phase.

---

### 4. Private File Leakage via Storage URLs
**Threat:** An attacker obtains or guesses a Firebase Storage download URL for a private file.

**Attack path:** Attacker uses a known or guessed Storage path to download a private CV or file attachment.

**Control:** Firebase Storage security rules validate `request.auth != null` and workspace membership. Do NOT use publicly accessible Storage download URLs for private files. Short-lived signed URLs must be generated server-side (Cloud Functions, future).

**Residual risk:** Phase 1 has no signed URL server (requires Cloud Functions + Blaze). Private file serving is deferred. Storage deny-all baseline is in place.

---

### 5. Performance Note Leakage
**Threat:** Performance notes readable via admin role assumption or cross-user query.

**Attack path:** Workspace admin calls `users/{victimUid}/performance_notes/{noteId}.get()`.

**Control:** Performance notes are stored under `users/{userId}/performance_notes/`. Firestore rule: `allow read, write: if request.auth.uid == userId`. Admin role does not grant cross-user access.

**Test:** `test-rules/firestore.rules.test.js` — `authenticated user cannot read another user's performance notes` (Phase 1, implemented).

**Residual risk:** Server-side code using Admin SDK must separately enforce this restriction. Document this clearly in the Admin SDK authorisation layer when Cloud Functions are added.

---

### 6. Anonymous Account Abuse
**Threat:** Guest/anonymous accounts create spam content or consume Firestore quota.

**Attack path:** Attacker creates many anonymous sessions and writes workspace, task, or note documents.

**Control:** Guest accounts are restricted to read-only on public content. Firestore rules deny all writes from unauthenticated sessions. App Check (future, Phase 3) will attest app integrity and limit automated account creation.

**Residual risk:** No App Check in Phase 1. Anonymous account creation is not rate-limited by Firestore rules alone; Firebase Auth has basic rate limits but these can be bypassed. Acceptable for pre-launch phase.

---

### 7. Cost / Denial-of-Service via Large Documents or Expensive Queries
**Threat:** An authenticated user writes very large documents or runs expensive collection-group queries using valid credentials.

**Attack path:** Attacker writes a task with a 1 MB `description` field, repeated rapidly, exhausting Firestore write quota.

**Control:** Firestore rules will validate document size limits (`request.resource.size < N`). App Check + server-side rate limiting (future) for quota protection. Spark plan has hard quota caps that limit blast radius.

**Residual risk:** No document size validation in Phase 1 rules (added with task CRUD feature). No rate limiting in Phase 1. Spark plan cap provides some protection; monitor usage after launch.

---

### 8. Admin SDK Authorisation Bypass
**Threat:** Server-side Cloud Functions code using the Firebase Admin SDK skips Security Rules and accesses or modifies data it should not.

**Attack path:** A Cloud Function triggered by a user event reads `performance_notes` for all users to generate a report.

**Control:** All Admin SDK usage must implement explicit authorisation checks that mirror Security Rules logic. Documented in AGENTS.md and architecture.md.

**Residual risk:** Phase 1 has no Cloud Functions. Risk is noted for future implementation. Requires code review of every new Cloud Function.

---

### 9. Public Content Exposes Private Fields
**Threat:** A workspace set to `visibility: 'public'` returns documents containing private task content.

**Attack path:** Attacker queries the `tasks` subcollection of a public workspace and receives tasks with `isPrivate: true` and sensitive descriptions.

**Control:** Firestore rules deny reads of tasks where `resource.data.isPrivate == true` and `resource.data.createdBy != request.auth.uid`. Public queries must be structured to exclude private documents.

**Residual risk:** Firestore does not support field-level masking in rules for read operations. If a query could match both public and private documents, the query will fail (not silently exclude). Public workspace content queries must explicitly filter by `isPrivate == false`.

---

### 10. Shared Workspace Ownership on Account Deletion
**Threat:** Workspace owner deletes their account, leaving workspace contents inaccessible or owned by nobody.

**Attack path:** Owner uses account deletion flow; workspace and all its tasks become ownerless.

**Control (planned):** Account deletion flow must include workspace transfer prompt or automatic dissolution. Ownership transfer rules must be designed before account deletion is implemented.

**Residual risk:** Not implemented in Phase 1. Must be resolved before account deletion is released (required by App Store guidelines).
