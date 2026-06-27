#!/usr/bin/env bash
# 20-portainer — Portainer CE web dashboard, defined by the committed
# docker-compose.yml in this directory. Idempotent: `compose up -d` reconciles.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use sudo only if the current shell isn't yet in the docker group (fresh install
# before re-login). Once re-logged-in, plain `docker` works.
DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "docker socket needs elevated access in this shell, using sudo"
  DOCKER="sudo docker"
fi

step "bringing up Portainer (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "Portainer up — https://${ip:-<pi-ip>}:9443 (set the admin password on first visit)"
