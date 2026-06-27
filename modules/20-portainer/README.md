# 20-portainer

**Portainer CE** — a web dashboard for observing Docker (container health, logs,
resource stats) at `https://<pi-ip>:9443`.

Defined by the committed `docker-compose.yml` here. On first visit you set the
admin password (stored in the `portainer_data` volume, not in git).

## Role in this setup

Portainer is for **monitoring**, not for defining services. Keep each service as a
committed `docker-compose.yml` module so the repo stays the single source of
truth. Avoid creating "stacks" through Portainer's UI — that state lives only in
its volume and breaks reproducibility.
