#!/usr/bin/env bash
# 170-pidm — PiDM parallel download manager (IDM-style web UI) on 8094,
# saving into the samba Downloads share (~/downloads). Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

have docker || { err "docker not installed — run 10-docker first"; exit 1; }

APP_DIR="$HOME/workspaces/downloader"
[ -f "$APP_DIR/setup.sh" ] || { err "$APP_DIR missing — restore the downloader project first"; exit 1; }

step "building + starting PiDM (setup.sh: .env, folders, compose up -d --build)"
DOWNLOADS_DIR="$HOME/downloads" SHARES_DIR="$HOME/shares" bash "$APP_DIR/setup.sh"
