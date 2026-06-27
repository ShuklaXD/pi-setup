# 00-dotfiles

Bootstraps the personal dotfiles from [`ShuklaXD/dotfiles`](https://github.com/ShuklaXD/dotfiles):
zsh + oh-my-zsh + powerlevel10k, vim, tmux, git config, htop.

- Clones to `~/dotfiles` (or pulls if already present), then runs its `install.sh`.
- The dotfiles repo owns the actual config files; this module only ensures it's
  present and applied on a fresh machine. Edit shell/editor configs **there**.
