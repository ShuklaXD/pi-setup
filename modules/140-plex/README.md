# 140-plex

**Plex Media Server** — streams the media on this Pi to Plex apps (TV, phone,
browser). Web UI / server at **http://10.75.12.44:32400/web**.

## Networking

Runs with `network_mode: host` — Plex needs it for GDM/DLNA discovery so clients
find the server automatically on the LAN, and for clean remote access. It binds
`32400` plus the DLNA/discovery ports (`1900/udp`, `32410-32414/udp`, `32469`)
directly on the host; all were free before this module.

`ALLOWED_NETWORKS` is set to the LAN subnet (derived from the Pi's own address at
install time), so browsers on the LAN reach the UI without a login prompt.

## Layout

| Host path | In container | Purpose |
|---|---|---|
| `~/appdata/plex` | `/config` | Plex database, metadata, settings |
| `~/appdata/plex/transcode` | `/transcode` | transcode scratch (kept off `/config`) |
| `~/media/{movies,tv,music,photos}` | `/media/…` | the library |
| `~/downloads/completed` | `/downloads` (**ro**) | finished torrents, optional library |

Add libraries in the Plex UI pointing at `/media/movies`, `/media/tv`, etc.

## Claiming the server

The server starts **unclaimed**. Either:

1. Open `http://10.75.12.44:32400/web` from a machine on the LAN and sign in —
   the setup wizard claims it; or
2. `cp .env.example .env`, paste a token from <https://www.plex.tv/claim>
   (**expires after 4 minutes**), and re-run `install.sh`.

`.env` is gitignored — the token is a credential and is never committed.

## Performance notes (Pi 4)

A Pi 4 has **no Plex-usable hardware transcoder**, so:

- Aim for **Direct Play** — keep media in formats your clients decode natively
  (H.264 MP4/MKV, AAC). Software transcoding 1080p will stutter.
- Set client quality to *Original* / *Maximum* to avoid forcing a transcode.
- In **Settings → Library**, leave *Generate video preview thumbnails* **off** —
  it will peg all four cores for days on a large library.
- `mem_limit: 1g` is declared as a guard rail. **It is currently not enforced**:
  the kernel cgroup memory controller is off on this machine (see
  `modules/05-cgroup-memory` — it needs re-running plus a reboot, because the
  boot cmdline no longer carries `cgroup_enable=memory`). The cap starts working
  by itself once that is fixed; nothing here needs changing.

## Re-run

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/140-plex/install.sh
```

## Cloudflare

Plex has its own account-based remote access (**Settings → Remote Access**),
which is the normal way to watch away from home — it does not need a tunnel.
Note that Cloudflare tunnels forbid proxying video streams of this kind, so do
not put Plex behind one; use Plex's own remote access instead.
