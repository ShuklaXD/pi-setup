# 80-stirling-pdf

**Stirling-PDF** — a self-hosted PDF toolkit: merge/split, rotate, compress,
convert to/from Office & images, OCR, sign, watermark, redact, and more. At
`http://<pi-ip>:8083`.

- **No login** by default (`SECURITY_ENABLELOGIN=false`) — intended for LAN /
  Tailscale access. Set it to `true` and re-run to enable accounts.
- **No database** — lighter than SnapOtter; a Java/Spring app plus bundled tools
  (LibreOffice, OCRmyPDF, Ghostscript).

## Image variants

Uses `:latest` (all PDF features, incl. OCR + Office conversion). Alternatives:

| Tag | Notes |
|-----|-------|
| `latest` | All PDF features (current choice) |
| `latest-fat` | + extra fonts/tools for best-quality conversions (largest) |
| `latest-ultra-lite` | Core features only — no OCR/conversions. Lightest; swap to this if RAM is tight on the Pi |

## Pi 4 notes

- Standard `:latest` runs well on arm64. OCR and Office conversions are the heavy
  operations (CPU + RAM); typical documents are fine.
- Capped at **1.5 GB** (`mem_limit`) — only enforced once `05-cgroup-memory` is
  applied and the Pi rebooted; otherwise the cap is silently ignored.

## Data

Persists on the host under `~/appdata/stirling-pdf/{configs,tessdata,logs,pipeline}`
(not in git). Add OCR language packs into `tessdata`.

## Overlap

SnapOtter (`70-snapotter`) also does PDF work. Stirling-PDF is the more polished
PDF-specific tool; keep both, or drop one to save RAM.
