#!/usr/bin/env bash
# Scan the ROM folders and (re)write library/games.json used by the menu page.
set -euo pipefail
LIB="${1:-$HOME/emulatorjs/library}"
python3 - "$LIB" <<'PY'
import sys, os, json
lib = sys.argv[1]
roms = os.path.join(lib, "roms")
# folder name -> EmulatorJS core name
CORE = {"nes":"nes","snes":"snes","gb":"gb","gbc":"gb","gba":"gba",
        "genesis":"segaMD","md":"segaMD","sms":"segaMS","n64":"n64",
        "arcade":"arcade","psx":"psx","atari2600":"atari2600"}
EXT = {".nes",".sfc",".smc",".gb",".gbc",".gba",".md",".gen",".bin",".z64",".n64",".a26"}
def title(fn):
    n = os.path.splitext(fn)[0].replace("-", " ").replace("_", " ")
    return " ".join(w.capitalize() for w in n.split())
games = []
if os.path.isdir(roms):
    for system in sorted(os.listdir(roms)):
        sd = os.path.join(roms, system)
        if not os.path.isdir(sd): continue
        core = CORE.get(system.lower(), system.lower())
        for fn in sorted(os.listdir(sd)):
            if fn.startswith(".") or os.path.splitext(fn)[1].lower() not in EXT: continue
            games.append({"title": title(fn), "system": system.lower(),
                          "core": core, "rom": "roms/%s/%s" % (system, fn)})
os.makedirs(lib, exist_ok=True)
with open(os.path.join(lib, "games.json"), "w") as f:
    json.dump({"games": games}, f, indent=2)
print("games.json: %d games" % len(games))
PY
