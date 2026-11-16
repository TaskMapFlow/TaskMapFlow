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
