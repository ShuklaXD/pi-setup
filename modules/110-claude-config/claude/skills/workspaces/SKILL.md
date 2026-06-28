---
name: workspaces
description: Ensures every new code project lives under ~/workspaces. Use whenever the user asks to create, scaffold, initialize, clone, or start a new project, app, service, library, or repository — before running any scaffolder (git clone, npm/pnpm/yarn create, cargo new, npx create-*, django-admin startproject, go mod init, etc.) or creating a project directory. Not for machine/system config (that is the pi-setup skill).
---

# workspaces

All code projects on this machine live under **`~/workspaces`**
(`/home/shukks/workspaces`). A new project must never be created in the home
directory, the current working directory, `/tmp`, or anywhere else — it goes in
its own subfolder of `~/workspaces`.

Existing projects there: `ledger`, `tunes`, `pi-setup`.

## When this applies

Any time a *new* project/codebase is about to come into existence:

- Cloning a repo (`git clone …`)
- Scaffolding (`npm/pnpm/yarn create …`, `npx create-*`, `cargo new`,
  `go mod init`, `django-admin startproject`, `vite`, `next`, `bun init`, …)
- Manually making a project directory and `git init`
- The user says "start/build/spin up a new <thing>"

It does **not** apply to editing an existing project, or to machine/system
configuration — that belongs to the `pi-setup` skill.

## The rule

1. **Pick the target path:** `~/workspaces/<project-name>` (kebab-case the name
   if needed). If the user gave an explicit absolute path elsewhere, honor it but
   confirm they really want it outside `~/workspaces`.
2. **Create from inside `~/workspaces`.** Run the scaffolder/clone so the project
   lands there:
   ```bash
   git -C ~/workspaces clone <url>
   # or
   cd ~/workspaces && <scaffold command> <project-name>
   ```
   Avoid bare `cd` in the harness when a tool's own `-C`/`--cwd` works; for
   scaffolders that must run in the dir, `cd ~/workspaces && …` in one command.
3. **Refuse the wrong location:** if a scaffold is about to run in `~`, `/tmp`, or
   an unrelated cwd, redirect it to `~/workspaces` first and tell the user.
4. **Don't clobber:** if `~/workspaces/<name>` already exists and is non-empty,
   stop and ask before writing into it.

## Notes

- `~/workspaces` already exists; just use it (no need to recreate).
- If the project is meant to be a Docker service for the home server, the
  *config* still gets captured as a `pi-setup` module — the two skills compose.
- This skill sets the convention; it does not auto-enforce on every shell command.
  If you want hard enforcement, a settings.json hook can block scaffolds outside
  `~/workspaces` (ask the update-config skill).
