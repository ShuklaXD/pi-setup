# 50-dashy

**Dashy** — a single landing page that links every service on this Pi, with a
clean themeable UI. At `http://<pi-ip>:4000`.

## Config is version-controlled

The dashboard layout lives in `conf.yml` **in this module** (committed to git), so
your dashboard is reproducible. Edit `conf.yml` and re-run the module to apply, or
edit live in the Dashy UI and export the YAML back into this file.

- Update the `10.75.12.44` URLs if your Pi's LAN IP changes.
- Add new services as `items` under a `section` as you install more modules.

## Port

| Port | Purpose |
|------|---------|
| 4000 | Web UI (container listens on 8080) |
