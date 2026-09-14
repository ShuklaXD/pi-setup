# 150-sso-gateway

**One login — the Cloudflare Access one — opens every app.**

## The problem

Every app on this box already sits behind Cloudflare Access on
`*.shubhiixd.com`: hitting `portainer.shubhiixd.com` redirects to
`shuklaxd.cloudflareaccess.com` and you sign in once. But two apps then showed a
*second* login of their own, and neither can be taught to trust the first:

- **Portainer CE** — OIDC/OAuth is Business Edition only.
- **Deluge** — no header auth, no OIDC, nothing. Just a password box.

Everything else (Stirling-PDF, SnapOtter, IT-Tools, Dashy, Area Finder, Arcade,
the homepage) has no login at all, so Access alone is enough for them.

## What this does

A small gateway binds the ports Portainer and Deluge *used to* publish — 9443
and 8112 — and proxies to the containers, which are now reachable only on their
docker networks. When your browser already holds the app's session cookie the
gateway is a plain reverse proxy and stays out of the way (websockets, log
streaming and the container console all pass through). When the cookie is
missing, the request goes to the minter, which logs in to the app over the
docker network and 302s you back to where you were headed with the cookie set.

```
browser ──> Cloudflare Access ──> tunnel ─┐
                                          ├──> :9443 caddy ──> portainer:9443
browser (LAN, trusted) ───────────────────┘         │
                                                    └──(no cookie)──> minter ──login──> app
```

Because the gateway keeps the original port numbers, **nothing downstream
changed**: the Cloudflare tunnel ingress, the homepage LAN links and the Dashy
tiles all still point at `:9443` and `:8112`.

## Credentials

The apps keep their own passwords — the gateway holds a copy so it can log in
for you, in a gitignored `.env` beside this README:

```
PORTAINER_USER=...
PORTAINER_PASSWORD=...
DELUGE_PASSWORD=...
```

`install.sh` prompts for anything missing (silently, no echo) and writes the
file `chmod 600`. Because the passwords stay set inside the apps, anything that
reaches a container without going through the gateway still has to know them.

## Scope, deliberately

- **The LAN is trusted.** Direct `http://<pi>:8112` from the home network gets
  auto-logged-in exactly like the tunnel does; the gateway does not verify the
  Cloudflare Access JWT. That was a conscious choice — if you ever want the LAN
  gated too, add a `forward_auth`/JWT check to the Caddyfile and close the
  ports to anything but Tailscale.
- **Plex is untouched.** A Plex account is mandatory and can't be federated;
  it's not tunneled either. `ALLOWED_NETWORKS` already skips its login on the LAN.
- **AdGuard has no login to remove** — it was never taken through its setup
  wizard (`/install.html`), so its config dir is empty and its DNS filtering is
  not actually running. When it does get set up, `users: []` in
  `AdGuardHome.yaml` disables its auth outright, or it can be added here as a
  third app (it mints an `agh_session` cookie from `POST /control/login`).

## Operating it

```sh
docker logs sso-gateway     # caddy: proxying
docker logs sso-minter      # one line per login it performs
docker restart sso-minter   # after changing .env
```

If a login starts failing you get a plain-text 502 from the gateway naming the
app and the reason, rather than a redirect loop — the minter sets a 10-second
guard cookie and refuses to bounce you twice.

## Caveat

The gateway is now in front of Portainer and Deluge, so if it is down those two
UIs are unreachable (the containers themselves keep running, and Deluge keeps
torrenting). `docker compose -f modules/150-sso-gateway/docker-compose.yml up -d`
brings it back.
