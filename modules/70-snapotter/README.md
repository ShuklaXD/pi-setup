# 70-snapotter

**SnapOtter** — self-hosted file-manipulation suite (image/video/audio/PDF tools,
format conversion, plus some local AI). At `http://<pi-ip>:1349`.

- **Default login:** `admin` / `admin` — you're required to change it on first use.
- **Stack:** SnapOtter app + PostgreSQL 17 + Redis 8 (one compose file).
- **Image:** CPU build (`snapotter/snapotter:latest`) — the Pi 4 has no NVIDIA GPU,
  so the GPU image doesn't apply.

## Pi 4 expectations (important)

- **Everyday file tools** (PDF, convert, resize, format) work well — they're light.
- **AI features** (background removal, upscaling, OCR, transcription) run
  **CPU-only** and are **slow** (seconds-to-minutes per job). Use small inputs.
- The app container is **capped at 2 GB RAM** (`mem_limit`). A runaway AI job will
  be OOM-killed in isolation rather than taking down Deluge/AdGuard/etc. If an AI
  job fails, that limit is usually why — it's the intended safety behaviour.

## Data

Everything persists on the host under `~/appdata/snapotter/{data,postgres,redis}`
(not in git). Postgres uses the upstream default password and is **not** exposed
to the host (internal Docker network only).

## Memory caps

| Container | Limit |
|-----------|-------|
| snapotter (app) | 2 GB |
| postgres | 512 MB |
| redis | 256 MB (maxmemory 192 MB, LRU) |

> **The `mem_limit` only works if the kernel cgroup memory controller is enabled.**
> Raspberry Pi OS disables it by default — see module `05-cgroup-memory` (requires
> a reboot). Until that's applied + rebooted, these caps are silently ignored.

