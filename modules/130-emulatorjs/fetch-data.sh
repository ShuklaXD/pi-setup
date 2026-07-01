#!/usr/bin/env bash
# Download + extract the EmulatorJS engine bundle (all WASM cores) so the
# emulator runs fully offline (no CDN). Idempotent: skips if already extracted.
set -euo pipefail
DEST="${1:-$HOME/emulatorjs}"
VER="4.2.3"
URL="https://github.com/EmulatorJS/EmulatorJS/releases/download/v${VER}/${VER}.7z"

if [ -f "$DEST/data/loader.js" ]; then
  echo "EmulatorJS engine already present ($(ls "$DEST"/data/cores/*-wasm.data 2>/dev/null | wc -l) core files)"
  exit 0
fi

SEVENZ="$(command -v 7z 7za 7zz 2>/dev/null | head -1 || true)"
[ -z "$SEVENZ" ] && { echo "ERROR: need a 7z tool (install p7zip-full)"; exit 1; }

mkdir -p "$DEST/.cache"
echo "Downloading EmulatorJS ${VER} (~290 MB)…"
curl -fL --retry 3 "$URL" -o "$DEST/.cache/${VER}.7z"
echo "Extracting engine + cores…"
( cd "$DEST" && "$SEVENZ" x ".cache/${VER}.7z" data -y >/dev/null )
[ -f "$DEST/data/loader.js" ] || { echo "ERROR: extraction failed"; exit 1; }
echo "engine ready ($(ls "$DEST"/data/cores/*-wasm.data | wc -l) core files)"
