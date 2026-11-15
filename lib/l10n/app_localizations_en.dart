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
}
