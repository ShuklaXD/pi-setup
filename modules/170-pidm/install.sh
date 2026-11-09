#!/usr/bin/env bash
# 170-pidm — PiDM parallel download manager (IDM-style web UI) on 8094,
# saving into the samba Downloads share (~/downloads). Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

APP_DIR="$HOME/workspaces/downloader"
[ -f "$APP_DIR/docker-compose.yml" ] || { err "$APP_DIR missing — restore the downloader project first"; exit 1; }

mkdir -p "$HOME/downloads"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo docker"
fi

step "building + starting PiDM (compose up -d --build)"
$DOCKER compose -f "$APP_DIR/docker-compose.yml" up -d --build

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "PiDM up — http://${ip:-<pi-ip>}:8094  (files -> ~/downloads)"
