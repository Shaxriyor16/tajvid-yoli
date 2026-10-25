#!/usr/bin/env python3
"""Tajvid yo'li: bitta buyruq bilan yangi versiya chiqarish (Google Play'siz).

    python deploy/release.py 1.0.3 --notes-uz "Yangi dizayn va xatolar tuzatildi"

Nima qiladi (tartib bilan):
  1. pubspec.yaml da versiyani oshiradi (1.0.2+3 -> 1.0.3+4)
  2. flutter analyze + flutter test            (--skip-tests bilan o'tkazib yuboriladi)
  3. Bitta universal APK yig'adi (hamma qurilmalarga mos). --split bilan: arm64 (~38 MB) + armv7 (~34 MB) alohida
  4. APK larni website/downloads/ ga qo'yadi, website/version.json ni yozadi (sha256, hajm, izohlar)
  5. Saytni Vercel'ga joylaydi                 (--no-deploy bilan o'tkazib yuboriladi)
  6. git commit + tag v<versiya> + push, GitHub Release yaratadi (zaxira nusxa)  (--no-git)

Ilovalar `version.json` ni o'qib, yangi versiya borligini foydalanuvchiga ko'rsatadi
(lib/core/services/update_service.dart). `--min-build N` bersangiz, N dan eski versiyalar yangilashga
MAJBURLANADI.

Talab: flutter, vercel (kirgan), gh (kirgan), git. Imzo kaliti android/key.properties da (omborda yo'q).
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = ROOT / "pubspec.yaml"
WEBSITE = ROOT / "website"
APK_DIR = ROOT / "build" / "app" / "outputs" / "flutter-apk"
SITE_URL = "https://tajvid-yoli.vercel.app"  # domen olingach `set_domain.py` yangilaydi


def run(cmd, cwd=ROOT, check=True):
    print(f"\n$ {' '.join(map(str, cmd))}")
    cmd = [str(c) for c in cmd]  # bo'sh joyli yo'llarni subprocess o'zi to'g'ri qo'shtirnoqlaydi
    return subprocess.run(cmd, cwd=cwd, check=check, shell=(sys.platform == "win32"))


# gh o'rnatilgach yangi terminal ochilmaguncha PATH'ga tushmasligi mumkin: odatiy joylarni ham tekshiramiz.
EXTRA_PATHS = {
    "gh": [r"C:\Program Files\GitHub CLI\gh.exe", "/c/Program Files/GitHub CLI/gh.exe"],
}


def tool(name):
    found = shutil.which(name)
    if found:
        return name
    for p in EXTRA_PATHS.get(name, []):
        if Path(p).exists():
            return p
    return None


def need(name):
    if not tool(name):
        sys.exit(f"'{name}' topilmadi. O'rnating va qayta urinib ko'ring.")


def read_version():
    m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", PUBSPEC.read_text(encoding="utf-8"), re.M)
    if not m:
        sys.exit("pubspec.yaml da 'version: X.Y.Z+N' topilmadi.")
    return m.group(1), int(m.group(2))


def write_version(version, build):
    text = PUBSPEC.read_text(encoding="utf-8")
    text = re.sub(r"^version:.*$", f"version: {version}+{build}", text, count=1, flags=re.M)
    PUBSPEC.write_text(text, encoding="utf-8")


def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def newer(a, b):
    """a > b (X.Y.Z)."""
    return tuple(map(int, a.split("."))) > tuple(map(int, b.split(".")))


def main():
    ap = argparse.ArgumentParser(description="Yangi versiya chiqarish")
    ap.add_argument("version", help="yangi versiya, masalan 1.0.3")
    ap.add_argument("--notes-uz", default="", help="o'zbekcha izoh")
    ap.add_argument("--notes-en", default="", help="inglizcha izoh")
    ap.add_argument("--notes-ar", default="", help="arabcha izoh")
    ap.add_argument("--min-build", type=int, default=None,
                    help="shu build raqamidan ESKI versiyalar majburan yangilanadi")
    ap.add_argument("--split", action="store_true",
                    help="har bir qurilma uchun alohida kichik APK (arm64 ~38 MB, armv7 ~34 MB). Standart: bitta universal APK")
    ap.add_argument("--only-arm64", action="store_true", help="--split bilan: faqat arm64 yig'ish (tezroq)")
    ap.add_argument("--apk", help="tayyor APK yo'li (yig'ishni o'tkazib yuboradi, sinov uchun)")
    ap.add_argument("--no-obfuscate", action="store_true", help="kodni siqish/yashirishni o'chirish")
    ap.add_argument("--skip-tests", action="store_true")
    ap.add_argument("--no-deploy", action="store_true", help="Vercel'ga joylamaslik")
    ap.add_argument("--no-git", action="store_true", help="git commit/tag/push va GitHub Release yo'q")
    ap.add_argument("--dry-run", action="store_true", help="faqat rejani ko'rsatadi")
    a = ap.parse_args()

    if not re.fullmatch(r"\d+\.\d+\.\d+", a.version):
        sys.exit("Versiya X.Y.Z ko'rinishida bo'lsin (masalan 1.0.3).")
    cur_version, cur_build = read_version()
    if not newer(a.version, cur_version):
        sys.exit(f"Yangi versiya ({a.version}) hozirgisidan ({cur_version}) katta bo'lishi kerak.")
    build = cur_build + 1
    min_build = a.min_build if a.min_build is not None else 0
    split = a.split or a.only_arm64
    abis = (["arm64-v8a"] if a.only_arm64 else ["arm64-v8a", "armeabi-v7a"]) if split else ["universal"]

    print(f"Versiya: {cur_version}+{cur_build}  ->  {a.version}+{build}")
    print(f"APK: {'har bir qurilma uchun alohida (' + ', '.join(abis) + ')' if split else 'bitta universal (hamma qurilmalarga mos)'}  |  "
          + (f"majburiy yangilash: build < {min_build}" if min_build else "majburiy yangilash: yo'q"))
    if a.dry_run:
        print("\n(dry-run: hech narsa o'zgartirilmadi)")
        return

    for name in ["flutter"] + ([] if a.no_deploy else ["vercel"]) + ([] if a.no_git else ["git", "gh"]):
        need(name)

    write_version(a.version, build)
    built = {}
    try:
        if not a.skip_tests:
            run(["flutter", "analyze", "--no-fatal-infos"])
            run(["flutter", "test"])
        if a.apk:
            if not Path(a.apk).exists():
                sys.exit(f"APK topilmadi: {a.apk}")
            built[abis[0]] = Path(a.apk)
        else:
            # Standart: bitta universal APK. --split: har bir arxitektura uchun alohida (kichik) APK.
            # --obfuscate: Dart kodi kichrayadi va o'qish qiyinlashadi (belgilar build/symbols da saqlanadi).
            cmd = ["flutter", "build", "apk", "--release"] + (["--split-per-abi"] if split else [])
            if not a.no_obfuscate:
                cmd += ["--obfuscate", "--split-debug-info=build/symbols"]
            if a.only_arm64:
                cmd += ["--target-platform", "android-arm64"]
            run(cmd)
            for abi in abis:
                f = APK_DIR / ("app-release.apk" if abi == "universal" else f"app-{abi}-release.apk")
                if not f.exists():
                    sys.exit(f"APK topilmadi: {f}")
                built[abi] = f
            gradlew = ROOT / "android" / ("gradlew.bat" if sys.platform == "win32" else "gradlew")
            if gradlew.exists():
                run([str(gradlew), "--stop"], cwd=ROOT / "android", check=False)  # kompyuter qizib ketmasin
    except subprocess.CalledProcessError as e:
        write_version(cur_version, cur_build)  # xato bo'lsa versiya orqaga qaytadi
        sys.exit(f"Xato ({e.returncode}). Versiya {cur_version}+{cur_build} ga qaytarildi.")

    downloads = WEBSITE / "downloads"
    downloads.mkdir(parents=True, exist_ok=True)
    for old in downloads.glob("*.apk"):
        old.unlink()  # eski versiya fayllari qolib ketmasin
    apks, dests = {}, []
    for abi, src in built.items():
        dest = downloads / ("tajvid-yoli.apk" if abi == "universal" else f"tajvid-yoli-{abi}.apk")
        shutil.copyfile(src, dest)
        dests.append(dest)
        apks[abi] = {"url": f"{SITE_URL}/downloads/{dest.name}", "sha256": sha256_of(dest), "sizeBytes": dest.stat().st_size}
        print(f"APK {abi}: {dest.name}  {dest.stat().st_size / 1048576:.1f} MB  sha256={apks[abi]['sha256'][:16]}...")
    main_apk = apks.get("arm64-v8a") or apks["universal"]
    info = {
        "version": a.version,
        "build": build,
        "minBuild": min_build,
        "url": main_apk["url"],  # eski ilovalar va noma'lum arxitektura uchun zaxira (arm64)
        "sha256": main_apk["sha256"],
        "sizeBytes": main_apk["sizeBytes"],
        **({"apks": apks} if split else {}),  # universal rejimda faqat "url" yetarli
        "notes": {k: v for k, v in (("uz", a.notes_uz), ("en", a.notes_en), ("ar", a.notes_ar)) if v},
        "publishedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    (WEBSITE / "version.json").write_text(json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if not a.no_deploy:
        run(["vercel", "deploy", "--prod", "--yes"], cwd=WEBSITE)

    if not a.no_git:
        tag = f"v{a.version}"
        run(["git", "add", "pubspec.yaml", "website/version.json"])
        run(["git", "commit", "-m", f"Release {tag} (build {build})"])
        run(["git", "tag", tag])
        run(["git", "push", "origin", "HEAD"])
        run(["git", "push", "origin", tag])
        notes = a.notes_uz or a.notes_en or f"Tajvid yo'li {a.version}"
        run([tool("gh"), "release", "create", tag, *map(str, dests), "--title", f"Tajvid yo'li {a.version}", "--notes", notes])

    print(f"\nTayyor: {a.version} (build {build}). Foydalanuvchilar ilovani ochganda yangilanish taklifini ko'radi.")


if __name__ == "__main__":
    main()
