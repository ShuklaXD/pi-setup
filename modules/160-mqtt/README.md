# 160-mqtt

**Mosquitto MQTT broker** + **MQTTX Web** dashboard, exposed to the internet
through **Tailscale Funnel** (TLS terminated by Tailscale, no port-forwarding),
plus a **recorder** sidecar that persists every message on `dmrc/#` and
`system-health/#` to SQLite, and a **dashboard** that monitors the recorded
sensor data. Mirrors the `SETUP.md` in the project repo.

The project itself lives in its own repo at `~/workspaces/mqtt-server`
(`git@bitbucket.org:verit_aiworx/mqtt-server.git`) and ships its own idempotent
`start.sh`. This module only clones/pulls the repo and hands off to that script,
so a machine rebuild and a manual start run identical code.

`start.sh` generates the gitignored `config/passwd` (default user `mqtt-tri`;
override with `MQTT_USER`/`MQTT_PASS` at install time), brings up all four
containers, waits until each one answers, and re-asserts the Funnel routes.
Run it directly for day-to-day use:

```bash
~/workspaces/mqtt-server/start.sh            # full start + Funnel
~/workspaces/mqtt-server/start.sh --status   # what is running, changes nothing
```

## One-time tailnet prerequisites (not scriptable)

- Tailscale installed + `sudo tailscale up` on the node
- MagicDNS + HTTPS Certificates enabled: <https://login.tailscale.com/admin/dns>
- Funnel allowed for the node in the ACL (the first `funnel` run prints the link)
- `sudo tailscale set --operator=$USER` — **run this yourself in a terminal once.**
  The module attempts it, but `sudo` needs a password, so an unattended run
  cannot complete it. Until it is set every funnel command dies with
  `sending serve config: Access denied: serve config denied`.

The module detects the operator with
`tailscale debug prefs | grep '"OperatorUser": "$USER"'` and skips the step when
already set, so re-runs are clean. (The prefs key is `OperatorUser`, not
`Operator`; and `tailscale funnel status` exiting 0 does not imply the operator
is set — it prints "No serve config" either way.)

The three `tailscale funnel --bg ...` calls are idempotent: each re-run just
re-asserts the same route.

## Endpoints

| Port | Where | Purpose |
|------|-------|---------|
| 1883 | LAN | MQTT (raw TCP) |
| 9001 | LAN | MQTT over WebSocket |
| 8080 | LAN | MQTTX Web UI |
| 8443 | Funnel `mqtts://pi.tail62068e.ts.net` | MQTT over TLS → 1883 |
| 10000 | Funnel `wss://pi.tail62068e.ts.net:10000/mqtt` | WebSocket over TLS → 9001 |
| 443 | Funnel `https://pi.tail62068e.ts.net` | MQTTX Web UI → 8080 |
| 8093 | LAN (route via Cloudflare for public access) | Sensor monitoring dashboard |

## Recorded messages

Mosquitto keeps no history; the `mqtt-recorder` container does. Database:
`~/workspaces/mqtt-server/data/mqtt.db` (gitignored, survives `compose down`).

```bash
cd ~/workspaces/mqtt-server
docker compose exec recorder python recorder.py tail    # last 20 messages
docker compose exec recorder python recorder.py stats   # counts per topic
sqlite3 data/mqtt.db                                    # ad-hoc SQL
watch -n 2 'sqlite3 -header -column data/mqtt.db "SELECT committed_at, topic, payload FROM messages ORDER BY committed_at DESC LIMIT 5"'
```

## Dashboard

`http://<pi-ip>:8093` — per-sensor latest readings, trend small-multiples
(1h/6h/12h/24h/7d × temperature/humidity/CO₂/battery) and per-sensor message
counts. Read-only against `data/mqtt.db`; self-contained (no CDN).

Unlike the MQTT endpoints this is **not** on Tailscale Funnel — route it through
the Cloudflare tunnel alongside the other apps to publish it.

## Tear down

```bash
tailscale funnel reset
docker compose -f ~/workspaces/mqtt-server/docker-compose.yaml down
```
