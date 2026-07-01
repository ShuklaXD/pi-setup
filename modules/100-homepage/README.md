# 100-homepage

The home server's landing page — a single branded page that ties every service
together. Plain `nginx:alpine` serving the committed `site/` directory; the page
itself is a self-contained static HTML file (Nord dark theme).

- **Local:** http://10.75.12.44:8090
- **Public:** https://shubhiixd.com (via the Cloudflare Tunnel — see below)
- Each app card links to its own subdomain (`portainer.shubhiixd.com`, …).
  Click **"LAN links"** in the footer to switch every card to its `10.75.12.44:PORT`
  address for when you're on the home network.

## Editing the page

Edit `site/index.html`. The app list lives in the `APPS` object near the bottom
of the file — add/remove cards there. Re-run the module to apply (nginx serves
the bind-mounted dir live, so a browser refresh is usually enough):

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/100-homepage/install.sh
```

## Cloudflare: public hostnames + SSO

The Pi's tunnel is **token-managed**, so its routing and Access (SSO) policies
live in the **Cloudflare Zero Trust dashboard**, not in a local file. To publish
this page and lock it down:

### 1. Route the hostnames to the tunnel

Zero Trust → **Networks → Tunnels** → your tunnel → **Public Hostname** → *Add*,
one per row (all served from this host, so the service is `localhost:PORT`):

| Hostname                   | Service                          |
|----------------------------|----------------------------------|
| `shubhiixd.com`            | `http://localhost:8090`          |
| `www.shubhiixd.com`        | `http://localhost:8090`          |
| `portainer.shubhiixd.com`  | `https://localhost:9443` *(TLS → No TLS Verify ON)* |
| `adguard.shubhiixd.com`    | `http://localhost:3000`          |
| `dashy.shubhiixd.com`      | `http://localhost:4000`          |
| `deluge.shubhiixd.com`     | `http://localhost:8112`          |
| `it-tools.shubhiixd.com`   | `http://localhost:8082`          |
| `stirling.shubhiixd.com`   | `http://localhost:8083`          |
| `snapotter.shubhiixd.com`  | `http://localhost:1349`          |
| `area.shubhiixd.com`       | `http://localhost:8091`          |
| `games.shubhiixd.com`      | `http://localhost:8092`          |

### 2. Lock everything behind SSO (Cloudflare Access)

Zero Trust → **Access → Applications → Add an application → Self-hosted**.
Create two apps so one policy covers the apex and all subdomains:

- App A — Application domain: `shubhiixd.com`
- App B — Application domain: `*.shubhiixd.com`

For each, add a policy: **Action = Allow**, **Include → Emails →
`dev@veritaiworx.com`**. Set the login method to **One-time PIN** (emails you a
code — no IdP setup needed) or Google.

Result: anyone hitting any `*.shubhiixd.com` page must pass Cloudflare's login
and be `dev@veritaiworx.com`; everyone else is blocked at Cloudflare's edge,
before the request ever reaches the Pi.

> Note: because routing/SSO are stored in the Cloudflare dashboard (token
> tunnel), they are **not** reproduced by this module's `install.sh`. This README
> is the source of truth for that side — re-apply these steps on a rebuild.
