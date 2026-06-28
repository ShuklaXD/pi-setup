#!/usr/bin/env bash
# 02-ssh-config — SSH client config so git uses the right key per host.
# Idempotent. Captures the host->key mapping only; private keys are secrets and
# are NOT stored in this repo (see README).
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

SSH_DIR="$HOME/.ssh"
CFG="$SSH_DIR/config"

# host -> identity file mappings to ensure (one block per Host).
# Format: "Host|HostName|User|IdentityFile"
MAPPINGS=(
  "github.com|github.com|git|$SSH_DIR/shuklaxd"
)

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$CFG"
chmod 600 "$CFG"

for m in "${MAPPINGS[@]}"; do
  IFS='|' read -r host hostname user idfile <<<"$m"
  if grep -qE "^Host[[:space:]]+$host([[:space:]]|$)" "$CFG"; then
    ok "ssh config already maps $host"
  else
    step "adding ssh config block for $host -> $idfile"
    # keep a blank line before the block if the file already has content
    [ -s "$CFG" ] && printf '\n' >>"$CFG"
    cat >>"$CFG" <<EOF
Host $host
    HostName $hostname
    User $user
    IdentityFile $idfile
    IdentitiesOnly yes
EOF
    ok "added ssh config block for $host"
  fi

  # The private key itself is a secret kept out of this repo. Warn if absent so a
  # fresh box knows it still needs the key dropped in before git auth will work.
  if [ ! -f "$idfile" ]; then
    warn "key $idfile not present — copy it in (chmod 600) for $host auth to work"
  fi
done

ok "ssh config ensured ($CFG)"
