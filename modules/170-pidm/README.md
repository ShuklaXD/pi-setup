# 170-pidm

Deploys **PiDM**, an IDM-style download manager with a web UI on **:8094**.
Paste a link → it downloads with up to 8 parallel connections (when the server
supports byte ranges) into `~/downloads` — the samba **Downloads** share.

The app is its own project at `~/workspaces/downloader` (private GitHub repo
`ShuklaXD/downloader`, cloned here if missing). This module runs its `setup.sh` (writes `.env` with ~/downloads + ~/shares, then `docker compose up -d --build`). Queue and
resume state persist in the `pidm-data` Docker volume.

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/170-pidm/install.sh
```

Depends on `10-docker`. No auth of its own — LAN/tailnet only unless placed
behind the Cloudflare Access SSO gateway (`150-sso-gateway`).
