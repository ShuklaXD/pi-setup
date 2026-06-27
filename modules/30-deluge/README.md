# 30-deluge

**Deluge** BitTorrent client ([LinuxServer.io](https://docs.linuxserver.io/images/docker-deluge/))
routed through a **Private Internet Access (PIA) VPN** via
[gluetun](https://github.com/qdm12/gluetun). Web UI at `http://<pi-ip>:8112`.

## How the VPN routing works

- `gluetun` establishes the PIA OpenVPN tunnel and owns the network namespace.
- Deluge uses `network_mode: service:gluetun`, so **all** its traffic exits
  through the VPN. gluetun's built-in **kill-switch** blocks traffic if the
  tunnel drops — no IP leaks.
- Because they share a namespace, Deluge's ports (8112 web UI, 58846 RPC) are
  published on the **gluetun** container, not on deluge.

## Credentials (required)

PIA login is secret and lives in a **gitignored** `.env` in this directory:

```sh
cp modules/30-deluge/.env.example modules/30-deluge/.env
# then edit .env: PIA_USER, PIA_PASSWORD, PIA_REGION, LAN_SUBNET
```

`install.sh` refuses to start until `.env` exists with real credentials.

## Data

- **Config:** `~/appdata/deluge` (host, not in git). Default web password `deluge`
  — change it on first login.
- **Downloads:** `~/downloads` → `/downloads` in the container. Set Deluge's
  download location to `/downloads`.

## Verify the tunnel

```sh
docker exec gluetun wget -qO- https://ipinfo.io/ip   # should show a PIA IP, not yours
```

## Notes

- **Port forwarding is not enabled** — torrenting works but incoming peer
  connections are limited. PIA supports it; enabling + syncing the forwarded port
  into Deluge is a possible follow-up.
- Region is set by `PIA_REGION` in `.env` (currently Singapore). Change and
  re-run the module to switch.
