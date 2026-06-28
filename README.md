# pi-setup

Reproducible provisioning for my Raspberry Pi / home server. The goal: after an
OS reinstall (or on a brand-new machine), clone this repo and run one command to
get back to an identically configured system.

```sh
git clone git@github.com:ShuklaXD/pi-setup.git ~/workspaces/pi-setup
cd ~/workspaces/pi-setup
./install.sh
```

## How it works

Every customization is a **module** under `modules/NN-name/` with its own
idempotent `install.sh`. The top-level `install.sh` runs them in order by their
`NN` prefix. Re-running is always safe.

```
pi-setup/
├── install.sh          # orchestrator: runs every module in order
├── lib/common.sh       # shared helpers (logging, pkg_install, link, ...)
├── MANIFEST.md         # human-readable log of what's configured
└── modules/
    ├── 00-dotfiles/    # clone + apply ShuklaXD/dotfiles
    └── NN-name/        # one folder per customization
```

### Running a subset

```sh
./install.sh --list          # show all modules
./install.sh tailscale       # run only modules matching "tailscale"
```

## Module conventions

- Numbered prefix sets order. Lower numbers run first (`00` foundational, then
  `10`, `20`, ...). Leave gaps so new modules can slot in between.
- Each module: `modules/NN-name/install.sh` (required) + `README.md` (what & why).
- Source helpers at the top: `source "$PI_SETUP_ROOT/lib/common.sh"`.
- Must be **idempotent** — check-before-change, never assume a clean machine.
- Use `pkg_install`, `link`, `ensure_line`, `have` from `lib/common.sh`.

## Conventions for secrets

Secrets never go in this repo. Modules that need a key/token read it from the
environment or prompt at install time. See `.gitignore`.
