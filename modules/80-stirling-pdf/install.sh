#!/usr/bin/env bash
# 80-stirling-pdf — Stirling-PDF toolkit, defined by the committed
# docker-compose.yml here. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export APPDATA="${APPDATA:-$HOME/appdata}"
step "ensuring data dirs under $APPDATA/stirling-pdf"
mkdir -p "$APPDATA/stirling-pdf"/{configs,tessdata,logs,pipeline}

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=APPDATA docker"
fi

step "bringing up Stirling-PDF (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "Stirling-PDF up — http://${ip:-<pi-ip>}:8083"
