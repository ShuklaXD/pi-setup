#!/usr/bin/env bash
# 120-area-finder — deploy the area-finder app (property area converter +
# offline property snapshots). The app is its own project under ~/workspaces;
# this module clones it (if needed) and brings up its container. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

APP_DIR="$HOME/workspaces/area-finder"
REPO="git@github.com:ShuklaXD/property-log.git"

if [ -d "$APP_DIR/.git" ]; then
  step "updating area-finder (git pull --ff-only)"
  git -C "$APP_DIR" pull --ff-only || warn "pull skipped (offline or local changes)"
elif [ -d "$APP_DIR" ]; then
  warn "$APP_DIR exists but isn't a git repo — building it as-is"
else
  step "cloning area-finder into $APP_DIR"
  git clone "$REPO" "$APP_DIR"
fi

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo docker"
fi

step "building + starting area-finder (compose up -d --build)"
$DOCKER compose -f "$APP_DIR/docker-compose.yml" up -d --build

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "area-finder up — http://${ip:-<pi-ip>}:8091  (public: https://area.shubhiixd.com once routed)"
