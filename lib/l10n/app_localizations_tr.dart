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
  String get loginHeadline => 'Her şey birbiriyle bağlı.';

  @override
  String get loginSubtitle => 'Projelerini ve derslerini tek yerde yönet.';

  @override
  String get registerHeadline => 'Planlarına alan aç.';

  @override
  String get createAccountButton => 'Hesap oluştur';

  @override
  String get firstNamePlaceholder => 'Adını gir';

  @override
  String get lastNamePlaceholder => 'Soyadını gir';

  @override
  String get emailPlaceholder => 'E-posta adresini gir';

  @override
  String get passwordPlaceholder => 'Şifreni gir';

  @override
  String get confirmPasswordPlaceholder => 'Şifreni tekrar gir';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signUp => 'Kayıt ol';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get confirmPassword => 'Şifreyi doğrula';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get continueAsGuest => 'Misafir olarak devam et';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get forgotPasswordTitle => 'Şifre sıfırlama';

  @override
  String get forgotPasswordDescription =>
      'Şifre sıfırlama bağlantısı almak için e-posta adresinizi girin.';

  @override
  String get sendResetLink => 'Sıfırlama bağlantısı gönder';

  @override
  String get resetLinkSent =>
      'Bu e-posta adresiyle bir hesap varsa, şifre sıfırlama bağlantısı gönderildi.';

  @override
  String get noAccountPrompt => 'Hesabın yok mu?';

  @override
  String get alreadyHaveAccount => 'Zaten hesabın var mı?';

  @override
  String get verifyEmailTitle => 'E-postanızı doğrulayın';

  @override
  String verifyEmailBody(String email) {
    return '$email adresine doğrulama e-postası gönderildi. Tüm özelliklere erişmek için lütfen e-postanızı doğrulayın.';
  }

  @override
  String get resendVerificationEmail => 'Doğrulama e-postasını yeniden gönder';

  @override
  String resendCooldown(int seconds) {
    return '$seconds sn içinde yeniden gönder';
  }

  @override
  String get checkVerificationStatus => 'Doğruladım, durumu yenile';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get signOutConfirmTitle => 'Çıkış yapmayı onayla';

  @override
  String get signOutConfirmBody => 'Çıkış yapmak istediğinize emin misiniz?';

  @override
  String get guestAccountBadge => 'Misafir oturumu';

  @override
  String get guestAccountNotice =>
      'Şu anda misafir olarak oturum açtınız. İlerlemenizi korumak ve hesabınızı cihazlar arasında kullanmak için bir e-posta bağlayın.';

  @override
  String get linkAccount => 'Hesabı e-posta ile kaydet';

  @override
  String get linkAccountTitle => 'E-posta hesabı bağla';

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
  String get retry => 'Yeniden dene';

  @override
  String get createFirstAreaTitle => 'İlk alanını oluştur';

  @override
  String get createFirstAreaSubtitle =>
      'Projelerini veya derslerini haritaya ekleyerek görsel olarak organize et.';

  @override
  String get createAreaButton => 'Alan Oluştur';

  @override
  String get newAreaTitle => 'Yeni Alan Oluştur';

  @override
  String get areaNameLabel => 'Alan Adı';

  @override
  String get areaNamePlaceholder => 'Örn: Mobil Uygulama Projesi';

  @override
  String get areaDescriptionLabel => 'Açıklama (İsteğe bağlı)';

  @override
  String get areaDescriptionPlaceholder => 'Alan hakkında kısa bilgi...';

  @override
  String get areaTypeLabel => 'Tür';

  @override
  String get typeProject => 'Proje';

  @override
  String get typeLesson => 'Ders';

  @override
  String get typeFreeform => 'Serbest';

  @override
  String get allFilter => 'Tümü';

  @override
  String get areaColorLabel => 'Renk';

  @override
  String get create => 'Oluştur';

  @override
  String get save => 'Kaydet';

  @override
  String get editMode => 'Düzenle';

  @override
  String get viewMode => 'Görüntüle';

  @override
  String get centerView => 'Görünümü Ortala';

  @override
  String get editModeBanner =>
      'Düzenleme Modu: Alanları sürükleyip tutamaçla boyutlandırabilirsiniz.';

  @override
  String get areaDetailTitle => 'Alan Ayrıntısı';

  @override
  String get createdAtLabel => 'Oluşturulma';

  @override
  String get editArea => 'Alanı Düzenle';

  @override
  String get deleteArea => 'Alanı Sil';

  @override
  String get deleteConfirmTitle => 'Alanı Silmek İstediğinize Emin Misiniz?';

  @override
  String get deleteConfirmBody =>
      'Bu alan ve haritadaki yerleşimi kalıcı olarak silinecektir. Bu işlem geri alınamaz.';

  @override
  String get delete => 'Sil';

  @override
  String get noDescription => 'Açıklama belirtilmemiş';

  @override
  String get areaNameRequired => 'Lütfen alan adı girin';

  @override
  String get noWorkspacesYet => 'Henüz bir alan oluşturmadınız';

  @override
  String get noWorkspacesSubtitle =>
      'Yeni bir proje veya ders ekleyerek çalışmalarınızı organize edin.';

  @override
  String get themeModeLight => 'Açık Tema';

  @override
  String get themeModeDark => 'Koyu Tema';

  @override
  String get tasksTitle => 'Görevler';

  @override
  String get studyStepsTitle => 'Çalışma Adımları';

  @override
  String get addTask => 'Görev Ekle';

  @override
  String get addStep => 'Adım Ekle';

  @override
  String get taskTitle => 'Görev Başlığı';

  @override
  String get stepTitle => 'Adım Başlığı';

  @override
  String get taskTitlePlaceholder => 'Görev başlığını girin';

  @override
  String get stepTitlePlaceholder => 'Adım başlığını girin';

  @override
  String get taskDescription => 'Açıklama (İsteğe bağlı)';

  @override
  String get taskDescriptionPlaceholder => 'Ayrıntıları yazın';

  @override
  String get taskStatus => 'Durum';

  @override
  String get taskPriority => 'Öncelik';

  @override
  String get dueDate => 'Son Tarih';

  @override
  String get noDueDate => 'Tarih Yok';

  @override
  String get selectDate => 'Tarih Seç';

  @override
  String get clearDate => 'Temizle';

  @override
  String get statusTodo => 'Yapılacak';

  @override
  String get statusInProgress => 'Devam Ediyor';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get priorityLow => 'Düşük';

  @override
  String get priorityMedium => 'Normal';

  @override
  String get priorityHigh => 'Yüksek';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterTodo => 'Yapılacak';

  @override
  String get filterInProgress => 'Devam Eden';

  @override
  String get filterCompleted => 'Tamamlanan';

  @override
  String get overdue => 'Gecikmiş';

  @override
  String get editTask => 'Görevi Düzenle';

  @override
  String get deleteTask => 'Görevi Sil';

  @override
  String get deleteTaskConfirmTitle =>
      'Görevi Silmek İstediğinize Emin Misiniz?';

  @override
  String get deleteTaskConfirmBody =>
      'Bu görev kalıcı olarak silinecektir. Bu işlem geri alınamaz.';

  @override
  String get noTasksYet => 'Henüz görev eklenmedi';

  @override
  String get noTasksSubtitle => 'Bu alan için ilk görevinizi ekleyin.';

  @override
  String get noStepsYet => 'Henüz çalışma adımı eklenmedi';

  @override
  String get noStepsSubtitle => 'Bu ders için ilk çalışma adımınızı ekleyin.';

  @override
  String taskProgress(int completed, int total, int percent) {
    return '$completed / $total tamamlandı (%$percent)';
  }

  @override
  String get deleteAreaHasTasksError =>
      'Bu alanda görevler bulunuyor. Alanı silmeden önce lütfen tüm görevleri silin.';

  @override
  String get deleteAreaTaskCheckFailed =>
      'Görev kontrolü yapılamadı. Güvenlik nedeniyle alan silinemedi.';

  @override
  String get taskTitleRequired => 'Lütfen görev başlığı girin';
}
