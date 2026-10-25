// Admin panel sozlamalari.
//
// 1) Firebase Console → Project settings → Your apps → "Add app" → Web (</>)
//    Ro'yxatdan o'tkazgach chiqadigan `firebaseConfig` dagi apiKey va appId ni quyiga qo'ying.
//    (Bu qiymatlar maxfiy emas — web ilovalarda ochiq bo'ladi. Himoya Firestore qoidalari bilan.)
// 2) Admin emaili BU FAYLGA YOZILMAYDI (fayl hammaga ochiq). Ruxsat faqat server tomonida,
//    `firestore.rules` dagi isAdmin() ro'yxati orqali beriladi.
export const CONFIG = {
  firebase: {
    apiKey: "AIzaSyDpaQ7s2KkagA-eF_U14sWhHuowpwFHxFo", // Default Web App
    authDomain: "tajvi-yo-li.firebaseapp.com",
    projectId: "tajvi-yo-li",
    storageBucket: "tajvi-yo-li.firebasestorage.app",
    messagingSenderId: "942217335877",
    appId: "1:942217335877:web:0a090570efb8ce3ff4ff2c",
  },
  // "firestore": users/{uid} hujjatlaridan o'qiydi (bepul, Spark tarifida ishlaydi).
  //   Faqat profilini to'ldirgan foydalanuvchilarni ko'rsatadi.
  // "functions": Firebase Auth'dagi HAMMA foydalanuvchilarni (tasdiqlanmaganlarni ham,
  //   oxirgi kirishni ham) ko'rsatadi. Cloud Functions (Blaze tarifi) kerak: `adminListUsers`.
  source: "firestore",
  firestoreLimit: 5000,
};
