#!/usr/bin/env bash
# 50-dashy — Dashy dashboard (single landing page for all services), defined by
# the committed docker-compose.yml + conf.yml here. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pin the committed config by absolute path so the bind mount is unambiguous.
export DASHY_CONF="$MOD_DIR/conf.yml"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=DASHY_CONF docker"
fi

step "bringing up Dashy (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "Dashy up — http://${ip:-<pi-ip>}:4000"
