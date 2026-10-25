# Xavfsizlik

Bu hujjat Tajvid yo'li loyihasining xavfsizlik holati, qabul qilingan choralar va **qo'lda bajariladigan** qadamlarni
tavsiflaydi. Zaiflik topsangiz, ochiq issue ochmang. Loyiha egasiga shaxsiy xabar yozing.

## Himoya qatlamlari

| Soha | Chora |
|---|---|
| **Sirlar** | Server kalitlari (Groq) faqat Cloud Functions'da (`defineSecret`). Ilovada AI kaliti yo'q (Firebase AI Logic). Imzo kaliti, `ai_config.json`, App Check tokenlari `.gitignore` da. Git tarixida sir topilmadi |
| **Firestore qoidalari** | Standart bo'yicha yopiq. Foydalanuvchi faqat o'z hujjatini o'qiydi/yozadi, maydonlar qat'iy tekshiriladi. 28 ta emulyator testi (`firestore-tests/`), CI'da har yuborishda |
| **Admin** | Email bilan emas, **UID** bilan aniqlanadi (`isAdmin()`), brauzer kodida admin ma'lumoti yo'q. Faqat Console'da yaratilgan hisob. Hisob ochish yo'q |
| **Mulohazalar** | Foydalanuvchi faqat yozadi (o'qiy olmaydi). **Server tomonida tezlik cheklovi**: 60 soniyada bittadan (`feedbackMeta`) |
| **Kirish (ilova)** | Firebase Auth throttling + qurilmada o'sib boruvchi bloklash (5 xatodan keyin 30 s, 15 daqiqagacha). Parol: 8+ belgi, harf+raqam, keng tarqalgan parollar taqiqlangan. Xatolar hisob mavjudligini oshkor qilmaydi |
| **Kirish (admin)** | Brauzer darajasida o'sib boruvchi bloklash + umumiy xabarlar. Admin hisobi uchun email tasdiqlash shart emas (UID himoyasi) |
| **AI** | Ilova Firebase AI Logic ishlatadi (kalit ilovada yo'q); uni App Check bilan **qo'lda majburiy** qiling (pastga qarang). `functions/` dagi `tajvidAi` kodida App Check majburiy, kvota (kuniga 30, daqiqasiga 4), kirish va hajm tekshiruvi bor, lekin hali deploy qilinmagan |
| **Veb** | CSP, HSTS, `X-Frame-Options`, `nosniff`, `Referrer-Policy`, `Permissions-Policy`. Admin: `noindex`, kesh yo'q |
| **Android** | HTTPS majburiy, `allowBackup=false`, backup'dan ma'lumot chiqarilmaydi, R8/proguard yoqilgan, faqat bitta `exported` activity |

## Qo'lda bajariladigan qadamlar (kodda qilib bo'lmaydi)

1. **API kalit cheklovlari** — Google Cloud Console → APIs & Services → Credentials:
   - Android kaliti: *Android apps* (paket `com.tajvid_yoli` va SHA-1) bilan cheklang.
   - iOS kaliti: *iOS apps* (bundle ID) bilan cheklang.
   - Web kaliti (admin paneldagi): *HTTP referrers* — admin panel manzili va `localhost`.
2. **App Check majburiy** — Firebase Console → App Check → har bir xizmat (Firestore, Storage, AI Logic) uchun **Enforce**.
   Busiz Gemini (AI Logic) so'rovlarini kalitni bilgan har kim yuborishi mumkin.
3. **AI Logic foydalanuvchi limiti** — Firebase Console → AI Logic → Settings → *per-user rate limit* ni pasaytiring.
4. **Parol siyosati** — Authentication → Settings → *Password policy*: kamida 8 belgi, harf va raqam talab qiling.
5. **Email enumeration protection** — Authentication → Settings → yoqing (hisob mavjudligini sezdirmaydi).
6. **Admin parolini** kuchli (16+ belgi) qiling, parol menejerida saqlang.
7. **Vercel Firewall** — admin loyihada faqat o'zingizning IP'ingizga ruxsat qoidasini qo'shing.
8. **Gemini kaliti** — mahalliy `ai_config.json` dagi `GEMINI_API_KEY` ilovada ishlatilmaydi. Uni Google AI Studio'da
   **o'chiring (revoke)** va faylni tozalang.
9. **Cloud Functions** hali deploy qilinmagan (Blaze tarifi kerak). Deploy qilinmaguncha hisobni o'chirish funksiyasi
   ishlamaydi. Play Store talabi sababli chiqarishdan oldin deploy qiling: `firebase deploy --only functions`.

## Ma'lum, qabul qilingan xavflar

- `functions/` da 9 ta *moderate* tranzitiv zaiflik qoldi (asosan `uuid`); ularni yopish `firebase-admin` 14 ga
  **breaking** yangilashni talab qiladi. Kodimiz zaif funksiyalardan foydalanmaydi. Reja: Blaze'ga o'tganda yangilash.
- Saytdagi forma tasodifiy FormSubmit identifikatori orqali ishlaydi; spamga qarshi honeypot va 30 soniyalik cheklov bor.
- Firebase web/mobil API kalitlari (`google-services.json`, `firebase_options.dart`) maxfiy emas (Firebase dizayni),
  himoya qoidalar va App Check orqali. Repo private.
