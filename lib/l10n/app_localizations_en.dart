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
}
