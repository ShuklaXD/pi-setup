# 130-emulatorjs

Self-hosted **EmulatorJS** — play retro console games in the browser at
**http://10.75.12.44:8092**.

EmulatorJS runs the emulation **client-side (WASM)**, so the server is just
static hosting — plain `nginx` (arm64-safe; the LinuxServer image has no arm64
build). The emulator engine/cores load from EmulatorJS's CDN at play time; your
**ROMs stay local** on the Pi.

## Layout

- `site/` — the menu (`index.html`) and player (`play.html`), served read-only.
- `~/emulatorjs/library/` (outside the repo) — `roms/<system>/…` + generated
  `games.json`. Mounted at `/usr/share/nginx/html/library`.

## Games

First install runs `fetch-roms.sh`, which downloads the **free, redistributable
homebrew NES collection** from [retrobrews/nes-games](https://github.com/retrobrews/nes-games)
(~80 games) into `~/emulatorjs/library/roms/nes/`.

To add your own: drop ROMs into `~/emulatorjs/library/roms/<system>/` (e.g.
`nes`, `snes`, `gb`, `gba`, `genesis`), then re-run the module (or just
`gen-library.sh`) to rebuild the menu.

> **Legality:** only homebrew / public-domain ROMs, or dumps of cartridges you
> personally own. No commercial ROMs are shipped or fetched.

## Re-run

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/130-emulatorjs/install.sh
```

## Cloudflare

To play remotely, add a tunnel hostname (e.g. `games.shubhiixd.com` →
`http://localhost:8092`) behind the same Access/SSO policy — see
`modules/100-homepage/README.md`. (The EmulatorJS CDN must be reachable from
your browser.)
