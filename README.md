# Tajvid yo'li

Qur'onni tajvid qoidalari bilan o'rganish ilovasi: arab alifbosidan tajvid kursigacha bosqichma-bosqich
darslar, tilovat audiosi va talaffuzni tekshiruvchi sun'iy intellekt. **O'zbek · English · العربية**.

| Qism | Papka | Tavsif |
|---|---|---|
| Mobil ilova | `lib/`, `android/`, `ios/` | Flutter (Android, iOS) |
| Reklama sayti | `website/` | Statik HTML/CSS/JS, 3D iPhone (Three.js) |
| Admin panel | `admin/` | Statik, Firebase'ga ulangan, faqat admin uchun |
| Server funksiyalari | `functions/` | Firebase Cloud Functions (AI, hisobni o'chirish, admin ro'yxati) |
| Xavfsizlik qoidalari | `firestore.rules`, `storage.rules` | Firestore va Storage |
| Joylash namunalari | `deploy/` | nginx sozlamasi |

## Imkoniyatlar
- Alifbo, harakatlar, so'z o'qish, harf ulanishi va tajvid kursi darslari, testlar
- Qur'on o'quvchi, sura kitobi, qidiruv, xatcho'plar, offline ishlash
- AI orqali talaffuzni tekshirish va ovoz orqali sura topish (Firebase AI Logic)
- Kunlik reja, streak, XP va sertifikat
- Avtomatik bildirishnomalar: kunlik eslatma, maslahatlar, juma xabari, streak himoyasi
- Ilova ichida fikr bildirish (yulduz + matn) — admin panelga tushadi
- Premium shisha (glass) dizayn, yorug'/qorong'i mavzu, RTL (arabcha) qo'llab-quvvatlash

## Ishga tushirish (ilova)
Talab: Flutter 3.44+ (Dart 3.3+), Android Studio yoki Xcode.

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

### Maxfiy sozlamalar (omborda YO'Q)
Quyidagi fayllar `.gitignore` da. Namunalarni nusxalab, o'zingiznikini to'ldiring:

| Fayl | Namuna | Nima uchun |
|---|---|---|
| `ai_config.json` | `ai_config.json.example` | Gemini sozlamalari (`--dart-define-from-file`) |
| `app_check_android_config.json` | `*.example` | Firebase App Check debug tokeni |
| `app_check_ios_config.json` | `*.example` | Firebase App Check debug tokeni |
| `android/key.properties` + `*.jks` | — | Release imzo kaliti |

```bash
flutter run --dart-define-from-file=ai_config.json
```

> **Imzo kalitini (`upload-keystore.jks`) zaxiralang.** Yo'qolsa, Google Play'dagi ilovani yangilab bo'lmaydi.

### Release yig'ish
```bash
flutter build apk --release --target-platform android-arm64   # ~40 MB, zamonaviy telefonlar
flutter build apk --release --split-per-abi                   # har bir arxitektura alohida
flutter build appbundle --release                             # Google Play uchun
```

## Firebase
Loyiha: `tajvi-yo-li`. Ishlatiladi: Authentication (email, Google, Apple), Firestore, Storage, Crashlytics,
App Check, AI Logic (Gemini), Functions.

```bash
firebase deploy --only firestore:rules     # Firestore qoidalari
firebase deploy --only functions           # Blaze tarifi kerak
```

Admin emaillari `firestore.rules` dagi `isAdmin()` ro'yxatida. Yangi admin qo'shish: emailni (kichik harflarda) ro'yxatga
qo'shib, qoidalarni qayta deploy qiling.

## Sayt va admin panel
```bash
cd website && python -m http.server 8790     # http://127.0.0.1:8790
cd admin   && python -m http.server 8800     # http://127.0.0.1:8800  (demo: ?demo=1)
```
- Sayt toza manzillarda ishlaydi (`/privacy/`, `/terms/`, ...), domen **ildizida** joylanishi kerak.
- Admin panelni saytdan **alohida** (masalan `boshqaruv.<domen>`) joylang va server darajasida yoping:
  qarang `deploy/nginx.example.conf`, `admin/README.md`, `website/README.md`.
- Katta `tajvid-yoli.apk` ni omborga emas, GitHub **Releases** ga qo'ying.

## Tuzilma
```
lib/
  core/        tema, l10n (uz/en/ar), router, servislar (bildirishnoma, AI), vidjetlar
  features/    auth, home, quran, lessons, ai_check, daily_plan, feedback, settings, ...
test/          vidjet va birlik testlari
functions/     Cloud Functions + testlar
website/       reklama sayti
admin/         admin panel
```

## Sifat nazorati
GitHub Actions (`.github/workflows/ci.yml`) har yuborishda ishga tushadi: `flutter analyze`, `flutter test`,
Cloud Functions testlari va sayt/admin JavaScript sintaksisi.

## Litsenziya
Barcha huquqlar himoyalangan. Qarang: [LICENSE](LICENSE).
