import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'TaskMapFlow'**
  String get appTitle;

  /// Bottom nav: Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// Bottom nav: Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// Bottom nav: Manage tab
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageTab;

  /// Placeholder text on Home screen
  ///
  /// In en, this message translates to:
  /// **'Map canvas will be added in a future phase.'**
  String get homeScreenPlaceholder;

  /// Placeholder text on Manage screen
  ///
  /// In en, this message translates to:
  /// **'Workspace management will be added in a future phase.'**
  String get manageScreenPlaceholder;

  /// Placeholder text on Profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile content will be added in a future phase.'**
  String get profileScreenPlaceholder;

  /// Shown when Firebase is not configured
  ///
  /// In en, this message translates to:
  /// **'Firebase Setup Required'**
  String get setupRequired;

  /// Setup instruction body text
  ///
  /// In en, this message translates to:
  /// **'No Firebase project is configured yet. Add GoogleService-Info.plist (iOS) after completing the steps in docs/firebase-setup.md.'**
  String get setupRequiredBody;

  /// Headline on Login screen
  ///
  /// In en, this message translates to:
  /// **'Everything is connected.'**
  String get loginHeadline;

  /// Subtitle on Login screen
  ///
  /// In en, this message translates to:
  /// **'Manage your projects and classes in one place.'**
  String get loginSubtitle;

  /// Headline on Register screen
  ///
  /// In en, this message translates to:
  /// **'Make space for your plans.'**
  String get registerHeadline;

  /// Create account button label on register screen
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// Placeholder for first name input
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNamePlaceholder;

  /// Placeholder for last name input
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get lastNamePlaceholder;

  /// Placeholder for email input
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailPlaceholder;

  /// Placeholder for password input
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordPlaceholder;

  /// Placeholder for confirm password input
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordPlaceholder;

  /// Sign in button and header
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button and header
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password input field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password input field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// First name input field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Last name input field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Guest login button label
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Reset password screen title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// Reset password explanation
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to receive a password reset link.'**
  String get forgotPasswordDescription;

  /// Send reset link button
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Generic message after requesting password reset
  ///
  /// In en, this message translates to:
  /// **'If an account exists with this email address, a password reset link has been sent.'**
  String get resetLinkSent;

  /// Prompt for new users
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// Prompt for registered users
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Email verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// Email verification explanation
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to {email}. Please verify your email to access all features.'**
  String verifyEmailBody(String email);

  /// Button to resend email verification
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerificationEmail;

  /// Cooldown timer text for resending verification email
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendCooldown(int seconds);

  /// Button to reload user profile and check email verification
  ///
  /// In en, this message translates to:
  /// **'I\'ve Verified, Refresh Status'**
  String get checkVerificationStatus;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Sign out confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Sign Out'**
  String get signOutConfirmTitle;

  /// Sign out confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmBody;

  /// Badge showing user is in guest session
  ///
  /// In en, this message translates to:
  /// **'Guest Session'**
  String get guestAccountBadge;

  /// Notice for guest users on profile screen
  ///
  /// In en, this message translates to:
  /// **'You are currently signed in as a guest. Link an email to protect your progress and use your account across devices.'**
  String get guestAccountNotice;

  /// Button to open link account flow
  ///
  /// In en, this message translates to:
  /// **'Save Account with Email'**
  String get linkAccount;

  /// Link account screen title
  ///
  /// In en, this message translates to:
  /// **'Link Email Account'**
  String get linkAccountTitle;

  /// Explanation of linking guest to permanent email account
  ///
  /// In en, this message translates to:
  /// **'Create credentials to convert this guest session into a permanent account while preserving your data and ID.'**
  String get linkAccountDescription;

  /// Notice when email linking fails because account already exists
  ///
  /// In en, this message translates to:
  /// **'This email is already registered to an existing account. Automatic account merging is disabled to protect your data. Please sign in to that account or use a different email.'**
  String get linkAccountConflict;

  /// Success banner when guest account is linked
  ///
  /// In en, this message translates to:
  /// **'Account successfully linked!'**
  String get linkAccountSuccess;

  /// Validation message when email is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// Validation message when email is malformed
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// Validation message when password is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// Validation message when password is less than 6 chars
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Validation message when confirm password does not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Validation message when first name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get firstNameRequired;

  /// Validation message when last name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get lastNameRequired;

  /// Generic auth error for incorrect credentials
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get authErrorInvalidCredentials;

  /// Auth error when signing up with existing email
  ///
  /// In en, this message translates to:
  /// **'This email address is already in use'**
  String get authErrorEmailInUse;

  /// Auth error when password is weak
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please choose a stronger password.'**
  String get authErrorWeakPassword;

  /// Auth error when rate limited
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// Auth error on network issue
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get authErrorNetwork;

  /// Generic auth error
  ///
  /// In en, this message translates to:
  /// **'An unexpected authentication error occurred.'**
  String get authErrorUnknown;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Turkish language name
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Loading message during initial session check
  ///
  /// In en, this message translates to:
  /// **'Checking session...'**
  String get sessionLoading;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Empty map headline
  ///
  /// In en, this message translates to:
  /// **'Create your first area'**
  String get createFirstAreaTitle;

  /// Empty map subtitle
  ///
  /// In en, this message translates to:
  /// **'Organize your projects and lessons visually by adding them to the map.'**
  String get createFirstAreaSubtitle;

  /// Create area button
  ///
  /// In en, this message translates to:
  /// **'Create Area'**
  String get createAreaButton;

  /// Create area sheet title
  ///
  /// In en, this message translates to:
  /// **'Create New Area'**
  String get newAreaTitle;

  /// Area name input label
  ///
  /// In en, this message translates to:
  /// **'Area Name'**
  String get areaNameLabel;

  /// Area name placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Mobile App Project'**
  String get areaNamePlaceholder;

  /// Area description input label
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get areaDescriptionLabel;

  /// Area description placeholder
  ///
  /// In en, this message translates to:
  /// **'Brief info about the area...'**
  String get areaDescriptionPlaceholder;

  /// Area type picker label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get areaTypeLabel;

  /// Project type
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get typeProject;

  /// Lesson type
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get typeLesson;

  /// Freeform type
  ///
  /// In en, this message translates to:
  /// **'Freeform'**
  String get typeFreeform;

  /// All filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// Area color picker label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get areaColorLabel;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Map edit mode button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMode;

  /// Map view mode button
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewMode;

  /// Center map view button
  ///
  /// In en, this message translates to:
  /// **'Center View'**
  String get centerView;

  /// Map edit mode info banner
  ///
  /// In en, this message translates to:
  /// **'Edit Mode: Drag areas to move them or use the handle to resize.'**
  String get editModeBanner;

  /// Area detail screen title
  ///
  /// In en, this message translates to:
  /// **'Area Detail'**
  String get areaDetailTitle;

  /// Creation date label
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAtLabel;

  /// Edit area action
  ///
  /// In en, this message translates to:
  /// **'Edit Area'**
  String get editArea;

  /// Delete area action
  ///
  /// In en, this message translates to:
  /// **'Delete Area'**
  String get deleteArea;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this area?'**
  String get deleteConfirmTitle;

  /// Delete confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'This area and its map position will be permanently deleted. This action cannot be undone.'**
  String get deleteConfirmBody;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Text when no description is set
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get noDescription;

  /// Error when area name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter an area name'**
  String get areaNameRequired;

  /// Empty state title on manage screen
  ///
  /// In en, this message translates to:
  /// **'No areas created yet'**
  String get noWorkspacesYet;

  /// Empty state subtitle on manage screen
  ///
  /// In en, this message translates to:
  /// **'Add a new project or lesson to organize your workflow.'**
  String get noWorkspacesSubtitle;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeModeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeModeDark;

  /// Tasks section title
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Lesson area study steps title
  ///
  /// In en, this message translates to:
  /// **'Study Steps'**
  String get studyStepsTitle;

  /// Add task button
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// Add step button for lessons
  ///
  /// In en, this message translates to:
  /// **'Add Step'**
  String get addStep;

  /// Task title label
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// Step title label
  ///
  /// In en, this message translates to:
  /// **'Step Title'**
  String get stepTitle;

  /// Task title placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter task title'**
  String get taskTitlePlaceholder;

  /// Step title placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter step title'**
  String get stepTitlePlaceholder;

  /// Task description label
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get taskDescription;

  /// Task description placeholder
  ///
  /// In en, this message translates to:
  /// **'Write details'**
  String get taskDescriptionPlaceholder;

  /// Task status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get taskStatus;

  /// Task priority label
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriority;

  /// Due date label
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// Label when no due date is set
  ///
  /// In en, this message translates to:
  /// **'No Due Date'**
  String get noDueDate;

  /// Select date button
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Clear date button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearDate;

  /// To do status label
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get statusTodo;

  /// In progress status label
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// Completed status label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Low priority label
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Medium priority label
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// High priority label
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// All tasks filter label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// To do filter label
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get filterTodo;

  /// In progress filter label
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filterInProgress;

  /// Completed filter label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// Overdue warning label
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// Edit task button
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// Delete task button
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// Delete task dialog title
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirmTitle;

  /// Delete task dialog body
  ///
  /// In en, this message translates to:
  /// **'This task will be permanently deleted. This action cannot be undone.'**
  String get deleteTaskConfirmBody;

  /// Empty tasks state title
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// Empty tasks state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your first task for this area.'**
  String get noTasksSubtitle;

  /// Empty study steps state title
  ///
  /// In en, this message translates to:
  /// **'No study steps yet'**
  String get noStepsYet;

  /// Empty study steps state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your first study step for this lesson.'**
  String get noStepsSubtitle;

  /// Task progress status
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} completed ({percent}%)'**
  String taskProgress(int completed, int total, int percent);

  /// Error shown when trying to delete an area with tasks
  ///
  /// In en, this message translates to:
  /// **'This area contains tasks. Please delete all tasks before deleting the area.'**
  String get deleteAreaHasTasksError;

  /// Error shown when task verification fails on area delete
  ///
  /// In en, this message translates to:
  /// **'Could not verify tasks. The area was not deleted for safety.'**
  String get deleteAreaTaskCheckFailed;

  /// Error when task title is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a task title'**
  String get taskTitleRequired;

  /// Tasks view tab
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get viewTasks;

  /// Backlog view tab
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get viewBacklog;

  /// Sprints view tab
  ///
  /// In en, this message translates to:
  /// **'Sprints'**
  String get viewSprints;

  /// Create sprint button
  ///
  /// In en, this message translates to:
  /// **'Create Sprint'**
  String get createSprint;

  /// Edit sprint button
  ///
  /// In en, this message translates to:
  /// **'Edit Sprint'**
  String get editSprint;

  /// Sprint name field
  ///
  /// In en, this message translates to:
  /// **'Sprint Name'**
  String get sprintName;

  /// Sprint goal field
  ///
  /// In en, this message translates to:
  /// **'Sprint Goal (optional)'**
  String get sprintGoal;

  /// Start date field
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// End date field
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// Planned sprint status
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get sprintStatusPlanned;

  /// Active sprint status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sprintStatusActive;

  /// Completed sprint status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sprintStatusCompleted;

  /// Start sprint button
  ///
  /// In en, this message translates to:
  /// **'Start Sprint'**
  String get startSprint;

  /// Complete sprint button
  ///
  /// In en, this message translates to:
  /// **'Complete Sprint'**
  String get completeSprint;

  /// Delete sprint button
  ///
  /// In en, this message translates to:
  /// **'Delete Sprint'**
  String get deleteSprint;

  /// Assign task to sprint option
  ///
  /// In en, this message translates to:
  /// **'Assign to Sprint'**
  String get assignToSprint;

  /// Move task to backlog option
  ///
  /// In en, this message translates to:
  /// **'Move to Backlog'**
  String get moveToBacklog;

  /// Empty sprints state title
  ///
  /// In en, this message translates to:
  /// **'No sprints yet'**
  String get noSprintsYet;

  /// Empty sprints state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a sprint to group your tasks into time periods.'**
  String get noSprintsSubtitle;

  /// Empty backlog state title
  ///
  /// In en, this message translates to:
  /// **'No tasks in Backlog'**
  String get noBacklogTasks;

  /// Empty backlog state subtitle
  ///
  /// In en, this message translates to:
  /// **'All tasks not assigned to a sprint will appear here.'**
  String get noBacklogTasksSubtitle;

  /// Date ordering error
  ///
  /// In en, this message translates to:
  /// **'End date cannot be earlier than start date.'**
  String get dateOrderError;

  /// Complete sprint dialog title
  ///
  /// In en, this message translates to:
  /// **'Complete Sprint'**
  String get completeSprintConfirmTitle;

  /// Incomplete tasks prompt on sprint complete
  ///
  /// In en, this message translates to:
  /// **'There are {count} incomplete tasks. What would you like to do with them?'**
  String completeSprintPrompt(int count);

  /// Move incomplete tasks to backlog button
  ///
  /// In en, this message translates to:
  /// **'Move to Backlog'**
  String get moveIncompleteToBacklog;

  /// Keep incomplete tasks in sprint button
  ///
  /// In en, this message translates to:
  /// **'Keep in Sprint'**
  String get keepInSprint;

  /// Delete sprint with tasks question
  ///
  /// In en, this message translates to:
  /// **'This sprint contains {count} tasks. What would you like to do?'**
  String deleteSprintWithTasksConfirm(int count);

  /// Move tasks to backlog and delete sprint button
  ///
  /// In en, this message translates to:
  /// **'Move to Backlog & Delete'**
  String get moveTasksToBacklogAndDelete;

  /// Active sprint badge
  ///
  /// In en, this message translates to:
  /// **'Active Sprint'**
  String get sprintActiveBadge;

  /// Subtasks title
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasksTitle;

  /// Add subtask placeholder
  ///
  /// In en, this message translates to:
  /// **'Add subtask...'**
  String get addSubtask;

  /// Subtask limit warning
  ///
  /// In en, this message translates to:
  /// **'Maximum of 20 subtasks allowed.'**
  String get subtaskLimitReached;

  /// Connect areas map button
  ///
  /// In en, this message translates to:
  /// **'Connect Areas'**
  String get connectAreas;

  /// Connecting mode hint
  ///
  /// In en, this message translates to:
  /// **'Select target area to connect'**
  String get connectingModeHint;

  /// Connection type title
  ///
  /// In en, this message translates to:
  /// **'Connection Type'**
  String get connectionType;

  /// Related connection type
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get connectionRelated;

  /// Related connection description
  ///
  /// In en, this message translates to:
  /// **'Both areas are connected to each other.'**
  String get connectionRelatedDesc;

  /// Blocks connection type
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get connectionBlocks;

  /// Blocks connection description
  ///
  /// In en, this message translates to:
  /// **'The target area cannot start until this area is completed.'**
  String get connectionBlocksDesc;

  /// Delete connection button
  ///
  /// In en, this message translates to:
  /// **'Delete Connection'**
  String get deleteConnection;

  /// Delete connection confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this connection?'**
  String get deleteConnectionConfirm;

  /// Blocked by dependency warning badge
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to complete'**
  String blockedByDependencyWarning(String name);

  /// Duplicate connection error
  ///
  /// In en, this message translates to:
  /// **'A connection already exists between these two areas.'**
  String get duplicateConnectionError;

  /// Self connection error
  ///
  /// In en, this message translates to:
  /// **'An area cannot be connected to itself.'**
  String get selfConnectionError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
