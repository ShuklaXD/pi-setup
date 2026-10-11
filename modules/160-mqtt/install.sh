#!/usr/bin/env bash
# 160-mqtt — Mosquitto MQTT broker + MQTTX Web console + SQLite message
# recorder + sensor monitoring dashboard, published via Tailscale Funnel.
#
# The stack is its own repo under ~/workspaces and ships its own idempotent
# start.sh. This module's job is only to get the checkout in place and hand off
# to that script, so the machine rebuild and a manual start run identical code.
# Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker    || { err "docker not installed — run 10-docker first"; exit 1; }
have tailscale || { err "tailscale not installed — install it and run 'sudo tailscale up' first"; exit 1; }

APP_DIR="$HOME/workspaces/mqtt-server"
REPO="git@bitbucket.org:verit_aiworx/mqtt-server.git"

# --- project checkout --------------------------------------------------------
if [ -d "$APP_DIR/.git" ]; then
  step "updating mqtt-server (git pull --ff-only)"
  git -C "$APP_DIR" pull --ff-only || warn "pull skipped (offline or local changes)"
elif [ -d "$APP_DIR" ]; then
  warn "$APP_DIR exists but isn't a git repo — using it as-is"
else
  step "cloning mqtt-server into $APP_DIR"
  git clone "$REPO" "$APP_DIR"
fi

[ -x "$APP_DIR/start.sh" ] || { err "$APP_DIR/start.sh is missing or not executable"; exit 1; }

# --- hand off to the project's own startup script -----------------------------
# start.sh generates config/passwd if absent, brings up all four containers,
# waits for each to answer, and re-asserts the Funnel routes. It skips Funnel
# with a clear message if the Tailscale operator has not been set (that step
# needs an interactive sudo and cannot be done from here).
step "running mqtt-server/start.sh"
MQTT_USER="${MQTT_USER:-mqtt-tri}" MQTT_PASS="${MQTT_PASS:-mqtt-tri}" \
  "$APP_DIR/start.sh"

ok "mqtt stack started (see endpoints above)"
