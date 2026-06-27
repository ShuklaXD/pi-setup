#!/usr/bin/env bash
# 05-cgroup-memory — enable the kernel cgroup MEMORY controller so Docker
# `mem_limit` actually works. The memory controller is disabled by a
# `cgroup_disable=memory` boot arg, which makes container memory limits silently
# no-ops. On this machine that arg is INJECTED BY THE FIRMWARE (it appears in
# /proc/device-tree/chosen/bootargs but NOT in cmdline.txt). Since the firmware
# prepends its args and cmdline.txt is appended last, adding
# `cgroup_enable=memory cgroup_memory=1` here overrides it (kernel = last wins).
# This also handles the normal case where cgroup_disable=memory IS in cmdline.txt.
# Edits the boot cmdline and requires a REBOOT. Idempotent.
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
