# Data Model – TaskMapFlow

Initial Firestore data model. This is a starting point and will evolve as features are built. Schema changes must be accompanied by updated Security Rules and index definitions.

## Collections

### users/{userId}
```
displayName : string
email       : string
photoUrl    : string | null
bio         : string | null
githubUrl   : string | null
cvUrl       : string | null   # Storage URL – added with file upload feature
createdAt   : timestamp
updatedAt   : timestamp
```

### users/{userId}/performance_notes/{noteId}
Access: **owner only** (`request.auth.uid == userId`)
```
content    : string
writtenBy  : string   # userId – must equal the document owner
createdAt  : timestamp
```

### users/{userId}/archive/{itemId}
Access: **owner only**
```
type       : 'task' | 'workspace' | 'note'
originalId : string
archivedAt : timestamp
snapshot   : map      # denormalised copy at archive time
```

### workspaces/{workspaceId}
```
name       : string
ownerId    : string   # userId
type       : 'personal' | 'team'
visibility : 'private' | 'team' | 'selected' | 'public'
memberIds  : string[] # keep small; large teams use subcollection only
createdAt  : timestamp
```

### workspaces/{workspaceId}/members/{userId}
```
role       : 'owner' | 'admin' | 'member' | 'viewer'
joinedAt   : timestamp
invitedBy  : string   # userId
```

### workspaces/{workspaceId}/map_nodes/{nodeId}
```
label          : string
description    : string | null
color          : string         # hex colour
type           : 'task' | 'lesson' | 'project' | 'note'
positionX      : number
positionY      : number
width          : number
height         : number
linkedEntityId : string | null  # taskId, etc.
createdBy      : string         # userId
createdAt      : timestamp
```

### workspaces/{workspaceId}/map_edges/{edgeId}
```
sourceNodeId : string
targetNodeId : string
label        : string | null
createdBy    : string   # userId
createdAt    : timestamp
```

### workspaces/{workspaceId}/tasks/{taskId}
```
title            : string
description      : string | null
status           : 'backlog' | 'todo' | 'in_progress' | 'done'
priority         : 'low' | 'medium' | 'high' | 'critical'
assigneeIds      : string[]
dueDate          : timestamp | null
sprintId         : string | null
parentTaskId     : string | null   # for subtasks
dependsOnTaskIds : string[]        # warning only; does not block
isPrivate        : boolean
createdBy        : string          # userId
createdAt        : timestamp
updatedAt        : timestamp
```

### workspaces/{workspaceId}/sprints/{sprintId}
```
name      : string
startDate : timestamp
endDate   : timestamp
status    : 'planning' | 'active' | 'completed'
createdBy : string   # userId
```

### workspaces/{workspaceId}/notes/{noteId}
```
content   : string
authorId  : string   # userId
mentions  : string[] # userIds
isPrivate : boolean
createdAt : timestamp
updatedAt : timestamp
```

### files/{fileId}  (or storage path: workspaces/{workspaceId}/files/{fileId})
```
name        : string
storagePath : string
mimeType    : string
uploadedBy  : string   # userId
workspaceId : string
visibility  : 'private' | 'team' | 'selected' | 'public'
createdAt   : timestamp
```

## Query and Index Notes

| Query | Index needed |
|---|---|
| Tasks by status + sprintId, ordered by createdAt DESC | `status ASC, sprintId ASC, createdAt DESC` |
| Notes by authorId, ordered by createdAt DESC | `authorId ASC, createdAt DESC` |
| Files by workspaceId + visibility, ordered by createdAt DESC | `workspaceId ASC, visibility ASC, createdAt DESC` |

> **Important**: Firestore rules are NOT query filters. If a query returns documents the user is not allowed to read, the entire query fails — it does not silently omit those documents. Queries must be scoped so that all returned documents pass the security rules.

> **Collection group queries** (e.g., querying `tasks` across all workspaces) require a collection group index and must be guarded so users cannot access cross-workspace data. Avoid unless specifically needed.

## Separation of Concerns
- Map position/size data (`positionX`, `positionY`, `width`, `height`) lives in `map_nodes`, not in task documents.
- Task business logic (status, priority, sprint) is independent of lesson or project type.
- Lesson-specific fields (if added in future) will be in a separate `lessons` subcollection, not mixed into `tasks`.
