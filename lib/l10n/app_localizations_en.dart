// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TaskMapFlow';

  @override
  String get profileTab => 'Profile';

  @override
  String get homeTab => 'Home';

  @override
  String get manageTab => 'Manage';

  @override
  String get homeScreenPlaceholder =>
      'Map canvas will be added in a future phase.';

  @override
  String get manageScreenPlaceholder =>
      'Workspace management will be added in a future phase.';

  @override
  String get profileScreenPlaceholder =>
      'Profile content will be added in a future phase.';

  @override
  String get setupRequired => 'Firebase Setup Required';

  @override
  String get setupRequiredBody =>
      'No Firebase project is configured yet. Add GoogleService-Info.plist (iOS) after completing the steps in docs/firebase-setup.md.';

  @override
  String get loginHeadline => 'Everything is connected.';

  @override
  String get loginSubtitle => 'Manage your projects and classes in one place.';

  @override
  String get registerHeadline => 'Make space for your plans.';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get firstNamePlaceholder => 'Enter your first name';

  @override
  String get lastNamePlaceholder => 'Enter your last name';

  @override
  String get emailPlaceholder => 'Enter your email address';

  @override
  String get passwordPlaceholder => 'Enter your password';

  @override
  String get confirmPasswordPlaceholder => 'Re-enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordDescription =>
      'Enter your email address to receive a password reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent =>
      'If an account exists with this email address, a password reset link has been sent.';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String verifyEmailBody(String email) {
    return 'A verification email has been sent to $email. Please verify your email to access all features.';
  }

  @override
  String get resendVerificationEmail => 'Resend Verification Email';

  @override
  String resendCooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get checkVerificationStatus => 'I\'ve Verified, Refresh Status';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmTitle => 'Confirm Sign Out';

  @override
  String get signOutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String get guestAccountBadge => 'Guest Session';

  @override
  String get guestAccountNotice =>
      'You are currently signed in as a guest. Link an email to protect your progress and use your account across devices.';

  @override
  String get linkAccount => 'Save Account with Email';

  @override
  String get linkAccountTitle => 'Link Email Account';

  @override
  String get linkAccountDescription =>
      'Create credentials to convert this guest session into a permanent account while preserving your data and ID.';

  @override
  String get linkAccountConflict =>
      'This email is already registered to an existing account. Automatic account merging is disabled to protect your data. Please sign in to that account or use a different email.';

  @override
  String get linkAccountSuccess => 'Account successfully linked!';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get firstNameRequired => 'Please enter your first name';

  @override
  String get lastNameRequired => 'Please enter your last name';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password';

  @override
  String get authErrorEmailInUse => 'This email address is already in use';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak. Please choose a stronger password.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authErrorNetwork => 'Network error. Please check your connection.';

  @override
  String get authErrorUnknown => 'An unexpected authentication error occurred.';

  @override
  String get cancel => 'Cancel';

  @override
  String get language => 'Language';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get sessionLoading => 'Checking session...';

  @override
  String get retry => 'Retry';

  @override
  String get createFirstAreaTitle => 'Create your first area';

  @override
  String get createFirstAreaSubtitle =>
      'Organize your projects and lessons visually by adding them to the map.';

  @override
  String get createAreaButton => 'Create Area';

  @override
  String get newAreaTitle => 'Create New Area';

  @override
  String get areaNameLabel => 'Area Name';

  @override
  String get areaNamePlaceholder => 'e.g. Mobile App Project';

  @override
  String get areaDescriptionLabel => 'Description (Optional)';

  @override
  String get areaDescriptionPlaceholder => 'Brief info about the area...';

  @override
  String get areaTypeLabel => 'Type';

  @override
  String get typeProject => 'Project';

  @override
  String get typeLesson => 'Lesson';

  @override
  String get typeFreeform => 'Freeform';

  @override
  String get allFilter => 'All';

  @override
  String get areaColorLabel => 'Color';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get editMode => 'Edit';

  @override
  String get viewMode => 'View';

  @override
  String get centerView => 'Center View';

  @override
  String get editModeBanner =>
      'Edit Mode: Drag areas to move them or use the handle to resize.';

  @override
  String get areaDetailTitle => 'Area Detail';

  @override
  String get createdAtLabel => 'Created';

  @override
  String get editArea => 'Edit Area';

  @override
  String get deleteArea => 'Delete Area';

  @override
  String get deleteConfirmTitle => 'Are you sure you want to delete this area?';

  @override
  String get deleteConfirmBody =>
      'This area and its map position will be permanently deleted. This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get noDescription => 'No description provided';

  @override
  String get areaNameRequired => 'Please enter an area name';

  @override
  String get noWorkspacesYet => 'No areas created yet';

  @override
  String get noWorkspacesSubtitle =>
      'Add a new project or lesson to organize your workflow.';

  @override
  String get themeModeLight => 'Light Theme';

  @override
  String get themeModeDark => 'Dark Theme';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get studyStepsTitle => 'Study Steps';

  @override
  String get addTask => 'Add Task';

  @override
  String get addStep => 'Add Step';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get stepTitle => 'Step Title';

  @override
  String get taskTitlePlaceholder => 'Enter task title';

  @override
  String get stepTitlePlaceholder => 'Enter step title';

  @override
  String get taskDescription => 'Description (Optional)';

  @override
  String get taskDescriptionPlaceholder => 'Write details';

  @override
  String get taskStatus => 'Status';

  @override
  String get taskPriority => 'Priority';

  @override
  String get dueDate => 'Due Date';

  @override
  String get noDueDate => 'No Due Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get clearDate => 'Clear';

  @override
  String get statusTodo => 'To Do';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get filterAll => 'All';

  @override
  String get filterTodo => 'To Do';

  @override
  String get filterInProgress => 'In Progress';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get overdue => 'Overdue';

  @override
  String get editTask => 'Edit Task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteTaskConfirmTitle =>
      'Are you sure you want to delete this task?';

  @override
  String get deleteTaskConfirmBody =>
      'This task will be permanently deleted. This action cannot be undone.';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get noTasksSubtitle => 'Add your first task for this area.';

  @override
  String get noStepsYet => 'No study steps yet';

  @override
  String get noStepsSubtitle => 'Add your first study step for this lesson.';

  @override
  String taskProgress(int completed, int total, int percent) {
    return '$completed / $total completed ($percent%)';
  }

  @override
  String get deleteAreaHasTasksError =>
      'This area contains tasks. Please delete all tasks before deleting the area.';

  @override
  String get deleteAreaTaskCheckFailed =>
      'Could not verify tasks. The area was not deleted for safety.';

  @override
  String get taskTitleRequired => 'Please enter a task title';

  @override
  String get viewTasks => 'Tasks';

  @override
  String get viewBacklog => 'Backlog';

  @override
  String get viewSprints => 'Sprints';

  @override
  String get createSprint => 'Create Sprint';

  @override
  String get editSprint => 'Edit Sprint';

  @override
  String get sprintName => 'Sprint Name';

  @override
  String get sprintGoal => 'Sprint Goal (optional)';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get sprintStatusPlanned => 'Planned';

  @override
  String get sprintStatusActive => 'Active';

  @override
  String get sprintStatusCompleted => 'Completed';

  @override
  String get startSprint => 'Start Sprint';

  @override
  String get completeSprint => 'Complete Sprint';

  @override
  String get deleteSprint => 'Delete Sprint';

  @override
  String get assignToSprint => 'Assign to Sprint';

  @override
  String get moveToBacklog => 'Move to Backlog';

  @override
  String get noSprintsYet => 'No sprints yet';

  @override
  String get noSprintsSubtitle =>
      'Create a sprint to group your tasks into time periods.';

  @override
  String get noBacklogTasks => 'No tasks in Backlog';

  @override
  String get noBacklogTasksSubtitle =>
      'All tasks not assigned to a sprint will appear here.';

  @override
  String get dateOrderError => 'End date cannot be earlier than start date.';

  @override
  String get completeSprintConfirmTitle => 'Complete Sprint';

  @override
  String completeSprintPrompt(int count) {
    return 'There are $count incomplete tasks. What would you like to do with them?';
  }

  @override
  String get moveIncompleteToBacklog => 'Move to Backlog';

  @override
  String get keepInSprint => 'Keep in Sprint';

  @override
  String deleteSprintWithTasksConfirm(int count) {
    return 'This sprint contains $count tasks. What would you like to do?';
  }

  @override
  String get moveTasksToBacklogAndDelete => 'Move to Backlog & Delete';

  @override
  String get sprintActiveBadge => 'Active Sprint';

  @override
  String get subtasksTitle => 'Subtasks';

  @override
  String get addSubtask => 'Add subtask...';

  @override
  String get subtaskLimitReached => 'Maximum of 20 subtasks allowed.';

  @override
  String get connectAreas => 'Connect Areas';

  @override
  String get connectingModeHint => 'Select target area to connect';

  @override
  String get connectionType => 'Connection Type';

  @override
  String get connectionRelated => 'Related';

  @override
  String get connectionRelatedDesc => 'Both areas are connected to each other.';

  @override
  String get connectionBlocks => 'Blocks';

  @override
  String get connectionBlocksDesc =>
      'The target area cannot start until this area is completed.';

  @override
  String get deleteConnection => 'Delete Connection';

  @override
  String get deleteConnectionConfirm =>
      'Are you sure you want to delete this connection?';

  @override
  String blockedByDependencyWarning(String name) {
    return 'Waiting for $name to complete';
  }

  @override
  String get duplicateConnectionError =>
      'A connection already exists between these two areas.';

  @override
  String get selfConnectionError => 'An area cannot be connected to itself.';

  @override
  String get tabWork => 'Work';

  @override
  String get tabNotes => 'Notes';

  @override
  String get tabInfo => 'Info';

  @override
  String get quickNotesTitle => 'Quick Notes';

  @override
  String get addNote => 'Add Note';

  @override
  String get editNote => 'Edit Note';

  @override
  String get noteTitleLabel => 'Title (Optional)';

  @override
  String get noteContentLabel => 'Content';

  @override
  String get noteContentPlaceholder => 'Write your note here...';

  @override
  String get noteTitlePlaceholder => 'Note title...';

  @override
  String get noNotesYet => 'No notes added yet.';

  @override
  String get noNotesSub => 'Keep your thoughts and links for this area here.';

  @override
  String get loadMore => 'Load more';

  @override
  String get deleteNoteConfirmTitle => 'Delete Note';

  @override
  String get deleteNoteConfirmMessage =>
      'Are you sure you want to delete this note?';

  @override
  String get noteUpdated => 'Updated';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get addTag => 'Add Tag';

  @override
  String get tagPlaceholder => 'e.g. react, math, mobile...';

  @override
  String get tagLimitReached => 'Maximum 20 tags allowed.';

  @override
  String get tagLengthExceeded => 'Tag can be at most 30 characters.';

  @override
  String get resourcesTitle => 'Resource Links';

  @override
  String get addResource => 'Add Resource';

  @override
  String get editResource => 'Edit Resource';

  @override
  String get resourceTitleLabel => 'Resource Title';

  @override
  String get resourceTitlePlaceholder => 'e.g. GitHub Repo, Lecture Notes...';

  @override
  String get resourceUrlLabel => 'URL (http/https)';

  @override
  String get resourceUrlPlaceholder => 'https://...';

  @override
  String get invalidUrlError => 'Please enter a valid http or https URL.';

  @override
  String get noResourcesYet => 'No resource links added yet.';

  @override
  String get deleteResourceConfirmTitle => 'Delete Resource';

  @override
  String get deleteResourceConfirmMessage =>
      'Are you sure you want to delete this resource?';

  @override
  String get deleteAreaHasContentError =>
      'This workspace contains tasks, sprints, or notes. Please clear them before deleting the workspace.';

  @override
  String get urlLaunchError => 'Could not open link.';

  @override
  String get saveInfo => 'Save Info';

  @override
  String get infoSavedSuccess => 'Information updated.';

  @override
  String get archivedAreasTitle => 'Archive';

  @override
  String get noArchivedAreasYet => 'No archived areas.';

  @override
  String get noArchivedAreasSubtitle =>
      'Areas you archive will appear here in read-only mode.';

  @override
  String get archiveArea => 'Archive Area';

  @override
  String get archiveAreaConfirmTitle => 'Archive Area';

  @override
  String get archiveAreaConfirmBody =>
      'Are you sure you want to archive this area? Archived areas are hidden from the main map and become read-only. You can restore them anytime from Profile > Archive.';

  @override
  String get restoreArea => 'Restore Area';

  @override
  String get restoreAreaConfirm =>
      'Are you sure you want to restore this area from archive?';

  @override
  String get areaArchivedBadge => 'Archived';

  @override
  String get areaArchivedNotice => 'This area is archived and read-only.';

  @override
  String get archivedAtLabel => 'Archived on';

  @override
  String get connectedAreaArchivedWarning => 'Connected area is archived';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileNameLabel => 'Full Name';

  @override
  String get profileNamePlaceholder => 'Enter your full name';

  @override
  String get profileNameEmptyError => 'Please enter your name';

  @override
  String get profileBioLabel => 'Bio';

  @override
  String get profileBioPlaceholder => 'A short note about yourself...';

  @override
  String get githubUrlLabel => 'GitHub Profile';

  @override
  String get githubUrlPlaceholder => 'https://github.com/username';

  @override
  String get invalidGithubUrlError =>
      'Please enter a valid GitHub profile URL (https://github.com/... only)';

  @override
  String get profileSavedSuccess => 'Profile updated.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSetting => 'Language';

  @override
  String get themeSetting => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get teamSectionTitle => 'Team';

  @override
  String get enableTeamTitle => 'Enable Teamwork';

  @override
  String get enableTeamDescription =>
      'When you enable teamwork, existing and new tasks, notes, and content in this workspace will become visible to joined members. Do you confirm?';

  @override
  String get enableTeamButton => 'Enable Teamwork';

  @override
  String get teamEnabledSuccess => 'Teamwork enabled.';

  @override
  String get membersTitle => 'Team Members';

  @override
  String get memberRoleOwner => 'Owner';

  @override
  String get memberRoleAdmin => 'Admin';

  @override
  String get memberRoleMember => 'Member';

  @override
  String get makeAdmin => 'Make Admin';

  @override
  String get removeAdmin => 'Remove Admin';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get removeMemberConfirm =>
      'Are you sure you want to remove this member from the team?';

  @override
  String get leaveTeam => 'Leave Team';

  @override
  String get leaveTeamConfirm =>
      'Are you sure you want to leave this workspace? Your contributions will be preserved.';

  @override
  String get noLongerOnTeam => 'No longer on team';

  @override
  String get inviteMember => 'Invite Member';

  @override
  String get inviteCodeTitle => 'Invite Code';

  @override
  String get inviteCodeDescription =>
      'This code is single-use and valid for 7 days. Share it with the invitee:';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get codeCopied => 'Invite code copied.';

  @override
  String get joinWithCode => 'Join with Invite Code';

  @override
  String get enterInviteCode => 'Enter Invite Code';

  @override
  String get inviteCodePlaceholder => '8-character invite code';

  @override
  String get joinButton => 'Join';

  @override
  String get joinSuccess => 'Successfully joined workspace!';

  @override
  String get joinedWorkspaces => 'Joined Areas';

  @override
  String get myWorkspaces => 'My Areas';

  @override
  String get assignedToMe => 'Assigned to Me';

  @override
  String get assignee => 'Assignee';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get assignToMe => 'Assign to Me';

  @override
  String get filterAssignedToMe => 'Assigned to Me';

  @override
  String get noAssignedTasks => 'No tasks assigned to you.';

  @override
  String get noJoinedWorkspaces =>
      'You haven\'t joined any team workspaces yet.';

  @override
  String get guestJoinWarning =>
      'Guest users cannot accept team invites. Please link an account or sign up first.';

  @override
  String get mapView => 'Map';

  @override
  String get overviewView => 'Overview';

  @override
  String get dailySummaryTitle => 'Daily Work Summary';

  @override
  String get todayTasks => 'Today';

  @override
  String get overdueTasks => 'Overdue';

  @override
  String get upcomingTasks => 'Next 7 Days';

  @override
  String get inProgressTasks => 'In Progress';

  @override
  String get activeWorkspaces => 'Active Areas';

  @override
  String seeAll(int count) {
    return 'See All ($count)';
  }

  @override
  String get showLess => 'Show Less';

  @override
  String get searchWorkspacesPlaceholder => 'Search areas...';

  @override
  String get noMatchingWorkspaces => 'No matching areas found.';

  @override
  String get dailySummaryEmptyTitle => 'No tasks or areas yet';

  @override
  String get dailySummaryEmptySubtitle =>
      'Create your first area and add tasks to start managing your work.';

  @override
  String get allClearTitle => 'All clear!';

  @override
  String get allClearSubtitle => 'No overdue or due today tasks pending.';
}
