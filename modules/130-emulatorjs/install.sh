#!/usr/bin/env bash
# 130-emulatorjs — self-hosted EmulatorJS (static nginx site + browser WASM
# cores), fully offline. Serves a game menu from ./site, the engine from
# ~/emulatorjs/data, and a ROM library from ~/emulatorjs/library (both outside
# the repo). First run downloads the engine bundle + the free homebrew games.
# Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
pkg_install p7zip-full     # 7z, to unpack the EmulatorJS engine bundle
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EJS_HOME="$HOME/emulatorjs"
export EJS_SITE="$MOD_DIR/site"
export EJS_ENGINE="$EJS_HOME/data"
export EJS_LIBRARY="$EJS_HOME/library"
mkdir -p "$EJS_LIBRARY/roms"

step "ensuring EmulatorJS engine (offline cores)"
bash "$MOD_DIR/fetch-data.sh" "$EJS_HOME"

step "fetching free homebrew ROMs (all systems)"
bash "$MOD_DIR/fetch-roms.sh" "$EJS_LIBRARY" || warn "ROM fetch had issues (network / rate limit) — re-run later"

step "generating games library (games.json)"
bash "$MOD_DIR/gen-library.sh" "$EJS_LIBRARY"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=EJS_SITE,EJS_ENGINE,EJS_LIBRARY docker"
fi

step "bringing up EmulatorJS (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "EmulatorJS up (offline) — play at http://${ip:-<pi-ip>}:8092"
