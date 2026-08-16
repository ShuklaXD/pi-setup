#!/usr/bin/env bash
# Download the free, redistributable NES homebrew collection from the retrobrews
# GitHub repo (shallow clone — the REST API is rate-limited) into the library.
# Idempotent: re-running only copies what's missing.
#
# Homebrew / public-domain only. Commercial NES ROMs (Mario, Contra, TMNT, …) are
# still under copyright and are deliberately NOT fetched — drop your own
# cartridge dumps into roms/nes/ instead (see README).
set -euo pipefail
LIBROOT="${1:-$HOME/emulatorjs/library}"
CACHE="$LIBROOT/../.cache/repos"
mkdir -p "$CACHE"

REPO="nes-games"
romdir="$LIBROOT/roms/nes"; artdir="$LIBROOT/art/nes"
mkdir -p "$romdir" "$artdir"

clone="$CACHE/$REPO"
if [ -d "$clone/.git" ]; then
  git -C "$clone" pull -q --ff-only 2>/dev/null || true
else
  echo "== cloning retrobrews/$REPO =="
  git clone --depth 1 -q "https://github.com/retrobrews/$REPO.git" "$clone" || {
    echo "  ! clone failed — check network, re-run later"; exit 1; }
fi

n=0
shopt -s nullglob nocaseglob
for f in "$clone"/*.nes; do
  base="$(basename "$f")"
  case "$base" in README*|LICENSE*) continue;; esac
  [ -f "$romdir/$base" ] || { cp "$f" "$romdir/$base"; n=$((n + 1)); }
  # box art shares the ROM basename (e.g. nomolos.nes / nomolos.png)
  stem="${base%.*}"
  [ -f "$clone/$stem.png" ] && [ ! -f "$artdir/$stem.png" ] && cp "$clone/$stem.png" "$artdir/$stem.png" || true
done
shopt -u nullglob nocaseglob

echo "  nes: +$n new ($(ls -1 "$romdir" | wc -l) total ROMs, $(ls -1 "$artdir" | wc -l) with art)"
