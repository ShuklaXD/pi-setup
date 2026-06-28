---
name: pi-setup
description: Capture and reproduce this Raspberry Pi / home-server setup. Use whenever the user asks to install, configure, customize, or personalize the machine (packages, services, system settings, daemons, dotfiles). Every customization is recorded as an idempotent module in the ~/workspaces/pi-setup git repo and committed, so the whole machine can be rebuilt from scratch with one command.
---

# pi-setup

This machine's configuration is kept reproducible in the git repo at `~/workspaces/pi-setup`.
The contract: **anything we change on the machine must also be captured there as a
module and committed**, so a fresh OS install can be restored by cloning the repo
and running `./install.sh`.

## When this applies

Any request to install a package, set up a service/daemon, change a system
setting, add a cron job, configure networking, or otherwise personalize the Pi.
If it changes the machine's state, it gets a module.

## The workflow for every customization

1. **Do the change** on the live machine so the user gets the result now (e.g.
   actually `apt-get install`, enable the service, write the config).
2. **Capture it as a module** in `~/workspaces/pi-setup/modules/NN-name/`:
   - `install.sh` — idempotent script that reproduces the change from scratch.
   - `README.md` — what it does and why (short).
3. **Verify** the module re-runs cleanly: `bash modules/NN-name/install.sh`
   should be a no-op the second time (no errors, reports "ok").
4. **Update `MANIFEST.md`** with a one-row entry (newest first).
5. **Commit** in `~/workspaces/pi-setup` with a clear message, one commit per customization.

Prefer doing step 1 *by writing and running the module's `install.sh`* — that way
the live change and the captured change are guaranteed identical.

## Repo layout & conventions

- `install.sh` — orchestrator; runs every `modules/*/install.sh` in lexical order.
- `lib/common.sh` — source it at the top of every module:
  `source "$PI_SETUP_ROOT/lib/common.sh"`. Provides:
  - `pkg_install <pkg…>` — apt install only what's missing (updates once).
  - `link <src> <dst>` — symlink with backup of any existing file.
  - `ensure_line <file> <line>` — append a line only if absent.
  - `have <cmd>` — is a command on PATH?
  - `log/ok/warn/err/step` — consistent logging.
- Modules are numbered: `00` foundational (dotfiles), then `10`, `20`, …. Leave
  gaps so new modules slot in. Higher number = runs later.
- **Idempotency is mandatory.** Check before changing. Never assume a clean box.

## Module template

```bash
#!/usr/bin/env bash
# NN-name — <one line>
set -euo pipefail
source "$PI_SETUP_ROOT/lib/common.sh"

pkg_install some-package
# ... idempotent configuration ...
ok "name configured"
```

When invoking a module's `install.sh` directly for testing, export the root first:
`PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/NN-name/install.sh`.

## Secrets

Never commit secrets. Modules that need a token/key read it from the environment
or prompt at install time. `.gitignore` already excludes `*.env`, `*.key`, etc.

## Remote

The repo is local-only for now (no remote configured). If the user later wants
one-click restore on another machine, set up a GitHub remote and push.

## Commit style

One commit per customization, present-tense summary, e.g.
`Add 20-docker module: install Docker Engine + compose`. Run git commands with
`-C ~/workspaces/pi-setup`.
