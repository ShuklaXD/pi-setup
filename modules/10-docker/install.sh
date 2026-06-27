#!/usr/bin/env bash
# 10-docker — install Docker Engine + Compose plugin (native, via the official
# get.docker.com convenience script) and enable it as a system service.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

if have docker; then
  ok "docker present: $(docker --version)"
else
  step "installing Docker via get.docker.com (official convenience script)"
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sudo sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh
  ok "installed: $(docker --version)"
fi

# Run docker without sudo: add the invoking user to the docker group.
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  ok "$USER already in docker group"
else
  step "adding $USER to docker group (re-login needed for it to take effect)"
  sudo usermod -aG docker "$USER"
  warn "log out/in (or run 'newgrp docker') before using docker without sudo"
fi

# Ensure the daemon is enabled + running.
if have systemctl; then
  sudo systemctl enable --now docker >/dev/null 2>&1 || true
  systemctl is-active --quiet docker && ok "docker service active" || warn "docker service not active"
fi

# Compose v2 ships as a plugin with the convenience script.
if docker compose version >/dev/null 2>&1; then
  ok "compose plugin: $(docker compose version | head -1)"
else
  warn "docker compose plugin missing — installing docker-compose-plugin"
  pkg_install docker-compose-plugin
fi

ok "docker configured"
