# 10-docker

Installs **Docker Engine + Compose v2 plugin** natively (the foundation for all
containerized services), using the official `get.docker.com` script.

- Adds the current user to the `docker` group (re-login or `newgrp docker` to use
  docker without `sudo`).
- Enables the `docker` systemd service so containers come back after a reboot.
- Compose v2 is the `docker compose` subcommand (plugin), not the old
  `docker-compose` binary.

This is the base layer; every service module after this defines a
`docker-compose.yml` committed to the repo.
