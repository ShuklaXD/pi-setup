#!/usr/bin/env bash
# 05-cgroup-memory — enable the kernel cgroup MEMORY controller on Raspberry Pi OS
# so Docker `mem_limit` actually works. Raspberry Pi OS ships with the memory
# controller disabled (cmdline has `cgroup_disable=memory`), which makes container
# memory limits silently no-ops. Edits the boot cmdline and requires a REBOOT.
# Idempotent: does nothing once the controller is active.
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

# Already enabled? Then we're done — no edit, no reboot.
if grep -qw memory /sys/fs/cgroup/cgroup.controllers 2>/dev/null; then
  ok "cgroup memory controller already enabled"
  exit 0
fi

# Locate the active boot cmdline (bookworm uses /boot/firmware, older uses /boot).
CMDLINE=/boot/firmware/cmdline.txt
[ -f "$CMDLINE" ] || CMDLINE=/boot/cmdline.txt
[ -f "$CMDLINE" ] || { err "cannot find cmdline.txt (looked in /boot/firmware and /boot)"; exit 1; }
step "editing $CMDLINE"

# Back up once before touching the boot file.
[ -f "$CMDLINE.bak" ] || sudo cp "$CMDLINE" "$CMDLINE.bak"

# cmdline.txt MUST stay a single line. Drop the disable flag, add the enable flags
# if missing, then collapse any leftover double spaces.
sudo sed -i 's/\bcgroup_disable=memory\b//g' "$CMDLINE"
grep -qw 'cgroup_enable=memory' "$CMDLINE" || sudo sed -i 's/[[:space:]]*$/ cgroup_enable=memory cgroup_memory=1/' "$CMDLINE"
sudo sed -i 's/  */ /g; s/^ //; s/ $//' "$CMDLINE"

ok "boot cmdline updated:"
step "$(cat "$CMDLINE")"
warn "REBOOT REQUIRED for the memory controller to take effect: sudo reboot"
