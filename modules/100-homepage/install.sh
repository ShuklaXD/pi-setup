#!/usr/bin/env bash
# 100-homepage — landing page for the home server (nginx + committed static
# site), defined by the docker-compose.yml + ./site here. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pin the committed site dir by absolute path so the bind mount is unambiguous
# no matter where install.sh is invoked from.
export HOMEPAGE_SITE="$MOD_DIR/site"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=HOMEPAGE_SITE docker"
fi

step "bringing up homepage (compose up -d)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "homepage up — http://${ip:-<pi-ip>}:8090  (public: https://shubhiixd.com once the tunnel route is added)"
