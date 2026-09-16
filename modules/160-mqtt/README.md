# 160-mqtt

**Mosquitto MQTT broker** + **MQTTX Web** dashboard, exposed to the internet
through **Tailscale Funnel** (TLS terminated by Tailscale, no port-forwarding),
plus a **recorder** sidecar that persists every message on `dmrc/#` and
`system-health/#` to SQLite. Mirrors the `SETUP.md` in the project repo.

The project itself lives in its own repo at `~/workspaces/mqtt-server`
(`git@bitbucket.org:verit_aiworx/mqtt-server.git`) — compose file + `mosquitto.conf`.
This module clones/pulls it, generates the gitignored `config/passwd`
(default user `mqtt-tri`; override with `MQTT_USER`/`MQTT_PASS` env at install
time), runs `docker compose up -d`, and re-asserts the Funnel routes.

## One-time tailnet prerequisites (not scriptable)

- Tailscale installed + `sudo tailscale up` on the node
- MagicDNS + HTTPS Certificates enabled: <https://login.tailscale.com/admin/dns>
- Funnel allowed for the node in the ACL (the first `funnel` run prints the link)
- `sudo tailscale set --operator=$USER` — the module does this, but it prompts for sudo

## Endpoints

| Port | Where | Purpose |
|------|-------|---------|
| 1883 | LAN | MQTT (raw TCP) |
| 9001 | LAN | MQTT over WebSocket |
| 8080 | LAN | MQTTX Web UI |
| 8443 | Funnel `mqtts://pi.tail62068e.ts.net` | MQTT over TLS → 1883 |
| 10000 | Funnel `wss://pi.tail62068e.ts.net:10000/mqtt` | WebSocket over TLS → 9001 |
| 443 | Funnel `https://pi.tail62068e.ts.net` | MQTTX Web UI → 8080 |

## Recorded messages

Mosquitto keeps no history; the `mqtt-recorder` container does. Database:
`~/workspaces/mqtt-server/data/mqtt.db` (gitignored, survives `compose down`).

```bash
cd ~/workspaces/mqtt-server
docker compose exec recorder python recorder.py tail    # last 20 messages
docker compose exec recorder python recorder.py stats   # counts per topic
sqlite3 data/mqtt.db                                    # ad-hoc SQL
```

## Tear down

```bash
tailscale funnel reset
docker compose -f ~/workspaces/mqtt-server/docker-compose.yaml down
```
