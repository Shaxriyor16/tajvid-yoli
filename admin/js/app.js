import { CONFIG } from "./config.js";
import { demoUsers, loadFirestore, loadFunction, fmtDate, shortDay, ago, FB_CATS, FB_STATUS, demoFeedback, loadFeedback, setFeedbackStatus, deleteFeedback } from "./data.js";
import { areaChart, donut, sparkline } from "./charts.js";

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const esc = (s) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const FB_VERSION = "10.12.5";
const FB_BASE = `https://www.gstatic.com/firebasejs/${FB_VERSION}/`;

const PROVIDERS = {
  google: { label: "Google", color: "#6ea8ff", icon: "i-google" },
  apple: { label: "Apple", color: "#c9c9d1", icon: "i-apple" },
  email: { label: "Email", color: "#e8c77b", icon: "i-mail" },
};

const state = {
  demo: new URLSearchParams(location.search).has("demo"),
  users: [],
  status: "idle", // idle | loading | ready | error
  error: null,
  truncated: false,
  updatedAt: null,
  view: "overview",
  range: 30,
  filter: "all",
  q: "",
  sort: "new",
  shown: 40,
  me: null,
  source: CONFIG.source,
  feedback: [],
  fbError: null,
  fbFilter: "all",
  fbShown: 30,
};
let fb = null; // { app, auth, authMod, fs, db, fnMod, functions }

const configured = () => !!(CONFIG.firebase.apiKey && CONFIG.firebase.appId);

/* ---------------- Yordamchilar ---------------- */
const icon = (id, cls = "") => `<svg class="${cls}" aria-hidden="true"><use href="#${id}"/></svg>`;
const initials = (n) =>
  (n || "?")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0].toUpperCase())
    .join("") || "?";
const hue = (s) => {
  let h = 0;
  for (const c of String(s)) h = (h * 31 + c.charCodeAt(0)) % 360;
  return h;
};
function avatar(u, cls = "") {
  const ini = esc(initials(u.name));
  const inner = u.photoUrl
    ? `<img src="${esc(u.photoUrl)}" alt="" referrerpolicy="no-referrer" loading="lazy" data-ini="${ini}">`
    : ini;
  return `<span class="avatar ${cls}" style="--h:${hue(u.uid || u.email)}">${inner}</span>`;
}
document.addEventListener(
  "error",
  (e) => {
    const t = e.target;
    if (t && t.tagName === "IMG" && t.dataset.ini) t.replaceWith(document.createTextNode(t.dataset.ini));
  },
  true
);
function badge(p, extra = "") {
  const v = PROVIDERS[p] || PROVIDERS.email;
  return `<span class="badge ${p} ${extra}">${icon(v.icon)}${v.label}</span>`;
}
let toastTimer;
function toast(msg) {
  const t = $("#toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove("show"), 2200);
}
async function copy(text) {
  try {
    await navigator.clipboard.writeText(text);
    toast("Nusxalandi");
  } catch {
    toast("Nusxalab bo'lmadi");
  }
}
function setTheme(t) {
  document.documentElement.setAttribute("data-theme", t);
  try {
    localStorage.setItem("admin-theme", t);
  } catch {}
  const ic = t === "dark" ? "i-sun" : "i-moon";
  $$("#btn-theme use, #btn-theme-m use").forEach((u) => u.setAttribute("href", "#" + ic));
  const tm = document.querySelector('meta[name="theme-color"]');
  if (tm) tm.setAttribute("content", t === "dark" ? "#0a2a22" : "#e9f2ec");
}

/* ---------------- Hisob-kitoblar ---------------- */
function computeStats(users) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const DAY = 86400000;
  const inRange = (from, to) => users.filter((u) => u.createdAt && u.createdAt.getTime() >= from && u.createdAt.getTime() < to).length;
  const today = inRange(start, start + DAY);
  const w1 = inRange(start - 6 * DAY, start + DAY);
  const w0 = inRange(start - 13 * DAY, start - 6 * DAY);
  const m1 = inRange(start - 29 * DAY, start + DAY);
  const m0 = inRange(start - 59 * DAY, start - 29 * DAY);
  const byProv = { google: 0, apple: 0, email: 0 };
  users.forEach((u) => (byProv[u.provider] = (byProv[u.provider] || 0) + 1));
  const daily = (days) => {
    const out = [];
    for (let i = days - 1; i >= 0; i--) {
      const from = start - i * DAY;
      const d = new Date(from);
      out.push({ label: shortDay(d), full: fmtDate(d, false), value: inRange(from, from + DAY), t: from });
    }
    return out;
  };
  const withVerify = users.filter((u) => u.emailVerified !== null);
  return {
    total: users.length,
    today,
    w1,
    w0,
    m1,
    m0,
    byProv,
    daily,
    verified: withVerify.filter((u) => u.emailVerified).length,
    unverified: withVerify.filter((u) => !u.emailVerified).length,
    neverSignedIn: users.filter((u) => u.lastSignIn === null).length,
    hasVerify: withVerify.length > 0,
  };
}
function delta(cur, prev) {
  if (!prev && !cur) return `<span class="delta flat">0%</span>`;
  if (!prev) return `<span class="delta up">yangi</span>`;
  const p = Math.round(((cur - prev) / prev) * 100);
  if (p === 0) return `<span class="delta flat">0%</span>`;
  return `<span class="delta ${p > 0 ? "up" : "down"}">${p > 0 ? "+" : ""}${p}%</span>`;
}


const SORTS = [
  ["new", "Avval yangilari"],
  ["old", "Avval eskilari"],
  ["name", "Ism bo'yicha"],
  ["email", "Email bo'yicha"],
];
function sortMenu() {
  const cur = SORTS.find((x) => x[0] === state.sort) || SORTS[0];
  return `<div class="dd" id="sort-dd">
    <button type="button" class="dd-btn" id="sort-btn" aria-haspopup="listbox" aria-expanded="false" aria-controls="sort-menu">${icon("i-sort")}<span id="sort-label">${esc(cur[1])}</span>${icon("i-down", "caret")}</button>
    <ul class="dd-menu" id="sort-menu" role="listbox" tabindex="-1" aria-label="Saralash" hidden>
      ${SORTS.map(([v, l]) => `<li role="option" data-val="${v}" aria-selected="${state.sort === v}" tabindex="-1"><span>${esc(l)}</span>${icon("i-check")}</li>`).join("")}
    </ul></div>`;
}
function closeMenu(focusBtn) {
  const m = $("#sort-menu");
  if (!m || m.hidden) return;
  m.hidden = true;
  const b = $("#sort-btn");
  b.setAttribute("aria-expanded", "false");
  if (focusBtn) b.focus();
}
function openMenu() {
  const m = $("#sort-menu");
  m.hidden = false;
  $("#sort-btn").setAttribute("aria-expanded", "true");
  const sel = $('#sort-menu [aria-selected="true"]') || $("#sort-menu li");
  sel.focus();
}
function pickSort(v) {
  state.sort = v;
  const cur = SORTS.find((x) => x[0] === v);
  $("#sort-label").textContent = cur[1];
  $$("#sort-menu li").forEach((li) => li.setAttribute("aria-selected", String(li.dataset.val === v)));
  closeMenu(true);
  renderUsersList();
}

/* ---------------- Ko'rinishlar ---------------- */
const TITLES = {
  overview: ["Umumiy", "Ro'yxatdan o'tishlar va provayderlar bo'yicha qisqacha ko'rinish"],
  users: ["Foydalanuvchilar", "Kim va qaysi usul bilan ro'yxatdan o'tgan"],
  feedback: ["Mulohazalar", "Foydalanuvchilar ilova ichidan yuborgan fikrlar"],
  setup: ["Ulanish", "Firebase bilan aloqa holati va sozlash bosqichlari"],
};

function skeleton() {
  return `<div class="stats">${'<div class="skel"></div>'.repeat(4)}</div><div class="grid2"><div class="skel" style="min-height:320px"></div><div class="skel" style="min-height:320px"></div></div>`;
}
function errorBox() {
  const e = state.error || {};
  return `<section class="glass panel"><div class="banner err">${icon("i-alert")}<div><b>${esc(e.title || "Ma'lumotni yuklab bo'lmadi")}</b>${esc(e.text || "")}</div></div>
    <div style="margin-top:16px;display:flex;gap:10px;flex-wrap:wrap"><button class="btn primary" data-act="refresh">${icon("i-refresh")}Qayta urinish</button><button class="btn" data-go="setup">${icon("i-gear")}Ulanish sozlamalari</button></div></section>`;
}

function viewOverview() {
  if (state.status === "loading" && !state.users.length) return skeleton();
  if (state.status === "error") return errorBox();
  const st = computeStats(state.users);
  const series = st.daily(state.range);
  const spark = (days) => st.daily(days).map((d) => d.value);
  const recent = state.users.slice(0, 7);
  const provTotal = st.total || 1;
  const parts = Object.entries(PROVIDERS).map(([k, v]) => ({ label: v.label, value: st.byProv[k] || 0, color: v.color, key: k }));
  const stat = (lbl, ic, color, num, sub, sp) => `<article class="glass stat" style="--c:${color}"><div class="lbl"><i>${icon(ic)}</i>${lbl}</div><div class="num">${num}</div><div class="sub">${sub}</div>${sp ? sparkline(sp, color) : ""}</article>`;
  const second =
    state.source === "functions" && st.hasVerify
      ? `<section class="glass panel"><div class="head"><h2>Email tasdig'i<small>Faqat email orqali kirganlar uchun ahamiyatli</small></h2></div>
          <ul class="legend" style="--c:var(--mint)">
            <li style="--c:var(--mint)"><i class="dot"></i><span>Tasdiqlangan</span><b>${st.verified}</b></li>
            <li style="--c:var(--red)"><i class="dot"></i><span>Tasdiqlanmagan</span><b>${st.unverified}</b></li>
            <li style="--c:var(--blue)"><i class="dot"></i><span>Hech qachon kirmagan</span><b>${st.neverSignedIn}</b></li>
          </ul></section>`
      : `<section class="glass panel"><div class="head"><h2>Eslatma</h2></div>
          <div class="banner">${icon("i-info")}<div><b>Hozir faqat profili to'ldirganlar ko'rinadi</b>Email bilan ro'yxatdan o'tib, pochtasini tasdiqlamaganlar bu ro'yxatda bo'lmaydi (ular faqat Firebase → Authentication'da). To'liq ro'yxat uchun Cloud Functions rejimiga o'ting.</div></div>
          <div style="margin-top:14px"><button class="btn" data-go="setup">${icon("i-gear")}Qanday qilinadi</button></div></section>`;
  return `
    <div class="stats">
      ${stat("Jami foydalanuvchi", "i-users", "#e8c77b", st.total, `<span>barcha vaqt</span>`, spark(30))}
      ${stat("Bugun", "i-plus", "#46d6a6", st.today, `<span>yangi hisob</span>`, null)}
      ${stat("Oxirgi 7 kun", "i-cal", "#6ea8ff", st.w1, `${delta(st.w1, st.w0)}<span>oldingi 7 kunga nisbatan</span>`, spark(7))}
      ${stat("Oxirgi 30 kun", "i-pulse", "#ff9ec4", st.m1, `${delta(st.m1, st.m0)}<span>oldingi 30 kunga</span>`, spark(14))}
    </div>
    <div class="grid2">
      <section class="glass panel">
        <div class="head"><h2>Ro'yxatdan o'tish dinamikasi<small>Kunlik yangi foydalanuvchilar</small></h2>
          <div class="seg" role="group" aria-label="Davr">${[7, 30, 90].map((n) => `<button type="button" data-range="${n}" aria-pressed="${state.range === n}">${n} kun</button>`).join("")}</div></div>
        <div class="chart" id="chart"></div>
      </section>
      <section class="glass panel">
        <div class="head"><h2>Qaysi usulda<small>Provayderlar bo'yicha</small></h2></div>
        <div class="donut-wrap">
          <div class="donut">${donut(parts, st.total)}<div class="mid"><div><b>${st.total}</b><br><span>foydalanuvchi</span></div></div></div>
          <ul class="legend">${parts
            .map((p) => `<li style="--c:${p.color}"><i class="dot"></i><span>${icon(PROVIDERS[p.key].icon).replace("<svg", '<svg width="15" height="15" style="vertical-align:-2px;margin-right:6px"')}${p.label}</span><span><b>${p.value}</b><em>${Math.round((p.value / provTotal) * 100)}%</em></span></li>`)
            .join("")}</ul>
        </div>
      </section>
    </div>
    <div class="grid2 even">
      <section class="glass panel">
        <div class="head"><h2>Oxirgi ro'yxatdan o'tganlar</h2><button class="btn" data-go="users">Hammasi${icon("i-chev")}</button></div>
        ${recent.length ? `<div class="list compact">${recent.map(rowHtml).join("")}</div>` : emptyHtml("Hali foydalanuvchi yo'q", "Birinchi ro'yxatdan o'tgan foydalanuvchi shu yerda paydo bo'ladi.")}
      </section>
      ${second}
    </div>`;
}

function rowHtml(u) {
  return `<button class="row" type="button" data-uid="${esc(u.uid)}">${avatar(u)}
    <span class="nm"><b>${esc(u.name)}</b><small>${esc(ago(u.createdAt))}</small></span>
    <span class="mail">${esc(u.email || "email yo'q")}</span>
    <span class="prov">${badge(u.provider)}</span>
    <span class="when">${esc(fmtDate(u.createdAt, false))}</span>
    ${icon("i-chev", "chev")}</button>`;
}
function emptyHtml(t, s) {
  return `<div class="empty">${icon("i-users")}<b>${esc(t)}</b>${esc(s)}</div>`;
}

function filteredUsers() {
  const q = state.q.trim().toLowerCase();
  let a = state.users.filter((u) => (state.filter === "all" || u.provider === state.filter) && (!q || `${u.name} ${u.email} ${u.uid}`.toLowerCase().includes(q)));
  const by = {
    new: (x, y) => (y.createdAt || 0) - (x.createdAt || 0),
    old: (x, y) => (x.createdAt || 0) - (y.createdAt || 0),
    name: (x, y) => x.name.localeCompare(y.name, "uz"),
    email: (x, y) => x.email.localeCompare(y.email),
  }[state.sort];
  return a.sort(by);
}

function viewUsers() {
  if (state.status === "loading" && !state.users.length) return `<div class="skel" style="min-height:420px"></div>`;
  if (state.status === "error") return errorBox();
  const counts = { all: state.users.length, google: 0, apple: 0, email: 0 };
  state.users.forEach((u) => (counts[u.provider] = (counts[u.provider] || 0) + 1));
  const segBtn = (k, label, ic) => `<button type="button" data-filter="${k}" aria-pressed="${state.filter === k}">${ic ? icon(ic) : ""}${label} <span style="opacity:.6">${counts[k] ?? 0}</span></button>`;
  return `
    <div class="filters">
      <label class="search"><span class="sr">Qidirish</span>${icon("i-search")}<input id="q" type="search" placeholder="Ism, email yoki UID bo'yicha qidirish" value="${esc(state.q)}" autocomplete="off"><button type="button" class="clear" id="q-clear" aria-label="Tozalash"${state.q ? "" : " hidden"}>${icon("i-close")}</button></label>
      <div class="seg" role="group" aria-label="Provayder">${segBtn("all", "Hammasi")}${segBtn("google", "Google", "i-google")}${segBtn("apple", "Apple", "i-apple")}${segBtn("email", "Email", "i-mail")}</div>
      ${sortMenu()}
      <button class="btn" type="button" data-act="csv">${icon("i-download")}CSV</button>
    </div>
    <div id="users-list"></div>`;
}
function renderUsersList() {
  const box = $("#users-list");
  if (!box) return;
  const all = filteredUsers();
  const part = all.slice(0, state.shown);
  if (!all.length) {
    box.innerHTML = `<section class="glass panel">${emptyHtml("Hech narsa topilmadi", "Qidiruv yoki filtrni o'zgartirib ko'ring.")}</section>`;
    return;
  }
  box.innerHTML = `<div class="count-line">${all.length} ta natija</div>
    <section class="glass" style="padding:8px;margin-top:10px"><div class="list">
      <div class="row head-row"><span></span><span>Foydalanuvchi</span><span>Email</span><span>Usul</span><span>Sana</span><span></span></div>
      ${part.map(rowHtml).join("")}</div>
      ${all.length > part.length ? `<div class="more"><button class="btn" data-act="more">Yana ${Math.min(40, all.length - part.length)} ta ko'rsatish</button></div>` : ""}
    </section>`;
}


/* ---------------- Mulohazalar ---------------- */
const stars = (n) => `<span class="stars" role="img" aria-label="${n} / 5">${[1, 2, 3, 4, 5].map((i) => `<i class="${i <= n ? "on" : ""}">★</i>`).join("")}</span>`;
const PLAT = { android: "Android", ios: "iOS", other: "" };
function fbStats(list) {
  const rated = list.filter((f) => f.rating);
  const avg = rated.length ? rated.reduce((a, f) => a + f.rating, 0) / rated.length : 0;
  const dist = [0, 0, 0, 0, 0];
  rated.forEach((f) => dist[f.rating - 1]++);
  return { total: list.length, avg, dist, news: list.filter((f) => f.status === "new").length, bugs: list.filter((f) => f.category === "bug" && f.status !== "done").length };
}
function filteredFeedback() {
  const f = state.fbFilter;
  return state.feedback.filter((x) => f === "all" || (f === "new" ? x.status === "new" : x.category === f));
}
function viewFeedback() {
  if (state.status === "loading" && !state.feedback.length) return skeleton();
  if (state.fbError) {
    return `<section class="glass panel"><div class="banner err">${icon("i-alert")}<div><b>${esc(state.fbError.title)}</b>${esc(state.fbError.text)} Firestore qoidalari mulohazalarni o'qishga ruxsat berishi kerak (firestore.rules → feedback).</div></div></section>`;
  }
  const st = fbStats(state.feedback);
  const max = Math.max(1, ...st.dist);
  const stat = (lbl, ic, color, num, sub) => `<article class="glass stat" style="--c:${color}"><div class="lbl"><i>${icon(ic)}</i>${lbl}</div><div class="num">${num}</div><div class="sub"><span>${sub}</span></div></article>`;
  const counts = { all: state.feedback.length, new: st.news };
  state.feedback.forEach((f) => (counts[f.category] = (counts[f.category] || 0) + 1));
  const seg = (k, label) => `<button type="button" data-fbfilter="${k}" aria-pressed="${state.fbFilter === k}">${label} <span style="opacity:.6">${counts[k] || 0}</span></button>`;
  if (!state.feedback.length) {
    return `<section class="glass panel">${emptyHtml("Hali mulohaza yo'q", "Foydalanuvchilar ilovadagi Sozlamalar → Fikr bildirish orqali yozganda shu yerda paydo bo'ladi.")}</section>`;
  }
  return `
    <div class="stats">
      ${stat("O'rtacha baho", "i-star", "#e8c77b", st.avg ? st.avg.toFixed(1) + ' <small style="font-size:.5em;opacity:.6">/ 5</small>' : "—", stars(Math.round(st.avg)))}
      ${stat("Jami mulohaza", "i-chat", "#6ea8ff", st.total, "barcha vaqt")}
      ${stat("Yangi", "i-mail", "#46d6a6", st.news, "hali o'qilmagan")}
      ${stat("Ochiq xatoliklar", "i-alert", "#ff7a7a", st.bugs, "hal qilinmagan")}
    </div>
    <section class="glass panel">
      <div class="head"><h2>Baholar taqsimoti<small>Yulduzchalar bo'yicha</small></h2></div>
      <ul class="dist">${[5, 4, 3, 2, 1].map((n) => `<li><span>${n} <i>★</i></span><div class="bar"><b style="width:${(st.dist[n - 1] / max) * 100}%"></b></div><em>${st.dist[n - 1]}</em></li>`).join("")}</ul>
    </section>
    <div class="filters">
      <div class="seg" role="group" aria-label="Filtr">${seg("all", "Hammasi")}${seg("new", "Yangi")}${seg("bug", "Xatolik")}${seg("idea", "Taklif")}${seg("praise", "Maqtov")}${seg("other", "Boshqa")}</div>
    </div>
    <div id="fb-list"></div>`;
}
function fbCard(f) {
  const meta = [PLAT[f.platform], f.appVersion && "v" + f.appVersion, f.locale && f.locale.toUpperCase()].filter(Boolean).join(" · ");
  const btn = (act, label, ic, cls = "") => `<button class="btn sm ${cls}" type="button" data-fbact="${act}" data-fbid="${esc(f.id)}">${icon(ic)}${label}</button>`;
  return `<article class="glass fb ${f.status}" data-st="${f.status}">
    <header>${avatar({ name: f.name, uid: f.uid, email: f.email })}
      <div class="who"><b>${esc(f.name)}</b><small>${esc(f.email || "email yo'q")}</small></div>
      <div class="right">${stars(f.rating)}<small>${esc(ago(f.createdAt))}</small></div></header>
    <p class="msg">${esc(f.message)}</p>
    <footer>
      <span class="chips"><span class="cat ${f.category}">${esc(FB_CATS[f.category])}</span><span class="stt ${f.status}">${esc(FB_STATUS[f.status])}</span>${meta ? `<span class="meta">${esc(meta)}</span>` : ""}</span>
      <span class="acts">
        ${f.status !== "read" ? btn("read", "O'qildi", "i-eye") : ""}
        ${f.status !== "done" ? btn("done", "Hal qilindi", "i-check") : btn("new", "Qayta ochish", "i-refresh")}
        ${f.email ? `<a class="btn sm" href="mailto:${esc(f.email)}">${icon("i-mail")}Javob</a>` : ""}
        ${btn("del", "", "i-trash", "danger icon")}
      </span>
    </footer></article>`;
}
function renderFeedbackList() {
  const box = $("#fb-list");
  if (!box) return;
  const all = filteredFeedback();
  const part = all.slice(0, state.fbShown);
  box.innerHTML = all.length
    ? `<div class="count-line">${all.length} ta natija</div><div class="fb-list">${part.map(fbCard).join("")}</div>${all.length > part.length ? `<div class="more"><button class="btn" data-act="fbmore">Yana ko'rsatish</button></div>` : ""}`
    : `<section class="glass panel">${emptyHtml("Hech narsa topilmadi", "Boshqa filtrni tanlab ko'ring.")}</section>`;
}
function updateFbBadge() {
  const n = state.feedback.filter((f) => f.status === "new").length;
  $$("[data-badge='feedback']").forEach((b) => {
    b.textContent = n > 99 ? "99+" : String(n);
    b.hidden = n === 0;
  });
}
let delArm = null;
async function fbAction(id, act, btnEl) {
  const f = state.feedback.find((x) => x.id === id);
  if (!f) return;
  if (act === "del") {
    if (delArm !== id) {
      delArm = id;
      btnEl.classList.add("armed");
      btnEl.innerHTML = icon("i-trash") + "O'chirilsinmi?";
      setTimeout(() => {
        if (delArm === id) {
          delArm = null;
          renderFeedbackList();
        }
      }, 3500);
      return;
    }
    delArm = null;
    try {
      if (!state.demo) await deleteFeedback(fb.fs, fb.db, id);
      state.feedback = state.feedback.filter((x) => x.id !== id);
      toast("O'chirildi");
    } catch (e) {
      console.error(e);
      return toast("O'chirib bo'lmadi");
    }
  } else {
    try {
      if (!state.demo) await setFeedbackStatus(fb.fs, fb.db, id, act);
      f.status = act;
    } catch (e) {
      console.error(e);
      return toast("Holatni saqlab bo'lmadi");
    }
  }
  updateFbBadge();
  render();
}

function check(ok, title, text) {
  const cls = ok === true ? "ok" : ok === false ? "bad" : "";
  const ic = ok === true ? "i-check" : ok === false ? "i-x" : "i-info";
  return `<li><span class="st ${cls}">${icon(ic)}</span><div><b>${esc(title)}</b><small>${text}</small></div></li>`;
}
function viewSetup() {
  const rules = `function isAdmin() {
  return request.auth != null
    && request.auth.token.email_verified == true
    && request.auth.token.email.lower() in [
      'sizning.gmail@gmail.com'
    ];
}
// match /users/{uid} va /feedback/{id} ichida:
allow read: if isAdmin();`;
  return `
    <div class="grid2 even">
      <section class="glass panel">
        <div class="head"><h2>Ulanish holati</h2></div>
        <ul class="check">
          ${check(configured(), "Firebase Web konfiguratsiyasi", configured() ? "apiKey va appId kiritilgan." : "<code>js/config.js</code> da <b>apiKey</b> va <b>appId</b> bo'sh.")}
          ${check(state.demo ? null : !!state.me, "Admin ruxsati", state.demo ? "Demo rejim." : state.me ? "Firestore qoidalari bu hisobga ruxsat berdi." : "Kirilmagan.")}
          ${check(state.demo ? null : !!state.me, "Kirish", state.demo ? "Demo rejim: haqiqiy hisobga ulanmagan." : state.me ? `${esc(state.me.email)} sifatida kirgansiz.` : "Kirilmagan.")}
          ${check(state.demo ? null : state.status === "ready", "Ma'lumot o'qish", state.demo ? "Demo (soxta) ma'lumotlar." : state.status === "ready" ? `${state.users.length} ta foydalanuvchi o'qildi (${state.source === "functions" ? "Cloud Functions" : "Firestore"}).` : state.status === "error" ? esc(state.error?.title || "Xato") : "Hali yuklanmagan.")}
        </ul>
        <div style="margin-top:16px;display:flex;gap:10px;flex-wrap:wrap">
          <a class="btn" href="https://console.firebase.google.com/project/${esc(CONFIG.firebase.projectId)}/overview" target="_blank" rel="noopener noreferrer">Firebase Console</a>
          <button class="btn" data-act="refresh">${icon("i-refresh")}Qayta tekshirish</button>
        </div>
      </section>
      <section class="glass panel">
        <div class="head"><h2>Qanday ulanadi</h2></div>
        <ol class="steps">
          <li><b>Web ilova yarating.</b> Firebase Console → Project settings → Your apps → <b>Add app → Web</b>. Chiqqan <code>apiKey</code> va <code>appId</code> ni <code>admin/js/config.js</code> ga yozing.</li>
          <li><b>Admin hisobini Console'da yarating:</b> Authentication → Users → <b>Add user</b> (email va parol). Panelda hisob yaratib bo'lmaydi.</li>
          <li><b>Admin emailini faqat Firestore qoidasiga yozing</b> (<code>firestore.rules</code> → <code>isAdmin()</code>). Brauzer fayllarida admin emaili saqlanmaydi.</li>
          <li><b>Qoidani deploy qiling:</b> <pre class="code">firebase deploy --only firestore:rules</pre></li>
          <li><b>Ixtiyoriy — to'liq ro'yxat:</b> <code>source: "functions"</code> va <pre class="code">firebase deploy --only functions:tajvid:adminListUsers</pre> (Blaze tarifi kerak).</li>
        </ol>
        <details style="margin-top:14px"><summary style="cursor:pointer;color:var(--accent);font-weight:700">Qoida namunasi</summary><pre class="code">${esc(rules)}</pre></details>
      </section>
    </div>`;
}

/* ---------------- Render ---------------- */
function render() {
  const [t, s] = TITLES[state.view];
  $("#title").textContent = t;
  const info = state.status === "ready" && state.updatedAt ? ` · yangilandi ${String(state.updatedAt.getHours()).padStart(2, "0")}:${String(state.updatedAt.getMinutes()).padStart(2, "0")}` : "";
  $("#subtitle").textContent = state.view === "feedback" && state.status === "ready" ? `${state.feedback.length} ta mulohaza${info}` : state.view === "users" && state.status === "ready" ? `${state.users.length} ta foydalanuvchi${info}` : s + info;
  $$("[data-view]").forEach((b) => (b.getAttribute("data-view") === state.view ? b.setAttribute("aria-current", "page") : b.removeAttribute("aria-current")));
  const v = $("#view");
  v.innerHTML = state.view === "overview" ? viewOverview() : state.view === "users" ? viewUsers() : state.view === "feedback" ? viewFeedback() : viewSetup();
  if (state.view === "overview") drawChart();
  if (state.view === "users") renderUsersList();
  if (state.view === "feedback") renderFeedbackList();
  updateFbBadge();
  const rb = $("#btn-refresh");
  rb.disabled = state.status === "loading";
  $("use", rb).parentElement.classList.toggle("spin", state.status === "loading");
}
function drawChart() {
  const el = $("#chart");
  if (!el || state.status !== "ready") return;
  const st = computeStats(state.users);
  areaChart(el, st.daily(state.range), { color: getComputedStyle(document.documentElement).getPropertyValue("--accent").trim() || "#e8c77b" });
}
let rz;
new ResizeObserver(() => {
  clearTimeout(rz);
  rz = setTimeout(() => state.view === "overview" && drawChart(), 120);
}).observe(document.body);

function go(view) {
  state.view = view;
  try {
    history.replaceState(null, "", location.pathname + location.search + "#" + view);
  } catch {}
  render();
  window.scrollTo({ top: 0 });
}

/* ---------------- Sheet ---------------- */
function openSheet(uid) {
  const u = state.users.find((x) => x.uid === uid);
  if (!u) return;
  const kv = (k, v, copyVal) => `<li><span>${k}</span><b>${v}${copyVal ? `<button class="copy" type="button" data-copy="${esc(copyVal)}" aria-label="Nusxalash">${icon("i-copy")}</button>` : ""}</b></li>`;
  const ver = u.emailVerified === null ? "" : `<span class="badge ${u.emailVerified ? "ok" : "warn"}">${u.emailVerified ? "Email tasdiqlangan" : "Email tasdiqlanmagan"}</span>`;
  $("#sheet").innerHTML = `<button class="btn icon x" type="button" data-close aria-label="Yopish">${icon("i-close")}</button>
    <div class="inner"><div class="who">${avatar(u, "lg")}<h3>${esc(u.name)}</h3><p>${esc(u.email || "email yo'q")}</p><div style="display:flex;gap:8px;justify-content:center;flex-wrap:wrap">${badge(u.provider)}${ver}</div></div>
    <ul class="kv">
      ${kv("Usul", esc((PROVIDERS[u.provider] || PROVIDERS.email).label))}
      ${kv("Ro'yxatdan o'tgan", esc(fmtDate(u.createdAt)))}
      ${u.lastSignIn ? kv("Oxirgi kirish", esc(fmtDate(u.lastSignIn))) : ""}
      ${u.firstName || u.lastName ? kv("Ism / familiya", esc(`${u.firstName} ${u.lastName}`.trim())) : ""}
      ${u.age !== null ? kv("Yosh", esc(u.age)) : ""}
      ${u.disabled !== null ? kv("Holat", u.disabled ? "O'chirilgan" : "Faol") : ""}
      ${kv("UID", `<span style="font-size:12.5px">${esc(u.uid)}</span>`, u.uid)}
      ${u.email ? kv("Email", esc(u.email), u.email) : ""}
    </ul>
    <div style="display:flex;gap:10px;margin-top:18px;flex-wrap:wrap">${u.email ? `<a class="btn primary" style="flex:1" href="mailto:${esc(u.email)}">${icon("i-mail")}Email yozish</a>` : ""}<button class="btn" style="flex:1" type="button" data-close>Yopish</button></div></div>`;
  const d = $("#sheet");
  if (typeof d.showModal === "function") d.showModal();
  else d.setAttribute("open", "");
}

/* ---------------- CSV ---------------- */
function exportCsv() {
  const rows = filteredUsers();
  const cell = (v) => {
    let s = v === null || v === undefined ? "" : String(v);
    if (/^[=+\-@\t\r]/.test(s)) s = "'" + s; // Excel formulasi in'ektsiyasidan himoya
    return `"${s.replace(/"/g, '""')}"`;
  };
  const head = ["uid", "email", "ism", "familiya", "yosh", "usul", "royxatdan_otgan", "oxirgi_kirish", "email_tasdiqlangan"];
  const lines = [head.join(",")].concat(
    rows.map((u) => [u.uid, u.email, u.firstName, u.lastName, u.age, u.provider, u.createdAt ? u.createdAt.toISOString() : "", u.lastSignIn ? u.lastSignIn.toISOString() : "", u.emailVerified === null ? "" : u.emailVerified ? "ha" : "yoq"].map(cell).join(","))
  );
  const blob = new Blob(["﻿" + lines.join("\r\n")], { type: "text/csv;charset=utf-8" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = `tajvid-foydalanuvchilar-${new Date().toISOString().slice(0, 10)}.csv`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
  toast(`${rows.length} ta qator yuklandi`);
}

/* ---------------- Ma'lumot yuklash ---------------- */
function explain(e) {
  const code = (e && (e.code || e.name)) || "";
  const msg = (e && e.message) || String(e);
  if (code.includes("permission-denied"))
    return { title: "Ruxsat yo'q (permission-denied)", text: "Firestore qoidalarida sizning emailingiz admin sifatida yozilmagan yoki qoidalar hali deploy qilinmagan. «Ulanish» bo'limidagi 3-bosqichni bajaring." };
  if (code.includes("not-found") || code.includes("functions/internal") || /adminListUsers/.test(msg))
    return { title: "Cloud Function topilmadi", text: "adminListUsers deploy qilinmagan yoki Blaze tarifi yoqilmagan. Yoki config.js da source: \"firestore\" ga qaytaring." };
  if (code.includes("unavailable") || code.includes("network"))
    return { title: "Internet yoki Firebase bilan aloqa yo'q", text: "Ulanishni tekshirib, qayta urinib ko'ring." };
  if (code.includes("failed-precondition"))
    return { title: "Indeks kerak", text: msg };
  return { title: "Kutilmagan xato", text: msg };
}
async function load() {
  state.status = "loading";
  state.error = null;
  render();
  try {
    if (state.demo) {
      await new Promise((r) => setTimeout(r, 450));
      state.users = demoUsers();
    } else if (state.source === "functions") {
      const res = await loadFunction(fb.fnMod, fb.functions);
      state.users = res.users;
      state.truncated = res.truncated;
    } else {
      state.users = await loadFirestore(fb.fs, fb.db, CONFIG.firestoreLimit);
    }
    state.fbError = null;
    try {
      state.feedback = state.demo ? demoFeedback() : await loadFeedback(fb.fs, fb.db, 500);
    } catch (e) {
      console.error(e);
      state.feedback = [];
      state.fbError = explain(e);
    }
    state.status = "ready";
    state.updatedAt = new Date();
  } catch (e) {
    console.error(e);
    state.status = "error";
    state.error = explain(e);
  }
  render();
}

/* ---------------- Kirish / Firebase ---------------- */
let busyAuth = false;

function gateBox(cls, title, text) {
  $("#gate-banner").innerHTML = text || title
    ? `<div class="banner ${cls}" style="margin-bottom:16px;text-align:left">${icon(cls === "ok" ? "i-check" : "i-alert")}<div><b>${esc(title)}</b>${text}</div></div>`
    : "";
}
function showGate(kind, extra) {
  $("#app").hidden = true;
  $("#tabbar").hidden = true;
  $("#gate").hidden = false;
  $("#auth-box").hidden = false;
  $("#verify-box").hidden = true;
  gateBox("", "", "");
  if (kind === "setup") {
    $("#auth-box").hidden = true;
    gateBox("", "Firebase hali ulanmagan", "<code>admin/js/config.js</code> ga Web ilovaning <b>apiKey</b> va <b>appId</b> qiymatlarini yozing. Hozircha demo rejimda ko'rishingiz mumkin.");
    $("#auth-box").hidden = false;
    $("#auth-form").hidden = true;
    return;
  }
  $("#auth-form").hidden = false;
  if (kind === "denied") gateBox("err", "Ruxsat yo'q", `${esc(extra || "Bu hisob")} admin emas.`);
  if (kind === "error") gateBox("err", "Kirib bo'lmadi", esc(extra || ""));
  if (kind === "info") gateBox("ok", "Tayyor", esc(extra || ""));
}
function showVerify(user) {
  $("#gate").hidden = false;
  $("#app").hidden = true;
  $("#tabbar").hidden = true;
  $("#auth-box").hidden = true;
  $("#verify-box").hidden = false;
  $("#verify-mail").textContent = " " + (user.email || "");
  gateBox("", "", "");
}
function authError(e) {
  const c = (e && e.code) || "";
  const map = {
    "auth/invalid-credential": ["Email yoki parol noto'g'ri", "Tekshirib qayta kiriting."],
    "auth/wrong-password": ["Email yoki parol noto'g'ri", ""],
    "auth/user-not-found": ["Bunday hisob topilmadi", "Hisob Firebase Console → Authentication → Users → Add user orqali yaratiladi."],
    "auth/invalid-email": ["Email noto'g'ri", "Manzilni tekshiring."],
    "auth/weak-password": ["Parol juda oddiy", "Kamida 8 belgi, harf va raqam ishlating."],
    "auth/too-many-requests": ["Urinishlar ko'p", "Biroz kutib, qayta urinib ko'ring."],
    "auth/user-disabled": ["Hisob bloklangan", ""],
    "auth/network-request-failed": ["Internet aloqasi yo'q", "Ulanishni tekshiring."],
    "auth/operation-not-allowed": ["Email/parol yoqilmagan", "Firebase Console → Authentication → Sign-in method → Email/Password ni yoqing."],
    "auth/unauthorized-domain": ["Bu domen ruxsat etilmagan", `<b>${esc(location.hostname)}</b> ni Authentication → Settings → Authorized domains ga qo'shing. Mahalliy ishlatsangiz <b>localhost</b> orqali oching.`],
    "auth/missing-password": ["Parolni kiriting", ""],
  };
  const m = map[c] || ["Kirib bo'lmadi", esc((e && e.message) || c)];
  gateBox("err", m[0], m[1]);
}
function startApp() {
  $("#gate").hidden = true;
  $("#app").hidden = false;
  $("#tabbar").hidden = false;
  $("#demo-ribbon").hidden = !state.demo;
  const me = state.me || { email: "demo@namuna", name: "Demo" };
  $("#me-name").textContent = me.name || "Admin";
  $("#me-mail").textContent = me.email || "";
  const av = $("#me-avatar");
  av.style.setProperty("--h", hue(me.email || "a"));
  av.textContent = initials(me.name || me.email);
  const h = location.hash.replace("#", "");
  state.view = TITLES[h] ? h : "overview";
  load();
}
async function handleUser(u) {
  if (!u) return showGate();
  if (!u.emailVerified) return showVerify(u);
  // Admin ekanini brauzer emas, Firestore qoidasi hal qiladi: ruxsat bo'lmasa o'qish rad etiladi.
  if (!state.demo) {
    try {
      await fb.fs.getDocs(fb.fs.query(fb.fs.collection(fb.db, "feedback"), fb.fs.limit(1)));
    } catch (e) {
      if ((e && e.code) === "permission-denied") {
        await fb.authMod.signOut(fb.auth);
        return showGate("denied", u.email);
      }
    }
  }
  state.me = { email: u.email, name: u.displayName || u.email };
  startApp();
}
async function initFirebase() {
  const [appM, authM, fsM] = await Promise.all([import(FB_BASE + "firebase-app.js"), import(FB_BASE + "firebase-auth.js"), import(FB_BASE + "firebase-firestore.js")]);
  const app = appM.initializeApp(CONFIG.firebase);
  fb = { app, authMod: authM, auth: authM.getAuth(app), fs: fsM, db: fsM.getFirestore(app) };
  if (state.source === "functions") {
    const fnMod = await import(FB_BASE + "firebase-functions.js");
    fb.fnMod = fnMod;
    fb.functions = fnMod.getFunctions(app, "us-central1");
  }
  authM.onAuthStateChanged(fb.auth, handleUser);
}
async function submitAuth(e) {
  e.preventDefault();
  if (busyAuth || !fb) return;
  const email = $("#a-email").value.trim().toLowerCase();
  const pass = $("#a-pass").value;
  const ok = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
  $("#a-email").setAttribute("aria-invalid", String(!ok));
  if (!ok) return gateBox("err", "Email noto'g'ri", "Manzilni tekshiring."), $("#a-email").focus();
  if (pass.length < 8) {
    $("#a-pass").setAttribute("aria-invalid", "true");
    return gateBox("err", "Parol qisqa", "Kamida 8 belgi kiriting.");
  }
  $("#a-pass").setAttribute("aria-invalid", "false");
  busyAuth = true;
  $("#a-submit").disabled = true;
  try {
    await fb.authMod.signInWithEmailAndPassword(fb.auth, email, pass);
    $("#a-pass").value = "";
  } catch (err) {
    authError(err);
  } finally {
    busyAuth = false;
    $("#a-submit").disabled = false;
  }
}
async function sendVerify() {
  const u = fb.auth.currentUser;
  if (!u) return showGate();
  const b = $("#v-send");
  b.disabled = true;
  try {
    await fb.authMod.sendEmailVerification(u);
    toast("Tasdiqlash xati yuborildi");
  } catch (err) {
    authError(err);
    toast(err.code === "auth/too-many-requests" ? "Biroz kutib qayta urinib ko'ring" : "Yuborib bo'lmadi");
  } finally {
    b.disabled = false;
  }
}
async function verifiedCheck() {
  const u = fb.auth.currentUser;
  if (!u) return showGate();
  try {
    await u.reload();
    await u.getIdToken(true); // tokendagi email_verified yangilansin (Firestore qoidasi uchun)
  } catch (err) {
    return toast("Tekshirib bo'lmadi: " + (err.code || ""));
  }
  if (!fb.auth.currentUser.emailVerified) return toast("Email hali tasdiqlanmagan");
  handleUser(fb.auth.currentUser);
}

/* ---------------- Voqealar ---------------- */
document.addEventListener("click", (e) => {
  if (e.target.closest("#sort-btn")) {
    const m = $("#sort-menu");
    return m.hidden ? openMenu() : closeMenu(true);
  }
  const opt = e.target.closest("#sort-menu li");
  if (opt) return pickSort(opt.dataset.val);
  if (!e.target.closest("#sort-dd")) closeMenu(false);
  if (e.target.closest("#q-clear")) {
    state.q = "";
    const q = $("#q");
    q.value = "";
    $("#q-clear").hidden = true;
    state.shown = 40;
    renderUsersList();
    return q.focus();
  }
  const t = e.target.closest("button, a, [data-uid]");
  if (!t) return;
  if (t.dataset.go) return go(t.dataset.go);
  if (t.dataset.view) return go(t.dataset.view);
  if (t.dataset.range) {
    state.range = Number(t.dataset.range);
    return render();
  }
  if (t.dataset.filter) {
    state.filter = t.dataset.filter;
    state.shown = 40;
    $$("[data-filter]").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.filter === state.filter)));
    return renderUsersList();
  }
  if (t.dataset.fbfilter) {
    state.fbFilter = t.dataset.fbfilter;
    state.fbShown = 30;
    $$("[data-fbfilter]").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.fbfilter === state.fbFilter)));
    return renderFeedbackList();
  }
  if (t.dataset.fbact) return fbAction(t.dataset.fbid, t.dataset.fbact, t);
  if (t.dataset.uid) return openSheet(t.dataset.uid);
  if (t.dataset.copy) return copy(t.dataset.copy);
  if ("close" in t.dataset) return $("#sheet").close();
  const act = t.dataset.act;
  if (act === "refresh") return load();
  if (act === "more") {
    state.shown += 40;
    return renderUsersList();
  }
  if (act === "csv") return exportCsv();
  if (act === "fbmore") {
    state.fbShown += 30;
    return renderFeedbackList();
  }
});
document.addEventListener("keydown", (e) => {
  const m = $("#sort-menu");
  if (!m || m.hidden) return;
  const items = $$("#sort-menu li");
  const i = items.indexOf(document.activeElement);
  if (e.key === "Escape") {
    e.preventDefault();
    return closeMenu(true);
  }
  if (e.key === "ArrowDown" || e.key === "ArrowUp") {
    e.preventDefault();
    const n = (i + (e.key === "ArrowDown" ? 1 : -1) + items.length) % items.length;
    return items[n].focus();
  }
  if ((e.key === "Enter" || e.key === " ") && i >= 0) {
    e.preventDefault();
    pickSort(items[i].dataset.val);
  }
  if (e.key === "Tab") closeMenu(false);
});
document.addEventListener("input", (e) => {
  if (e.target.id === "q") {
    const c = $("#q-clear");
    if (c) c.hidden = !e.target.value;
    state.q = e.target.value;
    state.shown = 40;
    renderUsersList();
  }
});
document.addEventListener("change", (e) => {
  if (e.target.id === "sort") {
    state.sort = e.target.value;
    renderUsersList();
  }
});
$("#sheet").addEventListener("click", (e) => {
  if (e.target === $("#sheet")) $("#sheet").close();
});
$("#btn-refresh").addEventListener("click", load);
const flip = () => setTheme(document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark");
$("#btn-theme").addEventListener("click", () => {
  flip();
  if (state.view === "overview") drawChart();
});
$("#btn-theme-m").addEventListener("click", () => {
  flip();
  if (state.view === "overview") drawChart();
});
$("#btn-out").addEventListener("click", async () => {
  if (state.demo) {
    location.href = location.pathname;
    return;
  }
  if (fb) await fb.authMod.signOut(fb.auth);
  state.users = [];
  state.status = "idle";
});
$("#auth-form").addEventListener("submit", submitAuth);
$("#v-send").addEventListener("click", sendVerify);
$("#v-done").addEventListener("click", verifiedCheck);
$("#v-out").addEventListener("click", async () => {
  if (fb) await fb.authMod.signOut(fb.auth);
  showGate();
});
$("#a-eye").addEventListener("click", () => {
  const i = $("#a-pass");
  const show = i.type === "password";
  i.type = show ? "text" : "password";
  $("#a-eye use").setAttribute("href", show ? "#i-eyeoff" : "#i-eye");
  $("#a-eye").setAttribute("aria-label", show ? "Parolni yashirish" : "Parolni ko'rsatish");
});
$("#btn-demo").addEventListener("click", () => {
  location.search = "?demo=1";
});
document.addEventListener("visibilitychange", () => {
  if (!document.hidden && state.status === "ready" && !state.demo && state.updatedAt && Date.now() - state.updatedAt > 5 * 60000 && !$("#app").hidden) load();
});

/* ---------------- Boshlash ---------------- */
(function boot() {
  let theme = null;
  try {
    theme = localStorage.getItem("admin-theme");
  } catch {}
  setTheme(theme || (matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark"));
  if (state.demo) {
    state.me = { email: "demo@namuna.uz", name: "Demo admin" };
    return startApp();
  }
  if (!configured()) return showGate("setup");
  showGate();
  initFirebase().catch((e) => {
    console.error(e);
    showGate("error", e.message || String(e));
  });
})();
