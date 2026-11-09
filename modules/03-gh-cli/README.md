# 03-gh-cli

Installs the GitHub CLI (`gh`, pinned official release binary in `~/.local/bin`, checksum-verified, no sudo) so repos and PRs can be created
from the Pi (SSH alone can push but cannot create repositories).

Login is interactive and the token is not stored in this repo; run it once
after install:

```bash
gh auth login     # GitHub.com → SSH → login with a web browser
```

Git pushes still use the SSH key from `02-ssh-config`.
