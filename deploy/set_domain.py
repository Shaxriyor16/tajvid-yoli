"""Domen olingach: python deploy/set_domain.py https://tajvidyoli.uz
canonical, og:url, og:image, sitemap va robots dagi manzillarni yangi domenga almashtiradi."""
import sys, pathlib

OLD = "https://tajvid-yoli.vercel.app"
if len(sys.argv) != 2 or not sys.argv[1].startswith("http"):
    sys.exit("Ishlatish: python deploy/set_domain.py https://tajvidyoli.uz")
new = sys.argv[1].rstrip("/")
n = 0
for f in pathlib.Path("website").rglob("*"):
    if f.suffix in {".html", ".xml", ".txt", ".json", ".webmanifest"} and f.is_file():
        s = f.read_text(encoding="utf-8")
        if OLD in s:
            f.write_text(s.replace(OLD, new), encoding="utf-8")
            n += 1
print(f"{n} ta fayl yangilandi: {OLD} -> {new}")
