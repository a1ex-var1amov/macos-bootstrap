# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A dotfiles/configuration repo for a modern terminal setup. It contains config files for Ghostty, Zsh, Starship, Powerlevel10k, Vim, Neovim, Tmux, Git, and Cursor IDE — all themed with Catppuccin Frappé.

## Installation

```bash
./install.sh   # Interactive: installs all configs, asks for prompt engine choice
```

The installer symlinks/copies configs to their target paths (see table below), backs up existing files with `.bak.TIMESTAMP` suffixes, and optionally installs missing Homebrew packages.

## Color Themes

Eleven themes are available across three families:
- **Catppuccin**: Frappé (default), Macchiato, Mocha, Latte (light)
- **Tokyo Night**: Night, Storm, Moon, Day (light)
- **Rosé Pine**: Main, Moon, Dawn (light)

Plus pair modes that auto-switch with macOS appearance in Ghostty: Catppuccin (Mocha ↔ Latte), Tokyo Night (Night/Storm/Moon ↔ Day), Rosé Pine (Main/Moon ↔ Dawn).

Theme files live in `configs/{ghostty,tmux,nvim}/themes/`. The installer (section 10, choices 1–17) asks which scheme to use and writes:
- `~/.config/ghostty/themes/` + `theme = <name>` line in `~/.config/ghostty/config`
- `~/.config/tmux-theme.conf` (sourced at end of `~/.tmux.conf`)
- `~/.config/nvim/lua/active_theme.lua` + `~/.config/nvim/lua/theme_base.lua`
- `~/.config/terminal-color-theme` (persists choice across reinstalls)

To switch theme without re-running the full installer:
```bash
# Ghostty: edit ~/.config/ghostty/config → theme = tokyo-night
# Tmux:
cp configs/tmux/themes/tokyo-night.conf ~/.config/tmux-theme.conf && tmux source-file ~/.tmux.conf
# Neovim:
cp configs/nvim/themes/tokyo-night.lua ~/.config/nvim/lua/active_theme.lua
```

## Config File → Install Target Mapping

| Source | Installed to |
|--------|-------------|
| `configs/zsh/zshrc` | `~/.zshrc` |
| `configs/starship/starship.toml` | `~/.config/starship.toml` |
| `configs/p10k/p10k-starship-style.zsh` | `~/.p10k.zsh` |
| `configs/ghostty/config` | `~/.config/ghostty/config` |
| `configs/vim/vimrc` | `~/.vimrc` |
| `configs/nvim/init.lua` | `~/.config/nvim/init.lua` |
| `configs/tmux/tmux.conf` | `~/.tmux.conf` |
| `configs/git/gitconfig` | `~/.config/git/gitconfig` (included via `~/.gitconfig`) |
| `configs/git/gitignore_global` | `~/.gitignore_global` |
| `configs/cursor/settings.json` | `~/Library/Application Support/Cursor/User/settings.json` |
| `configs/vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `cheatsheets/*.txt` | `~/.config/*.txt` |

## Architecture Notes

### Prompt Engine Selection
The prompt choice (Starship vs Powerlevel10k) is persisted at `~/.config/terminal-fix-prompt` as `export PROMPT_ENGINE=starship|p10k`. The `.zshrc` reads this file at load time and initializes the appropriate prompt. Both prompts are configured to look identical (same segments: directory, git, k8s, languages, duration).

### Zsh Plugin Load Order (important)
In `configs/zsh/zshrc`, order matters:
1. `fpath` + `compinit` (completions must come first)
2. `zsh-autosuggestions`
3. `zsh-fast-syntax-highlighting` (must be last among plugins)
4. `zoxide`, `fzf`, `direnv`
5. `fzf-tab` (after fzf)
6. Prompt init (last — p10k resets zsh options, so history options are re-applied after)

### Kubernetes Context Shortening
`_shorten_k8s_context()` in `.zshrc` normalizes long k8s context strings (AWS EKS ARNs, GKE prefixes, OpenShift API URLs, custom `sc-k8s-*` patterns) to short display names. This feeds both the terminal title and the `ts` tmux session-naming function.

### Tool Aliases with Fallbacks
All modern CLI replacements (`bat`, `eza`, `rg`, `fd`, `btop`, `duf`, `delta`, etc.) use `(( $+commands[tool] ))` guards so the config degrades gracefully when tools are missing.

### Terminal Title
Title is set via `zle-line-init` (fires just before each prompt) and `preexec` hook (shows running command). Format: `folder | k8s-context`. Inside tmux, uses pass-through escape sequences to update both the tmux window name and the outer terminal (Ghostty).
