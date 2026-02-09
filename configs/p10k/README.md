# Powerlevel10k Starship-style config

This config makes Powerlevel10k look and behave like the Starship prompt used in this repo:

- Same segment order: directory, git, kubernetes, python (venv), golang, node, command duration, then newline and `[$]`
- Same colors: Catppuccin Macchiato (blue dir, cyan git/k8s, yellow duration, etc.)
- Same behaviour: directory truncate to 3, cmd duration from 300ms with milliseconds, jobs on right

It sources the official p10k lean config and overrides only what is needed. Requires Powerlevel10k to be installed at `~/.zsh/themes/powerlevel10k` (or set `POWERLEVEL9K_INSTALLATION_DIR`).
