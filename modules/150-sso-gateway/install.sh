#!/usr/bin/env bash
# 150-sso-gateway — make the Cloudflare Access login the only login.
#
# Portainer CE and Deluge have their own login forms and speak no SSO. This
# module puts a small gateway on the ports they used to publish; it proxies to
# them and, when a session cookie is missing, logs in for you. Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$(cd "$MOD_DIR/.." && pwd)"

export APPDATA="${APPDATA:-$HOME/appdata}"
export GW_CADDYFILE="$MOD_DIR/Caddyfile"
export GW_MINTER="$MOD_DIR/minter"

DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  step "this shell lacks docker group access, using sudo"
  DOCKER="sudo --preserve-env=APPDATA,GW_CADDYFILE,GW_MINTER docker"
fi

# --- credentials -------------------------------------------------------------
# The apps keep their passwords; the gateway holds a copy so it can log in for
# you. Never committed — .gitignore excludes *.env.
ENV_FILE="$MOD_DIR/.env"
touch "$ENV_FILE"
chmod 600 "$ENV_FILE"

ask_secret() {
  local key="$1" prompt="$2" value=""
  if grep -q "^${key}=." "$ENV_FILE" 2>/dev/null; then
    ok "$key already set in modules/150-sso-gateway/.env"
    return 0
  fi
  value="${!key:-}"
  if [ -z "$value" ]; then
    if [ ! -t 0 ]; then
      err "$key is not set and there is no terminal to prompt on."
      err "Add it to $ENV_FILE (or export it) and re-run."
      exit 1
    fi
    read -rsp "  $prompt: " value; echo
  fi
  [ -n "$value" ] || { err "$key cannot be empty"; exit 1; }
  printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  ok "$key recorded"
}

step "collecting app credentials (stored only in modules/150-sso-gateway/.env)"
ask_secret PORTAINER_USER     "Portainer admin username"
ask_secret PORTAINER_PASSWORD "Portainer admin password"
ask_secret DELUGE_PASSWORD    "Deluge web UI password"

# --- TLS cert ----------------------------------------------------------------
# 9443 has always been HTTPS with a self-signed cert (Portainer's own). The
# gateway takes over that port, so it needs an equivalent cert.
CERT_DIR="$APPDATA/sso-gateway/certs"
mkdir -p "$CERT_DIR"
if [ -s "$CERT_DIR/gateway.crt" ] && [ -s "$CERT_DIR/gateway.key" ]; then
  ok "gateway TLS cert present"
else
  have openssl || pkg_install openssl
  lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  step "generating self-signed cert for the gateway (10y)"
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$CERT_DIR/gateway.key" -out "$CERT_DIR/gateway.crt" \
    -subj "/CN=pi-sso-gateway" \
    -addext "subjectAltName=DNS:localhost,DNS:pi,IP:127.0.0.1${lan_ip:+,IP:$lan_ip}" \
    >/dev/null 2>&1
  chmod 644 "$CERT_DIR/gateway.crt"
  chmod 600 "$CERT_DIR/gateway.key"
  ok "cert written to $CERT_DIR"
fi

# --- release the ports -------------------------------------------------------
# 20-portainer and 30-deluge no longer publish 9443/8112 (see their compose
# files). Re-apply them so a machine that is already running hands the ports
# over. Recreating gluetun briefly drops the VPN and restarts Deluge.
for mod in 20-portainer 30-deluge; do
  compose="$MODULES_DIR/$mod/docker-compose.yml"
  [ -f "$compose" ] || continue
  if $DOCKER compose -f "$compose" ps --format '{{.Names}}' 2>/dev/null | grep -q .; then
    step "re-applying $mod so it releases its published port"
    ( cd "$MODULES_DIR/$mod" && $DOCKER compose -f "$compose" up -d )
  fi
done

# --- gateway -----------------------------------------------------------------
step "bringing up the SSO gateway (compose up -d)"
( cd "$MOD_DIR" && $DOCKER compose -f "$MOD_DIR/docker-compose.yml" up -d )

step "waiting for the gateway to answer"
for _ in $(seq 1 30); do
  if curl -sk -o /dev/null --max-time 3 https://127.0.0.1:9443/ \
     && curl -s -o /dev/null --max-time 3 http://127.0.0.1:8112/; then
    ok "gateway is serving 9443 (Portainer) and 8112 (Deluge)"
    break
  fi
  sleep 2
done

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
ok "SSO gateway up — https://${ip:-<pi-ip>}:9443 and http://${ip:-<pi-ip>}:8112 no longer prompt"
