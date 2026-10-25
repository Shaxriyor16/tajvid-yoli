(function () {
  "use strict";
  var root = document.documentElement;
  var store = {
    get: function (k) {
      try {
        return localStorage.getItem(k);
      } catch (e) {
        return null;
      }
    },
    set: function (k, v) {
      try {
        localStorage.setItem(k, v);
      } catch (e) {}
    },
  };

  /* Til: ?lang=en, saqlangan tanlov yoki brauzer tili */
  var params = new URLSearchParams(location.search);
  var lang = params.get("lang") || store.get("lang");
  if (lang !== "uz" && lang !== "en") {
    lang = /^en/i.test(navigator.language || "") ? "en" : "uz";
  }
  function setLang(l) {
    lang = l;
    root.setAttribute("data-lang", l);
    root.setAttribute("lang", l);
    store.set("lang", l);
    var btn = document.getElementById("lang-btn");
    if (btn) btn.textContent = l === "uz" ? "EN" : "UZ";
    var t = document.documentElement.getAttribute("data-title-" + l);
    if (t) document.title = t;
  }
  setLang(lang);
  var langBtn = document.getElementById("lang-btn");
  if (langBtn) {
    langBtn.addEventListener("click", function () {
      setLang(lang === "uz" ? "en" : "uz");
    });
  }

  /* Mavzu: kun / tun */
  var theme = store.get("theme");
  if (theme === "light" || theme === "dark") root.setAttribute("data-theme", theme);
  var themeBtn = document.getElementById("theme-btn");
  if (themeBtn) {
    themeBtn.addEventListener("click", function () {
      var dark =
        root.getAttribute("data-theme") === "dark" ||
        (!root.getAttribute("data-theme") &&
          window.matchMedia("(prefers-color-scheme: dark)").matches);
      var next = dark ? "light" : "dark";
      root.setAttribute("data-theme", next);
      store.set("theme", next);
    });
  }

  /* Mobil menyu */
  var menuBtn = document.getElementById("menu-btn");
  var links = document.getElementById("nav-links");
  if (menuBtn && links) {
    menuBtn.addEventListener("click", function () {
      var open = links.classList.toggle("open");
      menuBtn.setAttribute("aria-expanded", open ? "true" : "false");
    });
    links.addEventListener("click", function (e) {
      if (e.target.tagName === "A") {
        links.classList.remove("open");
        menuBtn.setAttribute("aria-expanded", "false");
      }
    });
  }

  /* Sarlavha soyasi */
  var header = document.querySelector(".site-header");
  function onScroll() {
    if (header) header.classList.toggle("scrolled", window.scrollY > 8);
  }
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  /* Paydo bo'lish */
  var items = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && items.length) {
    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting) {
            en.target.classList.add("in");
            io.unobserve(en.target);
          }
        });
      },
      { threshold: 0.12 }
    );
    items.forEach(function (el) {
      io.observe(el);
    });
  } else {
    items.forEach(function (el) {
      el.classList.add("in");
    });
  }

  var y = document.getElementById("year");
  if (y) y.textContent = new Date().getFullYear();

  /* 3D egilish: sichqoncha ostida kartalar sal qiyshayadi */
  var fine = window.matchMedia("(hover: hover) and (pointer: fine)").matches;
  var calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (fine && !calm) {
    document.querySelectorAll(".card, .step").forEach(function (el) {
      el.classList.add("tilt");
      if (el.classList.contains("reveal")) {
        setTimeout(function () {
          el.classList.add("done");
        }, 1400);
      }
      el.addEventListener("pointermove", function (e) {
        var r = el.getBoundingClientRect();
        var x = e.clientX - r.left,
          y = e.clientY - r.top;
        el.style.setProperty("--ry", ((x / r.width - 0.5) * 11).toFixed(2) + "deg");
        el.style.setProperty("--rx", ((0.5 - y / r.height) * 11).toFixed(2) + "deg");
        el.style.setProperty("--mx", x + "px");
        el.style.setProperty("--my", y + "px");
        el.classList.add("active");
      });
      el.addEventListener("pointerleave", function () {
        el.style.setProperty("--rx", "0deg");
        el.style.setProperty("--ry", "0deg");
        el.classList.remove("active");
      });
    });
  }

  /* Galereya: markazdagi telefon to'g'ri, chetdagilari 3D burilgan */
  var gal = document.querySelector(".gallery");
  if (gal && !calm) {
    var shots = gal.querySelectorAll(".shot");
    var ticking = false;
    var update = function () {
      ticking = false;
      var gr = gal.getBoundingClientRect();
      var cx = gr.left + gr.width / 2;
      shots.forEach(function (s) {
        var r = s.getBoundingClientRect();
        var d = (r.left + r.width / 2 - cx) / (gr.width / 2);
        d = Math.max(-1.4, Math.min(1.4, d));
        var ang = -d * 32;
        var sc = 1 - Math.min(Math.abs(d), 1.2) * 0.1;
        s.style.transform =
          "rotateY(" + ang.toFixed(1) + "deg) scale(" + sc.toFixed(3) + ")";
        s.style.opacity = (1 - Math.min(Math.abs(d), 1.4) * 0.28).toFixed(2);
      });
    };
    var req = function () {
      if (!ticking) {
        ticking = true;
        requestAnimationFrame(update);
      }
    };
    gal.addEventListener("scroll", req, { passive: true });
    window.addEventListener("resize", req);
    update();
  }

  /* "Chiqqanda xabar bering" oynasi */
  var dlg = document.getElementById("notify");

  /* Xat matnlari: sizga boradigan xabar (uz) va obunachiga boradigan tasdiq (til bo'yicha).
     FormSubmit xat dizaynini o'zgartirishga ruxsat bermaydi, faqat andoza (box) va matnlarni. */
  var AUTO = {
    uz:
      "Assalomu alaykum!\n\n" +
      "Tajvid yo'li ilovasi chiqqanda sizga xabar beramiz — so'rovingiz qabul qilindi. Rahmat!\n\n" +
      "Ilova nima beradi:\n" +
      "• Arab alifbosidan tajvid qoidalarigacha bosqichma-bosqich darslar\n" +
      "• Talaffuzingizni tekshiruvchi sun'iy intellekt\n" +
      "• Kunlik reja, streak va sertifikat\n\n" +
      "Bu avtomatik xabar, unga javob berish shart emas. Emailingiz faqat ilova chiqishi haqida xabar berish uchun ishlatiladi.\n\n" +
      "Tajvid yo'li jamoasi",
    en:
      "Hello!\n\n" +
      "We'll let you know as soon as the Tajvid yo'li app is released. Your request has been received. Thank you!\n\n" +
      "What the app offers:\n" +
      "• Step-by-step lessons from the Arabic alphabet to tajweed rules\n" +
      "• An AI that checks your pronunciation\n" +
      "• Daily plan, streak and certificates\n\n" +
      "This is an automatic message, no reply is needed. Your email is used only to tell you about the release.\n\n" +
      "The Tajvid yo'li team",
  };
  function mailPayload(email) {
    return {
      email: email,
      Rozilik: "Ha — faqat chiqish haqida xabar berish uchun",
      Til: lang === "en" ? "English" : "O'zbekcha",
      Sahifa: location.href,
      _subject: "🌙 Tajvid yo'li — yangi kutuvchi: " + email,
      _replyto: email,
      _template: "box",
      _captcha: "false",
      _autoresponse: AUTO[lang] || AUTO.uz,
    };
  }

  var form = document.getElementById("notify-form");
  if (dlg && form) {
    var msg = document.getElementById("nf-msg");
    var submit = document.getElementById("nf-submit");
    var emailInput = document.getElementById("nf-email");
    var T = {
      uz: {
        bad: "Emailni to'g'ri kiriting (masalan: ism@pochta.uz).",
        consent: "Davom etish uchun rozilik belgisini qo'ying.",
        ok: "Rahmat! Ilova chiqqanda sizga xabar beramiz.",
        wait: "Biroz kuting va qayta urinib ko'ring.",
        fail: "Yuborib bo'lmadi. Internetni tekshiring yoki support@tajvidyoli.uz ga yozing.",
      },
      en: {
        bad: "Enter a valid email (for example: name@mail.com).",
        consent: "Please tick the consent box to continue.",
        ok: "Thank you! We'll let you know when the app is released.",
        wait: "Please wait a moment and try again.",
        fail: "Could not send. Check your connection or write to support@tajvidyoli.uz.",
      },
    };
    var say = function (key, kind) {
      msg.textContent = T[lang][key] || key;
      msg.className = "form-msg " + (kind || "");
    };
    document.querySelectorAll("[data-open='notify']").forEach(function (b) {
      b.addEventListener("click", function () {
        say("", "");
        msg.textContent = "";
        if (typeof dlg.showModal === "function") dlg.showModal();
        else dlg.setAttribute("open", "");
        setTimeout(function () {
          emailInput.focus();
        }, 60);
      });
    });
    dlg.querySelectorAll("[data-close]").forEach(function (b) {
      b.addEventListener("click", function () {
        dlg.close();
      });
    });
    dlg.addEventListener("click", function (e) {
      if (e.target === dlg) dlg.close();
    });
    form.addEventListener("submit", function (e) {
      var email = emailInput.value.trim();
      var valid = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
      emailInput.setAttribute("aria-invalid", valid ? "false" : "true");
      if (!valid) {
        e.preventDefault();
        say("bad", "err");
        emailInput.focus();
        return;
      }
      if (!form.elements.consent.checked) {
        e.preventDefault();
        say("consent", "err");
        return;
      }
      if (typeof fetch !== "function") return; // oddiy POST (JS'siz variant)
      e.preventDefault();
      if (form.elements._honey.value) {
        say("ok", "ok"); // bot: jim yutib yuboramiz
        return;
      }
      var last = Number(store.get("notify_ts") || 0);
      if (Date.now() - last < 30000) {
        say("wait", "err");
        return;
      }
      submit.disabled = true;
      fetch(form.getAttribute("data-endpoint"), {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify(mailPayload(email)),
      })
        .then(function (r) {
          return r.json().then(function (d) {
            return { ok: r.ok, d: d };
          });
        })
        .then(function (res) {
          var good = res.ok && (res.d.success === true || res.d.success === "true");
          if (!good) throw new Error("rad etildi");
          store.set("notify_ts", String(Date.now()));
          form.reset();
          say("ok", "ok");
        })
        .catch(function () {
          say("fail", "err");
        })
        .then(function () {
          submit.disabled = false;
        });
    });
  }

  /* Maxfiylik mundarijasi: tanlangan til blokidagi bo'limga o'tish */
  function goSec(n) {
    var el = document.querySelector('[lang="' + lang + '"] [data-sec="' + n + '"]');
    if (el) el.scrollIntoView({ behavior: calm ? "auto" : "smooth", block: "start" });
  }
  document.querySelectorAll('.toc a[href^="#s"]').forEach(function (a) {
    a.addEventListener("click", function (e) {
      e.preventDefault();
      goSec(a.getAttribute("href").replace("#s", ""));
    });
  });
  if (/^#s\d+$/.test(location.hash)) {
    setTimeout(function () {
      goSec(location.hash.replace("#s", ""));
    }, 80);
  }
})();

/* APK yuklab olish: /version.json (release skripti yozadi) mavjud bo'lsa yuklab olish tugmasi ko'rinadi.
   Telefon 64-bit bo'lsa arm64, 32-bit bo'lsa armeabi-v7a APK beriladi (har biri ~35-40 MB). Fayl bo'lmasa, tugma yo'q. */
(function () {
  var apk = document.getElementById("apk-btn");
  var soon = document.querySelector('[data-open="notify"]');
  var note = document.getElementById("soon-note");
  if (!apk || !window.fetch) return;

  function safe(u) {
    try {
      var p = new URL(u, location.href);
      // Faqat /downloads/*.apk yo'li olinadi va shu saytning o'z domenida ishlatiladi (tashqi havola yo'q).
      return /^\/downloads\/[\w.-]+\.apk$/.test(p.pathname) ? p.pathname : null;
    } catch (e) {
      return null;
    }
  }
  function mb(n) {
    return n ? " \u00b7 " + Math.round(n / 1048576) + " MB" : "";
  }
  // Brauzer bitness'ni bersa (Chrome/Android) shuni ishlatamiz, aks holda 64-bit deb olamiz.
  function bitness() {
    var uad = navigator.userAgentData;
    if (!uad || !uad.getHighEntropyValues) return Promise.resolve("64");
    return uad.getHighEntropyValues(["bitness"]).then(function (r) { return r.bitness || "64"; }, function () { return "64"; });
  }

  Promise.all([fetch("/version.json", { cache: "no-store" }).then(function (r) { return r.ok ? r.json() : null; }), bitness()])
    .then(function (res) {
      var v = res[0], bits = res[1];
      if (!v) return;
      var apks = v.apks || {};
      var a64 = apks["arm64-v8a"] || { url: v.url, sizeBytes: v.sizeBytes };
      var a32 = apks["armeabi-v7a"] || null;
      var pick = bits === "32" && a32 ? a32 : a64;
      var other = pick === a64 ? a32 : a64;
      var href = safe(pick.url);
      if (!href) return;
      apk.setAttribute("href", href);
      apk.hidden = false;
      if (soon) soon.hidden = true;
      var small = document.createElement("small");
      small.textContent = "v" + String(v.version || "").replace(/[^\d.]/g, "") + mb(pick.sizeBytes);
      small.style.cssText = "opacity:.7;font-weight:600;margin-left:6px";
      apk.appendChild(small);
      if (note) {
        var otherHref = other && safe(other.url);
        var otherLabel = pick === a64 ? ["32-bit (eski) telefon uchun", "For older 32-bit phones"] : ["64-bit telefon uchun", "For 64-bit phones"];
        note.innerHTML =
          '<ul class="apk-meta">' +
          '<li><span lang="uz">Android 5.0 va undan yuqori</span><span lang="en">Android 5.0 or newer</span></li>' +
          '<li><span lang="uz">Bepul</span><span lang="en">Free</span></li>' +
          '<li><span lang="uz">Ilova o\u2018zi yangilanadi: yangi versiya chiqsa, taklif ko\u2018rsatadi</span><span lang="en">The app tells you when a new version is out</span></li>' +
          '<li><span lang="uz">O\u2018rnatishda \u201cNomaʼlum manbalar\u201d ruxsatini bering</span><span lang="en">Allow \u201cInstall unknown apps\u201d when asked</span></li>' +
          (otherHref
            ? '<li><a href="' + otherHref + '" download><span lang="uz">' + otherLabel[0] + '</span><span lang="en">' + otherLabel[1] + "</span>" + mb(other.sizeBytes) + "</a></li>"
            : "") +
          "</ul>";
      }
    })
    .catch(function () {});
})();
