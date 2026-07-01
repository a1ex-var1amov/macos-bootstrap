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

Pairs-only menu (15 pairs) — every pair auto-switches with macOS appearance in Ghostty/tmux/nvim/Cursor/VS Code/Slack/bat/delta:

| # | Pair | Dark | Light |
|---|------|------|-------|
| 1  | Catppuccin                 | Mocha     | Latte      |
| 2  | Catppuccin Macchiato       | Macchiato | Latte      |
| 3  | Catppuccin Frappé          | Frappé    | Latte      |
| 4  | Tokyo Night                | Night     | Day        |
| 5  | Tokyo Night Storm          | Storm     | Day        |
| 6  | Tokyo Night Moon           | Moon      | Day        |
| 7  | Rosé Pine                  | Main      | Dawn       |
| 8  | Rosé Pine Moon             | Moon      | Dawn       |
| 9  | Dracula                    | Dracula   | Alucard    |
| 10 | Solarized                  | Dark      | Light      |
| 11 | Gruvbox                    | Dark      | Light      |
| 12 | Everforest                 | Dark      | Light      |
| 13 | Kanagawa                   | Wave      | Lotus      |
| 14 | GitHub                     | Dark      | Light      |
| 15 | Nord                       | Nord      | Nord Light |

Single-theme mode no longer exists — the menu now produces `THEME_DARK` + `THEME_LIGHT` for every choice, and `VSCODE_AUTO_DETECT` is always `true`. The `--theme=<n|key>` install.sh flag lets callers pre-select a pair non-interactively. It accepts either the menu number (1–15) or a name (`catppuccin`, `gruvbox`, etc. — full list in `--help`).

**Single source of truth for theme mappings**: `lib/theme-lib.sh`. All the pair/key/label/vscode-metadata tables live there and are consumed by both `install.sh` (which sources it at the top) and `bin/theme-switch` (the fast standalone changer). Adding a new pair means editing `lib/theme-lib.sh` (bump `theme_choice_to_pair`, `theme_key_to_choice`, `theme_choice_label`, `vscode_theme_meta`, and `THEME_LIB_MAX_CHOICE`) plus dropping three theme files (`configs/{ghostty,tmux,nvim}/themes/`). `tests/check.sh` validates the constant matches the highest case number in `theme_choice_to_pair`.

Theme files live in `configs/{ghostty,tmux,nvim}/themes/`. The installer (section 10, choices 1–15) asks which scheme to use and writes:
- `~/.config/ghostty/themes/` + `theme = dark:X,light:Y` line in `~/.config/ghostty/config`
- `~/.config/tmux-theme.conf` (sourced at end of `~/.tmux.conf`)
- `~/.config/nvim/lua/active_theme.lua` + `~/.config/nvim/lua/theme_base.lua`
- `~/.config/terminal-color-theme` and `~/.config/terminal-theme-pair` (persist choice across reinstalls)

**Switching without reinstalling — `theme-switch`**: `bin/theme-switch` is a standalone script that sources `lib/theme-lib.sh` and only touches theme-related files. `install.sh` symlinks it into `~/.local/bin/theme-switch` (which is already on PATH via `zshrc`). Typical runtime <1s. Usage:
```bash
theme-switch                  # interactive menu (shows current pair)
theme-switch 11               # non-interactive; menu-number or key
theme-switch gruvbox          # same, by name (legacy single-theme keys too)
theme-switch --list           # print all pairs
theme-switch --current        # print the active pair
```
Skip-work fast path: if the requested pair equals the current one, `theme-switch` exits immediately without rewriting any file. Cursor / VS Code still need a "Developer: Reload Window" to pick up the new theme; every other layer (Ghostty, tmux, nvim, bat, delta) live-reloads.

**Extension installs happen on every real switch, not just the first `install.sh` run**: rendering `settings.json` with a theme name whose extension was never installed doesn't error anywhere — Cursor/VS Code just silently keep showing whatever theme was already active, which looks exactly like "the switch didn't work" (this was a real bug: 4 of the 15 pairs appeared broken because their extensions were only ever installed for whichever pair `install.sh` happened to be run with). Both `install.sh` and `theme-switch` now call `ensure_vscode_extensions` (in `lib/theme-lib.sh`) for the pair's dark/light `VS_EXT` ids, which checks `--list-extensions` first (fast, offline) so already-seen pairs stay instant — only a genuinely new pair touches the network. Every `cursor`/`code` CLI call inside it is wrapped in `_run_with_timeout` (a portable polling-based timeout, since macOS ships neither `timeout` nor bash 4.3's `wait -n`) so a hung editor CLI can never wedge the whole script.

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
| `configs/cursor/settings-base.json` | `~/Library/Application Support/Cursor/User/settings.json` (rendered through `render_vscode_settings` in `lib/theme-lib.sh`) |
| `configs/vscode/settings-base.json` | `~/Library/Application Support/Code/User/settings.json` (rendered through `render_vscode_settings` in `lib/theme-lib.sh`) |
| `configs/ghostty/config-base` | `~/.config/ghostty/config` (theme line substituted by `render_ghostty_config` in `lib/theme-lib.sh`); plus a one-line `config-file = ~/.config/ghostty/config` shim written to `~/Library/Application Support/com.mitchellh.ghostty/config` so the macOS app-bundle path can't shadow our XDG config |
| `configs/ssh/config-base` | `~/.ssh/config` (only if absent) |
| `configs/tmux/extras/mouse-{on,off}.conf` | `~/.config/tmux/extras/` (one of them copied to `~/.config/tmux-mouse.conf`) |
| `cheatsheets/*.txt` | `~/.config/*.txt` |
| `bin/theme-switch` | Symlinked into `~/.local/bin/theme-switch` for fast standalone theme swaps (no re-install) |
| `lib/theme-lib.sh` | Not installed — sourced in-repo by both `install.sh` and `bin/theme-switch` at runtime (single source of truth for theme tables) |

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

### Cursor / VS Code dark-light autoDetect
When install.sh writes Cursor or VS Code settings, it substitutes six placeholders into `configs/{cursor,vscode}/settings-base.json`:

- `__VSCODE_COLOR_THEME__` / `__VSCODE_ICON_THEME__` / `__VSCODE_BORDER_COLOR__` — single-theme values
- `__VSCODE_DARK_THEME__` / `__VSCODE_LIGHT_THEME__` — pair endpoints
- `__VSCODE_AUTO_DETECT__` — literal `true` or `false` (note: unquoted, since it's a JSON boolean)

When a PAIR is chosen (`THEME_DARK` and `THEME_LIGHT` are set), `__VSCODE_AUTO_DETECT__` becomes `true` and the IDE follows macOS appearance via `window.autoDetectColorScheme` + `preferred{Dark,Light}ColorTheme`. When a single theme is chosen, all three placeholders point at it and autoDetect is `false`.

The `_vscode_theme_meta()` helper in install.sh maps a theme key (e.g. `catppuccin-mocha`) to `VS_NAME`/`VS_ICON`/`VS_EXT`/`VS_BORDER`/`VS_SLACK`. When adding a new theme, extend this single function — both the primary-theme path and both ends of any pair will pick it up automatically.

`tests/check.sh` scans the rendered placeholder set in both settings-base.json files and asserts each has a matching `sed -e "s|__NAME__|..."` line in install.sh, so new placeholders can't be added without their substitution.

### Tmux Mouse Mode (`~/.config/tmux-mouse.conf`)
`tmux.conf` does NOT hardcode `set -g mouse on` / `set -g set-clipboard on`. Instead it sources `~/.config/tmux-mouse.conf`, which install.sh writes from one of two bundled snippets:
- `configs/tmux/extras/mouse-on.conf` — full tmux mouse UX (click, scroll, drag-resize, context menu, OSC 52 clipboard, mouse forwarded to vim/fzf)
- `configs/tmux/extras/mouse-off.conf` — **scroll-only hybrid**: tmux still has `mouse on` but binds ONLY the wheel; every other mouse binding is explicitly `unbind -n`'d. Click / drag / right-click become tmux no-ops; native Ghostty selection requires holding `⌥ Option`.

The chosen mode is persisted to `~/.config/terminal-tmux-mouse` (contents: `on` or `off`) so `--update` runs don't re-prompt. To flip manually:
```bash
cp ~/.config/tmux/extras/mouse-{off,on}.conf ~/.config/tmux-mouse.conf
tmux source ~/.tmux.conf
```

**Important design note**: there's intentionally NO "truly mouse off" config. Tmux always uses Ghostty's alternate screen, and Ghostty's xterm emulation translates wheel events on the alternate screen into Up/Down arrow keys — which zsh interprets as command-history navigation. So a `set -g mouse off` config breaks wheel-scrolling in a way users don't expect. The scroll-only hybrid in `mouse-off.conf` is the smallest possible footprint that still gives natural wheel scrolling.

When adding mouse-related bindings, put them in the corresponding `mouse-*.conf` file, not in `tmux.conf`. New unbinds should usually go in BOTH (e.g. if you stop wanting `MouseDown3Pane` to do anything, unbind it in both `mouse-on.conf` and `mouse-off.conf`).

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
All modern CLI replacements (`bat`, `eza`, `rg`, `fd`, `btop`, `duf`, `delta`, `yazi`, `procs`, `gh-dash`, etc.) use `(( $+commands[tool] ))` guards so the config degrades gracefully when tools are missing.

### FZF defaults
`FZF_DEFAULT_OPTS` is exported once near the top of `zshrc` so every fzf invocation (Ctrl+R, Ctrl+T, Alt+C, `kx`, `kn`, `prc`, fzf-tab, tmux popups) gets the same height/layout/border/preview-toggle keybinds. Per-call `--preview-window` overrides still win. Ctrl+T uses `bat` for previews when available; Alt+C uses `eza --tree`.

### Tmux universal bindings (keyboard, both mouse modes)
Added in `tmux.conf` so they're always available:
- `Prefix + V` — paste macOS clipboard (`pbpaste | load-buffer - && paste-buffer`)
- `Prefix + W` — `capture-pane -p -S -` into `~/tmux-<sess>-w<idx>p<idx>-<ts>.log`
- `Prefix + T` — `command-prompt -p "pane title:" "select-pane -T '%%'"`
- A commented `pane-border-status top` recipe near `Prefix + T` so users can opt into visible pane titles.

### Tmux mouse-on extras
`mouse-on.conf` adds, on top of the basics:
- `DoubleClick1Pane` / `TripleClick1Pane` — select word/line, copy to pbcopy. Both guard on `pane_in_mode` / `mouse_any_flag` so vim/fzf/htop still see their own mouse events.
- `MouseDown1StatusLeft` — fzf session-switcher popup (mouse-accessible mirror of `Prefix + f`).

### Clock-mode colour resolution
`clock-mode-colour` is a raw-colour option in tmux — it does NOT expand `#{@token}` format strings. After sourcing the theme file, `tmux.conf` runs a one-liner `run-shell` that reads `#{@accent}` via `display-message -p` and feeds the literal hex into `set -g clock-mode-colour`. Do NOT add `set -g clock-mode-colour "#{@accent}"` back — it throws `bad colour: #{@accent}` on every reload.

### Ghostty config precedence on macOS
Ghostty looks for config in two places on macOS:
1. `~/.config/ghostty/config` (XDG path — what `install.sh` writes)
2. `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS-conventional path — auto-created by Ghostty on first launch if no config exists)

The AppSupport file can shadow our XDG config and silently strip the `theme = …` directive (because the auto-template doesn't include one). To prevent surprises, `install.sh` writes a one-line `config-file = ~/.config/ghostty/config` shim into the AppSupport path so it always defers to our managed config. The check is idempotent (skipped when the line is already there) and backs up any prior content. Symptoms of forgetting this: Ghostty on macOS uses its default palette regardless of which theme is set in `~/.config/ghostty/config`, and the dark/light pair never swaps with macOS appearance.

When changing how the Ghostty config is rendered, update BOTH the XDG render block (`sed … > ~/.config/ghostty/config`) and verify the AppSupport shim is still a single `config-file =` line. The AppSupport shim must NOT contain anything else — extra keys there override XDG.

### Cursor / VS Code light theme overrides for "no real light variant" cases
Two theme pairs need a special-case override on the IDE side because their extension's "light" variant isn't actually a `vs`/`hc-light` theme — `autoDetectColorScheme` silently no-ops when `preferredLightColorTheme` points at a `vs-dark` theme.
- **Dracula** (option 9, `THEME_LIGHT=dracula-alucard`) — the Dracula extension's "Dracula Theme Soft" is `vs-dark`. `install.sh` substitutes `rose-pine-dawn` on the IDE side only (tmux/nvim/Ghostty keep using `dracula-alucard`, which all three have real light recipes for).
- **Nord** (option 15, `THEME_LIGHT=nord-light`) — the official `arcticicestudio.nord-visual-studio-code` extension only ships the Nord (dark) theme. `_vscode_theme_meta nord-light` therefore maps to Cursor's built-in **"Default Light Modern"** (always available, no extension required). Tmux/nvim/Ghostty have a real Snow-Storm light palette under `nord-light`.

When adding a new theme pair, verify the light side has `uiTheme: vs` or `hc-light` in its extension's `package.json` — otherwise apply the same override pattern (substitute a real light theme in `_vscode_theme_meta` for the light key, OR add an `if [[ "$THEME_LIGHT" == "..." ]]` block right after `_vscode_theme_meta "$THEME_LIGHT"`).

**Verify the `VS_EXT` id is actually installable in Cursor before shipping it.** Cursor's extension marketplace is Open VSX-backed, not the full Microsoft VS Code Marketplace — an id that's correct for stock VS Code can still 404 in Cursor (`cursor --install-extension <id>` prints `Extension '<id>' not found`). This bit Kanagawa: `qufiwefefwoyn.kanagawa` is what kanagawa.nvim's own docs point to, and it installs fine in VS Code, but it doesn't exist in Cursor's registry at all *and* only ships a single dark theme (no Lotus/light variant) even where it does exist. `metaphore.kanagawa-vscode-color-theme` is the correct id — it ships all three flavours (Wave/Dragon/Lotus) and installs on both editors. Sanity-check any new `VS_EXT` with `cursor --install-extension <id>` (and `code --install-extension <id>` if you use stock VS Code too) before wiring it into `vscode_theme_meta`; `tests/check.sh`'s "Theme extensions actually installed" section will also flag it once it's rendered somewhere and the extension is missing locally.

### Optional tmux session persistence
A commented TPM + tmux-resurrect + tmux-continuum block lives near the bottom of `tmux.conf` (after the theme source-file). Users opt in by uncommenting and running the TPM clone one-liner from the README. Default ships disabled to keep tmux's startup zero-dependency.

### Terminal Title
Title is set via `zle-line-init` (fires just before each prompt) and `preexec` hook (shows running command). Format: `folder | k8s-context`. Inside tmux, uses pass-through escape sequences to update both the tmux window name and the outer terminal (Ghostty).
