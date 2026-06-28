#!/usr/bin/env python3
"""PreToolUse(Bash) hook: force new projects to be created under ~/workspaces.

Reads the hook JSON on stdin. If the Bash command looks like project
scaffolding or a clone AND would not land under ~/workspaces, it returns a
"deny" decision with a helpful message. Anything else passes through silently.

Escape hatch: prefix the command with ALLOW_OUTSIDE_WORKSPACES=1 to bypass.
"""
import json
import os
import re
import sys

def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0  # never block on a parse error

    cmd = (data.get("tool_input") or {}).get("command") or ""
    cwd = data.get("cwd") or ""
    if not cmd.strip():
        return 0

    # Explicit opt-out.
    if "ALLOW_OUTSIDE_WORKSPACES=1" in cmd:
        return 0

    home = os.path.expanduser("~")
    ws = os.path.join(home, "workspaces")

    # Commands that bring a new project into existence. The leading group anchors
    # each pattern to a command position — start of string or just after a shell
    # separator/opener ( ; | & newline ( { ) — so a trigger word merely quoted or
    # embedded in another argument (e.g. git commit -m "fix git clone docs") is
    # NOT matched.
    scaffold = re.compile(
        r"(?:^|[|&;\n(){])\s*(?:"
        r"git\s+(?:-C\s+\S+\s+)?clone\b"
        r"|(?:npm|pnpm|yarn|bun)\s+(?:create|init)\b"
        r"|npx\s+create-"
        r"|(?:pnpm|yarn)\s+dlx\s+create-"
        r"|cargo\s+(?:new|init)\b"
        r"|go\s+mod\s+init\b"
        r"|django-admin\s+startproject\b"
        r"|python[0-9.]*\s+-m\s+django\s+startproject\b"
        r"|rails\s+new\b"
        r"|flutter\s+create\b"
        r"|dotnet\s+new\b"
        r"|composer\s+create-project\b"
        r")"
    )
    if not scaffold.search(cmd):
        return 0

    # Look at every home-rooted path the command mentions (~, $HOME, /home/...).
    # If any points somewhere other than ~/workspaces, treat it as an explicit
    # foreign destination and block — even if we're currently inside workspaces.
    home_path = re.compile(
        r"(?:~|\$\{HOME\}|\$HOME|" + re.escape(home) + r")(/[^\s'\";|&)]*)?"
    )
    refs_ws = False
    foreign = False
    for m in home_path.finditer(cmd):
        seg = (m.group(1) or "").lstrip("/").split("/", 1)[0]
        if seg == "workspaces":
            refs_ws = True
        else:
            foreign = True

    if foreign:
        target_ok = False
    elif refs_ws:
        target_ok = True
    elif cwd:
        c = os.path.normpath(cwd)
        target_ok = c == ws or c.startswith(ws + os.sep)
    else:
        target_ok = False

    if target_ok:
        return 0

    reason = (
        "Blocked by the workspaces-enforcement hook: new projects must be "
        "created under ~/workspaces.\n"
        "Re-run it there, e.g.:\n"
        "  cd ~/workspaces && <command>\n"
        "  git -C ~/workspaces clone <url>\n"
        "If you really need this elsewhere, prefix the command with "
        "ALLOW_OUTSIDE_WORKSPACES=1 ."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    return 0

if __name__ == "__main__":
    sys.exit(main())
