# 60-it-tools

**IT-Tools** — a self-hosted collection of ~50 handy utilities: token/UUID
generators, base64/JWT/hash encoders, JSON/SQL/XML formatters, cron parsers,
color/network helpers, and more. At `http://<pi-ip>:8082`.

Stateless — no config or volumes. Updating is just pulling a newer image and
re-running the module.

## Port

| Port | Purpose |
|------|---------|
| 8082 | Web UI (container listens on 80) |
