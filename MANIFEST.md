# Manifest

Human-readable log of every customization captured in this repo, newest first.
Each entry corresponds to a module under `modules/`.

| Module | What it does | Added |
|--------|--------------|-------|
| `160-mqtt` | Mosquitto MQTT broker + MQTTX Web, published to the internet via Tailscale Funnel (mqtts 8443, wss 10000, dashboard 443); project repo at `~/workspaces/mqtt-server` | 2026-09-14 |
| `150-sso-gateway` | Makes the Cloudflare Access login the only login: Caddy binds 9443/8112 (Portainer + Deluge no longer publish them) and a minter service injects each app's session cookie, so neither shows a login form again | 2026-09-05 |
| `140-plex` | Plex Media Server (host networking for client discovery); library at `~/media/{movies,tv,music,photos}` + finished torrents read-only; UI on 32400 | 2026-08-16 |
| `130-emulatorjs` | Self-hosted **NES arcade** on EmulatorJS, fully offline (engine+cores bundled locally); all 82 free/homebrew NES games w/ box art, searchable menu, drop-in folder for your own cartridge dumps; UI on 8092 | 2026-08-16 |
| `120-area-finder` | Deploys the area-finder app (property area converter + offline snapshots, PWA + Node backend) from `ShuklaXD/property-log`; UI on 8091 | 2026-06-28 |
| `110-claude-config` | Captures Claude Code config into `~/.claude` (symlinked): workspaces-enforcement Bash hook + `workspaces`/`pi-setup` skills; merges hook into settings.json | 2026-06-28 |
| `02-ssh-config` | SSH client config mapping `github.com` → `~/.ssh/shuklaxd` key (enables git push); keys kept out of repo | 2026-06-28 |
| `100-homepage` | Home server landing page (nginx static site, Nord theme); links every app via its Cloudflare subdomain; UI on 8090 | 2026-06-28 |
| `90-samba` | Samba network drive (SMB): Shares (rw) + Downloads (ro), private login, host net | 2026-06-27 |
| `80-stirling-pdf` | Stirling-PDF toolkit (merge/split/OCR/convert/sign), RAM-capped; UI on 8083 | 2026-06-27 |
| `70-snapotter` | SnapOtter file-tools suite (app + Postgres 17 + Redis 8), CPU image, RAM-capped; UI on 1349 | 2026-06-27 |
| `05-cgroup-memory` | Enable kernel cgroup memory controller so Docker mem_limit works (boot cmdline + reboot) | 2026-06-27 |
| `60-it-tools` | IT-Tools self-hosted developer utilities (web UI on 8082) | 2026-06-27 |
| `50-dashy` | Dashy dashboard linking all services; layout committed as conf.yml (4000) | 2026-06-27 |
| `40-adguard` | AdGuard Home network-wide DNS ad-blocking (53 DNS, 3000 admin) | 2026-06-27 |
| `30-deluge` | Deluge BitTorrent client routed through PIA VPN (gluetun + kill-switch); web UI on 8112 | 2026-06-27 |
| `20-portainer` | Portainer CE web dashboard (monitoring) via committed compose | 2026-06-27 |
| `10-docker` | Docker Engine + Compose v2 plugin (native foundation) | 2026-06-27 |
| `00-dotfiles` | Clone + apply `ShuklaXD/dotfiles` (zsh, vim, tmux, git, htop) | 2026-06-27 |
