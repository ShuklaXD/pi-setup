#!/usr/bin/env bash
# Download the free, redistributable homebrew game collections from the
# retrobrews GitHub repos, across every system EmulatorJS can play. Uses shallow
# git clones (not the REST API, which is rate-limited). Idempotent. Homebrew /
# public-domain only — no commercial ROMs.
set -euo pipefail
LIBROOT="${1:-$HOME/emulatorjs/library}"
CACHE="$LIBROOT/../.cache/repos"
mkdir -p "$CACHE"

# retrobrews repo | local folder | ROM extensions (space-separated)
MAP="
nes-games|nes|nes
snes-games|snes|smc sfc
gbc-games|gbc|gb gbc
gba-games|gba|gba
md-games|md|bin smd
sms-games|sms|sms
atari2600-games|atari2600|bin
colecovision-games|coleco|rom bin
c64-games|c64|prg d64 tap
"

echo "$MAP" | while IFS='|' read -r repo folder exts; do
  [ -z "$repo" ] && continue
  romdir="$LIBROOT/roms/$folder"; mkdir -p "$romdir"
  clone="$CACHE/$repo"
  if [ -d "$clone/.git" ]; then
    git -C "$clone" pull -q --ff-only 2>/dev/null || true
  else
    echo "== cloning retrobrews/$repo =="
    git clone --depth 1 -q "https://github.com/retrobrews/$repo.git" "$clone" || { echo "  ! clone failed"; continue; }
  fi
  n=0
  shopt -s nullglob nocaseglob
  for ext in $exts; do
    for f in "$clone"/*."$ext"; do
      base="$(basename "$f")"
      case "$base" in README*|LICENSE*|readme*|license*) continue;; esac
      [ -f "$romdir/$base" ] || { cp "$f" "$romdir/$base"; n=$((n + 1)); }
    done
  done
  shopt -u nullglob nocaseglob
  echo "  $folder: +$n new ($(ls -1 "$romdir" | wc -l) total)"
done
echo "Total ROMs: $(find "$LIBROOT/roms" -type f | wc -l) across $(ls "$LIBROOT/roms" | wc -l) systems"
