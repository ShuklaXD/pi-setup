#!/usr/bin/env bash
# common.sh — shared helpers sourced by the orchestrator and every module.
# Everything here is written to be idempotent: safe to run repeatedly.

# --- logging -----------------------------------------------------------------
_c_reset=$'\033[0m'; _c_blue=$'\033[34m'; _c_green=$'\033[32m'
_c_yellow=$'\033[33m'; _c_red=$'\033[31m'; _c_dim=$'\033[2m'

log()   { printf '%s==>%s %s\n'   "$_c_blue"   "$_c_reset" "$*"; }
ok()    { printf '%s  ok%s %s\n'  "$_c_green"  "$_c_reset" "$*"; }
warn()  { printf '%swarn%s %s\n'  "$_c_yellow" "$_c_reset" "$*" >&2; }
err()   { printf '%s err%s %s\n'  "$_c_red"    "$_c_reset" "$*" >&2; }
step()  { printf '%s  · %s%s\n'   "$_c_dim"    "$*" "$_c_reset"; }

# --- detection ---------------------------------------------------------------
have()  { command -v "$1" >/dev/null 2>&1; }   # is a command on PATH?

# --- apt package install (Debian/Raspberry Pi OS) ----------------------------
# pkg_install <pkg> [pkg...] — install only what's missing, update once if needed.
_apt_updated=0
pkg_install() {
  local missing=()
  local p
  for p in "$@"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    ok "packages present: $*"
    return 0
  fi
  if [ "$_apt_updated" -eq 0 ]; then
    step "apt-get update"
    sudo apt-get update -qq
    _apt_updated=1
  fi
  step "apt-get install: ${missing[*]}"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"
  ok "installed: ${missing[*]}"
}

# --- safe symlink with backup ------------------------------------------------
# link <source> <target> — symlink target -> source, backing up any real file.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "linked: $dst"
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak="$dst.bak.$(date +%s 2>/dev/null || echo backup)"
    warn "backing up existing $dst -> $bak"
    mv "$dst" "$bak"
  fi
  ln -s "$src" "$dst"
  ok "linked: $dst -> $src"
}

# --- append-once line into a file -------------------------------------------
# ensure_line <file> <line> — add line only if not already present.
ensure_line() {
  local file="$1" line="$2"
  touch "$file"
  grep -qxF "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# Resolve the repo root regardless of where a module is invoked from.
PI_SETUP_ROOT="${PI_SETUP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export PI_SETUP_ROOT
