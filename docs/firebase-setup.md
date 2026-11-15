# Firebase Setup – TaskMapFlow

> **Status**: Firebase projesi kullanıcı tarafından oluşturulmuştur. Bekleyen işlem, gerçek project ID'nin teyit edilmesi ve iOS uygulamasının eklenmesidir.

## Bundle ID

**Aday**: `com.taskmapflow.app`

Bundle ID kesinleştirildikten sonra Firebase Console'a iOS uygulaması olarak eklenmelidir.

## Firebase Projesi

**Proje Adı**: taskmapflow
**Proje ID**: Kullanıcı tarafından oluşturulan mevcut projenin ID'si doğrulanacaktır.
**Mevcut Plan**: Spark (Ücretsiz Plan). Plan yükseltme yapılmamıştır.

## Firebase İstemci Yapılandırması ve Güvenlik Ayrımı

- **İstemci Yapılandırması (`GoogleService-Info.plist` / `google-services.json`)**:
  İstemci yapılandırma dosyaları herkese açık proje numarası, API anahtarı ve depolama kovası adı gibi istemci tanımlayıcılarını içerir. Bunlar **sunucu sırrı değildir** (Admin SDK servis hesabı anahtarı veya signing sertifikası gibi kritik sırlar ile aynı sınıfta tutulmaz).
  Buna rağmen, ortamlar arası karışıklığı önlemek ve temiz altyapı yönetimi için `.gitignore` içine alınmıştır.
  Uygulamanın asıl veri güvenliği istemci dosyasını saklamakla değil; **Firestore & Storage Security Rules** ve **Firebase App Check** ile sağlanır.

## iOS Uygulamasını Firebase'e Ekleme Adımları

1. [Firebase Console](https://console.firebase.google.com/)'a gidin ve mevcut `taskmapflow` projesini seçin.
2. Proje Ayarları → Uygulamalarınız → **Uygulama Ekle** → iOS seçin.
3. Bundle ID girin: `com.taskmapflow.app`
4. `GoogleService-Info.plist` dosyasını indirin.
5. **Xcode'da**: `GoogleService-Info.plist` dosyasını `Runner` grubunun içine sürükleyin. "Copy items if needed" seçeneğinin işaretli olduğundan ve hedefin `Runner` olduğundan emin olun.
6. Bu dosyayı git deposuna commit etmeyin (`.gitignore` ile hariç tutulmuştur).

## Hata Yönetimi ve Güvenli Sınıflandırma

Uygulama açılışında `main.dart` Firebase başlatmayı güvenli bir try-catch bloğu ile sarmalar:
- **Eksik Yapılandırma / Başlatma Hatası**: `GoogleService-Info.plist` bulunmadığında veya genel başlatma hatası oluştuğunda uygulama çökmek yerine kullanıcıya yerelleştirilmiş `_SetupRequiredScreen` ekranını sunar.
- Sessizce sahte (mock) bir backend'e geçilmez; kullanıcı ve geliştirici net bir şekilde kurulum yapılması gerektiğinden haberdar edilir.

## Gerekli Servisler ve Plan Gereksinimleri

| Servis | Plan | Durum & Notlar |
|---|---|---|
| Authentication | Spark | E-posta, Google, Apple (ücretsiz kotada) |
| Firestore | Spark | 1 GiB depolama, 50k okuma/gün, 20k yazma/gün (Deny-All kurallarıyla kilitli) |
| Storage | Spark | 5 GB depolama, 1 GB/gün indirme. Storage kuralları `firestore.get()` destekler. |
| Cloud Functions | **Blaze gerekli** | FCM bildirimleri, imzalı URL üretimi ve sunucu yetkilendirme işlemleri için Blaze gerekir. Aşama 1'de etkinleştirilmemiştir. |
| App Check | Spark / Blaze | Aşama 3 için planlanmıştır. |

## Yerel Emulator Altyapısı (Java Gereksinimi)

Firebase Emulator Suite'i (`firestore`, `storage`, `auth`) yerel makinede veya CI ortamında çalıştırmak için **Java Runtime Environment (JRE/JDK 11+)** gereklidir.
- CI üzerinde GitHub Actions `setup-java` (Temurin JDK 21) adımıyla emulator sorunsuz çalıştırılır.
- Yerel makinede Java kurulu değilse emulator çalıştırılamaz; geliştirici makinesine JDK kurulması gerekir.

```bash
# Emulator test çalıştırma komutu (gerçek Firebase'e bağlanmaz)
firebase emulators:exec \
  --only firestore,storage,auth \
  --project demo-taskmapflow \
  "cd test-rules && npm test"
```
