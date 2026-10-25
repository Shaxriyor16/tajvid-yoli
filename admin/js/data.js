// Ma'lumot manbalari: demo (soxta) | Firestore | Cloud Functions.
// Hammasi bitta "normal" ko'rinishga keltiriladi.

const MONTHS = ["yan", "fev", "mar", "apr", "may", "iyn", "iyl", "avg", "sen", "okt", "noy", "dek"];
const pad = (n) => String(n).padStart(2, "0");

export function fmtDate(d, withTime = true) {
  if (!d) return "—";
  const base = `${d.getDate()}-${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
  return withTime ? `${base}, ${pad(d.getHours())}:${pad(d.getMinutes())}` : base;
}
export function shortDay(d) {
  return `${d.getDate()}-${MONTHS[d.getMonth()]}`;
}
export function ago(d) {
  if (!d) return "—";
  const s = Math.max(0, (Date.now() - d.getTime()) / 1000);
  if (s < 60) return "hozirgina";
  if (s < 3600) return `${Math.floor(s / 60)} daqiqa oldin`;
  if (s < 86400) return `${Math.floor(s / 3600)} soat oldin`;
  if (s < 86400 * 30) return `${Math.floor(s / 86400)} kun oldin`;
  return fmtDate(d, false);
}

const toDate = (v) => {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (typeof v === "object" && typeof v.toDate === "function") return v.toDate();
  const d = new Date(v);
  return isNaN(d) ? null : d;
};
export function normProvider(p) {
  const s = String(p || "").toLowerCase();
  if (s.includes("google")) return "google";
  if (s.includes("apple")) return "apple";
  return "email";
}
function displayName(first, last, email) {
  const n = `${first || ""} ${last || ""}`.trim();
  return n || (email ? email.split("@")[0] : "") || "Nomsiz";
}

export function fromFirestore(id, d) {
  const email = d.email || "";
  return {
    uid: d.uid || id,
    email,
    firstName: d.firstName || "",
    lastName: d.lastName || "",
    name: displayName(d.firstName, d.lastName, email),
    age: typeof d.age === "number" ? d.age : null,
    photoUrl: typeof d.photoUrl === "string" && d.photoUrl.startsWith("https://") ? d.photoUrl : "",
    provider: normProvider(d.provider),
    createdAt: toDate(d.createdAt),
    lastSignIn: null,
    emailVerified: null,
    disabled: null,
  };
}
export function fromFunction(d) {
  const email = d.email || "";
  return {
    uid: d.uid,
    email,
    firstName: d.firstName || "",
    lastName: d.lastName || "",
    name: displayName(d.firstName || (d.displayName || "").split(" ")[0], d.lastName || (d.displayName || "").split(" ").slice(1).join(" "), email),
    age: typeof d.age === "number" ? d.age : null,
    photoUrl: typeof d.photoUrl === "string" && d.photoUrl.startsWith("https://") ? d.photoUrl : "",
    provider: normProvider(d.provider || (d.providerIds || [])[0]),
    createdAt: toDate(d.createdAt),
    lastSignIn: toDate(d.lastSignInAt),
    emailVerified: typeof d.emailVerified === "boolean" ? d.emailVerified : null,
    disabled: typeof d.disabled === "boolean" ? d.disabled : null,
  };
}

export async function loadFirestore(fs, db, limitN) {
  const q = fs.query(fs.collection(db, "users"), fs.orderBy("createdAt", "desc"), fs.limit(limitN));
  const snap = await fs.getDocs(q);
  return snap.docs.map((doc) => fromFirestore(doc.id, doc.data()));
}
export async function loadFunction(fnMod, functions) {
  const call = fnMod.httpsCallable(functions, "adminListUsers");
  const res = await call({});
  return { users: (res.data.users || []).map(fromFunction), truncated: !!res.data.truncated };
}

// ---------- DEMO: soxta, deterministik namunaviy ma'lumotlar ----------
function rng(seed) {
  let s = seed >>> 0;
  return () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296;
}
export function demoUsers() {
  const r = rng(20261024);
  const first = ["Aziz", "Madina", "Jasur", "Dilnoza", "Sardor", "Zilola", "Bekzod", "Malika", "Otabek", "Nigora", "Shahzod", "Feruza", "Umid", "Gulnora", "Anvar", "Sevara", "Rustam", "Nodira", "Behruz", "Kamola", "Ilhom", "Mohira", "Timur", "Laylo"];
  const last = ["Karimov", "Yusupova", "Rahimov", "Ergasheva", "Tursunov", "Ismoilova", "Abdullayev", "Nazarova", "Qodirov", "Sobirova", "Aliyev", "Hasanova", "Mirzayev", "Normatova"];
  const mails = ["gmail.com", "gmail.com", "gmail.com", "icloud.com", "mail.ru", "yahoo.com", "inbox.uz"];
  const now = Date.now();
  const out = [];
  for (let i = 0; i < 268; i++) {
    const f = first[Math.floor(r() * first.length)];
    const l = last[Math.floor(r() * last.length)];
    const pr = r();
    const provider = pr < 0.5 ? "google" : pr < 0.82 ? "email" : "apple";
    // so'nggi kunlarda ko'proq ro'yxatdan o'tish
    const days = Math.floor(Math.pow(r(), 1.7) * 90);
    const created = new Date(now - days * 86400000 - Math.floor(r() * 86400000));
    const email = `${f}.${l}${Math.floor(r() * 90 + 10)}@${provider === "apple" ? "icloud.com" : mails[Math.floor(r() * mails.length)]}`.toLowerCase();
    const verified = provider !== "email" || r() > 0.18;
    out.push({
      uid: Array.from({ length: 28 }, () => "abcdefghijklmnopqrstuvwxyz0123456789"[Math.floor(r() * 36)]).join(""),
      email,
      firstName: f,
      lastName: l,
      name: `${f} ${l}`,
      age: r() > 0.45 ? Math.floor(14 + r() * 40) : null,
      photoUrl: "",
      provider,
      createdAt: created,
      lastSignIn: new Date(Math.min(now, created.getTime() + Math.floor(r() * (now - created.getTime())))),
      emailVerified: verified,
      disabled: false,
    });
  }
  return out.sort((a, b) => b.createdAt - a.createdAt);
}

// ---------- Mulohazalar (feedback) ----------
export const FB_CATS = { idea: "Taklif", bug: "Xatolik", praise: "Maqtov", other: "Boshqa" };
export const FB_STATUS = { new: "Yangi", read: "O'qilgan", done: "Hal qilingan" };

export function fromFeedback(id, d) {
  const rating = Number.isInteger(d.rating) ? Math.min(5, Math.max(1, d.rating)) : 0;
  return {
    id,
    uid: d.uid || "",
    name: (d.name || "").trim() || (d.email ? String(d.email).split("@")[0] : "") || "Nomsiz",
    email: d.email || "",
    rating,
    category: FB_CATS[d.category] ? d.category : "other",
    message: typeof d.message === "string" ? d.message : "",
    appVersion: d.appVersion || "",
    platform: ["android", "ios"].includes(d.platform) ? d.platform : "other",
    locale: d.locale || "",
    status: FB_STATUS[d.status] ? d.status : "new",
    createdAt: toDate(d.createdAt),
  };
}
export async function loadFeedback(fs, db, limitN) {
  const q = fs.query(fs.collection(db, "feedback"), fs.orderBy("createdAt", "desc"), fs.limit(limitN));
  const snap = await fs.getDocs(q);
  return snap.docs.map((doc) => fromFeedback(doc.id, doc.data()));
}
export async function setFeedbackStatus(fs, db, id, status) {
  await fs.updateDoc(fs.doc(db, "feedback", id), { status });
}
export async function deleteFeedback(fs, db, id) {
  await fs.deleteDoc(fs.doc(db, "feedback", id));
}
export function demoFeedback() {
  const r = rng(77123);
  const msgs = [
    ["praise", 5, "Juda foydali ilova! Tajvid qoidalarini birinchi marta shunchalik tushunarli o'rgandim."],
    ["idea", 4, "Har bir darsdan keyin qisqa audio izoh bo'lsa yaxshi bo'lardi."],
    ["bug", 2, "AI tekshiruvda mikrofon ba'zan ishlamay qoladi, ilovani qayta ochishga to'g'ri keladi."],
    ["praise", 5, "Dizayni juda chiroyli, bolalarimga ham yoqdi. Rahmat!"],
    ["idea", 4, "Qori ovozini tanlash imkoniyatini qo'shing."],
    ["bug", 3, "Sura sahifasida ba'zan matn kech yuklanadi."],
    ["other", 4, "Arabcha interfeys juda qulay, lekin ba'zi matnlar o'zbekchada qolgan."],
    ["praise", 5, "Streak tizimi har kuni o'qishga undaydi."],
    ["idea", 5, "Oilaviy reja va do'stlar bilan musobaqa bo'lsa zo'r bo'lardi."],
    ["bug", 1, "Bildirishnoma kelmayapti, sozlamalarda yoqilgan."],
  ];
  const names = ["Aziz Karimov", "Madina Yusupova", "Jasur Rahimov", "Dilnoza Ergasheva", "Sardor Tursunov", "Zilola Ismoilova", "Bekzod Abdullayev", "Malika Nazarova"];
  const now = Date.now();
  return msgs
    .map((m, i) => {
      const n = names[Math.floor(r() * names.length)];
      return {
        id: "demo" + i,
        uid: "demo-uid-" + i,
        name: n,
        email: n.toLowerCase().replace(" ", ".") + "@gmail.com",
        rating: m[1],
        category: m[0],
        message: m[2],
        appVersion: "1.0.0+1",
        platform: r() > 0.25 ? "android" : "ios",
        locale: ["uz", "uz", "en", "ar"][Math.floor(r() * 4)],
        status: i < 4 ? "new" : i < 7 ? "read" : "done",
        createdAt: new Date(now - (i * 7 + Math.floor(r() * 5)) * 3600 * 1000 * 5),
      };
    })
    .sort((a, b) => b.createdAt - a.createdAt);
}
