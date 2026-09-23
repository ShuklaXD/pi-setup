#!/usr/bin/env bash
# 160-mqtt — Mosquitto MQTT broker + MQTTX Web + SQLite message recorder +
# sensor monitoring dashboard, exposed to the internet via Tailscale Funnel. The broker project is its own repo under ~/workspaces;
# this module clones it (if needed), generates the password file, brings up
# the containers and (re)applies the Funnel config. Mirrors its SETUP.md.
# Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker    || { err "docker not installed — run 10-docker first"; exit 1; }
have tailscale || { err "tailscale not installed — install it and run 'sudo tailscale up' first"; exit 1; }

APP_DIR="$HOME/workspaces/mqtt-server"
REPO="git@bitbucket.org:verit_aiworx/mqtt-server.git"
MQTT_USER="${MQTT_USER:-mqtt-tri}"
MQTT_PASS="${MQTT_PASS:-mqtt-tri}"

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

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo docker"
fi

# --- password file (gitignored, generated once) ------------------------------
if [ -s "$APP_DIR/config/passwd" ]; then
  ok "passwd present: $APP_DIR/config/passwd"
else
  step "generating mosquitto password file for user '$MQTT_USER'"
  $DOCKER run --rm -v "$APP_DIR/config:/tmp/mqtt" eclipse-mosquitto:2 \
    sh -c "mosquitto_passwd -b -c /tmp/mqtt/passwd '$MQTT_USER' '$MQTT_PASS' && chmod 644 /tmp/mqtt/passwd"
  ok "passwd generated"
fi

# --- containers --------------------------------------------------------------
step "bringing up mosquitto + mqttx-web + recorder + dashboard (compose up -d --build)"
$DOCKER compose -f "$APP_DIR/docker-compose.yaml" up -d --build

# --- tailscale funnel ----------------------------------------------------------
if ! tailscale status >/dev/null 2>&1; then
  err "tailscale is not connected — run 'sudo tailscale up' then re-run this module"
  exit 1
fi

# Let $USER manage serve/funnel without sudo (one-time; harmless to repeat).
if tailscale debug prefs 2>/dev/null | grep -q "\"OperatorUser\": \"$USER\""; then
  ok "tailscale operator: $USER"
else
  step "setting tailscale operator to $USER (needs sudo)"
  sudo tailscale set --operator="$USER"
fi

# `funnel --bg` writes the config idempotently — re-running just re-asserts it.
# If Funnel isn't yet enabled for this node in the tailnet ACL, the command
# prints an admin-console URL; visit it once and re-run.
step "exposing MQTT (TLS-terminated TCP :8443 -> localhost:1883)"
tailscale funnel --bg --tls-terminated-tcp=8443 tcp://localhost:1883
step "exposing MQTTX Web dashboard (https :443 -> localhost:8080)"
tailscale funnel --bg --https=443 http://localhost:8080
step "exposing Mosquitto WebSocket (https :10000 -> localhost:9001)"
tailscale funnel --bg --https=10000 http://localhost:9001

node="$(tailscale status --json 2>/dev/null | sed -n 's/.*"DNSName": *"\([^"]*\)\.".*/\1/p' | head -1)"
node="${node:-<node>.ts.net}"
ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "MQTT up — mqtts://$node:8443 · wss://$node:10000/mqtt · https://$node (MQTTX Web) · user '$MQTT_USER'"
ok "Dashboard up — http://${ip:-<pi-ip>}:8093  (public: https://dmrc.shubhiixd.com once routed)"
