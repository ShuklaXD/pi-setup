#!/usr/bin/env bash
# 70-snapotter — SnapOtter file-tools suite (app + Postgres 17 + Redis 8),
# defined by the committed docker-compose.yml here. CPU image with memory caps.
# Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export APPDATA="${APPDATA:-$HOME/appdata}"
step "ensuring data dirs under $APPDATA/snapotter"
mkdir -p "$APPDATA/snapotter/data" "$APPDATA/snapotter/postgres" "$APPDATA/snapotter/redis"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=APPDATA docker"
fi

step "bringing up SnapOtter + Postgres + Redis (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "SnapOtter up — http://${ip:-<pi-ip>}:1349 (default login admin/admin — change on first use)"
step "AI tools (upscale/transcribe) run CPU-only and are slow; app is capped at 2g RAM"
