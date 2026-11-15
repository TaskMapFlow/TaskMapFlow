# Product Scope – TaskMapFlow

## Vision
TaskMapFlow is a visual task and project management application for students and professionals. It enables users to create visual maps of their work, linking tasks, lessons, and projects on an interactive canvas.

## Confirmed Phase 1 Scope
- Flutter iOS project foundation with Clean Architecture structure
- 3-tab app shell: Home (map canvas placeholder), Manage, Profile
- Firestore + Storage deny-all security rules (baseline)
- Firebase Emulator security rules tests
- Architecture, security, and data model documentation
- GitHub Actions CI (format, analyze, flutter test, rules tests)
- Turkish and English localisation infrastructure (ARB files)
- Light and dark theme support

## Primary Platform
iOS and App Store. Android may be added in a future phase.

## Languages
Turkish (tr) and English (en). Language selection follows device settings initially.

## Themes
Light and dark, following system preference. Manual override is a future feature.

## User Types
- **Personal workspace users**: individuals managing their own tasks and lessons
- **Team workspace members**: invited to a shared workspace by an owner

## Main Navigation (3 tabs)
1. **Home** – visual map canvas (node/connection map)
2. **Manage** – workspace, sprint, backlog management
3. **Profile** – user bio, CV, GitHub link, archive

## Home Screen – Visual Map
- User-created boxes (nodes) and connections on a canvas
- Tap a box → full-screen detail view
- Moving, resizing, connecting boxes: separate editing mode (not tap-to-open)
- Box properties: name, description, colour, type (task / lesson / project)

## Task Model
- Tasks, subtasks, backlog items, sprints
- Assignees, priorities (low / medium / high / critical), due dates
- Dependencies: warn user but do NOT block task start
- Private tasks: access-protected, visible only to creator

## Workspaces
- Personal workspaces (private by default)
- Team workspaces (invite-only)

## Sharing
- Visibility levels: private / team / selected users / public
- Workspace owner controls team-wide sharing
- Personal workspace contents remain private to the owner
- Private tasks and performance notes require separate access protection

## Communication
- Quick notes with @mentions and notifications
- No audio or video meeting features

## Profile
- Photo, biography, CV, GitHub link
- Completed-work archive

## Authentication
- Email/password
- Sign in with Google
- Sign in with Apple (required for App Store if any third-party login is offered)
- Guest/anonymous access (read-only on public content)

## Production Data Policy
- NO fake users, tasks, or success rates in production builds
- Test/seed data is isolated to the Firebase Emulator environment only
- No placeholder statistics visible to real users

## Future Phases (not in Phase 1)
- Animated dark planet/space login screen design
- Login flow and authentication UI
- Task CRUD operations
- Map canvas with node/edge interactions
- File upload (photos, CVs)
- Push notifications (requires Cloud Functions + Blaze plan)
- Android support
- Public content moderation workflow

## Open Product Decisions
The following are NOT confirmed requirements and must be decided before implementation:
- Exact lesson/course feature set (no scoring, grading, or curriculum system confirmed)
- Moderation workflow for public workspace content (not designed)
- Exact performance note access rules beyond owner-only read
- Blaze plan upgrade timeline and trigger
- Shared workspace ownership transfer on account deletion
- Language switching mechanism (device-follow vs. in-app toggle)
