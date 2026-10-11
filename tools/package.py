"""Build the CurseForge / release zip: dist/SimpleRogueHelperForever-<version>.zip

The zip holds a single SimpleRogueHelperForever/ folder with what the game
loads: the TOC and its files, Bindings.xml, LICENSE, README and CHANGELOG.
The tests, tools and docs are left out.

Usage:
    python tools/package.py
"""
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = "SimpleRogueHelperForever"
EXTRA = ["Bindings.xml", "LICENSE", "README.md", "CHANGELOG.md"]


def build(dist=None):
    """The zip, in dist/ (or the folder given); its path."""
    toc = (ROOT / f"{ADDON}.toc").read_text(encoding="utf-8")
    version = re.search(r"^## Version:\s*(\S+)", toc, re.M).group(1)
    # (the TOC's paths with the game's backslash, the zip's with a slash)
    listed = [line.strip().replace("\\", "/") for line in toc.splitlines()
              if line.strip() and not line.startswith("#")]

    files = [f"{ADDON}.toc"] + listed + EXTRA
    missing = [f for f in files if not (ROOT / f).is_file()]
    if missing:
        sys.exit("Missing files: " + ", ".join(missing))

    dist = Path(dist) if dist else ROOT / "dist"
    dist.mkdir(exist_ok=True)
    out = dist / f"{ADDON}-{version}.zip"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files:
            z.write(ROOT / f, f"{ADDON}/{f}")
    size = out.stat().st_size / 1024
    print(f"{out.name}: {len(files)} files, {size:.0f} KB")
    return out


def main():
    build()


if __name__ == "__main__":
    main()
