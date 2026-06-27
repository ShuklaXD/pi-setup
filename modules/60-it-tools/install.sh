#!/usr/bin/env bash
# 60-it-tools — IT-Tools (self-hosted developer utilities), defined by the
# committed docker-compose.yml here. Stateless. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo docker"
fi

step "bringing up IT-Tools (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "IT-Tools up — http://${ip:-<pi-ip>}:8082"
