#!/usr/bin/env python3
"""Tajvid yo'li: bitta buyruq bilan yangi versiya chiqarish (Google Play'siz).

    python deploy/release.py 1.0.3 --notes-uz "Yangi dizayn va xatolar tuzatildi"

Nima qiladi (tartib bilan):
  1. pubspec.yaml da versiyani oshiradi (1.0.2+3 -> 1.0.3+4)
  2. flutter analyze + flutter test            (--skip-tests bilan o'tkazib yuboriladi)
  3. Release APK yig'adi (hamma qurilmalarga mos universal; --arm64 tezroq va kichikroq)
  4. APK ni website/downloads/tajvid-yoli.apk ga qo'yadi, website/version.json ni yozadi (sha256, hajm, izohlar)
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
APK_OUT = ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
SITE_URL = "https://tajvid-yoli.vercel.app"  # domen olingach `set_domain.py` yangilaydi


def run(cmd, cwd=ROOT, check=True):
    print(f"\n$ {' '.join(map(str, cmd))}")
    return subprocess.run(cmd, cwd=cwd, check=check, shell=(sys.platform == "win32"))


def need(tool):
    if not shutil.which(tool):
        sys.exit(f"'{tool}' topilmadi. O'rnating va qayta urinib ko'ring.")


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
    ap.add_argument("--arm64", action="store_true", help="faqat arm64 (tezroq, ~40 MB)")
    ap.add_argument("--apk", help="tayyor APK yo'li (yig'ishni o'tkazib yuboradi)")
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

    print(f"Versiya: {cur_version}+{cur_build}  ->  {a.version}+{build}")
    print(f"APK: {'tayyor fayl ' + a.apk if a.apk else ('arm64' if a.arm64 else 'universal')}  |  majburiy yangilash: build < {min_build}"
          if min_build else f"APK: {'tayyor fayl ' + a.apk if a.apk else ('arm64' if a.arm64 else 'universal')}  |  majburiy yangilash: yo'q")
    if a.dry_run:
        print("\n(dry-run: hech narsa o'zgartirilmadi)")
        return

    for tool in ["flutter"] + ([] if a.no_deploy else ["vercel"]) + ([] if a.no_git else ["git", "gh"]):
        need(tool)

    write_version(a.version, build)
    try:
        if not a.skip_tests:
            run(["flutter", "analyze", "--no-fatal-infos"])
            run(["flutter", "test"])
        if a.apk:
            apk = Path(a.apk)
            if not apk.exists():
                sys.exit(f"APK topilmadi: {apk}")
        else:
            cmd = ["flutter", "build", "apk", "--release"]
            if a.arm64:
                cmd += ["--target-platform", "android-arm64"]
            run(cmd)
            apk = APK_OUT
            gradlew = ROOT / "android" / ("gradlew.bat" if sys.platform == "win32" else "gradlew")
            if gradlew.exists():
                run([str(gradlew), "--stop"], cwd=ROOT / "android", check=False)  # kompyuter qizib ketmasin
    except subprocess.CalledProcessError as e:
        write_version(cur_version, cur_build)  # xato bo'lsa versiya orqaga qaytadi
        sys.exit(f"Xato ({e.returncode}). Versiya {cur_version}+{cur_build} ga qaytarildi.")

    dest = WEBSITE / "downloads" / "tajvid-yoli.apk"
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(apk, dest)
    info = {
        "version": a.version,
        "build": build,
        "minBuild": min_build,
        "url": f"{SITE_URL}/downloads/tajvid-yoli.apk",
        "sha256": sha256_of(dest),
        "sizeBytes": dest.stat().st_size,
        "notes": {k: v for k, v in (("uz", a.notes_uz), ("en", a.notes_en), ("ar", a.notes_ar)) if v},
        "publishedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    (WEBSITE / "version.json").write_text(json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"\nAPK: {dest}  ({info['sizeBytes'] / 1048576:.1f} MB)  sha256={info['sha256'][:16]}...")

    if not a.no_deploy:
        run(["vercel", "deploy", "--prod", "--yes"], cwd=WEBSITE)

    if not a.no_git:
        tag = f"v{a.version}"
        run(["git", "add", "pubspec.yaml", "website/version.json"])
        run(["git", "commit", "-m", f"Release {tag} (build {build})"])
        run(["git", "tag", tag])
        run(["git", "push", "origin", "HEAD", "--follow-tags"])
        notes = a.notes_uz or a.notes_en or f"Tajvid yo'li {a.version}"
        run(["gh", "release", "create", tag, str(dest), "--title", f"Tajvid yo'li {a.version}", "--notes", notes])

    print(f"\nTayyor: {a.version} (build {build}). Foydalanuvchilar ilovani ochganda yangilanish taklifini ko'radi.")


if __name__ == "__main__":
    main()
