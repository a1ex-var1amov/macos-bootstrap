# Terminal Configuration

A modern, integrated terminal setup with Ghostty, Zsh, Starship, Vim, and Tmux.

## Features

- **Ghostty** - GPU-accelerated terminal with Catppuccin Macchiato theme
- **Zsh** - Fast shell with completions, syntax highlighting, and smart aliases
- **Prompt** - Starship (default) or Powerlevel10k with a Starship-style config; same look (directory, git, k8s, langs, duration)
- **Vim** - Modern config with sensible defaults and custom keybindings
- **Tmux** - Terminal multiplexer with matching theme and smart session naming

### Highlights

- Consistent Catppuccin Macchiato color scheme across all tools
- Automatic tab/window titles showing `folder | k8s-context`
- Smart Kubernetes context shortening (AWS EKS, GKE, OpenShift)
- Tmux sessions auto-named based on directory and k8s context
- Cheatsheets for tmux and vim (`th` and `vh` commands)
- Navigation keys (Home, End, PgUp, PgDown) work properly

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/terminal-config.git
cd terminal-config
./install.sh
```

## Dependencies

### Required
- zsh
- vim
- tmux
- git

### Recommended

The install script will offer to install these automatically. During install you can choose:
- **Starship** (default) - cross-shell, minimal prompt
- **Powerlevel10k (p10k)** - Zsh-only, same look as Starship via `configs/p10k/p10k-starship-style.zsh`

```bash
# Core shell tools (Starship only if you picked Starship; p10k is cloned by install.sh if you picked p10k)
brew install starship fzf zoxide

# Modern CLI replacements
brew install bat eza ripgrep fd git-delta btop jq yq ncdu duf tldr lazygit lazydocker

# Kubernetes tools
brew install kubectl kubecolor k9s stern kubectx

# Zsh plugins
brew install zsh-autosuggestions zsh-fast-syntax-highlighting

# Font
brew install --cask font-jetbrains-mono-nerd-font
```

### What These Tools Do

| Tool | Replaces | Description |
|------|----------|-------------|
| **bat** | cat | Syntax highlighting, line numbers, git integration |
| **eza** | ls | Icons, git status, colors, tree view |
| **ripgrep (rg)** | grep | 10-100x faster, respects .gitignore |
| **fd** | find | Faster, simpler syntax |
| **delta** | diff | Beautiful syntax-highlighted diffs |
| **btop** | top/htop | Beautiful system monitor |
| **jq** / **yq** | - | JSON/YAML processing |
| **ncdu** | du | Interactive disk usage analyzer |
| **duf** | df | Better disk free with colors |
| **tldr** | man | Practical command examples |
| **lazygit** | git commands | Full git TUI - staging, commits, branches |
| **lazydocker** | docker commands | Full docker TUI - containers, images, logs |
| **k9s** | kubectl | Full Kubernetes TUI |
| **stern** | kubectl logs | Multi-pod log tailing |
| **kubectx/kubens** | - | Fast k8s context/namespace switching |

## Structure

```
.
├── install.sh              # Installation script
├── README.md
├── configs/
│   ├── ghostty/
│   │   └── config          # ~/.config/ghostty/config
│   ├── zsh/
│   │   └── zshrc           # ~/.zshrc
│   ├── starship/
│   │   └── starship.toml   # ~/.config/starship.toml (when prompt = Starship)
│   ├── p10k/
│   │   └── p10k-starship-style.zsh  # ~/.p10k.zsh (when prompt = p10k)
│   ├── vim/
│   │   └── vimrc           # ~/.vimrc
│   ├── tmux/
│   │   └── tmux.conf       # ~/.tmux.conf
│   ├── git/
│   │   └── gitconfig       # ~/.config/git/gitconfig (optional include)
│   └── cursor/
│       └── settings.json   # ~/Library/Application Support/Cursor/User/
└── cheatsheets/
    ├── tmux-cheatsheet.txt # ~/.config/tmux-cheatsheet.txt
    └── vim-cheatsheet.txt  # ~/.config/vim-cheatsheet.txt
```

## Cursor IDE Settings

The config includes Cursor/VS Code settings with:
- JetBrainsMono Nerd Font (matching terminal)
- Catppuccin Macchiato theme (install the extension)
- Sensible editor defaults
- Language-specific formatting

**Install Catppuccin theme in Cursor:**
1. Open Extensions (Cmd+Shift+X)
2. Search "Catppuccin for VSCode"
3. Install and select "Catppuccin Macchiato"

## Git Delta Integration

For beautiful git diffs, add this to your `~/.gitconfig`:

```ini
[include]
    path = ~/.config/git/gitconfig
```

This enables:
- Side-by-side diffs with syntax highlighting
- Line numbers in diffs
- Catppuccin theme matching the terminal
- Useful git aliases (`git lg`, `git s`, `git undo`, etc.)

## Quick Reference

### Shell Aliases

**Tmux:**
| Alias | Description |
|-------|-------------|
| `ts` | Create/attach tmux session (auto-named) |
| `ts NAME` | Create/attach tmux session with name |
| `tsp` | Pick tmux session with fzf |
| `tls` | List tmux sessions |
| `tks NAME` | Kill tmux session |
| `tka` | Kill all tmux sessions |
| `th` | Tmux cheatsheet |
| `vh` | Vim cheatsheet |

**Modern CLI (auto-detected):**
| Alias | Actual Command | Fallback |
|-------|----------------|----------|
| `cat` | bat | cat |
| `ls` | eza | ls -G |
| `ll` | eza -la --git | ls -la |
| `tree` | eza --tree | - |
| `lsi` | eza --icons | - (when you want icons) |
| `grep` | rg | grep |
| `find` | fd | find |
| `top` | btop | htop/top |
| `df` | duf | df |
| `diff` | delta | diff |
| `lg` | lazygit | - |
| `ld` | lazydocker | - |

**Kubernetes:**
| Alias | Description |
|-------|-------------|
| `k` | kubectl |
| `kk` | k9s (Kubernetes TUI) |
| `kgp` | kubectl get pods |
| `kgs` | kubectl get svc |
| `kgd` | kubectl get deploy |
| `kctx` | kubectx (switch context) |
| `kns` | kubens (switch namespace) |
| `klog` | stern (multi-pod logs) |

### Vim Keybindings (Leader = Space)

| Key | Action |
|-----|--------|
| `Space + w` | Save |
| `Space + q` | Quit |
| `Space + n` | Toggle line numbers |
| `Space + c` | Copy mode (for mouse select) |
| `Space + C` | Exit copy mode |
| `jk` or `jj` | Exit insert mode |

### Tmux Keybindings (Prefix = Ctrl+b)

| Key | Action |
|-----|--------|
| `Prefix + \|` | Vertical split |
| `Prefix + -` | Horizontal split |
| `Prefix + h/j/k/l` | Navigate panes |
| `Prefix + s` | Session picker |
| `Prefix + w` | Window/session tree |
| `Alt + 1-5` | Switch to window |

## Customization

### Prompt: Starship vs Powerlevel10k

The installer asks you to pick a prompt. Both options give the same layout and Catppuccin colors:
- **Starship** - Uses `configs/starship/starship.toml`. Requires `starship` binary.
- **Powerlevel10k** - Uses `configs/p10k/p10k-starship-style.zsh` (copied to `~/.p10k.zsh`). Install script clones the theme to `~/.zsh/themes/powerlevel10k`. To switch later, re-run `./install.sh` and pick the other option, or edit `~/.config/terminal-fix-prompt` and set `export PROMPT_ENGINE=starship` or `export PROMPT_ENGINE=p10k`, then `source ~/.zshrc`.

### Kubernetes Context Patterns

The config automatically shortens k8s context names. Add your own patterns in:
- `configs/zsh/zshrc` - function `_shorten_k8s_context()`
- `configs/starship/starship.toml` - `[[kubernetes.contexts]]` sections (Starship only)

### Colors

All configs use Catppuccin Macchiato palette. Key colors:
- Background: `#24273a`
- Foreground: `#cad3f5`
- Accent: `#8aadf4` (blue)
- Cursor: `#f5a97f` (peach)

## Troubleshooting

### ESC key not working in vim
1. Check if your physical ESC key works: `cat -v` then press ESC (should show `^[`)
2. Use `Ctrl+[` as alternative (same as ESC)
3. Use `jk` or `jj` to exit insert mode (custom mapping)

### Navigation keys showing tildes
Reload your zshrc: `source ~/.zshrc` or restart terminal

### Tmux sessions have numeric names
Old sessions keep their names. Use `ts` to create new auto-named sessions.

## License

MIT
