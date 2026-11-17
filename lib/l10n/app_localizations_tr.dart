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

  @override
  String get viewTasks => 'Görevler';

  @override
  String get viewBacklog => 'Backlog';

  @override
  String get viewSprints => 'Sprintler';

  @override
  String get createSprint => 'Sprint Oluştur';

  @override
  String get editSprint => 'Sprinti Düzenle';

  @override
  String get sprintName => 'Sprint Adı';

  @override
  String get sprintGoal => 'Sprint Hedefi (isteğe bağlı)';

  @override
  String get startDate => 'Başlangıç Tarihi';

  @override
  String get endDate => 'Bitiş Tarihi';

  @override
  String get sprintStatusPlanned => 'Planlandı';

  @override
  String get sprintStatusActive => 'Aktif';

  @override
  String get sprintStatusCompleted => 'Tamamlandı';

  @override
  String get startSprint => 'Sprinti Başlat';

  @override
  String get completeSprint => 'Sprinti Bitir';

  @override
  String get deleteSprint => 'Sprinti Sil';

  @override
  String get assignToSprint => 'Sprinte Ata';

  @override
  String get moveToBacklog => 'Backlog\'a Al';

  @override
  String get noSprintsYet => 'Henüz sprint oluşturulmadı';

  @override
  String get noSprintsSubtitle =>
      'Görevlerinizi zaman dilimlerine ayırmak için bir sprint oluşturun.';

  @override
  String get noBacklogTasks => 'Backlog\'da görev bulunmuyor';

  @override
  String get noBacklogTasksSubtitle =>
      'Herhangi bir sprinte atanmamış tüm görevler burada listelenir.';

  @override
  String get dateOrderError => 'Bitiş tarihi başlangıç tarihinden önce olamaz.';

  @override
  String get completeSprintConfirmTitle => 'Sprinti Bitir';

  @override
  String completeSprintPrompt(int count) {
    return 'Tamamlanmamış $count görev var. Bu görevler ne yapılsın?';
  }

  @override
  String get moveIncompleteToBacklog => 'Backlog\'a Taşı';

  @override
  String get keepInSprint => 'Sprintte Bırak';

  @override
  String deleteSprintWithTasksConfirm(int count) {
    return 'Bu sprintte $count görev bulunuyor. Görevler ne yapılsın?';
  }

  @override
  String get moveTasksToBacklogAndDelete => 'Görevleri Backlog\'a Al ve Sil';

  @override
  String get sprintActiveBadge => 'Aktif Sprint';

  @override
  String get subtasksTitle => 'Alt Görevler';

  @override
  String get addSubtask => 'Alt görev ekle...';

  @override
  String get subtaskLimitReached => 'En fazla 20 alt görev eklenebilir.';

  @override
  String get connectAreas => 'Bağlantı Kur';

  @override
  String get connectingModeHint => 'Bağlamak istediğiniz hedef alanı seçin';

  @override
  String get connectionType => 'Bağlantı Türü';

  @override
  String get connectionRelated => 'İlişkili';

  @override
  String get connectionRelatedDesc => 'İki alan birbirleriyle bağlantılıdır.';

  @override
  String get connectionBlocks => 'Tamamlanmasını bekliyor';

  @override
  String get connectionBlocksDesc =>
      'Bu alan tamamlanmadan hedef alan başlayamaz.';

  @override
  String get deleteConnection => 'Bağlantıyı Sil';

  @override
  String get deleteConnectionConfirm =>
      'Bu bağlantıyı silmek istediğinize emin misiniz?';

  @override
  String blockedByDependencyWarning(String name) {
    return '$name tamamlanması bekleniyor';
  }

  @override
  String get duplicateConnectionError =>
      'Bu iki alan arasında zaten bir bağlantı mevcut.';

  @override
  String get selfConnectionError => 'Bir alan kendisine bağlanamaz.';

  @override
  String get tabWork => 'Çalışma';

  @override
  String get tabNotes => 'Notlar';

  @override
  String get tabInfo => 'Bilgiler';

  @override
  String get quickNotesTitle => 'Hızlı Notlar';

  @override
  String get addNote => 'Not Ekle';

  @override
  String get editNote => 'Notu Düzenle';

  @override
  String get noteTitleLabel => 'Başlık (İsteğe bağlı)';

  @override
  String get noteContentLabel => 'İçerik';

  @override
  String get noteContentPlaceholder => 'Notunuzu buraya yazın...';

  @override
  String get noteTitlePlaceholder => 'Not başlığı...';

  @override
  String get noNotesYet => 'Henüz not eklenmemiş.';

  @override
  String get noNotesSub =>
      'Bu alana dair düşünce ve bağlantılarını buraya not et.';

  @override
  String get loadMore => 'Daha fazla';

  @override
  String get deleteNoteConfirmTitle => 'Notu Sil';

  @override
  String get deleteNoteConfirmMessage =>
      'Bu notu silmek istediğinize emin misiniz?';

  @override
  String get noteUpdated => 'Güncellendi';

  @override
  String get tagsTitle => 'Etiketler';

  @override
  String get addTag => 'Etiket Ekle';

  @override
  String get tagPlaceholder => 'Örn: react, matematik, mobil...';

  @override
  String get tagLimitReached => 'En fazla 20 etiket eklenebilir.';

  @override
  String get tagLengthExceeded => 'Etiket en fazla 30 karakter olabilir.';

  @override
  String get resourcesTitle => 'Kaynak Bağlantıları';

  @override
  String get addResource => 'Kaynak Ekle';

  @override
  String get editResource => 'Kaynağı Düzenle';

  @override
  String get resourceTitleLabel => 'Kaynak Başlığı';

  @override
  String get resourceTitlePlaceholder => 'Örn: GitHub Deposu, Ders Notları...';

  @override
  String get resourceUrlLabel => 'Bağlantı Adresi (http/https)';

  @override
  String get resourceUrlPlaceholder => 'https://...';

  @override
  String get invalidUrlError =>
      'Lütfen geçerli bir http veya https adresi girin.';

  @override
  String get noResourcesYet => 'Henüz kaynak bağlantısı eklenmemiş.';

  @override
  String get deleteResourceConfirmTitle => 'Kaynağı Sil';

  @override
  String get deleteResourceConfirmMessage =>
      'Bu kaynak bağlantısını silmek istediğinize emin misiniz?';

  @override
  String get deleteAreaHasContentError =>
      'Bu çalışma alanında görevler, sprintler veya notlar bulunuyor. Alanı silmeden önce lütfen bunları temizleyin.';

  @override
  String get urlLaunchError => 'Bağlantı açılamadı.';

  @override
  String get saveInfo => 'Bilgileri Kaydet';

  @override
  String get infoSavedSuccess => 'Bilgiler güncellendi.';

  @override
  String get archivedAreasTitle => 'Arşiv';

  @override
  String get noArchivedAreasYet => 'Arşivlenmiş alan bulunmuyor.';

  @override
  String get noArchivedAreasSubtitle =>
      'Arşivlediğiniz alanlar burada listelenir ve salt okunur olarak saklanır.';

  @override
  String get archiveArea => 'Alanı Arşivle';

  @override
  String get archiveAreaConfirmTitle => 'Alanı Arşivle';

  @override
  String get archiveAreaConfirmBody =>
      'Bu alanı arşivlemek istediğinize emin misiniz? Arşivlenen alan ana haritadan gizlenir ve salt okunur hâle gelir. Dilediğiniz zaman Profil > Arşiv bölümünden geri yükleyebilirsiniz.';

  @override
  String get restoreArea => 'Alanı Geri Yükle';

  @override
  String get restoreAreaConfirm =>
      'Bu alanı arşivden geri yüklemek istediğinize emin misiniz?';

  @override
  String get areaArchivedBadge => 'Arşivde';

  @override
  String get areaArchivedNotice => 'Bu alan arşivlenmiştir ve salt okunurdur.';

  @override
  String get archivedAtLabel => 'Arşivlenme tarihi';

  @override
  String get connectedAreaArchivedWarning => 'Bağlı alan arşivde';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get profileNameLabel => 'Ad Soyad';

  @override
  String get profileNamePlaceholder => 'Adını ve soyadını gir';

  @override
  String get profileNameEmptyError => 'Lütfen adınızı girin';

  @override
  String get profileBioLabel => 'Biyografi';

  @override
  String get profileBioPlaceholder => 'Kendinden kısaca bahset...';

  @override
  String get githubUrlLabel => 'GitHub Profili';

  @override
  String get githubUrlPlaceholder => 'https://github.com/kullaniciadi';

  @override
  String get invalidGithubUrlError =>
      'Lütfen geçerli bir GitHub adresi girin (yalnızca https://github.com/...)';

  @override
  String get profileSavedSuccess => 'Profil kaydedildi.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get languageSetting => 'Dil';

  @override
  String get themeSetting => 'Tema';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get teamSectionTitle => 'Ekip';

  @override
  String get enableTeamTitle => 'Ekip Çalışmasını Etkinleştir';

  @override
  String get enableTeamDescription =>
      'Ekip çalışmasını etkinleştirdiğinizde, bu alandaki mevcut ve yeni görevler, notlar ve içerikler alana katılan üyeler tarafından görüntülenebilir hale gelecektir. Onaylıyor musunuz?';

  @override
  String get enableTeamButton => 'Ekip Çalışmasını Başlat';

  @override
  String get teamEnabledSuccess => 'Ekip çalışması etkinleştirildi.';

  @override
  String get membersTitle => 'Ekip Üyeleri';

  @override
  String get memberRoleOwner => 'Sahip';

  @override
  String get memberRoleAdmin => 'Yönetici';

  @override
  String get memberRoleMember => 'Üye';

  @override
  String get makeAdmin => 'Yönetici Yap';

  @override
  String get removeAdmin => 'Yöneticiliği Kaldır';

  @override
  String get removeMember => 'Üyeyi Çıkar';

  @override
  String get removeMemberConfirm =>
      'Bu üyeyi ekipten çıkarmak istediğinize emin misiniz?';

  @override
  String get leaveTeam => 'Ekipten Ayrıl';

  @override
  String get leaveTeamConfirm =>
      'Bu alandan ayrılmak istediğinize emin misiniz? Oluşturduğunuz içerikler korunacaktır.';

  @override
  String get noLongerOnTeam => 'Artık ekipte değil';

  @override
  String get inviteMember => 'Üye Davet Et';

  @override
  String get inviteCodeTitle => 'Davet Kodu';

  @override
  String get inviteCodeDescription =>
      'Bu kod tek kullanımlıktır ve 7 gün geçerlidir. Katılacak kişiye iletin:';

  @override
  String get copyCode => 'Kodu Kopyala';

  @override
  String get codeCopied => 'Davet kodu kopyalandı.';

  @override
  String get joinWithCode => 'Davet Koduyla Katıl';

  @override
  String get enterInviteCode => 'Davet Kodunu Girin';

  @override
  String get inviteCodePlaceholder => '8 karakterli davet kodu';

  @override
  String get joinButton => 'Katıl';

  @override
  String get joinSuccess => 'Çalışma alanına başarıyla katıldınız!';

  @override
  String get joinedWorkspaces => 'Katıldığım Alanlar';

  @override
  String get myWorkspaces => 'Alanlarım';

  @override
  String get assignedToMe => 'Bana Atananlar';

  @override
  String get assignee => 'Sorumlu';

  @override
  String get unassigned => 'Atanmamış';

  @override
  String get assignToMe => 'Kendime Ata';

  @override
  String get filterAssignedToMe => 'Bana Atananlar';

  @override
  String get noAssignedTasks => 'Size atanmış görev bulunmuyor.';

  @override
  String get noJoinedWorkspaces => 'Henüz katıldığınız bir ekip alanı yok.';

  @override
  String get guestJoinWarning =>
      'Misafir kullanıcılar ekip davetlerini kabul edemez. Lütfen önce profil ekranından bir hesap bağlayın veya kayıt olun.';

  @override
  String get mapView => 'Harita';

  @override
  String get overviewView => 'Genel Bakış';

  @override
  String get dailySummaryTitle => 'Günlük Çalışma Özeti';

  @override
  String get todayTasks => 'Bugün';

  @override
  String get overdueTasks => 'Gecikmiş';

  @override
  String get upcomingTasks => 'Önümüzdeki 7 Gün';

  @override
  String get inProgressTasks => 'Devam Eden';

  @override
  String get activeWorkspaces => 'Aktif Alanlar';

  @override
  String seeAll(int count) {
    return 'Tümünü Gör ($count)';
  }

  @override
  String get showLess => 'Daha Az Göster';

  @override
  String get searchWorkspacesPlaceholder => 'Alan ara...';

  @override
  String get noMatchingWorkspaces => 'Eşleşen alan bulunamadı.';

  @override
  String get dailySummaryEmptyTitle => 'Henüz görev veya alan yok';

  @override
  String get dailySummaryEmptySubtitle =>
      'Planlarını yönetmek için ilk alanını oluştur ve görevlerini ekle.';

  @override
  String get allClearTitle => 'Her şey yolunda!';

  @override
  String get allClearSubtitle =>
      'Bugün veya geciken bekleyen görev bulunmuyor.';

  @override
  String partialSummaryNotice(int count, int total) {
    return 'Özet en son $count aktif alanınızı gösterir (toplam $total alan).';
  }

  @override
  String partialFailedAreasWarning(int count) {
    return '$count alanın görevleri yüklenemedi.';
  }

  @override
  String get tabStudyPlan => 'Çalışma Planı';

  @override
  String get topicsTitle => 'Konular';

  @override
  String get studySessionsTitle => 'Çalışma Oturumları';

  @override
  String get topicProgress => 'Konu İlerlemesi';

  @override
  String completedTopicsCount(int completed, int total, int percent) {
    return '$completed / $total konu tamamlandı (%$percent)';
  }

  @override
  String get addTopic => 'Konu Ekle';

  @override
  String get editTopic => 'Konuyu Düzenle';

  @override
  String get deleteTopic => 'Konuyu Sil';

  @override
  String get deleteTopicConfirmTitle => 'Konuyu Sil';

  @override
  String get deleteTopicConfirmBody =>
      'Bu konuyu silmek istediğinizden emin misiniz? İlişkili çalışma oturumları silinmeyecektir.';

  @override
  String get topicTitleLabel => 'Konu Başlığı';

  @override
  String get topicTitlePlaceholder => 'Örn. Türev ve İntegral Giriş';

  @override
  String get topicDescLabel => 'Açıklama (İsteğe bağlı)';

  @override
  String get topicStatusNotStarted => 'Başlanmadı';

  @override
  String get topicStatusInProgress => 'Çalışılıyor';

  @override
  String get topicStatusCompleted => 'Tamamlandı';

  @override
  String get emptyTopics =>
      'Henüz konu eklenmedi. Konuları ekleyerek ders çalışma planınızı oluşturun.';

  @override
  String get planSession => 'Oturum Planla';

  @override
  String get editSession => 'Oturumu Düzenle';

  @override
  String get deleteSession => 'Oturumu Sil';

  @override
  String get deleteSessionConfirmTitle => 'Çalışma Oturumunu Sil';

  @override
  String get deleteSessionConfirmBody =>
      'Bu çalışma oturumunu silmek istediğinizden emin misiniz?';

  @override
  String get sessionTitleLabel => 'Oturum Başlığı';

  @override
  String get sessionTitlePlaceholder => 'Örn. Soru Çözümü - Limit';

  @override
  String get sessionDateLabel => 'Tarih';

  @override
  String get sessionTimeLabel => 'Başlangıç Saati';

  @override
  String get sessionPlannedDurationLabel => 'Planlanan Süre (Dakika)';

  @override
  String get sessionTopicLabel => 'Konu (İsteğe bağlı)';

  @override
  String get noTopicSelected => 'Konu Yok (Genel Çalışma)';

  @override
  String get deletedTopic => 'Silinmiş Konu';

  @override
  String get upcomingSessions => 'Yaklaşan Oturumlar';

  @override
  String get pastSessions => 'Geçmiş Oturumlar';

  @override
  String get emptySessions => 'Henüz planlanmış çalışma oturumu yok.';

  @override
  String plannedDurationText(int minutes) {
    return 'Planlanan: $minutes dk';
  }

  @override
  String actualDurationText(int minutes) {
    return 'Gerçekleşen: $minutes dk';
  }

  @override
  String get markSessionCompleted => 'Tamamlandı Olarak İşaretle';

  @override
  String get markSessionUncompleted => 'Tamamlanmadı Olarak İşaretle';

  @override
  String get completeSessionDialogTitle => 'Oturumu Tamamla';

  @override
  String get actualDurationLabel => 'Gerçekleşen Süre (dk, İsteğe bağlı)';

  @override
  String get reflectionNotesLabel => 'Değerlendirme Notu (İsteğe bağlı)';

  @override
  String get reflectionNotesPlaceholder =>
      'Bu oturumda neler öğrendin, nerede zorlandın?';

  @override
  String get sessionPlannedStatus => 'Planlandı';

  @override
  String get sessionCompletedStatus => 'Tamamlandı';

  @override
  String get sessionPastPlannedStatus => 'Planlandı (Geçmiş)';

  @override
  String get fieldRequired => 'Bu alan zorunludur';

  @override
  String get descriptionLabel => 'Açıklama';

  @override
  String get statusLabel => 'Durum';

  @override
  String get taskViewList => 'Liste';

  @override
  String get taskViewBoard => 'Pano';

  @override
  String get kanbanColumnTodo => 'Yapılacak';

  @override
  String get kanbanColumnInProgress => 'Devam Ediyor';

  @override
  String get kanbanColumnCompleted => 'Tamamlandı';

  @override
  String get emptyKanbanColumn => 'Görev yok';

  @override
  String get changeStatus => 'Durumu Değiştir';

  @override
  String sprintBoardTitle(String name) {
    return '$name Panosu';
  }

  @override
  String get viewSprintBoard => 'Pano';

  @override
  String get manageViewWorkspaces => 'Alanlar';

  @override
  String get manageViewCalendar => 'Takvim';

  @override
  String get jumpToToday => 'Bugün';

  @override
  String get agendaTitle => 'Gündem';

  @override
  String get showCompleted => 'Tamamlananları Göster';

  @override
  String get hideCompleted => 'Tamamlananları Gizle';

  @override
  String get noCalendarEventsTitle => 'Planlanmış etkinlik yok';

  @override
  String get noCalendarEventsSubtitle =>
      'Bu tarihte planlanmış bir görev veya çalışma oturumu bulunmuyor.';

  @override
  String get entryTypeTask => 'Görev';

  @override
  String get entryTypeStudySession => 'Çalışma Oturumu';

  @override
  String get dueDatePrefix => 'Son teslim';

  @override
  String get startTimePrefix => 'Başlangıç';

  @override
  String durationMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String partialCalendarWarning(int failedCount) {
    return 'Bazı alanların verileri yüklenemedi ($failedCount alan).';
  }
}
