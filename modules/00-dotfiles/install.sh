#!/usr/bin/env bash
# 00-dotfiles — clone the personal dotfiles repo and run its installer.
# Idempotent: clones if missing, pulls if present, then re-runs dotfiles/install.sh
# (which itself only relinks configs).
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

DOTFILES_REPO="https://github.com/ShuklaXD/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

pkg_install git

if [ -d "$DOTFILES_DIR/.git" ]; then
  step "dotfiles already cloned, pulling latest"
  git -C "$DOTFILES_DIR" pull --ff-only || warn "could not fast-forward dotfiles (local changes?)"
else
  step "cloning dotfiles -> $DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

if [ -x "$DOTFILES_DIR/install.sh" ]; then
  step "running dotfiles/install.sh"
  "$DOTFILES_DIR/install.sh"
elif [ -f "$DOTFILES_DIR/install.sh" ]; then
  step "running dotfiles/install.sh (via bash)"
  bash "$DOTFILES_DIR/install.sh"
else
  warn "dotfiles/install.sh not found — skipping"
fi

ok "dotfiles configured"
