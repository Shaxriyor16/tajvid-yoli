# Tajvid yo'li — sayt

Statik sayt (HTML/CSS/JS, build kerak emas). Sahifalar toza manzilda: `/`, `/privacy/`, `/terms/`,
`/delete-account/` (har biri o'z papkasidagi `index.html`), xato sahifasi `404.html`. Manzilda `.html` ko'rinmaydi;
eski `.html` manzillar `_redirects` (Netlify/Cloudflare) yoki `deploy/nginx.example.conf` orqali yo'naltiriladi.
Havolalar `/` bilan boshlanadi, shuning uchun sayt domen ildizida (yoki `python -m http.server` da) ochilishi kerak.

## Mahalliy ko'rish
```bash
cd website
python -m http.server 8790
# http://127.0.0.1:8790
```

## Joylash
Sayt statik (build kerak emas), hajmi taxminan 1.5 MB, shuning uchun istalgan bepul statik hostingga
`website/` papkasini yuklash yetadi (masalan Cloudflare Pages, GitHub Pages, Netlify). `firebase.json` da
hosting sozlamasi YO'Q (ataylab olib tashlangan).
Joylashdan keyin hosting panelida o'z domeningizni (masalan tajvidyoli.uz) ulang.

## Admin panelni yopish
`admin/` ni reklama saytidan ALOHIDA joyga (masalan `boshqaruv.tajvidyoli.uz`) qo'ying va havolani saytda bermang.
`admin/_headers` va `admin/robots.txt` qidiruv tizimlariga ko'rsatmaydi. Qo'shimcha eshik: Cloudflare Access (email kodi)
yoki nginx parol/IP (`deploy/nginx.example.conf`). Haqiqiy himoya baribir Firestore qoidalari va admin emaili.

## APK
`downloads/tajvid-yoli.apk` qo'yilsa, sayt avtomatik "Yuklab olish" tugmasini ko'rsatadi. Cloudflare Pages bitta faylni
25 MB gacha qabul qiladi, shuning uchun katta APK ni GitHub Releases yoki o'z serveringizga qo'ying.

## Joylashdan oldin tekshiring
- `support@tajvidyoli.uz` va Telegram `@m24_shaxa` haqiqatan ishlashini.
- Maxfiylik siyosati va shartlarni ilova bilan solishtirib, kerak bo'lsa huquqshunos ko'rib chiqsin.
- Ilova Google Play'da chiqqach, bosh sahifadagi «Chiqqanda xabar bering» tugmasini Play havolasiga almashtiring.
- Domen aniq bo'lgach `<link rel="canonical">`, `og:url`, `og:image` va `sitemap.xml` qo'shing.

## 3D qismi
- Bosh sahifadagi 3D sahna `js/hero3d.js` (Three.js r160, `js/vendor/` da mahalliy): iPhone 16 Pro Max
  (77.6 x 163 x 8.25 mm, titan korpus, Dynamic Island, Action/ovoz/quvvat/Camera Control tugmalari,
  orqa kamera plato) ekranlariga ilova rasmlari o'rnatilgan.
- WebGL yo'q, `prefers-reduced-motion` yoqilgan yoki xato chiqsa, bir xil nisbatdagi CSS telefonlar qoladi.
- Ekran rasmlari: `flutter test test/website_shots_test.dart` (440x956 pt, xavfsiz hududlar bilan)
  `.artifacts/web/` ga chizadi; iOS holat paneli qo'shilib `assets/screens/*.webp` ga aylantirilgan.
- Shriftlar: Chubbo + Supreme (qarang: `fonts/FONTS.txt`).
