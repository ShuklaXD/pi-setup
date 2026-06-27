#!/usr/bin/env bash
# install.sh — one-click reproducible setup for this Raspberry Pi / home server.
#
# Usage:
#   ./install.sh                 # run every module in modules/ (in order)
#   ./install.sh 10-tailscale    # run only matching module(s)
#   ./install.sh --list          # list available modules
#
# Each module lives in modules/NN-name/ and has its own install.sh that is
# idempotent (safe to re-run). Modules run in lexical order by their NN prefix.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PI_SETUP_ROOT="$ROOT"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

modules_dir="$ROOT/modules"

list_modules() {
  find "$modules_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

if [ "${1:-}" = "--list" ] || [ "${1:-}" = "-l" ]; then
  log "Available modules:"
  list_modules | sed 's/^/  /'
  exit 0
fi

# Optional filter: only run modules whose name contains the given arg(s).
filters=("$@")
matches() {
  [ ${#filters[@]} -eq 0 ] && return 0
  local name="$1" f
  for f in "${filters[@]}"; do [[ "$name" == *"$f"* ]] && return 0; done
  return 1
}

log "pi-setup starting (root: $ROOT)"
ran=0
while IFS= read -r mod; do
  [ -z "$mod" ] && continue
  matches "$mod" || continue
  script="$modules_dir/$mod/install.sh"
  if [ ! -f "$script" ]; then
    warn "$mod has no install.sh, skipping"
    continue
  fi
  log "module: $mod"
  bash "$script"
  ran=$((ran+1))
done < <(list_modules)

if [ "$ran" -eq 0 ]; then
  warn "no modules ran${filters:+ (filter: ${filters[*]})}"
else
  ok "done — $ran module(s) completed"
fi
