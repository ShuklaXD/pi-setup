# 02-ssh-config

SSH client config so `git` (and any SSH) picks the correct key per host. Without
this, `git@github.com` falls back to default key resolution and fails on this box
(no agent, no default key), which is why pushes to `ShuklaXD/*` repos didn't work
until this was added.

Currently maps:

| Host         | Identity file        |
|--------------|----------------------|
| `github.com` | `~/.ssh/shuklaxd`    |

The module appends a `Host` block to `~/.ssh/config` only if one isn't already
there (idempotent), and fixes perms (`~/.ssh` → 700, `config` → 600).

## Secrets

**Private keys are NOT in this repo.** This module captures only the host→key
*mapping*. On a fresh machine you must drop the actual key in place yourself:

```bash
install -m 600 /path/to/shuklaxd ~/.ssh/shuklaxd
```

The module warns at install time if the referenced key is missing.

## Add another host

Add a line to the `MAPPINGS` array in `install.sh`
(`Host|HostName|User|IdentityFile`) and re-run.

## Re-run

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/02-ssh-config/install.sh
```
