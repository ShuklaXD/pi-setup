#!/usr/bin/env python3
"""Idempotently ensure the workspaces-enforcement PreToolUse hook is present in
~/.claude/settings.json, preserving every other setting. Safe to re-run."""
import json
import os
import sys

PATH = os.path.expanduser("~/.claude/settings.json")
CMD = 'python3 "$HOME/.claude/hooks/enforce-workspaces.py"'

try:
    with open(PATH) as f:
        data = json.load(f)
except FileNotFoundError:
    data = {}
except Exception as e:  # malformed file — don't silently clobber it
    print(f"error: {PATH} is not valid JSON ({e}); fix it and re-run", file=sys.stderr)
    sys.exit(1)

pre = data.setdefault("hooks", {}).setdefault("PreToolUse", [])

# Already wired up?
for entry in pre:
    if entry.get("matcher") == "Bash":
        for h in entry.get("hooks", []):
            if h.get("type") == "command" and "enforce-workspaces" in h.get("command", ""):
                print("settings.json: hook already present")
                sys.exit(0)

# Reuse an existing Bash matcher block if there is one, else add a new one.
bash_entry = next((e for e in pre if e.get("matcher") == "Bash"), None)
if bash_entry is None:
    bash_entry = {"matcher": "Bash", "hooks": []}
    pre.append(bash_entry)

bash_entry.setdefault("hooks", []).append({
    "type": "command",
    "command": CMD,
    "statusMessage": "Checking project location policy",
})

with open(PATH, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("settings.json: added workspaces-enforcement hook")
