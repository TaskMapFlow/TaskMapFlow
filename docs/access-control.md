# Access Control – TaskMapFlow

## Roles

| Role | Scope | Description |
|---|---|---|
| owner | workspace | Created the workspace; full control |
| admin | workspace | Elevated privileges; assigned by owner |
| member | workspace | Standard participant |
| viewer | workspace | Read-only access |
| guest | app | Unauthenticated or anonymous; public content only |

## Access Matrix

| Resource | owner | admin | member | viewer | guest |
|---|---|---|---|---|---|
| Workspace settings | R/W | R | R | R | — |
| Workspace member list | R/W | R/W | R | R | — |
| Map nodes/edges (non-private) | R/W | R/W | R/W | R | — |
| Tasks (non-private) | R/W | R/W | R/W | R | — |
| **Private tasks** | own only | own only | own only | — | — |
| **Performance notes** | own user | — | — | — | — |
| Notes (non-private) | R/W | R/W | R/W | R | — |
| Private notes | own only | own only | own only | — | — |
| Sprint management | R/W | R/W | R | R | — |
| Files (team visibility) | R/W | R/W | R/W | R | — |
| **Files (private)** | uploader only | — | — | — | — |
| Public workspace content | R | R | R | R | R (read only) |
| Own user profile | R/W | — | — | — | — |
| Other user profile | R | R | R | R | — |

## Critical Rules

**1. Workspace ownership ≠ access to other users' personal data.**
Owning or administering a workspace does NOT grant access to another user's performance notes, private tasks, or personal workspace content.

**2. Public content must not expose private fields.**
A workspace set to `visibility: 'public'` allows reading of public documents, but Firestore rules must ensure that documents with private fields (e.g., `isPrivate: true`) are excluded from public queries. Field-level masking is not supported by Firestore rules — queries must be structured to avoid mixing public and private field documents.

**3. Performance notes are strictly owner-only.**
`users/{userId}/performance_notes/` is readable and writable only by the user whose `userId` matches `request.auth.uid`. This must never be relaxed, even for workspace owners or admins.

**4. Private tasks are strictly creator-only.**
Tasks with `isPrivate: true` are readable only by `createdBy == request.auth.uid`. Even admins cannot read them without explicit grant. Private task IDs must not leak through counters, notifications, or map edge labels.

**5. Invitation system integrity.**
The `invitedBy` field must be validated to match the authenticated sender's uid. Pending invitations must not expose workspace contents before acceptance.

**6. Covert information leakage.**
The following must not reveal private task or note content:
- Notification payloads (use generic messages for private items)
- File metadata (file names may reveal content)
- Map edge labels (do not auto-populate from private task titles)
- Unread counters (must not reveal count of private items to non-authorised users)

**7. Firestore rules are NOT query filters.**
A security rule that denies a document does not make a query skip that document — it makes the entire query fail. Queries must be written so that every document they can return passes the security rules for the requesting user.

**8. Admin SDK bypasses Security Rules.**
Server-side code using the Firebase Admin SDK (Cloud Functions) does not go through Security Rules. All Admin SDK usage must implement its own authorisation checks that mirror the Security Rules logic.

**9. Guest/anonymous users.**
Can only read content in workspaces with `visibility: 'public'`. Cannot create workspaces, tasks, notes, or any other content. Cannot read non-public workspace content or any user profile data.

**10. Sharing management is owner-controlled.**
Members cannot escalate their own permissions. Only the workspace owner can change `visibility` or promote members to admin.
