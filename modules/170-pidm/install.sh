#!/usr/bin/env bash
# 170-pidm — PiDM parallel download manager (IDM-style web UI) on 8094,
# saving into the samba Downloads share (~/downloads). Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

APP_DIR="$HOME/workspaces/downloader"
if [ ! -d "$APP_DIR/.git" ]; then
  step "cloning ShuklaXD/downloader (private, via SSH key from 02-ssh-config)"
  git -C "$HOME/workspaces" clone -q git@github.com:ShuklaXD/downloader.git downloader
fi

step "building + starting PiDM (setup.sh: .env, folders, compose up -d --build)"
DOWNLOADS_DIR="$HOME/downloads" SHARES_DIR="$HOME/shares" bash "$APP_DIR/setup.sh"
