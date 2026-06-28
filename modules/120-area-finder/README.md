# 120-area-finder

Deploys **area-finder** — a property-hunting area-unit converter plus an
offline-first property snapshot logger (PWA + tiny zero-dependency Node backend).
UI on **:8091**.

The app is its own project (kept under `~/workspaces/area-finder`, repo
`ShuklaXD/area-finder`), following the convention that code projects live in
`~/workspaces`. This module just deploys it:

1. Clones the repo into `~/workspaces/area-finder` (or `git pull` if present).
2. `docker compose up -d --build` — builds the image and starts the container.
3. Data (JSON store + uploaded photos) persists in the `area-finder-data`
   Docker volume.

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/120-area-finder/install.sh
```

## Dependencies

- `10-docker` (engine + compose).
- `02-ssh-config` so the clone over SSH authenticates on a fresh machine.
- The `ShuklaXD/area-finder` repo must be pushed for the clone step to work on a
  clean box. On this machine the directory already exists, so it builds in place.

## Cloudflare

`area.shubhiixd.com` is part of the home-server tunnel/SSO runbook — see
`modules/100-homepage/README.md` (route → `http://localhost:8091`). Compass and
GPS need the HTTPS hostname (a secure context), not the plain-LAN address.
