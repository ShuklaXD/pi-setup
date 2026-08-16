# 130-emulatorjs

Self-hosted **NES arcade** on EmulatorJS — play NES games in the browser at
**http://10.75.12.44:8092**. **Fully offline**: the emulator engine, the WASM
core, and the ROMs are all served from the Pi — nothing loads from a CDN.

EmulatorJS emulates client-side (WASM), so the server is just static `nginx`
(arm64-safe; the LinuxServer image has no arm64 build).

## Layout

- `site/` — the menu (`index.html`) + player (`play.html`), served read-only.
- `~/emulatorjs/data/` (outside repo) — the EmulatorJS engine + cores, mounted at
  `/usr/share/nginx/html/data`.
- `~/emulatorjs/library/` (outside repo) — `roms/nes/`, `art/nes/` and the
  generated `games.json`, mounted at `/usr/share/nginx/html/library`.

## What gets installed (idempotent scripts)

- **`fetch-data.sh`** — downloads the EmulatorJS `4.2.3.7z` release (~290 MB, all
  cores) and extracts it to `~/emulatorjs/data` (needs `7z` / `p7zip-full`).
- **`fetch-roms.sh`** — shallow-`git clone`s the **retrobrews/nes-games**
  collection and copies all **82 NES ROMs + matching box art** into
  `~/emulatorjs/library/`.
- **`titles.txt`** — display-name map (`filename.nes = Nice Title`) so the menu
  reads "Filthy Kitchen", not "Filthykitchen". Only needed where the automatic
  name looks wrong.
- **`gen-library.sh`** — scans `roms/nes/` and writes `games.json` for the menu.

The menu has search (`/` focuses it, `Enter` launches the top hit), box art for
every game, and save states / gamepad support via EmulatorJS itself.

## Adding your own games

Drop `.nes` (or `.fds`, `.unf`) files into `~/emulatorjs/library/roms/nes/`,
optionally add matching box art as `~/emulatorjs/library/art/nes/<same-name>.png`,
then rebuild the menu:

```bash
bash ~/workspaces/pi-setup/modules/130-emulatorjs/gen-library.sh
```

Titles are derived from the filename, with region/dump tags stripped — so
`Some Game (U) [!].nes` shows up as "Some Game". Add a line to `titles.txt` to
override any name.

> **Legality:** this module ships and fetches **only homebrew / public-domain
> ROMs**. Commercial NES titles (Super Mario Bros., Contra, TMNT, The Jungle
> Book, …) are still under copyright and are deliberately *not* downloaded —
> supply those yourself only as dumps of cartridges you personally own.

## Re-run

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/130-emulatorjs/install.sh
```

## Other systems

This module was narrowed from 9 consoles to NES-only. ROMs previously fetched for
SNES/GB/GBA/Genesis/SMS/Atari 2600/ColecoVision/C64 are still on disk under
`~/emulatorjs/library/roms/<system>/` (just not listed in the menu), and every
EmulatorJS core is still installed — so re-widening later is only a change to
`fetch-roms.sh` + `gen-library.sh`.

## Cloudflare

To play remotely, add a tunnel hostname (`games.shubhiixd.com` →
`http://localhost:8092`) behind the same Access/SSO policy — see
`modules/100-homepage/README.md`. Being fully offline, no external CDN is needed.
