#!/usr/bin/env bash
# 110-claude-config — capture Claude Code customizations into ~/.claude so a
# rebuild restores them: the workspaces-enforcement Bash hook and the custom
# skills. Files are symlinked back to this module so edits stay version
# controlled; settings.json is merged (never clobbered). Idempotent.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The hook is a python3 script.
pkg_install python3

# Hook script (symlink → repo copy).
link "$MOD_DIR/claude/hooks/enforce-workspaces.py" "$HOME/.claude/hooks/enforce-workspaces.py"

# Custom skills (symlink whole dirs → repo copies).
link "$MOD_DIR/claude/skills/workspaces" "$HOME/.claude/skills/workspaces"
link "$MOD_DIR/claude/skills/pi-setup"   "$HOME/.claude/skills/pi-setup"

# Wire the hook into settings.json without disturbing other settings.
step "ensuring workspaces hook in ~/.claude/settings.json"
python3 "$MOD_DIR/claude/merge-settings.py"

ok "Claude config captured (hook + skills) — open /hooks or restart to load the hook"
