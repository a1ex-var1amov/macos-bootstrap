# macOS Bootstrap + Terminal Config

A complete macOS developer bootstrap: one script that goes from a fresh machine to a fully configured, Catppuccin Frappé-themed terminal environment.

## What It Sets Up

| Layer | Tools |
|---|---|
| **Terminal** | Ghostty |
| **Shell** | Zsh + autosuggestions + fast-syntax-highlighting + fzf-tab |
| **Prompt** | Starship (default) or Powerlevel10k — identical look |
| **Multiplexer** | Tmux with Catppuccin Frappé status bar |
| **Editor** | Neovim (lazy.nvim, Catppuccin, Treesitter) + Vim fallback |
| **IDE** | Cursor + VS Code — settings, theme, extensions |
| **History** | atuin — fuzzy search across all sessions, cross-machine sync |
| **Version control** | Git + delta diffs + gh CLI |
| **Containers** | Podman (daemonless, rootless, Docker-compatible) |
| **Kubernetes** | kubectl, k9s, helm, stern, kubectx, kubie, kubecolor |
| **Languages** | Go, Node.js via fnm, Terraform |
| **Modern CLI** | bat, eza, ripgrep, fd, delta, btop, duf, dust, lazygit, lazydocker, and more |

Everything is themed with **Catppuccin Frappé** — terminal, prompt, tmux, delta diffs, Neovim, VS Code, and Cursor all match.

## Quick Start

```bash
git clone https://github.com/a1ex-var1amov/macos-bootstrap.git
cd macos-bootstrap
./install.sh                  # interactive (default)
./install.sh --yes            # non-interactive, all defaults
./install.sh --update         # only refresh config files / themes
./install.sh --update --yes   # silently re-sync after pulling repo changes
```

The installer is fully interactive by default — walks you through each step, asks before installing anything, and backs up existing files with `.bak.TIMESTAMP` suffixes. Use `--update` after `git pull` to quickly redeploy configs without re-running the full setup.

## What the Installer Does

```
 1. Homebrew          — installs if missing
 2. CLI tools         — required + core + modern CLI + history + k8s + languages
 3. GUI apps          — Ghostty, Cursor, VS Code, Podman Desktop, Raycast (Cask)
 4. Default shell     — sets zsh as default (chsh), adds brew zsh to /etc/shells
 5. ~/.zprofile       — brew shellenv so PATH is correct in all shell contexts (incl. tmux panes)
 6. Zsh plugins       — clones fzf-tab
 7. SSH key           — generates ed25519 key, adds to macOS keychain, creates ~/.ssh/config
 8. Git identity      — prompts for name + email if not set
 9. Prompt engine     — Starship or Powerlevel10k (your choice, same look)
10. Directories       — creates all required config dirs
11. Config files      — installs all dotfiles, Cursor/VS Code settings + extensions
12. macOS defaults    — key repeat, tap-to-click, Dock, Finder, screenshots, autocorrect
13. Post-install      — reloads tmux, initialises Podman machine
```

## Tools Installed

### Required
`git` · `zsh` · `tmux`

### Core terminal
`nvim` · `starship` · `fzf` · `zoxide` · `direnv` · `fnm` · `gh`  
`zsh-autosuggestions` · `zsh-fast-syntax-highlighting`

### Modern CLI replacements
| Alias | Replaces | What it does |
|---|---|---|
| `cat` → `bat` | cat | Syntax highlighting, line numbers, git markers |
| `ls`/`ll` → `eza` | ls | Icons, git status, tree view |
| `rm` → `trash` | rm | Sends to macOS Trash (reversible) |
| `rg` | grep | Use directly (10-100x faster, respects .gitignore) |
| `fd` | find | Use directly (faster, friendlier syntax) |
| `diff` → `delta` | diff | Side-by-side, syntax-highlighted diffs |
| `top` → `btop` | top | Beautiful system monitor |
| `df` → `duf` | df | Colourised disk usage |
| `du` → `dust` | du | Intuitive disk usage tree |
| `lg` → `lazygit` | git | Full git TUI |
| `ld` → `lazydocker` | docker | Container TUI (works with Podman) |
| `tldr` | man | Practical command examples |
| `jq` · `yq` | — | JSON/YAML processing |
| `ncdu` | — | Interactive disk space analyser |

`grep` and `find` are intentionally NOT shadowed — their flags differ from `rg`/`fd` and the muscle-memory hit isn't worth it. Use `\rm`, `\cp`, `\mv` to bypass the safety aliases when you really need to.

### History
`atuin` — replaces Ctrl+R with a fuzzy TUI showing timestamps, duration, and exit codes. All tmux panes and plain terminals share one database. Optional cross-machine sync: `atuin register` / `atuin login`.

### Kubernetes
`kubectl` · `kubecolor` · `k9s` · `helm` · `stern` · `kubectx` · `kubie`

| Alias | Description |
|---|---|
| `k` | kubectl |
| `kk` | k9s TUI |
| `kctx` / `kns` | switch context / namespace (kubectx CLI) |
| `kx` | fzf chooser for contexts (preview shows that cluster's namespaces) |
| `kn` | fzf chooser for namespaces (preview shows that namespace's pods) |
| `klog` | stern (multi-pod log tailing) |
| `kgp/kgs/kgd/kgn` | get pods/svc/deploy/nodes |
| `kaf` / `kdf` | apply / delete -f |

### GitHub
`gh` CLI authenticated via `gh auth login`.

| Function | Description |
|---|---|
| `prc` | fzf PR picker -> `gh pr checkout` |
| `prv` | fzf PR picker -> view PR locally |

### Languages
`go` · `terraform`  
`fnm` manages Node.js versions — run `fnm install --lts` after setup. Per-project auto-switching via `.nvmrc` / `.node-version` files.

### GUI apps (Cask)
`Ghostty` · `Cursor` · `Visual Studio Code` · `Podman Desktop` · `Raycast`

## Containers: Podman

Docker-compatible, daemonless, rootless. On a fresh machine, initialise the VM once:

```bash
podman machine init
podman machine start
```

The `docker` and `docker-compose` aliases are wired automatically when Podman is installed. `DOCKER_HOST` points at the Podman socket so `lazydocker` and VS Code DevContainers work without changes.

## History Across All Sessions

atuin stores every command in a local SQLite database. All tmux panes, tmux windows, and plain terminals write to the same database — `Ctrl+R` always searches your full history from anywhere.

To sync history between your work and home laptops:
```bash
atuin register   # first machine
atuin login      # every other machine
```

Up-arrow keeps its default per-session behaviour; only `Ctrl+R` is replaced.

## Git Setup

The installer:
- Sets `init.defaultBranch=main`, `pull.rebase=true`, `push.autoSetupRemote=true`, `fetch.prune=true`
- Configures `delta` for side-by-side diffs with Catppuccin Frappé syntax theme
- Wires `[include] path = ~/.config/git/gitconfig` into `~/.gitconfig` automatically
- Creates `~/.gitignore_global` covering `.DS_Store`, `.env`, editor swap files, `__pycache__`, etc.

Modern git defaults configured:
- `rerere.enabled` (remember conflict resolutions), `rebase.updateRefs` (stacked branches), `rebase.autoSquash`
- `branch.sort = -committerdate` (recent branches first), `tag.sort = version:refname`, `column.ui = auto`
- `commit.verbose = true` (full diff in editor), `diff.algorithm = histogram`, `merge.conflictstyle = zdiff3`
- `help.autocorrect = prompt` ("did you mean X?" instead of running blindly)

Useful git aliases (via `git <alias>`):

| Alias | Command |
|---|---|
| `s` | `status -sb` |
| `lg` | pretty graph log |
| `ll` | one-line log with author + time |
| `last` | last commit with stats |
| `undo` | `reset HEAD~1 --mixed` |
| `amend` | amend without editing message |
| `branches` | branches sorted by last commit |
| `today` | your commits since midnight |
| `staged` / `ds` | diff of staged changes |
| `pu` | `push -u origin HEAD` |
| `pushf` | safe force-push (`--force-with-lease --force-if-includes`) |
| `wip` / `unwip` | quick wip commit / undo it |
| `aliases` | list all configured aliases |

## Prompt

Both options give the same segments (directory, git branch/status, k8s context, language versions, command duration) with the same Catppuccin Frappé colours:

- **Starship** — cross-shell, fast, uses `configs/starship/starship.toml`
- **Powerlevel10k** — Zsh-only, uses `configs/p10k/p10k-starship-style.zsh`

To switch after install: edit `~/.config/terminal-fix-prompt` and set `PROMPT_ENGINE=starship` or `PROMPT_ENGINE=p10k`, then `source ~/.zshrc`. Or re-run `./install.sh`.

## Tmux

Prefix is `Ctrl+b`.

| Key | Action |
|---|---|
| `Prefix + \|` | Vertical split |
| `Prefix + -` | Horizontal split |
| `Prefix + h/j/k/l` | Navigate panes (vim-style) |
| `Prefix + H/J/K/L` | Resize panes |
| `Alt + ←/→/↑/↓` | Navigate panes (no prefix) |
| `Alt + 1–9` | Switch window (no prefix) |
| `Prefix + e` | Floating terminal popup |
| `Prefix + g` | Lazygit popup |
| `Prefix + f` | fzf session switcher popup |
| `Prefix + m` | Toggle pane zoom |
| `Prefix + y` | Toggle pane sync |
| `Prefix + r` | Reload config |
| `v` (copy mode) | Begin selection |
| `y` (copy mode) | Copy to macOS clipboard |

**Smart session management** (all safe to call from inside tmux — use switch-client):

```bash
ts             # create/attach session named after current dir + k8s context
ts NAME        # create/attach named session
tsp            # fzf session picker
tsk CLUSTER    # session with isolated KUBECONFIG=~/.kube/<cluster>.yaml
tad            # attach + detach other clients (steal session)
tls            # list sessions
tks NAME       # kill session
tka            # kill ALL sessions (asks for confirmation)
```

For viewing two clusters side-by-side: open two Ghostty splits (`Cmd+D`), run `tsk cluster-a` in one and `tsk cluster-b` in the other. Or use `Prefix + P` inside tmux to peek at another session in a popup.

### Tmux theme tokens

Each theme file is just 11 color tokens (`@bg`, `@accent`, etc.) — see `configs/tmux/themes/catppuccin-frappe.conf` for the template. The status bar, pane borders, and popup colors all live once in `tmux.conf` and read these tokens, so a new theme is a 12-line file.

### Tmux mouse mode (chosen at install time)

The installer asks whether you want tmux to intercept the mouse at all. The choice is saved to `~/.config/terminal-tmux-mouse` and preserved across `--update` runs.

| Mode | What tmux does | What Ghostty does |
|---|---|---|
| **on** (default) | Click panes to focus, drag borders to resize, wheel scrolls tmux's full history, right-click opens tmux's context menu, OSC 52 clipboard passthrough | Selection only works while holding `⌥ Option` |
| **off** ("normal terminal") | Nothing — tmux ignores the mouse | Owns selection, scroll, right-click — feels like a plain Ghostty window |

Either way, keyboard copy still works (`Prefix + [` → `v` → `y`). To flip later without re-running the installer:

```bash
cp ~/.config/tmux/extras/mouse-off.conf ~/.config/tmux-mouse.conf
tmux source ~/.tmux.conf
```

### Neovim plugins

Beyond LSP + treesitter + cmp, the `nvim` config ships with:
- **Telescope** — fuzzy files/grep/buffers/symbols/diagnostics (`<leader>f*`)
- **gitsigns** — git status in the gutter, hunk staging/preview (`<leader>h*`)
- **which-key** — popup guide for any leader chain after a delay
- **mini.pairs / mini.comment / mini.surround** — autopairs, `gcc`, `sa`/`sd`/`sr`
- **oil.nvim** — edit your filesystem like a buffer (`-` opens parent dir)
- **editorconfig** — respects `.editorconfig` files in projects

## Kubernetes Context Shortening

`_shorten_k8s_context()` in `.zshrc` normalises long context strings for the terminal title and tmux status bar. Built-in patterns cover AWS EKS ARNs, GKE, OpenShift API URLs, kubeadm, and Docker Desktop.

To add your own cluster naming patterns, edit the placeholder section in `configs/zsh/zshrc`:

```zsh
# ── Add your organisation-specific patterns below ──
# if [[ "$ctx" =~ ^my-company-([a-zA-Z0-9-]+)$ ]]; then echo "${match[1]}"; return; fi
```

## Local Overrides

Machine-specific config that you don't want in this repo (cluster aliases, work tokens, etc.) goes in `~/.zshrc.local` — it's sourced automatically at the end of `.zshrc` if it exists, and is never tracked.

## Repo Structure

```
.
├── install.sh
├── configs/
│   ├── ghostty/config          → ~/.config/ghostty/config
│   ├── zsh/zshrc               → ~/.zshrc
│   ├── starship/starship.toml  → ~/.config/starship.toml
│   ├── p10k/p10k-starship-style.zsh → ~/.p10k.zsh
│   ├── vim/vimrc               → ~/.vimrc
│   ├── nvim/init.lua           → ~/.config/nvim/init.lua
│   ├── tmux/tmux.conf          → ~/.tmux.conf
│   ├── git/
│   │   ├── gitconfig           → ~/.config/git/gitconfig (included via ~/.gitconfig)
│   │   └── gitignore_global    → ~/.gitignore_global
│   ├── cursor/settings.json    → ~/Library/Application Support/Cursor/User/settings.json
│   └── vscode/settings.json    → ~/Library/Application Support/Code/User/settings.json
└── cheatsheets/
    ├── tmux-cheatsheet.txt     → ~/.config/tmux-cheatsheet.txt  (alias: th)
    └── vim-cheatsheet.txt      → ~/.config/vim-cheatsheet.txt   (alias: vh)
```

## Troubleshooting

**ESC not working in Vim inside tmux**  
Set `set -s escape-time 0` in `tmux.conf` — already set. If still slow, check `$TERM`.

**Plugins not loading (autosuggestions, syntax highlighting)**  
Run `brew list zsh-autosuggestions zsh-fast-syntax-highlighting` to confirm they're installed. The zshrc resolves the Homebrew prefix automatically for both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`).

**Podman socket not found (lazydocker shows error)**  
Make sure the machine is running: `podman machine start`. The socket path is `~/.local/share/containers/podman/machine/qemu/podman.sock`.

**`brew` not found in tmux panes**  
The installer creates `~/.zprofile` with `brew shellenv` and makes `~/.zshrc` source it. If you set up manually, add to `~/.zprofile`:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**atuin not picking up old history**  
Import existing zsh history once: `atuin import zsh`

## License

MIT
