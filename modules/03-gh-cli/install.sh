#!/usr/bin/env bash
# 03-gh-cli — GitHub CLI (gh), official release binary in ~/.local/bin (no sudo).
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

GH_VERSION="2.103.3"
BIN="$HOME/.local/bin/gh"

if [ -x "$BIN" ] && "$BIN" --version | grep -q "gh version $GH_VERSION "; then
  ok "gh $GH_VERSION already installed"
else
  arch="$(dpkg --print-architecture)"            # arm64 / amd64 / armhf→armv6
  [ "$arch" = armhf ] && arch=armv6
  name="gh_${GH_VERSION}_linux_${arch}"
  base="https://github.com/cli/cli/releases/download/v${GH_VERSION}"
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  step "downloading $name"
  curl -fsSL -o "$tmp/$name.tar.gz" "$base/$name.tar.gz"
  curl -fsSL -o "$tmp/checksums.txt" "$base/gh_${GH_VERSION}_checksums.txt"
  (cd "$tmp" && grep " $name.tar.gz\$" checksums.txt | sha256sum -c --quiet)
  tar -xzf "$tmp/$name.tar.gz" -C "$tmp"
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$tmp/$name/bin/gh" "$BIN"
  ok "gh $GH_VERSION installed to $BIN"
fi

if "$BIN" auth status >/dev/null 2>&1; then
  ok "gh authenticated"
else
  warn "gh not logged in — run: gh auth login  (GitHub.com, SSH, web browser)"
fi
