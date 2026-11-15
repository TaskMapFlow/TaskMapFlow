# Access Control – TaskMapFlow

> **Önemli Not**: Bu dokümandaki erişim matrisi ve rol tablosu, ileriki aşamalarda geliştirilecek özellikler için **tasarım hedefidir**.
> **Aşama 1'de uygulanan güvenlik kuralı**: `firestore.rules` ve `storage.rules` üzerinde **tüm istemci erişimlerini reddeden (Deny-All)** temel kurallardır. Henüz hiçbir kullanıcıya profil, çalışma alanı veya görev erişimi açılmamıştır.

## Tasarlanan Roller (Gelecek Aşamalar)

| Role | Scope | Description |
|---|---|---|
| owner | workspace | Created the workspace; full control |
| admin | workspace | Elevated privileges; assigned by owner |
| member | workspace | Standard participant |
| viewer | workspace | Read-only access |
| guest | app | Unauthenticated or anonymous; public content only |

## Tasarlanan Erişim Matrisi (Gelecek Aşamalar İçin Hedef)

| Resource | owner | admin | member | viewer | guest |
|---|---|---|---|---|---|
| Workspace settings | R/W | R | R | R | — |
| Workspace member list | R/W | R/W | R | R | — |
| Map nodes/edges (non-private) | R/W | R/W | R/W | R | — |
| Tasks (non-private) | R/W | R/W | R/W | R | — |
| **Private tasks** | own only | own only | own only | — | — |
| **Performance notes** | own user | — | — | — | — |
| Notes (non-private) | R/W | R/W | R/W | R | — |
| Private notes | own only | own only | own only | — | — |
| Sprint management | R/W | R/W | R | R | — |
| Files (team visibility) | R/W | R/W | R/W | R | — |
| **Files (private)** | uploader only | — | — | — | — |
| Public workspace content | R | R | R | R | R (read only) |
| Own user profile | R/W | — | — | — | — |
| Other user profile | R | R | R | R | — |

## Bilinen Güvenlik Riskleri ve Gelecek Güvenlik Tasarım Önlemleri

Önceki taslak kuralların incelenmesi sonucunda tespit edilen ve özellikler geliştirilirken mutlaka hedeflenmiş testlerle çözülmesi gereken riskler:

1. **Admin'in Kendini Owner Yapabilmesi Riski:**
   - *Risk*: `members` koleksiyonunda yetki güncellenirken, bir yöneticinin (admin) kendi üyelik belgesini güncelleyerek rolünü `owner` seviyesine yükseltmesi.
   - *Önlem*: Gelecek kurallarda `role` alanının değişimi sadece mevcut `owner` tarafından yapılabilir olmalı; admin'ler başka admin veya member ekleyebilse de `owner` atayamaz veya kendi rollerini değiştiremez.

2. **Alan (Field) ve createdBy / authorId Doğrulamasının Bulunmaması:**
   - *Risk*: Yeni bir görev veya harita düğümü oluşturulurken istemcinin `createdBy` alanına başka bir kullanıcının `uid` değerini yazabilmesi ve izinsiz veri sahipliği iddia edebilmesi.
   - *Önlem*: `request.resource.data.createdBy == request.auth.uid` zorunluluğu getirilmeli ve gerekli alan tipleri doğrulanmalıdır.

3. **Silme Kurallarında Üyelik Şartının Eksik Kalması:**
   - *Risk*: Görev veya düğüm silme kurallarında yalnızca `resource.data.createdBy == request.auth.uid` kontrolü yapılırsa, çalışma alanından çıkarılmış eski bir üye kendi oluşturduğu eski görevi dışarıdan silebilirdi.
   - *Önlem*: Silme işleminde mutlaka `isWorkspaceMember(workspaceId)` ve aktif üyelik koşulu aranmalıdır.

4. **Performans Notu Erişiminin Kesinleşmeden Kullanıcıya Açılması:**
   - *Risk*: Kurumsal veya eğitim ortamında performans notlarının kime ait olduğu ve kimlerin değerlendirme girebileceği iş kuralları netleşmeden kural açmak gizlilik ihlaline yol açabilir.
   - *Önlem*: Aşama 1'de tamamen kapalı tutulmuştur. İlgili özellik aşamasında katı sahip-özel kurallarıyla test edilecektir.

5. **Storage Rules ve Firestore Entegrasyonu:**
   - *Düzeltme*: Storage Rules, Firestore veritabanını okuyabilir (`firestore.get()` ve `firestore.exists()`). Gelecekte çalışma alanı dosyalarının izinleri kontrol edilirken Storage kuralları doğrudan Firestore'daki üyelik kayıtlarını sorgulayabilecektir. Ancak Aşama 1'de Storage kuralları tamamen kapalıdır (`deny-all`).

## Kritik Kurallar

**1. Workspace ownership ≠ access to other users' personal data.**
Owning or administering a workspace does NOT grant access to another user's performance notes, private tasks, or personal workspace content.

**2. Public content must not expose private fields.**
A workspace set to `visibility: 'public'` allows reading of public documents, but Firestore rules must ensure that documents with private fields (e.g., `isPrivate: true`) are excluded from public queries.

**3. Performance notes are strictly owner-only.**
`users/{userId}/performance_notes/` is readable and writable only by the user whose `userId` matches `request.auth.uid`.

**4. Private tasks are strictly creator-only.**
Tasks with `isPrivate: true` are readable only by `createdBy == request.auth.uid`.

**5. Invitation system integrity.**
The `invitedBy` field must be validated to match the authenticated sender's uid.

**6. Covert information leakage.**
Counters, notifications, and edge labels must not leak private task names or existence.

**7. Firestore rules are NOT query filters.**
Queries must be written to request only authorized documents.

**8. Admin SDK bypasses Security Rules.**
Server-side code using the Firebase Admin SDK (Cloud Functions) does not go through Security Rules; it must enforce its own authorization.
