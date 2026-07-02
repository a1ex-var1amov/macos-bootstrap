# shellcheck shell=bash
# shellcheck disable=SC2034
#   ^ SC2034 flags "variable set but never used in this file" — most of the
#     globals below are consumed by *callers* (install.sh, bin/theme-switch)
#     after sourcing. Silence it once at file scope to keep the API surface
#     documented in-place.
#
# Shared theme-resolution + rendering helpers.
#
# Sourced by:
#   install.sh        (during first install / --update runs)
#   bin/theme-switch  (the fast standalone theme changer)
#
# Design goals:
#   - Single source of truth for the theme mapping tables. Adding a new pair
#     is one edit to *this* file plus dropping in three theme files
#     (ghostty/tmux/nvim). install.sh and theme-switch pick it up for free.
#   - No side effects at source time — every function is opt-in.
#   - No hard dependencies on install.sh's ambient state (colors, spinners).
#     Callers wire in their own logging via print_status / print_success or
#     just plain `echo`; the lib doesn't care.
#
# Contract:
#   Callers must set THEME_LIB_REPO to the repo root before invoking any
#   render_* / apply_* helper (used to locate configs/*/themes and *-base
#   template files).

if [[ -z "${THEME_LIB_REPO:-}" ]]; then
    # Default: assume this file lives at $REPO/lib/theme-lib.sh
    THEME_LIB_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# ── Resolution helpers ──────────────────────────────────────────────────────

# theme_choice_to_pair <choice-num> → sets $THEME_DARK / $THEME_LIGHT.
theme_choice_to_pair() {
    case "$1" in
        1)  THEME_DARK=catppuccin-mocha     ; THEME_LIGHT=catppuccin-latte    ;;
        2)  THEME_DARK=catppuccin-macchiato ; THEME_LIGHT=catppuccin-latte    ;;
        3)  THEME_DARK=catppuccin-frappe    ; THEME_LIGHT=catppuccin-latte    ;;
        4)  THEME_DARK=tokyo-night          ; THEME_LIGHT=tokyo-night-day     ;;
        5)  THEME_DARK=tokyo-night-storm    ; THEME_LIGHT=tokyo-night-day     ;;
        6)  THEME_DARK=tokyo-night-moon     ; THEME_LIGHT=tokyo-night-day     ;;
        7)  THEME_DARK=rose-pine            ; THEME_LIGHT=rose-pine-dawn      ;;
        8)  THEME_DARK=rose-pine-moon       ; THEME_LIGHT=rose-pine-dawn      ;;
        9)  THEME_DARK=dracula              ; THEME_LIGHT=dracula-alucard     ;;
        10) THEME_DARK=solarized-dark       ; THEME_LIGHT=solarized-light     ;;
        11) THEME_DARK=gruvbox-dark         ; THEME_LIGHT=gruvbox-light       ;;
        12) THEME_DARK=everforest-dark      ; THEME_LIGHT=everforest-light    ;;
        13) THEME_DARK=kanagawa-wave        ; THEME_LIGHT=kanagawa-lotus      ;;
        14) THEME_DARK=github-dark          ; THEME_LIGHT=github-light        ;;
        15) THEME_DARK=nord                 ; THEME_LIGHT=nord-light          ;;
        *)  THEME_DARK=catppuccin-mocha     ; THEME_LIGHT=catppuccin-latte    ;;
    esac
}

# theme_key_to_choice <n|key> → echoes the menu number (1-15) for a key.
# Accepts numeric input directly (1-15), any theme name (mocha, latte, night,
# day, etc.), or a legacy single-theme key (auto-mapped to its closest pair).
theme_key_to_choice() {
    case "$1" in
        1|catppuccin|catppuccin-mocha|catppuccin-latte)              echo 1  ;;
        2|catppuccin-macchiato)                                      echo 2  ;;
        3|catppuccin-frappe)                                         echo 3  ;;
        4|tokyo-night|tokyo-night-day)                               echo 4  ;;
        5|tokyo-night-storm)                                         echo 5  ;;
        6|tokyo-night-moon)                                          echo 6  ;;
        7|rose-pine|rose-pine-dawn)                                  echo 7  ;;
        8|rose-pine-moon)                                            echo 8  ;;
        9|dracula|dracula-alucard)                                   echo 9  ;;
        10|solarized|solarized-dark|solarized-light)                 echo 10 ;;
        11|gruvbox|gruvbox-dark|gruvbox-light)                       echo 11 ;;
        12|everforest|everforest-dark|everforest-light)              echo 12 ;;
        13|kanagawa|kanagawa-wave|kanagawa-lotus)                    echo 13 ;;
        14|github|github-dark|github-light)                          echo 14 ;;
        15|nord|nord-light)                                          echo 15 ;;
        *)                                                           echo 1  ;;
    esac
}

# theme_choice_label <choice-num> → echoes a short human-readable label
# like "Catppuccin (Mocha ↔ Latte)". Used by menu printers.
theme_choice_label() {
    case "$1" in
        1)  echo "Catppuccin              (Mocha     ↔ Latte)"       ;;
        2)  echo "Catppuccin Macchiato    (Macchiato ↔ Latte)"       ;;
        3)  echo "Catppuccin Frappé       (Frappé    ↔ Latte)"       ;;
        4)  echo "Tokyo Night             (Night     ↔ Day)"         ;;
        5)  echo "Tokyo Night Storm       (Storm     ↔ Day)"         ;;
        6)  echo "Tokyo Night Moon        (Moon      ↔ Day)"         ;;
        7)  echo "Rosé Pine               (Main      ↔ Dawn)"        ;;
        8)  echo "Rosé Pine Moon          (Moon      ↔ Dawn)"        ;;
        9)  echo "Dracula                 (Dracula   ↔ Alucard)"     ;;
        10) echo "Solarized               (Dark      ↔ Light)"       ;;
        11) echo "Gruvbox                 (Dark      ↔ Light)"       ;;
        12) echo "Everforest              (Dark      ↔ Light)"       ;;
        13) echo "Kanagawa                (Wave      ↔ Lotus)"       ;;
        14) echo "GitHub                  (Dark      ↔ Light)"       ;;
        15) echo "Nord                    (Nord      ↔ Nord Light)"  ;;
        *)  echo "???"                                                ;;
    esac
}

# THEME_LIB_MAX_CHOICE — set once, referenced everywhere that ranges over pairs
# (menu loop, "Pick [1-N]" hint, --help text). Bump when adding pairs.
THEME_LIB_MAX_CHOICE=15

# ── VS Code / Cursor metadata ───────────────────────────────────────────────

# vscode_theme_meta <theme-key> → sets the following globals as side-effects:
#   VS_NAME    — Cursor/VS Code theme name (matches an extension's package.json)
#   VS_ICON    — icon theme id (Catppuccin icons)
#   VS_EXT     — extension id to install (empty string = built-in theme)
#   VS_BORDER  — hex color for editorGroup / panel / sidebar / tab / terminal
#                borders in workbench.colorCustomizations
#   VS_SLACK   — 8 comma-separated hex colors for Slack's theme import
#
# Design note: intentionally avoids bash 4+ associative arrays because macOS
# still ships bash 3.2 by default (Apple licensing) and install.sh is bash-portable.
vscode_theme_meta() {
    case "$1" in
      catppuccin-frappe)
        VS_NAME="Catppuccin Frappé"; VS_ICON="catppuccin-frappe"; VS_EXT=""
        VS_BORDER="#51576d"
        VS_SLACK="#303446,#292c3c,#8caaee,#303446,#414559,#c6d0f5,#a6d189,#e78284" ;;
      catppuccin-macchiato)
        VS_NAME="Catppuccin Macchiato"; VS_ICON="catppuccin-macchiato"; VS_EXT=""
        VS_BORDER="#5b6078"
        VS_SLACK="#24273a,#1e2030,#8aadf4,#24273a,#363a4f,#cad3f5,#a6da95,#ed8796" ;;
      catppuccin-mocha)
        VS_NAME="Catppuccin Mocha"; VS_ICON="catppuccin-mocha"; VS_EXT=""
        VS_BORDER="#585b70"
        VS_SLACK="#1e1e2e,#181825,#89b4fa,#1e1e2e,#313244,#cdd6f4,#a6e3a1,#f38ba8" ;;
      catppuccin-latte)
        VS_NAME="Catppuccin Latte"; VS_ICON="catppuccin-latte"; VS_EXT=""
        VS_BORDER="#9ca0b0"
        VS_SLACK="#eff1f5,#e6e9ef,#1e66f5,#eff1f5,#ccd0da,#4c4f69,#40a02b,#d20f39" ;;
      tokyo-night)
        VS_NAME="Tokyo Night"; VS_ICON="catppuccin-mocha"; VS_EXT="enkia.tokyo-night"
        VS_BORDER="#414868"
        VS_SLACK="#1a1b26,#16161e,#7aa2f7,#c0caf5,#24283b,#c0caf5,#9ece6a,#f7768e" ;;
      tokyo-night-storm)
        VS_NAME="Tokyo Night Storm"; VS_ICON="catppuccin-mocha"; VS_EXT="enkia.tokyo-night"
        VS_BORDER="#3b4261"
        VS_SLACK="#24283b,#1f2335,#7aa2f7,#c0caf5,#292e42,#c0caf5,#9ece6a,#f7768e" ;;
      tokyo-night-moon)
        VS_NAME="Tokyo Night"; VS_ICON="catppuccin-mocha"; VS_EXT="enkia.tokyo-night"
        VS_BORDER="#444a73"
        VS_SLACK="#222436,#1e2030,#82aaff,#c8d3f5,#2d3f51,#c8d3f5,#c3e88d,#ff757f" ;;
      tokyo-night-day)
        VS_NAME="Tokyo Night Light"; VS_ICON="catppuccin-latte"; VS_EXT="enkia.tokyo-night"
        VS_BORDER="#a1a6c5"
        VS_SLACK="#e1e2e7,#d5d6db,#2e7de9,#e1e2e7,#b6bfe2,#3760bf,#587539,#f52a65" ;;
      rose-pine)
        VS_NAME="Rosé Pine"; VS_ICON="catppuccin-mocha"; VS_EXT="mvllow.rose-pine"
        VS_BORDER="#403d52"
        VS_SLACK="#191724,#16141f,#9ccfd8,#191724,#26233a,#e0def4,#31748f,#eb6f92" ;;
      rose-pine-moon)
        VS_NAME="Rosé Pine Moon"; VS_ICON="catppuccin-mocha"; VS_EXT="mvllow.rose-pine"
        VS_BORDER="#44415a"
        VS_SLACK="#232136,#1f1d2e,#9ccfd8,#232136,#393552,#e0def4,#3e8fb0,#eb6f92" ;;
      rose-pine-dawn)
        VS_NAME="Rosé Pine Dawn"; VS_ICON="catppuccin-latte"; VS_EXT="mvllow.rose-pine"
        VS_BORDER="#dfdad9"
        VS_SLACK="#faf4ed,#fffaf3,#286983,#faf4ed,#dfdad9,#575279,#56949f,#b4637a" ;;
      dracula)
        VS_NAME="Dracula Theme"; VS_ICON="catppuccin-mocha"; VS_EXT="dracula-theme.theme-dracula"
        VS_BORDER="#44475a"
        VS_SLACK="#282a36,#21222c,#bd93f9,#282a36,#44475a,#f8f8f2,#50fa7b,#ff5555" ;;
      dracula-alucard)
        VS_NAME="Dracula Theme Soft"; VS_ICON="catppuccin-latte"; VS_EXT="dracula-theme.theme-dracula"
        VS_BORDER="#cfcfde"
        VS_SLACK="#fffbeb,#f0ead8,#644ac9,#fffbeb,#cfcfde,#1f1f1f,#14710a,#cb3a2a" ;;
      solarized-dark)
        VS_NAME="Solarized Dark"; VS_ICON="catppuccin-mocha"; VS_EXT=""
        VS_BORDER="#073642"
        VS_SLACK="#002b36,#073642,#268bd2,#002b36,#586e75,#93a1a1,#859900,#dc322f" ;;
      solarized-light)
        VS_NAME="Solarized Light"; VS_ICON="catppuccin-latte"; VS_EXT=""
        VS_BORDER="#eee8d5"
        VS_SLACK="#fdf6e3,#eee8d5,#268bd2,#fdf6e3,#93a1a1,#586e75,#859900,#dc322f" ;;
      gruvbox-dark)
        VS_NAME="Gruvbox Dark Medium"; VS_ICON="catppuccin-mocha"; VS_EXT="jdinhlife.gruvbox"
        VS_BORDER="#3c3836"
        VS_SLACK="#282828,#3c3836,#fabd2f,#282828,#504945,#ebdbb2,#b8bb26,#fb4934" ;;
      gruvbox-light)
        VS_NAME="Gruvbox Light Medium"; VS_ICON="catppuccin-latte"; VS_EXT="jdinhlife.gruvbox"
        VS_BORDER="#ebdbb2"
        VS_SLACK="#fbf1c7,#ebdbb2,#b57614,#fbf1c7,#d5c4a1,#3c3836,#79740e,#9d0006" ;;
      everforest-dark)
        VS_NAME="Everforest Dark"; VS_ICON="catppuccin-mocha"; VS_EXT="sainnhe.everforest"
        VS_BORDER="#343f44"
        VS_SLACK="#2d353b,#343f44,#a7c080,#2d353b,#475258,#d3c6aa,#a7c080,#e67e80" ;;
      everforest-light)
        VS_NAME="Everforest Light"; VS_ICON="catppuccin-latte"; VS_EXT="sainnhe.everforest"
        VS_BORDER="#f4f0d9"
        VS_SLACK="#fdf6e3,#f4f0d9,#8da101,#fdf6e3,#e0dcc7,#5c6a72,#8da101,#f85552" ;;
      kanagawa-wave)
        # NOTE: qufiwefefwoyn.kanagawa (the extension name kanagawa.nvim's own
        # docs point to) is dark-only AND unavailable through Cursor's Open
        # VSX-backed marketplace ("not found" on install). metaphore's port
        # ships all three flavours (Wave/Dragon/Lotus) and installs fine on
        # both Cursor and stock VS Code — use that instead.
        VS_NAME="Kanagawa Wave"; VS_ICON="catppuccin-mocha"; VS_EXT="metaphore.kanagawa-vscode-color-theme"
        VS_BORDER="#2a2a37"
        VS_SLACK="#1f1f28,#2a2a37,#7e9cd8,#1f1f28,#363646,#dcd7ba,#98bb6c,#c34043" ;;
      kanagawa-lotus)
        VS_NAME="Kanagawa Lotus"; VS_ICON="catppuccin-latte"; VS_EXT="metaphore.kanagawa-vscode-color-theme"
        VS_BORDER="#e5dec7"
        VS_SLACK="#f2ecbc,#e5dec7,#4d699b,#f2ecbc,#d0c8a4,#545464,#6f894e,#c84053" ;;
      github-dark)
        VS_NAME="GitHub Dark Default"; VS_ICON="catppuccin-mocha"; VS_EXT="GitHub.github-vscode-theme"
        VS_BORDER="#30363d"
        VS_SLACK="#0d1117,#161b22,#58a6ff,#0d1117,#30363d,#c9d1d9,#3fb950,#ff7b72" ;;
      github-light)
        VS_NAME="GitHub Light Default"; VS_ICON="catppuccin-latte"; VS_EXT="GitHub.github-vscode-theme"
        VS_BORDER="#d0d7de"
        VS_SLACK="#ffffff,#f6f8fa,#0969da,#ffffff,#d0d7de,#24292f,#1a7f37,#cf222e" ;;
      nord)
        VS_NAME="Nord"; VS_ICON="catppuccin-mocha"; VS_EXT="arcticicestudio.nord-visual-studio-code"
        VS_BORDER="#3b4252"
        VS_SLACK="#2e3440,#3b4252,#88c0d0,#2e3440,#4c566a,#d8dee9,#a3be8c,#bf616a" ;;
      nord-light)
        # The Nord VS Code extension only ships a vs-dark theme. For the light
        # side of the Nord pair we fall back to Cursor's built-in "Default
        # Light Modern" so autoDetectColorScheme can swap on macOS appearance.
        VS_NAME="Default Light Modern"; VS_ICON="catppuccin-latte"; VS_EXT=""
        VS_BORDER="#e5e9f0"
        VS_SLACK="#eceff4,#e5e9f0,#5e81ac,#eceff4,#d8dee9,#2e3440,#a3be8c,#bf616a" ;;
      *)
        VS_NAME=""; VS_ICON=""; VS_EXT=""; VS_BORDER=""; VS_SLACK="" ;;
    esac
}

# _run_with_timeout <secs> <cmd...> — portable timeout (macOS ships no
# `timeout`/`gtimeout` by default, and its stock bash is 3.2 so `wait -n`
# isn't available either). Runs <cmd> in the background and polls it with
# `kill -0` every 0.1s, killing it if <secs> elapses. </dev/null on the
# command guards against it ever blocking on a stray prompt.
#
# Deliberately avoids a second "watcher" background process (e.g. a
# `(sleep N; kill -9 $pid) &` subshell): killing that watcher early — once
# the real command already finished — can orphan its `sleep` grandchild
# instead of reaping it, and the orphan keeps the shared stdout/stderr pipe
# open, which silently wedges whatever is reading that pipe (a terminal
# capture, a parent script, etc.) for the rest of the original timeout. A
# single tracked PID with polling sidesteps that class of bug entirely.
_run_with_timeout() {
    local secs="$1"; shift
    "$@" </dev/null &
    local pid=$!
    local max_ticks=$(( secs * 10 ))
    local tick=0
    while kill -0 "$pid" 2>/dev/null; do
        if (( tick >= max_ticks )); then
            kill -9 "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
            return 124
        fi
        sleep 0.1
        tick=$(( tick + 1 ))
    done
    wait "$pid" 2>/dev/null
}

# ensure_vscode_extensions <editor-cmd> <ext-id> [ext-id...]
# Installs any of the given (non-empty) extension ids that aren't already
# present, via `<editor-cmd> --install-extension`. No-ops silently if
# <editor-cmd> isn't on PATH. Checks --list-extensions first (fast, offline)
# so the common "already installed" case never touches the network — this
# is what keeps repeat theme-switch calls fast while still letting a
# *first-time* switch to a new pair fetch whatever extension it needs.
# Every editor CLI call is wrapped in _run_with_timeout: the `cursor`/`code`
# launcher scripts can hang indefinitely (e.g. no display server, extension
# host lock contention) instead of failing fast, which would otherwise wedge
# theme-switch/install.sh forever.
# Prints one line per extension actually installed via $ECHO_OK (default:
# echo); failures (timeout, offline, marketplace rejects the id) are
# swallowed since the rendered settings.json is still correct — the theme
# just won't visually apply until the extension shows up some other way.
ensure_vscode_extensions() {
    local cmd="$1"; shift
    command -v "$cmd" >/dev/null 2>&1 || return 0
    local echo_ok="${ECHO_OK:-echo}"
    local installed
    installed="$(_run_with_timeout 15 "$cmd" --list-extensions 2>/dev/null || true)"
    local ext
    for ext in "$@"; do
        [[ -n "$ext" ]] || continue
        if printf '%s\n' "$installed" | command grep -qiFx "$ext"; then
            continue
        fi
        if _run_with_timeout 30 "$cmd" --install-extension "$ext" >/dev/null 2>&1; then
            "$echo_ok" "$cmd: installed $ext"
        fi
    done
}

# ── Rendering helpers ───────────────────────────────────────────────────────

# render_ghostty_config <ghostty-theme-spec> → writes ~/.config/ghostty/config
# from configs/ghostty/config-base with the theme line substituted.
render_ghostty_config() {
    local ghostty_theme="$1"
    sed "s|^theme = .*|theme = $ghostty_theme|" \
        "$THEME_LIB_REPO/configs/ghostty/config-base" > ~/.config/ghostty/config
}

# ensure_ghostty_appsupport_shim → keeps the macOS Application Support config
# path (~/Library/Application Support/com.mitchellh.ghostty/config) mirrored
# with the real ~/.config/ghostty/config, so whichever one(s) Ghostty decides
# to load, the settings — including the theme line — are always identical.
# Idempotent: only writes when the content actually differs.
# Returns 0 always; prints one status line via $ECHO_OK (default: echo) only
# when it actually changed something.
#
# This used to write a one-line redirect (`config-file =
# ~/.config/ghostty/config`) into the AppSupport file instead of duplicating
# content. DON'T go back to that: Ghostty unconditionally auto-loads BOTH the
# XDG config *and* the macOS AppSupport config on every launch (this isn't
# conditional on one being missing — see ghostty-org/ghostty#11323). A
# `config-file` directive inside the AppSupport file that points back at the
# XDG file makes Ghostty visit that XDG file a second time in the same load
# pass ("the default config file is always loaded" per a Ghostty maintainer),
# which trips `cycle detected` even though it isn't a true cycle.
#
# We ALSO strip any `config-file = ...` line (e.g. the `?~/.config/ghostty/
# config.local` include) out of the mirrored copy before writing it. Reason:
# once both XDG config and the AppSupport mirror are separately auto-loaded
# as top-level defaults, if BOTH still contained their own `config-file =
# ...config.local` directive, config.local would be reached via two
# independent parents in the same session — the exact diamond shape behind
# the upstream bug. Only the XDG file (the one source of truth) should ever
# include config.local; the AppSupport mirror carries every literal setting
# except that one directive, so it can't cause a revisit of anything.
ensure_ghostty_appsupport_shim() {
    local shim_path="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    local xdg_path="$HOME/.config/ghostty/config"
    local echo_ok="${ECHO_OK:-echo}"
    [[ -f "$xdg_path" ]] || return 0
    local rendered
    rendered="$(grep -v '^config-file' "$xdg_path")"
    if [[ -f "$shim_path" ]] && [[ "$rendered" == "$(cat "$shim_path")" ]]; then
        return 0
    fi
    mkdir -p "$(dirname "$shim_path")"
    printf '%s\n' "$rendered" > "$shim_path"
    "$echo_ok" "Ghostty AppSupport config synced with ~/.config/ghostty/config"
}

# reload_ghostty_if_running → makes a running Ghostty actually pick up the
# config we just wrote. Ghostty does NOT watch its config files for changes
# (a deliberate upstream "wontfix" — see ghostty-org/ghostty#449); it only
# reloads on the Cmd+Shift+, keybind or on receiving SIGUSR2 (supported since
# ghostty-org/ghostty#7751, ~mid-2025, so any reasonably current install has
# it). Without this, writing a new theme to disk is silently invisible until
# the user manually reloads or restarts — this is the #1 cause of "theme-
# switch says it worked but Ghostty still looks the same".
# Returns 0 if a running Ghostty was signaled, non-zero otherwise (callers
# use this to word their status line); the manual Cmd+Shift+, keybind always
# remains as a fallback regardless.
reload_ghostty_if_running() {
    pkill -SIGUSR2 -x ghostty 2>/dev/null
}

# render_vscode_settings <src-template> <dst-settings.json>
# Substitutes __VSCODE_*__ placeholders. Callers must set:
#   VSCODE_COLOR_THEME, VSCODE_DARK_THEME, VSCODE_LIGHT_THEME,
#   VSCODE_AUTO_DETECT, VSCODE_ICON_THEME, VSCODE_BORDER_COLOR
# before invoking (matching install.sh's naming for continuity).
render_vscode_settings() {
    local src="$1" dst="$2"
    sed \
      -e "s|__VSCODE_COLOR_THEME__|$VSCODE_COLOR_THEME|g" \
      -e "s|__VSCODE_DARK_THEME__|$VSCODE_DARK_THEME|g" \
      -e "s|__VSCODE_LIGHT_THEME__|$VSCODE_LIGHT_THEME|g" \
      -e "s|__VSCODE_AUTO_DETECT__|$VSCODE_AUTO_DETECT|g" \
      -e "s|__VSCODE_ICON_THEME__|$VSCODE_ICON_THEME|g" \
      -e "s|__VSCODE_BORDER_COLOR__|$VSCODE_BORDER_COLOR|g" \
      "$src" > "$dst"
}

# compute_vscode_pair_metadata <theme-dark> <theme-light>
# Populates VSCODE_* globals from a pair. Applies the dracula-alucard IDE
# override transparently (Rosé Pine Dawn is used as the light side because
# Dracula Theme Soft is still uiTheme=vs-dark → autoDetect no-ops).
compute_vscode_pair_metadata() {
    local dark="$1" light="$2"
    vscode_theme_meta "$dark"
    VSCODE_DARK_THEME="$VS_NAME"
    VSCODE_DARK_EXT="$VS_EXT"
    VSCODE_COLOR_THEME="$VS_NAME"
    VSCODE_ICON_THEME="$VS_ICON"
    VSCODE_BORDER_COLOR="$VS_BORDER"
    VSCODE_THEME_EXT="$VS_EXT"
    SLACK_THEME_DARK="$VS_SLACK"

    vscode_theme_meta "$light"
    VSCODE_LIGHT_THEME="$VS_NAME"
    VSCODE_LIGHT_EXT="$VS_EXT"
    # Deliberately read Slack's light string from the *real* light theme
    # (before any dracula-alucard IDE override below) — Slack has no vs-dark
    # "no real light variant" problem, so it should always get the actual
    # light palette rather than the IDE's substitute.
    SLACK_THEME_LIGHT="$VS_SLACK"
    if [[ "$light" == "dracula-alucard" ]]; then
        vscode_theme_meta "rose-pine-dawn"
        VSCODE_LIGHT_THEME="$VS_NAME"
        VSCODE_LIGHT_EXT="$VS_EXT"
    fi
    VSCODE_AUTO_DETECT="true"
}

# macos_appearance_mode → prints "dark" or "light" for the current macOS
# system appearance. Ghostty/Cursor/VS Code follow appearance natively via
# their pair configs, but tmux/nvim/bat can only hold ONE palette at a time —
# callers use this to apply the matching half of the pair instead of always
# defaulting to dark (which looked broken when switching themes in light mode).
macos_appearance_mode() {
    if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
        echo dark
    else
        echo light
    fi
}

# apply_tmux_theme <theme-key> → copies the tmux theme file to
# ~/.config/tmux-theme.conf and live-reloads any running tmux server.
apply_tmux_theme() {
    local dark="$1"
    local src="$THEME_LIB_REPO/configs/tmux/themes/${dark}.conf"
    if [[ ! -f "$src" ]]; then
        return 1
    fi
    cp "$src" ~/.config/tmux-theme.conf
    # Live-reload only if a tmux server is actually running; suppress noise
    # when nothing is attached.
    if command -v tmux >/dev/null 2>&1 && tmux info &>/dev/null; then
        tmux source-file ~/.tmux.conf 2>/dev/null || true
    fi
}

# apply_nvim_theme <theme-key> → copies the nvim theme delegate to
# ~/.config/nvim/lua/active_theme.lua.
apply_nvim_theme() {
    local dark="$1"
    local src="$THEME_LIB_REPO/configs/nvim/themes/${dark}.lua"
    [[ -f "$src" ]] || return 1
    cp "$src" ~/.config/nvim/lua/active_theme.lua
}

# app_installed <App Name> → true if <App Name>.app exists in either the
# system or per-user Applications folder. Shared by install.sh (GUI app
# detection) and theme-switch (gating the Slack theme printout below).
app_installed() {
    local app="$1"
    [[ -d "/Applications/${app}.app" ]] || [[ -d "$HOME/Applications/${app}.app" ]]
}

# print_slack_theme_block <dark-key> <dark-slack> <light-key> <light-slack> [echo-fn]
# Slack has no config file and no CLI/API for setting the sidebar theme, so
# the best we can do is print the 8-value custom-theme string (see VS_SLACK
# in vscode_theme_meta for the field order/derivation) and copy the dark
# variant to the clipboard for a quick paste into Slack.
#
# IMPORTANT: since Slack's 2023 redesign ("A new visual language for Slack"),
# the main Custom Theme color pickers no longer take arbitrary hex — Slack's
# own design team collapsed 9 free-form inputs down to 4, mapped against ~20
# predetermined palettes. The old 8/9/10-hex-string format still works, but
# only via the "Import theme" legacy path (Preferences → Appearance → Custom
# theme → Import theme → "Paste your legacy theme colors" → Apply), NOT by
# pasting into the regular color-swatch UI. Don't "fix" the instructions
# below back to a plain paste without re-checking Slack's current UI first.
# $echo_fn (default: echo) styles the final confirmation line — pass
# print_success / success for consistency with the caller's other output.
print_slack_theme_block() {
    local dark_key="$1" dark_slack="$2" light_key="$3" light_slack="$4"
    local echo_ok="${5:-echo}"
    echo ""
    echo "  Slack sidebar theme (modern Slack's Custom Theme color pickers no"
    echo "  longer take free hex, but the legacy string import still does):"
    echo "    Easiest: paste into any Slack message/DM and hit Enter, then"
    echo "             click \"Apply Slack theme\" on the preview."
    echo "    Or:      Preferences → Appearance → Custom theme → Import theme"
    echo "             → \"Paste your legacy theme colors\" → Apply."
    echo ""
    printf "    Dark  (%s):\n      %s\n" "$dark_key" "$dark_slack"
    printf "    Light (%s):\n      %s\n" "$light_key" "$light_slack"
    echo ""
    if command -v pbcopy >/dev/null 2>&1; then
        printf '%s' "$dark_slack" | pbcopy
        "$echo_ok" "Slack dark variant copied to clipboard — paste it into a Slack message (or the legacy import dialog)"
    fi
}

# save_theme_choice <theme-dark> <theme-light> → persists the pair to the
# two config files that theme-sync and install.sh's --update logic read.
save_theme_choice() {
    local dark="$1" light="$2"
    mkdir -p ~/.config
    echo "export COLOR_THEME=$dark" > ~/.config/terminal-color-theme
    printf 'export THEME_DARK=%s\nexport THEME_LIGHT=%s\n' \
        "$dark" "$light" > ~/.config/terminal-theme-pair
}
