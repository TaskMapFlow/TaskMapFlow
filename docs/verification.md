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
| CocoaPods | 1.16.2 | Doğrulandı (`pod install` UTF-8 locale ile tamamlandı). |
| Java | Yerel makinede kurulu değil | Firebase Emulator çalıştırmak için JDK 11+ gereklidir. CI üzerinde Temurin JDK 21 yapılandırıldı. |
| Çalışma Dizini | `~/Developer/TaskMapFlow` | macOS iCloud File Provider dışındaki yerel APFS çalışma klasörü. |

## Controls Run & Results (Aşama 2A)

1. **Flutter Format Kontrolü:**
   - Komut: `dart format --output=none --set-exit-if-changed lib/ test/`
   - Sonuç: **BAŞARILI** (35 dosya incelendi, 0 ihlal).

2. **Flutter Statik Kod Analizi:**
   - Komut: `flutter analyze --fatal-infos`
   - Sonuç: **BAŞARILI** (0 hata, 0 uyarı, 0 bilgi).

3. **Flutter Birim & Widget Testleri:**
   - Komut: `flutter test --coverage`
   - Sonuç: **BAŞARILI** (45/45 test geçti):
     - `auth_models_test`: AuthUser ve tüm AuthStatus durum eşitlikleri.
     - `auth_controller_test`: E-posta/şifre, misafir, hesap bağlama, şifre sıfırlama, durum yenileme, çıkış.
     - `login_screen_test`: E-posta/şifre girişi, form doğrulaması, hata mesajı yerelleştirmesi, misafir girişi, dil seçimi (TR/EN dinamik geçişi).
     - `register_screen_test`: Form doğrulaması (ad, soyad, e-posta, min 6 karakter parola, parola eşleşmesi), kayıt akışı, e-posta kullanımda hatası.
     - `verify_email_screen_test`: Doğrulama e-postası bildirimi, cooldown sayacı, durum yenileme, çıkış yapma.
     - `link_account_screen_test`: Misafir oturumundan kalıcı hesaba geçişte UID korunması, e-posta çakışması durumunda otomatik birleştirmeyi reddedip güvenli yönlendirme sunulması.
     - `router_auth_guard_test`: `AuthInitial` (splash yükleme, ana ekran parlamaması), `AuthUnauthenticated` (`/login`), `AuthUnverified` (`/verify-email`), `AuthGuest` (3 sekme + link), çıkış sonrası korunan ekranlara geri dönülememesi.
     - `widget_test`: Kurulum ekranı ve 3 sekmeli kabuk seyrüseferi (EN/TR).

4. **iOS Simulator Derlemesi:**
   - Komut: `flutter build ios --simulator --no-codesign`
   - Çalışma Dizini: `~/Developer/TaskMapFlow`
   - Sonuç: **BAŞARILI** (`✓ Built build/ios/iphonesimulator/Runner.app` 27.3s).
   - Not: Proje `~/Developer/TaskMapFlow` konumuna taşındığı için önceki iCloud Desktop extended attribute kısıtı çözülmüştür.

5. **iOS Simulator Uygulama Açılışı:**
   - Komut: `xcrun simctl install booted build/ios/iphonesimulator/Runner.app && xcrun simctl launch booted com.taskmapflow.taskMapFlow`
   - Sonuç: **BAŞARILI** (PID 6960 olarak başlatıldı).

6. **Firebase Auth Emulator Testleri (CI):**
   - Dosya: `test-rules/auth.emulator.test.js`
   - Kapsam: Auth emulator üzerinde kullanıcı oluşturma, anonim misafir oturumu, UID korunarak hesap bağlama, e-posta çakışması ve auth sonrası Firestore/Storage deny-all kurallarının korunması.
   - CI Entegrasyonu: `.github/workflows/ci.yml` üzerinde `firebase emulators:exec --only auth,firestore,storage "cd test-rules && npm run test:auth"` adımıyla açık ve ayrı bir komut olarak yapılandırıldı.

7. **Güvenlik Kuralları (Firestore & Storage Deny-All):**
   - Dosya: `firestore.rules`, `storage.rules`, `test-rules/firestore.rules.test.js`
   - Postür: Deny-all kuralları KORUNDU; kimlik doğrulamasının başarılı olması veri erişimi açmamaktadır.

## Controls Not Run / Blocked / Pending

| Control | Reason | Status & Next Step |
|---|---|---|
| Yerel Firebase Emulator çalıştırma | Yerel makinede Java Runtime (JDK) kurulu değil | CI üzerinde Temurin JDK 21 ile otomatik koşturulmaktadır. Yerel çalıştırma için `brew install openjdk` önerilir. |
| Gerçek Firebase Manuel Giriş | Firebase Console üzerinde test kullanıcı hesabı henüz manuel oluşturulmadı | Otomatik testler Emulator ve FakeRepository ile doğrulanmıştır. Gerçek Firebase manuel testi kullanıcı hesabı oluşturulduktan sonra yapılmalıdır. |
| App Check Üretim Zorlaması | Phase 3 planı kapsamında | Geliştirme/Simulator ortamında bypass edilip sessizce devrede sayılmamış, release checklist'te takip edilmektedir. |
| Apple/Google Girişi & Hesap Silme | Kapsam dışı / Sonraki Aşama | Release checklist'inde App Store yayın engeli olarak işaretlendi. |
