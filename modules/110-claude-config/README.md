# 110-claude-config

Captures this machine's Claude Code customizations so a rebuild restores them.

What it installs into `~/.claude`:

| Item | Target | How |
|------|--------|-----|
| Workspaces-enforcement hook | `~/.claude/hooks/enforce-workspaces.py` | symlink → repo |
| `workspaces` skill | `~/.claude/skills/workspaces/` | symlink → repo |
| `pi-setup` skill | `~/.claude/skills/pi-setup/` | symlink → repo |
| PreToolUse(Bash) hook entry | `~/.claude/settings.json` | merged in place |

The files are **symlinked** back to this module, so editing them here (or there)
keeps the repo copy authoritative and version-controlled. `settings.json` can't be
symlinked (it holds other personal settings like `theme`), so `merge-settings.py`
adds the hook entry idempotently and leaves everything else untouched.

## The hook

`enforce-workspaces.py` is a `PreToolUse` hook on `Bash`. It blocks project
scaffolding / clone commands (`git clone`, `npm/pnpm/yarn/bun create|init`,
`npx create-*`, `cargo new`, `go mod init`, `django-admin startproject`, `rails
new`, `flutter create`, `dotnet new`, `composer create-project`, …) when they
would land **outside `~/workspaces`**. Bypass a single command with the prefix
`ALLOW_OUTSIDE_WORKSPACES=1`. This enforces the convention set by the
`workspaces` skill.

## Re-run

```bash
PI_SETUP_ROOT=~/workspaces/pi-setup bash ~/workspaces/pi-setup/modules/110-claude-config/install.sh
```

> Claude Code loads hook config at session start. After a fresh install, open
> `/hooks` once (reloads config) or restart Claude Code for the hook to take
> effect. The skills are picked up on next session start.

## Note

The original (non-symlinked) files are backed up by `link` to
`*.bak.<timestamp>` the first time this runs on an existing machine — safe to
delete once you've confirmed the symlinks work.
