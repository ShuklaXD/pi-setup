#!/usr/bin/env bash
# Scan roms/nes/ and (re)write library/games.json used by the menu page.
# Picks up any ROM you drop in yourself, not just the fetched homebrew.
#
# Display names: derived from the filename, unless overridden in titles.txt
# (next to this script) with "filename.nes = Nice Title" lines.
set -euo pipefail
LIB="${1:-$HOME/emulatorjs/library}"
SELF="$(cd "$(dirname "$0")" && pwd)"
python3 - "$LIB" "$SELF/titles.txt" <<'PY'
import sys, os, json, re

lib, titles_file = sys.argv[1], sys.argv[2]
romdir = os.path.join(lib, "roms", "nes")
EXT = {".nes", ".unf", ".unif", ".fds"}

# Optional display-name overrides: "filename.nes = Nice Title"
overrides = {}
if os.path.isfile(titles_file):
    for line in open(titles_file, encoding="utf-8"):
        line = line.split("#", 1)[0].strip()
        if "=" in line:
            k, v = line.split("=", 1)
            overrides[k.strip().lower()] = v.strip()

SMALL = {"of", "the", "a", "an", "and", "or", "in", "on", "to", "vs"}

def title(fn):
    if fn.lower() in overrides:
        return overrides[fn.lower()]
    n = os.path.splitext(fn)[0]
    n = re.sub(r"[\-_.]+", " ", n)             # dashes/underscores -> spaces
    n = re.sub(r"\s*\([^)]*\)", "", n)         # strip (U), (USA), [!] tags
    n = re.sub(r"\s*\[[^\]]*\]", "", n)
    n = re.sub(r"\s+", " ", n).strip()
    words = n.split()
    out = []
    for i, w in enumerate(words):
        out.append(w if w.isupper() and len(w) > 1                # keep acronyms
                   else w.lower() if i and w.lower() in SMALL     # minor words
                   else w[:1].upper() + w[1:].lower())
    return " ".join(out) or os.path.splitext(fn)[0]

games = []
if os.path.isdir(romdir):
    for fn in sorted(os.listdir(romdir), key=str.lower):
        if fn.startswith(".") or os.path.splitext(fn)[1].lower() not in EXT:
            continue
        stem = os.path.splitext(fn)[0]
        art = None
        for ext in (".png", ".jpg", ".jpeg", ".webp"):
            if os.path.isfile(os.path.join(lib, "art", "nes", stem + ext)):
                art = "art/nes/%s%s" % (stem, ext)
                break
        games.append({"title": title(fn), "system": "NES", "core": "nes",
                      "rom": "roms/nes/%s" % fn, "art": art})

games.sort(key=lambda g: g["title"].lower())
os.makedirs(lib, exist_ok=True)
with open(os.path.join(lib, "games.json"), "w", encoding="utf-8") as f:
    json.dump({"games": games}, f, indent=2)
print("games.json: %d NES games (%d with box art)"
      % (len(games), sum(1 for g in games if g["art"])))
PY
