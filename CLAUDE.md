# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A dotfiles/configuration repo for a modern terminal setup. It contains config files for Ghostty, Zsh, Starship, Powerlevel10k, Vim, Neovim, Tmux, Git, and Cursor IDE — all themed with Catppuccin Frappé.

## Installation

```bash
./install.sh                  # Interactive (default)
./install.sh --yes            # Non-interactive (accept all defaults)
./install.sh --update         # Skip install prompts; redeploy configs/themes only
./install.sh --update --yes   # Quiet refresh after pulling repo changes
```

The installer copies configs to their target paths (see table below), backs up existing files with `.bak.TIMESTAMP` suffixes, and optionally installs missing Homebrew packages. `--update` mode skips Homebrew/CLI/Cask/SSH/macOS-defaults sections and only re-syncs config files; useful for iterating on the repo.

## Color Themes

Twelve themes are available across four families:
- **Catppuccin**: Frappé (default), Macchiato, Mocha, Latte (light)
- **Tokyo Night**: Night, Storm, Moon, Day (light)
- **Rosé Pine**: Main, Moon, Dawn (light)
- **Dracula**: classic dark purple, Alucard (light warm cream)

Plus pair modes that auto-switch with macOS appearance in Ghostty: Catppuccin (Mocha ↔ Latte), Tokyo Night (Night/Storm/Moon ↔ Day), Rosé Pine (Main/Moon ↔ Dawn), Dracula (Dracula ↔ Alucard).

Theme files live in `configs/{ghostty,tmux,nvim}/themes/`. The installer (section 10, choices 1–20) asks which scheme to use and writes:
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
`_shorten_k8s_context()` in `.zshrc` normalizes long k8s context strings (AWS EKS ARNs, GKE prefixes, OpenShift API URLs, custom user patterns) to short display names. This feeds both the terminal title and the `ts` tmux session-naming function.

A parallel bash implementation lives at `configs/tmux/scripts/k8s-context.sh` and is used by the tmux status bar (with a 5s cache to avoid shelling out to `kubectl` on every status-interval render). Keep both implementations in sync when adding patterns.

User-defined patterns can be added to `~/.config/k8s-context-patterns` (one rule per line, format `<substring> <display-name>`); both implementations read this file.

### Tmux Theme Token System
Tmux themes (`configs/tmux/themes/*.conf`) are **color tokens only** — they each set 11 user options (`@bg`, `@surface`, `@text`, `@subtle`, `@muted`, `@accent`, `@accent2`, `@ok`, `@warn`, `@err`, `@select`). The actual status-bar format strings, pane border styles, popup color overrides, and all bindings live once in `configs/tmux/tmux.conf` and reference these tokens via `#{@bg}` etc.

Adding a new theme = copy any existing theme file and edit the 11 hex values. The token contract is enforced by `tests/check.sh` ("Tmux theme tokens" section).

### Tmux Helper Scripts
`configs/tmux/scripts/git-branch.sh` and `configs/tmux/scripts/k8s-context.sh` are used by the tmux status-right. Both:
- Apply a 1-second `timeout` (uses `timeout` or `gtimeout`, falls back to direct exec) so a slow disk or unreachable kubeconfig can't freeze the status bar.
- Cache results in `$TMPDIR/tmux-*` (k8s-context only) for 5s, matching `status-interval`.

The installer copies them to `~/.config/tmux/scripts/` and ensures the executable bit is set.

### Tmux Session Helpers (`ts`, `tsp`, `tsk`, `tka`)
All four functions in `.zshrc` are safe to call from inside an existing tmux client — they detect `$TMUX` and use `switch-client` instead of `attach`. `tsk` creates a session with a specific `KUBECONFIG` exported in its environment for multi-cluster workflows. `tka` always prompts before killing the server.

**Important**: The zshrc unsets stale `KUBECONFIG` values (paths that no longer exist) but preserves intentionally-set ones — this is required for `tsk` to work. The check is `[[ -n "$KUBECONFIG" && ! -r "${KUBECONFIG%%:*}" ]] && unset KUBECONFIG`. Don't replace this with an unconditional `unset` or `tsk` breaks.

### Lazy Plugin Loading
`fnm` (Node.js version manager) is lazy-loaded — `fnm env` only runs the first time you invoke `node`, `npm`, `npx`, `pnpm`, or `yarn`. This shaves ~100ms off every shell startup. The pattern is a stub function that self-replaces on first use.

### Shell Function Inventory
Beyond aliases, the zshrc defines these user-facing functions:
- Session: `ts`, `tsp`, `tsk`, `tka`, plus `tad` alias
- Kubernetes fzf choosers: `kx` (contexts with ns preview), `kn` (namespaces with pod preview)
- GitHub fzf choosers: `prc` (checkout PR), `prv` (view PR)
- Filesystem: `mkcd`, `extract`, `ff`, `fdir`
- Theme: `theme-sync` (auto-detect or explicit dark/light)
- System: `free`, `ports`, `path`, `h`, `topcmd`
- Internals: `_shorten_k8s_context`, `_get_k8s_context`, `_set_terminal_title`, `_fnm_lazy_init`

### Tool Aliases with Fallbacks
All modern CLI replacements (`bat`, `eza`, `rg`, `fd`, `btop`, `duf`, `delta`, etc.) use `(( $+commands[tool] ))` guards so the config degrades gracefully when tools are missing.

### Terminal Title
Title is set via `zle-line-init` (fires just before each prompt) and `preexec` hook (shows running command). Format: `folder | k8s-context`. Inside tmux, uses pass-through escape sequences to update both the tmux window name and the outer terminal (Ghostty).
