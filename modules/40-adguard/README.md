# 40-adguard

**AdGuard Home** — network-wide ad/tracker blocking that works as your DNS server.

## First-run setup

1. Open `http://<pi-ip>:3000` and complete the setup wizard.
2. When asked for the **Admin Web Interface** port, you can keep `3000` (reachable
   at `:3000`) or set it to `80` (then reachable at `:8081` from the host mapping).
3. Set the **DNS server** port to `53` (the default).
4. Create your admin username/password.

## Using it

Point your **router's DNS** (or individual devices) at this Pi's LAN IP so all
queries are filtered network-wide. Add blocklists under Filters → DNS blocklists.

## Data

- Config + state persist on the host at `~/appdata/adguard/{work,conf}` (not in
  git; it contains your admin password hash and settings).

## Ports

| Port | Purpose |
|------|---------|
| 53 (tcp+udp) | DNS — the actual ad-blocking resolver |
| 3000 | Setup wizard / optional admin UI |
| 8081 | Admin UI if you set it to container port 80 |

> Port 53 must be free on the host. On this Pi `systemd-resolved` is inactive, so
> there's no conflict. If you ever enable it, disable its stub listener first.
