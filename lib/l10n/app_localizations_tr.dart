// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'TaskMapFlow';

  @override
  String get profileTab => 'Profil';

  @override
  String get homeTab => 'Ana Sayfa';

  @override
  String get manageTab => 'Yönet';

  @override
  String get homeScreenPlaceholder =>
      'Harita görünümü bir sonraki aşamada eklenecek.';

  @override
  String get manageScreenPlaceholder =>
      'Çalışma alanı yönetimi bir sonraki aşamada eklenecek.';

  @override
  String get profileScreenPlaceholder =>
      'Profil içeriği bir sonraki aşamada eklenecek.';

  @override
  String get setupRequired => 'Firebase Kurulumu Gerekli';

  @override
  String get setupRequiredBody =>
      'Henüz Firebase projesi yapılandırılmamış. docs/firebase-setup.md adımlarını tamamladıktan sonra GoogleService-Info.plist (iOS) ekleyin.';
}
