# Tajvid yo'li — Admin panel

iOS "glass" uslubidagi statik panel: kim, qachon va **qaysi usulda** (Google / Apple / Email) ro'yxatdan o'tganini ko'rsatadi.
Build kerak emas. Firebase Hosting'ga **joylash shart emas** — avval o'z kompyuteringizda ishlating.

## Demo (Firebase'siz)
```bash
cd admin
python -m http.server 8800
```
`http://localhost:8800/?demo=1` — soxta, namunaviy ma'lumotlar bilan ko'rinishni ko'ring.

## Haqiqiy ma'lumotga ulash
1. **Web ilova yarating** (bepul): Firebase Console → Project settings → Your apps → Add app → **Web**.
   Ko'rsatilgan `apiKey` va `appId` ni `js/config.js` ga yozing (loyiha hozir faqat Android/iOS ilovalarga ega).
2. `js/config.js` da `adminEmails` ga o'z **Gmail** manzilingizni yozing.
3. `../firestore.rules` dagi `admin-emailni-shu-yerga-yozing@example.invalid` ni o'sha Gmail (kichik harflarda) bilan almashtiring va deploy qiling:
   `firebase deploy --only firestore:rules`
4. Authentication → Settings → **Authorized domains** — `localhost` tayyor; boshqa joyga qo'ysangiz domenni qo'shing.
5. **Admin hisobini Firebase Console'da yarating:** Authentication → Users → **Add user** (email = `adminEmails` dagi, parolni o'zingiz tanlang). Panelning o'zida hisob yaratib bo'lmaydi.
6. `http://localhost:8800` ni oching → email va parol bilan kiring. Console'da yaratilgan hisob "tasdiqlanmagan" bo'ladi: panel tasdiqlash xatini yuborish tugmasini ko'rsatadi; xatdagi havolani bosing.

### To'liq ro'yxat (ixtiyoriy, Blaze tarifi)
Firestore rejimi faqat profilini to'ldirgan foydalanuvchilarni ko'rsatadi (email bilan ro'yxatdan o'tib tasdiqlamaganlarni ko'rsatmaydi).
Hammasini ko'rish uchun: `functions/.env` ga `ADMIN_EMAILS=siz@gmail.com` yozing, `js/config.js` da `source: "functions"` qiling va
`firebase deploy --only functions:tajvid:adminListUsers`.

## Xavfsizlik
- Kirish: faqat tasdiqlangan Google email + admin ro'yxati. **Haqiqiy himoya** — Firestore qoidasidagi `isAdmin()` va Function'dagi tekshiruv; `config.js` dagi ro'yxat faqat interfeys uchun.
- Panel faqat O'QIYDI, hech narsani o'zgartirmaydi/o'chirmaydi.
- Sahifa `noindex`. Foydalanuvchi ma'lumotlari shaxsiy — panelni ommaga ochiq joyga qo'ymang.
