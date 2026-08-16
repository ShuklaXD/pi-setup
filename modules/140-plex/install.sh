#!/usr/bin/env bash
# 140-plex — Plex Media Server, defined by the committed docker-compose.yml here.
# Creates the media library dirs + config dir, derives the LAN subnet for
# ALLOWED_NETWORKS, picks up an optional PLEX_CLAIM from a gitignored .env, then
# brings the container up. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$MOD_DIR/.env"

# Host paths + identity, derived from the live system (overridable via env).
export PUID="${PUID:-$(id -u)}"
export PGID="${PGID:-$(id -g)}"
export TZ="${TZ:-$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo UTC)}"
export APPDATA="${APPDATA:-$HOME/appdata}"
export MEDIA="${MEDIA:-$HOME/media}"
export DOWNLOADS="${DOWNLOADS:-$HOME/downloads}"

# LAN subnet for ALLOWED_NETWORKS, derived from the primary interface's address.
if [ -z "${LAN_SUBNET:-}" ]; then
  LAN_SUBNET="$(ip -4 -o route get 1.1.1.1 2>/dev/null \
    | grep -oP 'src \K[\d.]+' \
    | awk -F. '{print $1"."$2"."$3".0/24"}')"
fi
export LAN_SUBNET="${LAN_SUBNET:-10.75.12.0/24}"

# Optional claim token — the module works fine without one.
export PLEX_CLAIM="${PLEX_CLAIM:-}"
if [ -f "$ENV_FILE" ] && ! grep -q 'claim-xxxx' "$ENV_FILE"; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
  [ -n "${PLEX_CLAIM:-}" ] && log "using PLEX_CLAIM from .env (only applies to an unclaimed server)"
fi

step "ensuring host dirs (config: $APPDATA/plex, media: $MEDIA)"
mkdir -p "$APPDATA/plex" "$APPDATA/plex/transcode" \
         "$MEDIA/movies" "$MEDIA/tv" "$MEDIA/music" "$MEDIA/photos" \
         "$DOWNLOADS/completed"

# docker access: prefer group membership; fall back to sudo on a fresh box.
DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=PUID,PGID,TZ,APPDATA,MEDIA,DOWNLOADS,LAN_SUBNET,PLEX_CLAIM docker"
fi

step "bringing up Plex (compose up -d, LAN $LAN_SUBNET)"
$DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "Plex up — set up / watch at http://${ip:-<pi-ip>}:32400/web"
log "libraries: $MEDIA/{movies,tv,music,photos} → /media/… in the container"
