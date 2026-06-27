# 90-samba

**Samba** network drive (SMB) so the Pi appears as a mapped drive on Windows
(also works on macOS/Linux). Uses the
[ServerContainers/samba](https://github.com/ServerContainers/samba) image with
host networking (clean SMB + Windows discovery via wsdd/avahi).

## Shares

| Share | Host path | Access |
|-------|-----------|--------|
| `Shares` | `~/shares` | read-write |
| `Downloads` | `~/downloads` | **read-only** (so you can grab completed torrents without disturbing Deluge) |

Login user: **`shukks`** (UID 1000, so files written from Windows stay owned by
your host user). Password is in a **gitignored** `.env` (`SMB_PASSWORD`).

## Credentials (required)

```sh
cp modules/90-samba/.env.example modules/90-samba/.env
# edit .env and set SMB_PASSWORD
```

`install.sh` won't start until `SMB_PASSWORD` is set.

## Map the drive on Windows

**File Explorer:** right-click *This PC* → *Map network drive…* → pick a letter
(e.g. `Z:`) → Folder: `\\<pi-ip>\Shares` → check *Connect using different
credentials* → user `shukks`, your `SMB_PASSWORD`.

**Or via command line (cmd/PowerShell):**

```bat
net use Z: \\<pi-ip>\Shares /user:shukks *
```

(`*` prompts for the password.) Replace `<pi-ip>` with the Pi's LAN IP.

## Notes

- To make `Downloads` writable, change `read only = yes` to `no` in
  `docker-compose.yml` and re-run the module.
- Modern Windows requires SMB2/3 (this image provides it). If an old client can't
  connect, it's likely SMB1 being (correctly) refused.
- Port 445 (and 139) must be free on the host — verified at setup time.
