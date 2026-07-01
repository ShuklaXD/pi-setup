#!/usr/bin/env bash
# Download the free, redistributable homebrew NES collection (retrobrews/nes-games)
# into the ROM folder. Idempotent: skips files already present. Homebrew only —
# no commercial ROMs.
set -euo pipefail
DEST="${1:-$HOME/emulatorjs/library/roms/nes}"
mkdir -p "$DEST"

echo "Listing retrobrews/nes-games…"
curl -fsSL "https://api.github.com/repos/retrobrews/nes-games/contents/" \
  | python3 -c '
import sys, json
for f in json.load(sys.stdin):
    if isinstance(f, dict) and f.get("name","").lower().endswith(".nes"):
        print(f["name"] + "\t" + f["download_url"])
' | while IFS=$'\t' read -r name url; do
  out="$DEST/$name"
  [ -f "$out" ] && continue
  if curl -fsSL "$url" -o "$out"; then echo "  + $name"; else echo "  ! failed $name"; rm -f "$out"; fi
done
echo "NES ROMs: $(ls -1 "$DEST" | wc -l) files in $DEST"
