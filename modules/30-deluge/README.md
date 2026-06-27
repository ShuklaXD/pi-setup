# 30-deluge

**Deluge** BitTorrent client with web UI ([LinuxServer.io](https://docs.linuxserver.io/images/docker-deluge/)
image) at `http://<pi-ip>:8112`.

- **First login:** default web UI password is `deluge` — change it immediately
  (Preferences → Interface / the password prompt on first connect).
- **Config:** persisted on the host at `~/appdata/deluge` (not in git).
- **Downloads:** saved to `~/downloads` (shared so other services — e.g. a media
  server — can read the same files). Inside the container this is `/downloads`,
  so set Deluge's download location to `/downloads`.

## Ports

| Port | Purpose |
|------|---------|
| 8112 | Web UI |
| 6881 (tcp+udp) | Torrent traffic — forward on your router for better connectivity |
| 58846 | Daemon RPC for thin/desktop clients (optional) |

## Notes

- The container runs as PUID/PGID 1000 so downloaded files are owned by your user.
- No VPN is bundled. If you want torrent traffic routed through a VPN, that's a
  separate change (e.g. a `gluetun` sidecar) — ask and it'll be its own module.
