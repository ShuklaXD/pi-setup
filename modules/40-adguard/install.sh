#!/usr/bin/env bash
# 40-adguard — AdGuard Home (network-wide DNS ad-blocking), defined by the
# committed docker-compose.yml here. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export APPDATA="${APPDATA:-$HOME/appdata}"
step "ensuring config dirs under $APPDATA/adguard"
mkdir -p "$APPDATA/adguard/work" "$APPDATA/adguard/conf"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=APPDATA docker"
fi

step "bringing up AdGuard Home (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "AdGuard Home up — first-run setup at http://${ip:-<pi-ip>}:3000"
step "after setup, point devices/router DNS at ${ip:-<pi-ip>} to enable blocking"
