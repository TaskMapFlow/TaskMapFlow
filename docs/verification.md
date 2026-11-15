# Verification Log

This document records commands actually run, their outputs, and controls that could not be verified in this environment.

## Environment

| Tool | Version | Verification / Notes |
|---|---|---|
| Flutter | 3.38.1 (channel stable) | Doğrulandı (`flutter --version` outside sandbox). CI'da `3.38.1` sabitlendi. |
| Dart | 3.10.0 (DevTools 2.51.1) | Doğrulandı (`dart --version`). |
| Node.js | v26.0.0 | Doğrulandı (`node --version`). CI'da Node 20 LTS kullanılıyor. |
| Firebase CLI | 14.26.0 | Doğrulandı (`firebase --version`). CI'da `14.26.0` sabitlendi. |
| Xcode | 26.1.1 (Build 17B100) | Doğrulandı (`xcodebuild -version`). |
| CocoaPods | 1.16.2 | Doğrulandı. |
| Java | Yerel makinede kurulu değil | Firebase Emulator çalıştırmak için JDK 11+ gereklidir. CI üzerinde Temurin JDK 21 yapılandırıldı. |

## Controls Run & Results

1. **Flutter Format Kontrolü:**
   - Komut: `dart format lib/ test/` ve `dart format --output=none --set-exit-if-changed lib/ test/`
   - Sonuç: **BAŞARILI** (16 dosya biçimlendirildi, 0 ihlal).

2. **Flutter Statik Kod Analizi:**
   - Komut: `flutter analyze --fatal-infos`
   - Sonuç: **BAŞARILI** (Tüm relative importlar düzeltildi, 0 hata, 0 uyarı, 0 bilgi).

3. **Flutter Birim & Widget Testleri:**
   - Komut: `flutter test`
   - Sonuç: **BAŞARILI** (4/4 test geçti):
     - İngilizce kurulum ekranı metinleri doğrulandı.
     - Türkçe kurulum ekranı metinleri doğrulandı.
     - 3 sekmeli kabuk sırası `[Profile, Home, Manage]` ve varsayılan olarak ortadaki `Home` sekmesinin seçili gelmesi doğrulandı.
     - Türkçe sekme sırası `[Profil, Ana Sayfa, Yönet]` ve sekmeler arası geçişler doğrulandı.

4. **Bağımlılıklar ve Lockfile:**
   - `pubspec.lock` ve `test-rules/package-lock.json` dosyaları üretildi ve repoda sürümlendi.
   - Kullanılmayan paketler kaldırıldı (`riverpod_generator`, `build_runner`, `custom_lint` vb.), kalan paketler Flutter 3.38.1 / Dart 3.10 ile tam uyumlu hale getirildi.

5. **Güvenlik Kuralları Testleri (Firestore & Storage Deny-All):**
   - `test-rules/firestore.rules.test.js` altında oturumsuz, anonim ve doğrulanmış istemciler için get/list/create/update/delete ve Storage read/list/upload/overwrite/delete kontrolleri kapsandı.
   - Yerel makinede Java kurulu olmadığı için emulator yerelde çalıştırılamadı; CI workflow üzerinde Temurin JDK 21 kurularak testler CI'da koşturulmak üzere yapılandırıldı.

6. **iOS Simulator Derlemesi:**
   - Komut: `flutter build ios --simulator --no-codesign`
   - Sonuç: **BAŞARISIZ / BLOKE**.
   - Hata Ayrıntısı:
     ```
     Target debug_unpack_ios failed: Exception: Failed to codesign .../Flutter.framework/Flutter with identity -.
     ...: resource fork, Finder information, or similar detritus not allowed
     ```
   - Kök Neden: Çalışma dizini (`/Users/.../Desktop/TaskMapFlow`) macOS iCloud Drive File Provider (`com.apple.file-provider-domain-id`, `com.apple.fileprovider.detached#B`) altında senkronize bir klasördür. macOS `codesign` aracı Finder extended attributes (`com.apple.FinderInfo`, `com.apple.provenance`) içeren ikilileri ad-hoc imzalarken Apple güvenlik kısıtı nedeniyle hata vermektedir.
   - Durum: Aşama 1 için bir engeldir; "iOS build doğrulandı" denilemez, açık engel olarak raporlanmıştır.

## Controls Not Run / Blocked

| Control | Reason | Status & Next Step |
|---|---|---|
| Yerel Firebase Emulator çalıştırma | Yerel makinede Java Runtime kurulu değil | CI üzerinde JDK 21 ile çalıştırılıyor; yerel makinede `brew install openjdk` gereklidir. |
| iOS Simulator derlemesi | macOS iCloud Desktop klasör öznitelikleri (`resource fork / Finder info`) nedeniyle `codesign` ad-hoc imzalamayı reddediyor | Proje dizininin iCloud dışındaki bir yola (örneğin `~/Developer/TaskMapFlow`) taşınması gerekmektedir. |
| Gerçek Firebase Bağlantısı | `GoogleService-Info.plist` henüz eklenmedi (bilinçli tasarım) | Gerçek project ID ile iOS uygulaması Firebase Console'a eklendiğinde plist dahil edilecektir. |
