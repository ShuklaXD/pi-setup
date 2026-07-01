# 130-emulatorjs

Self-hosted **EmulatorJS** — play retro console games in the browser at
**http://10.75.12.44:8092**. **Fully offline**: the emulator engine, all WASM
cores, and the ROMs are hosted on the Pi — nothing loads from a CDN.

EmulatorJS runs the emulation client-side (WASM), so the server is just static
`nginx` (arm64-safe; the LinuxServer image has no arm64 build).

## Layout

- `site/` — the menu (`index.html`) + player (`play.html`), served read-only.
- `~/emulatorjs/data/` (outside repo) — the EmulatorJS engine + cores, mounted at
  `/usr/share/nginx/html/data`.
- `~/emulatorjs/library/` (outside repo) — `roms/<system>/…` + generated
  `games.json`, mounted at `/usr/share/nginx/html/library`.

## What gets installed (idempotent scripts)

- **`fetch-data.sh`** — downloads the EmulatorJS `4.2.3.7z` release (~290 MB, all
  cores) and extracts it to `~/emulatorjs/data` (needs `7z` / `p7zip-full`).
- **`fetch-roms.sh`** — shallow-`git clone`s the **retrobrews** homebrew
  collections (not the rate-limited REST API) and copies ROMs into
  `~/emulatorjs/library/roms/<system>/`. **481 free games** across 9 systems:
  NES, SNES, Game Boy (Color), GBA, Genesis/Mega Drive, Master System,
  Atari 2600, ColecoVision, Commodore 64.
- **`gen-library.sh`** — scans the ROM folders and writes `games.json` (title,
  system label, EmulatorJS core) for the menu.

## Adding your own games

Drop ROMs into `~/emulatorjs/library/roms/<system>/` (folders: `nes snes gbc gba
md sms atari2600 coleco c64` — or any EmulatorJS system), then re-run
`gen-library.sh` (or the module) to rebuild the menu.

> **Legality:** only homebrew / public-domain ROMs, or dumps of cartridges you
> personally own. No commercial ROMs are shipped or fetched.

## Re-run

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/130-emulatorjs/install.sh
```

## Cloudflare

To play remotely, add a tunnel hostname (`games.shubhiixd.com` →
`http://localhost:8092`) behind the same Access/SSO policy — see
`modules/100-homepage/README.md`. Being fully offline, no external CDN is needed.
