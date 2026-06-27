#!/usr/bin/env bash
# 90-samba — Samba network drive (SMB) defined by the committed docker-compose.yml
# here. Creates the shares dir, requires a .env with the Samba password, then
# brings the container up. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$MOD_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  cp "$MOD_DIR/.env.example" "$ENV_FILE"
  err "created $ENV_FILE — set SMB_PASSWORD in it, then re-run this module"
  exit 1
fi
if grep -q 'SMB_PASSWORD=changeme' "$ENV_FILE"; then
  err "SMB_PASSWORD in $ENV_FILE is still the placeholder — set it, then re-run"
  exit 1
fi

export SHARES_DIR="${SHARES_DIR:-$HOME/shares}"
export DOWNLOADS="${DOWNLOADS:-$HOME/downloads}"
step "ensuring share dirs ($SHARES_DIR, $DOWNLOADS)"
mkdir -p "$SHARES_DIR" "$DOWNLOADS"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=SHARES_DIR,DOWNLOADS docker"
fi

step "bringing up Samba (compose up -d)"
$DOCKER compose --env-file "$ENV_FILE" -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "Samba up — shares: \\\\${ip:-<pi-ip>}\\Shares (rw) and \\\\${ip:-<pi-ip>}\\Downloads (ro)"
step "map on Windows: \\\\${ip:-<pi-ip>}\\Shares  user: shukks"
