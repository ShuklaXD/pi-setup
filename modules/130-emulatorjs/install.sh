#!/usr/bin/env bash
# 130-emulatorjs — self-hosted EmulatorJS (static nginx site + browser WASM
# cores). Serves a game menu from ./site and a ROM library from ~/emulatorjs
# (kept out of the repo). First run fetches the free homebrew NES collection.
# Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export EJS_SITE="$MOD_DIR/site"
export EJS_LIBRARY="$HOME/emulatorjs/library"
NES_DIR="$EJS_LIBRARY/roms/nes"
mkdir -p "$NES_DIR"

# First run (empty library) → pull the free homebrew NES games.
if [ -z "$(ls -A "$NES_DIR" 2>/dev/null)" ]; then
  step "fetching free homebrew NES ROMs"
  bash "$MOD_DIR/fetch-roms.sh" "$NES_DIR" || warn "ROM fetch failed (network?) — add ROMs later and re-run"
else
  ok "NES ROMs already present ($(ls -1 "$NES_DIR" | wc -l) files)"
fi

step "generating games library (games.json)"
bash "$MOD_DIR/gen-library.sh" "$EJS_LIBRARY"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=EJS_SITE,EJS_LIBRARY docker"
fi

step "bringing up EmulatorJS (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "EmulatorJS up — play at http://${ip:-<pi-ip>}:8092"
