#!/usr/bin/env bash
# 30-deluge — Deluge BitTorrent client routed through a PIA VPN (gluetun),
# defined by the committed docker-compose.yml here. Creates host dirs, requires
# a .env with PIA credentials, then brings the stack up. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$MOD_DIR/.env"

# PIA credentials live in a gitignored .env (copied from .env.example).
if [ ! -f "$ENV_FILE" ]; then
  cp "$MOD_DIR/.env.example" "$ENV_FILE"
  err "created $ENV_FILE — edit it with your PIA credentials, then re-run this module"
  exit 1
fi
if grep -q 'your_pia_password' "$ENV_FILE"; then
  err "PIA credentials in $ENV_FILE are still placeholders — edit them, then re-run"
  exit 1
fi

# Host paths + identity, derived from the live system (overridable via env).
export PUID="${PUID:-$(id -u)}"
export PGID="${PGID:-$(id -g)}"
export TZ="${TZ:-$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo UTC)}"
export APPDATA="${APPDATA:-$HOME/appdata}"
export DOWNLOADS="${DOWNLOADS:-$HOME/downloads}"

step "ensuring host dirs (config: $APPDATA/deluge, downloads: $DOWNLOADS)"
mkdir -p "$APPDATA/deluge" "$DOWNLOADS"

# docker access: prefer group membership; fall back to sudo on a fresh box.
DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=PUID,PGID,TZ,APPDATA,DOWNLOADS docker"
fi

step "bringing up gluetun (PIA VPN) + Deluge (compose up -d)"
$DOCKER compose --env-file "$ENV_FILE" -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "Deluge (via PIA VPN) up — http://${ip:-<pi-ip>}:8112"
step "verify the VPN with: docker exec gluetun wget -qO- https://ipinfo.io/ip"
