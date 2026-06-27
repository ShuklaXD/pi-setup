#!/usr/bin/env bash
# 30-deluge — Deluge BitTorrent client (web UI), defined by the committed
# docker-compose.yml here. Creates host dirs for config + downloads, then brings
# the container up. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

step "bringing up Deluge (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "Deluge up — http://${ip:-<pi-ip>}:8112 (default web password: 'deluge' — change it)"
