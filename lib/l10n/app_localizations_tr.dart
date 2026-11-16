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

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get confirmPassword => 'Şifre Doğrulama';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get continueAsGuest => 'Misafir Olarak Devam Et';

  @override
  String get forgotPassword => 'Şifremi Unuttum';

  @override
  String get forgotPasswordTitle => 'Şifre Sıfırlama';

  @override
  String get forgotPasswordDescription =>
      'Şifre sıfırlama bağlantısı almak için e-posta adresinizi girin.';

  @override
  String get sendResetLink => 'Sıfırlama Bağlantısı Gönder';

  @override
  String get resetLinkSent =>
      'Bu e-posta adresiyle bir hesap varsa, şifre sıfırlama bağlantısı gönderildi.';

  @override
  String get noAccountPrompt => 'Hesabınız yok mu?';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String get verifyEmailTitle => 'E-postanızı Doğrulayın';

  @override
  String verifyEmailBody(String email) {
    return '$email adresine doğrulama e-postası gönderildi. Tüm özelliklere erişmek için lütfen e-postanızı doğrulayın.';
  }

  @override
  String get resendVerificationEmail => 'Doğrulama E-postasını Yeniden Gönder';

  @override
  String resendCooldown(int seconds) {
    return '$seconds sn içinde yeniden gönder';
  }

  @override
  String get checkVerificationStatus => 'Doğruladım, Durumu Yenile';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signOutConfirmTitle => 'Çıkış Yapmayı Onayla';

  @override
  String get signOutConfirmBody => 'Çıkış yapmak istediğinize emin misiniz?';

  @override
  String get guestAccountBadge => 'Misafir Oturumu';

  @override
  String get guestAccountNotice =>
      'Şu anda misafir olarak oturum açtınız. İlerlemenizi korumak ve hesabınızı cihazlar arasında kullanmak için bir e-posta bağlayın.';

  @override
  String get linkAccount => 'Hesabı E-posta ile Kaydet';

  @override
  String get linkAccountTitle => 'E-posta Hesabı Bağla';

  @override
  String get linkAccountDescription =>
      'Misafir oturumunuzu verilerinizi ve kimliğinizi koruyarak kalıcı bir hesaba dönüştürmek için bilgilerinizi girin.';

  @override
  String get linkAccountConflict =>
      'Bu e-posta adresi zaten başka bir hesapla kayıtlı. Verilerinizi korumak için otomatik hesap birleştirme devre dışıdır. Lütfen o hesaba giriş yapın veya farklı bir e-posta kullanın.';

  @override
  String get linkAccountSuccess => 'Hesap başarıyla bağlandı!';

  @override
  String get emailRequired => 'Lütfen e-posta adresinizi girin';

  @override
  String get invalidEmail => 'Lütfen geçerli bir e-posta adresi girin';

  @override
  String get passwordRequired => 'Lütfen şifrenizi girin';

  @override
  String get passwordTooShort => 'Şifre en az 6 karakter olmalıdır';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get firstNameRequired => 'Lütfen adınızı girin';

  @override
  String get lastNameRequired => 'Lütfen soyadınızı girin';

  @override
  String get authErrorInvalidCredentials => 'E-posta veya şifre hatalı';

  @override
  String get authErrorEmailInUse => 'Bu e-posta adresi zaten kullanımda';

  @override
  String get authErrorWeakPassword =>
      'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';

  @override
  String get authErrorTooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';

  @override
  String get authErrorNetwork => 'Ağ hatası. Lütfen bağlantınızı kontrol edin.';

  @override
  String get authErrorUnknown =>
      'Beklenmeyen bir kimlik doğrulama hatası oluştu.';

  @override
  String get cancel => 'İptal';

  @override
  String get language => 'Dil';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get sessionLoading => 'Oturum kontrol ediliyor...';

  @override
  String get retry => 'Yeniden Dene';
}
