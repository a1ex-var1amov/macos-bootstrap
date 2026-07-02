#!/bin/bash
#
# macOS Bootstrap + Terminal Config Installer
# Installs Homebrew, CLI tools, GUI apps, dotfiles, and system defaults.
#
# Usage:
#   ./install.sh                  Full interactive install (default)
#   ./install.sh --yes            Non-interactive — accept all defaults
#                                 (prompt: starship, theme: catppuccin,
#                                  tmux mouse: on, tmux autostart: off)
#   ./install.sh --update         Update mode — skip install prompts, only
#                                 redeploy config files + themes + scripts.
#                                 Previously-chosen prompt / color theme /
#                                 tmux mouse mode are preserved.
#   ./install.sh --update --yes   Quietly refresh configs from this repo
#   ./install.sh --theme=<key>    Pre-select a theme pair (skips the menu).
#                                 Accepts a menu number (1-15) OR a key:
#                                 catppuccin (default = 1),
#                                 catppuccin-macchiato (2), catppuccin-frappe (3),
#                                 tokyo-night (4), tokyo-night-storm (5),
#                                 tokyo-night-moon (6), rose-pine (7),
#                                 rose-pine-moon (8), dracula (9),
#                                 solarized (10), gruvbox (11), everforest (12),
#                                 kanagawa (13), github (14), nord (15)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Shared theme helpers (single source of truth for install.sh + theme-switch)
export THEME_LIB_REPO="$SCRIPT_DIR"
# shellcheck source=lib/theme-lib.sh
source "$SCRIPT_DIR/lib/theme-lib.sh"

# ── Flags ────────────────────────────────────────────────────────────────────
INTERACTIVE=1
UPDATE_ONLY=0
THEME_FLAG=""
for arg in "$@"; do
    case "$arg" in
        -y|--yes|--non-interactive) INTERACTIVE=0 ;;
        -u|--update)                UPDATE_ONLY=1 ;;
        --theme=*)                  THEME_FLAG="${arg#--theme=}" ;;
        -h|--help)
            cat <<'EOF'
macOS Bootstrap + Terminal Config Installer

Usage:
  ./install.sh                  Full interactive install (default)
  ./install.sh --yes            Non-interactive — accept all defaults:
                                  prompt = starship
                                  theme  = catppuccin pair (Mocha ↔ Latte)
                                  tmux mouse mode = on
                                  tmux autostart  = off
  ./install.sh --update         Update mode — skip install prompts, only
                                redeploy config files + themes + scripts.
                                Previously-chosen prompt / theme / tmux
                                mouse mode are preserved.
  ./install.sh --update --yes   Quietly refresh configs from this repo
  ./install.sh --theme=<n|key>  Pre-select a theme pair, skipping the menu.
                                Accepts a menu number (1-15) OR a key:
                                  1  catppuccin (default)     9  dracula
                                  2  catppuccin-macchiato    10  solarized
                                  3  catppuccin-frappe       11  gruvbox
                                  4  tokyo-night             12  everforest
                                  5  tokyo-night-storm       13  kanagawa
                                  6  tokyo-night-moon        14  github
                                  7  rose-pine               15  nord
                                  8  rose-pine-moon
EOF
            exit 0 ;;
        *)  echo "Unknown flag: $arg (use --help)"; exit 1 ;;
    esac
done

# ask <prompt> [default Y|N] — returns 0 for yes, 1 for no.
# In --yes mode, returns the default without prompting.
ask() {
    local prompt="$1" default="${2:-Y}" reply
    if (( ! INTERACTIVE )); then
        [[ "$default" == "Y" ]] && return 0 || return 1
    fi
    read -p "$prompt " -n 1 -r reply; echo
    if [[ "$default" == "Y" ]]; then
        [[ $reply =~ ^[Nn]$ ]] && return 1 || return 0
    else
        [[ $reply =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# ask_value <prompt> <default> — returns user input, or default in --yes mode.
ask_value() {
    local prompt="$1" default="$2" reply
    if (( ! INTERACTIVE )); then
        echo "$default"; return
    fi
    read -p "$prompt" -r reply
    echo "${reply:-$default}"
}

print_status()  { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()   { echo -e "${RED}[-]${NC} $1"; }
print_section() { echo -e "\n${BOLD}${CYAN}── $1 ──────────────────────────────────────${NC}"; }

command_exists() { command -v "$1" &>/dev/null; }

backup_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    local backup
    backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup"
    print_warning "Backed up $file → $backup"
    # Prune: keep oldest (initial/system), second-newest (previous), and newest (just made).
    # Delete everything in between.
    local all_count to_prune
    all_count=$(ls -1 "${file}.bak."* 2>/dev/null | wc -l | awk '{print $1}')
    if (( all_count > 3 )); then
        to_prune="$(ls -1 "${file}.bak."* 2>/dev/null | sort | head -n $(( all_count - 2 )) | tail -n +2)"
        [[ -n "$to_prune" ]] && echo "$to_prune" | xargs rm -f
    fi
}

# Check if a brew formula or CLI tool is installed
# Sourced zsh plugins → check brew prefix. GUI-only apps → check /Applications.
is_installed() {
    case "$1" in
        zsh-autosuggestions)
            brew list --formula zsh-autosuggestions &>/dev/null 2>&1 ;;
        zsh-fast-syntax-highlighting)
            brew list --formula zsh-fast-syntax-highlighting &>/dev/null 2>&1 ;;
        ripgrep)       command_exists rg ;;
        git-delta)     command_exists delta ;;
        podman-compose) command_exists podman-compose ;;
        *)             command_exists "$1" ;;
    esac
}

# Check if a macOS .app is installed (for casks that don't put a CLI in PATH)
app_installed() {
    local app="$1"
    [[ -d "/Applications/${app}.app" ]] || [[ -d "$HOME/Applications/${app}.app" ]]
}

echo ""
echo "════════════════════════════════════════════════════════"
echo "   macOS Bootstrap + Terminal Config Installer"
if (( UPDATE_ONLY ));    then echo "   Mode: UPDATE (configs/themes only)"; fi
if (( ! INTERACTIVE )); then echo "   Mode: non-interactive (--yes)"; fi
echo "════════════════════════════════════════════════════════"
echo ""

# =============================================================================
# 1. HOMEBREW
# =============================================================================
if (( ! UPDATE_ONLY )); then
print_section "Homebrew"

if ! command_exists brew; then
    print_warning "Homebrew not found."
    if ! ask "Install Homebrew now? [Y/n]" Y; then
        print_error "Homebrew is required. Aborting."
        exit 1
    fi
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
else
    print_success "Homebrew: $(brew --version | head -1)"
fi
fi  # ! UPDATE_ONLY

# =============================================================================
# 2. CLI TOOLS
# =============================================================================
if (( ! UPDATE_ONLY )); then
print_section "CLI Tools"

# Required — brew-install instead of aborting
MISSING_REQUIRED=()
for f in git zsh tmux; do
    is_installed "$f" || MISSING_REQUIRED+=("$f")
done

# Core terminal stack
MISSING_CORE=()
for f in nvim starship fzf zoxide zsh-autosuggestions zsh-fast-syntax-highlighting direnv fnm gh shellcheck; do
    is_installed "$f" || MISSING_CORE+=("$f")
done

# Languages
MISSING_LANGS=()
for f in go terraform; do
    is_installed "$f" || MISSING_LANGS+=("$f")
done

# Modern CLI replacements
# Note: gh-dash is NOT a Homebrew formula — it's a `gh` CLI extension, so it's
# installed separately below (after `gh` itself is confirmed present) via
# `gh extension install dlvhdr/gh-dash` instead of `brew install`.
MISSING_CLI=()
for f in bat eza ripgrep fd git-delta btop jq yq ncdu duf dust tldr lazygit lazydocker podman podman-compose yazi procs; do
    is_installed "$f" || MISSING_CLI+=("$f")
done

# History — atuin: fuzzy search, timestamps, cross-machine sync
MISSING_HISTORY=()
is_installed atuin || MISSING_HISTORY+=(atuin)

# Kubernetes
MISSING_K8S=()
for f in kubectl kubecolor k9s stern kubectx kubie helm; do
    is_installed "$f" || MISSING_K8S+=("$f")
done

ALL_MISSING=("${MISSING_REQUIRED[@]}" "${MISSING_CORE[@]}" "${MISSING_CLI[@]}" \
             "${MISSING_HISTORY[@]}" "${MISSING_K8S[@]}" "${MISSING_LANGS[@]}")

if [[ ${#ALL_MISSING[@]} -eq 0 ]]; then
    print_success "All CLI tools present"
else
    echo "Missing tools:"
    [[ ${#MISSING_REQUIRED[@]} -gt 0 ]] && echo "  Required  : ${MISSING_REQUIRED[*]}"
    [[ ${#MISSING_CORE[@]} -gt 0 ]]     && echo "  Core      : ${MISSING_CORE[*]}"
    [[ ${#MISSING_CLI[@]} -gt 0 ]]      && echo "  Modern CLI: ${MISSING_CLI[*]}"
    [[ ${#MISSING_HISTORY[@]} -gt 0 ]]  && echo "  History   : ${MISSING_HISTORY[*]}"
    [[ ${#MISSING_K8S[@]} -gt 0 ]]      && echo "  Kubernetes: ${MISSING_K8S[*]}"
    [[ ${#MISSING_LANGS[@]} -gt 0 ]]    && echo "  Languages : ${MISSING_LANGS[*]}"
    echo ""
    if ask "Install all missing tools with Homebrew? [Y/n]" Y; then
        [[ ${#MISSING_REQUIRED[@]} -gt 0 ]] && brew install "${MISSING_REQUIRED[@]}" || true
        [[ ${#MISSING_CORE[@]} -gt 0 ]]     && brew install "${MISSING_CORE[@]}"     || true
        [[ ${#MISSING_CLI[@]} -gt 0 ]]      && brew install "${MISSING_CLI[@]}"      || true
        [[ ${#MISSING_HISTORY[@]} -gt 0 ]]  && brew install "${MISSING_HISTORY[@]}"  || true
        [[ ${#MISSING_K8S[@]} -gt 0 ]]      && brew install "${MISSING_K8S[@]}"      || true
        [[ ${#MISSING_LANGS[@]} -gt 0 ]]    && brew install "${MISSING_LANGS[@]}"    || true
        print_success "CLI tools installed"
    else
        if [[ ${#MISSING_REQUIRED[@]} -gt 0 ]]; then
            print_error "Required tools still missing: ${MISSING_REQUIRED[*]}. Aborting."
            exit 1
        fi
        print_warning "Skipping CLI install — some features may not work"
    fi
fi

# Nerd Font
print_status "Checking Nerd Font..."
if ! fc-list 2>/dev/null | grep -qi "nerd\|jetbrains"; then
    print_warning "JetBrainsMono Nerd Font not detected"
    if ask "Install JetBrainsMono Nerd Font? [Y/n]" Y; then
        brew install --cask font-jetbrains-mono-nerd-font && print_success "Nerd Font installed"
    fi
else
    print_success "Nerd Font found"
fi

# gh-dash — a `gh` CLI extension (dlvhdr/gh-dash), not a Homebrew formula.
# `brew install gh-dash` always fails with "No formulae or casks found";
# it must be installed via `gh extension install` once `gh` itself is present.
if command_exists gh; then
    print_status "Checking gh-dash extension..."
    if gh extension list 2>/dev/null | grep -q "dlvhdr/gh-dash"; then
        print_success "gh-dash extension found"
    elif ask "Install gh-dash (GitHub CLI dashboard extension)? [Y/n]" Y; then
        gh extension install dlvhdr/gh-dash \
            && print_success "gh-dash extension installed" \
            || print_warning "Could not install gh-dash extension (run manually: gh extension install dlvhdr/gh-dash)"
    fi
fi
fi  # ! UPDATE_ONLY

# =============================================================================
# 3. GUI APPS (CASKS)
# =============================================================================
if (( ! UPDATE_ONLY )); then
print_section "GUI Applications"

declare -a MISSING_CASKS=()

# Format: "cask-name:check-type:check-value"
#   check-type "cmd" → command_exists  (has a CLI binary in PATH)
#   check-type "app" → app_installed   (macOS .app bundle, no CLI)
GUI_APPS=(
    "ghostty:cmd:ghostty"
    "cursor:cmd:cursor"
    "visual-studio-code:cmd:code"
    "podman-desktop:app:Podman Desktop"
    "raycast:app:Raycast"
)

for entry in "${GUI_APPS[@]}"; do
    cask="${entry%%:*}"
    rest="${entry#*:}"
    check_type="${rest%%:*}"
    check_val="${rest#*:}"
    if [[ "$check_type" == "app" ]]; then
        app_installed "$check_val" || MISSING_CASKS+=("$cask")
    else
        command_exists "$check_val" || MISSING_CASKS+=("$cask")
    fi
done

if [[ ${#MISSING_CASKS[@]} -eq 0 ]]; then
    print_success "GUI apps present (Ghostty, Cursor, VS Code, Podman Desktop, Raycast)"
else
    echo "Missing apps: ${MISSING_CASKS[*]}"
    if ask "Install via Homebrew Cask? [Y/n]" Y; then
        for cask in "${MISSING_CASKS[@]}"; do
            print_status "Installing $cask..."
            brew install --cask "$cask" \
                && print_success "$cask installed" \
                || print_warning "Could not install $cask (install manually if needed)"
        done
    else
        print_warning "Skipping GUI apps"
    fi
fi
fi  # ! UPDATE_ONLY

# =============================================================================
# 4. DEFAULT SHELL → ZSH
# =============================================================================
if (( ! UPDATE_ONLY )); then
print_section "Default Shell"

# Prefer the brew-installed zsh (newer) over system /bin/zsh
BREW_ZSH="$(brew --prefix)/bin/zsh"
CURRENT_SHELL="$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')"

if [[ "$CURRENT_SHELL" != "$BREW_ZSH" && "$CURRENT_SHELL" != "/bin/zsh" ]]; then
    print_warning "Default shell is $CURRENT_SHELL"
    if ask "Change default shell to zsh? [Y/n]" Y; then
        # Add brew zsh to /etc/shells if not already listed
        if [[ -f "$BREW_ZSH" ]] && ! grep -qF "$BREW_ZSH" /etc/shells; then
            echo "$BREW_ZSH" | sudo tee -a /etc/shells > /dev/null
            print_success "Added $BREW_ZSH to /etc/shells"
        fi
        TARGET_ZSH="$([[ -f $BREW_ZSH ]] && echo $BREW_ZSH || echo /bin/zsh)"
        chsh -s "$TARGET_ZSH" && print_success "Default shell → $TARGET_ZSH" \
            || print_warning "chsh failed — run manually: chsh -s $TARGET_ZSH"
    fi
else
    print_success "Default shell is already zsh ($CURRENT_SHELL)"
fi
fi  # ! UPDATE_ONLY

# =============================================================================
# 5. ZPROFILE — Homebrew PATH for all shell contexts
# =============================================================================
# tmux panes start as non-login shells and won't read ~/.zprofile automatically.
# By sourcing ~/.zprofile from ~/.zshrc (if present), we ensure brew is always
# in PATH regardless of whether the shell is login or interactive.
print_section "Zsh Profile"

ZPROFILE="$HOME/.zprofile"
if [[ ! -f "$ZPROFILE" ]] || ! grep -q "brew shellenv" "$ZPROFILE" 2>/dev/null; then
    cat >> "$ZPROFILE" <<'EOF'
# Homebrew — set PATH, MANPATH, INFOPATH for this shell
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
EOF
    print_success "~/.zprofile created with Homebrew PATH"
else
    print_success "~/.zprofile already has Homebrew PATH"
fi

# Ensure ~/.zshrc sources ~/.zprofile so non-login shells (tmux) also get the PATH
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]] && ! grep -q "zprofile" "$ZSHRC" 2>/dev/null; then
    # Prepend the source line so it runs before anything else
    printf '[[ -f ~/.zprofile ]] && source ~/.zprofile\n\n' | cat - "$ZSHRC" > /tmp/_zshrc_tmp && mv /tmp/_zshrc_tmp "$ZSHRC"
    print_success "~/.zshrc now sources ~/.zprofile (brew in PATH in all shells)"
else
    print_success "~/.zshrc already sources ~/.zprofile"
fi

# =============================================================================
# 6. ZSH PLUGINS (git-managed, not from brew)
# =============================================================================
print_section "Zsh Plugins"

FZF_TAB_DIR="$HOME/.zsh/plugins/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]]; then
    print_status "Cloning fzf-tab (enhanced completion UI)..."
    mkdir -p "$HOME/.zsh/plugins"
    git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR" 2>/dev/null \
        && print_success "fzf-tab installed → $FZF_TAB_DIR" \
        || print_warning "Could not clone fzf-tab — completion falls back to default"
else
    print_success "fzf-tab already present"
fi

# =============================================================================
# 7. SSH KEY
# =============================================================================
print_section "SSH Key"

SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ -f "$SSH_KEY" ]]; then
    print_success "SSH key found: $SSH_KEY"
    echo "  Public key:"
    cat "${SSH_KEY}.pub" | awk '{print "  " $0}'
elif (( UPDATE_ONLY )); then
    print_warning "No SSH key — run without --update to generate one"
else
    print_warning "No SSH key found at $SSH_KEY"
    if ask "Generate a new SSH key (ed25519)? [Y/n]" Y; then
        SSH_EMAIL_INPUT="$(ask_value "Email for SSH key (default: git email): " "")"
        SSH_EMAIL="${SSH_EMAIL_INPUT:-${GIT_EMAIL_INPUT:-${GIT_EMAIL:-$(git config --global user.email 2>/dev/null)}}}"
        if [[ -z "$SSH_EMAIL" && $INTERACTIVE -eq 1 ]]; then
            SSH_EMAIL="$(ask_value "Email address: " "")"
        fi
        if [[ -z "$SSH_EMAIL" ]]; then
            print_warning "No email available — skipping SSH key generation"
        else
            mkdir -p ~/.ssh
            chmod 700 ~/.ssh
            ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" -N "" \
                && print_success "SSH key generated: $SSH_KEY" \
                || print_warning "ssh-keygen failed"
            # Start ssh-agent and add key to macOS keychain (persists across reboots)
            eval "$(ssh-agent -s)" &>/dev/null
            ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null \
                || ssh-add "$SSH_KEY" 2>/dev/null || true
            echo ""
            print_status "Your public key (add to GitHub → Settings → SSH Keys):"
            cat "${SSH_KEY}.pub"
            echo ""
            if (( INTERACTIVE )); then
                read -p "Press Enter once you've added it to GitHub..." -r
            fi
        fi
    fi
fi

# ~/.ssh/config — keychain integration + ControlMaster connection reuse +
# Include directives for per-host snippets (~/.ssh/config.d/*.conf) and a
# personal override file (~/.ssh/config.local). Template ships in
# configs/ssh/config-base; we only install it if no config exists yet (so we
# never clobber a user's hand-tuned setup).
mkdir -p ~/.ssh ~/.ssh/config.d ~/.ssh/sockets
chmod 700 ~/.ssh ~/.ssh/config.d ~/.ssh/sockets
SSH_CONFIG="$HOME/.ssh/config"
if [[ ! -f "$SSH_CONFIG" ]]; then
    cp "$SCRIPT_DIR/configs/ssh/config-base" "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    print_success "~/.ssh/config installed (keychain + ControlMaster + Includes)"
elif ! grep -q "UseKeychain" "$SSH_CONFIG" 2>/dev/null; then
    # Existing config without UseKeychain — append the minimum so keys persist
    # across reboots, but don't touch anything else.
    cat >> "$SSH_CONFIG" <<'EOF'

Host *
  AddKeysToAgent yes
  UseKeychain    yes
  IdentityFile   ~/.ssh/id_ed25519
EOF
    chmod 600 "$SSH_CONFIG"
    print_success "~/.ssh/config appended with keychain settings"
else
    print_success "~/.ssh/config already configured"
fi

# =============================================================================
# 8. GIT IDENTITY
# =============================================================================
print_section "Git Identity"

GIT_NAME=$(git config --global user.name  2>/dev/null || true)
GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [[ -z "$GIT_EMAIL" ]]; then
    if (( UPDATE_ONLY )); then
        print_warning "Git identity not configured (skipping in update mode)"
    else
        print_warning "Git identity not configured"
        GIT_NAME_INPUT="$(ask_value "Your full name for git commits : " "")"
        GIT_EMAIL_INPUT="$(ask_value "Your email for git commits     : " "")"
        if [[ -n "$GIT_NAME_INPUT" && -n "$GIT_EMAIL_INPUT" ]]; then
            git config --global user.name  "$GIT_NAME_INPUT"
            git config --global user.email "$GIT_EMAIL_INPUT"
            print_success "Git identity set: $GIT_NAME_INPUT <$GIT_EMAIL_INPUT>"
        else
            print_warning "Skipped — set later: git config --global user.name/email"
        fi
    fi
else
    print_success "Git identity: $GIT_NAME <$GIT_EMAIL>"
fi

# =============================================================================
# 9. PROMPT ENGINE
# =============================================================================
print_section "Prompt Engine"

PROMPT_ENGINE="starship"
if [[ -f "$HOME/.config/terminal-fix-prompt" ]]; then
    source "$HOME/.config/terminal-fix-prompt" 2>/dev/null || true
fi
# In update mode, keep the previously-saved choice.
if (( UPDATE_ONLY )) && [[ -n "$PROMPT_ENGINE" ]]; then
    PROMPT_CHOICE=$([[ "$PROMPT_ENGINE" == "p10k" ]] && echo 2 || echo 1)
    print_status "Keeping prompt engine: $PROMPT_ENGINE"
else
    echo "Choose your prompt (same look: directory, git, k8s, langs, time):"
    echo "  1) Starship         — cross-shell, fast (default)"
    echo "  2) Powerlevel10k    — Zsh-only, Starship-style config"
    echo ""
    PROMPT_CHOICE="$(ask_value "Pick [1/2] (default 1): " "1")"
fi
if [[ "$PROMPT_CHOICE" == "2" ]]; then
    PROMPT_ENGINE="p10k"
    print_status "Will use Powerlevel10k"
else
    PROMPT_ENGINE="starship"
    print_status "Will use Starship"
fi
mkdir -p ~/.config
echo "export PROMPT_ENGINE=$PROMPT_ENGINE" > ~/.config/terminal-fix-prompt
print_success "Prompt choice saved: $PROMPT_ENGINE"

if [[ "$PROMPT_ENGINE" == "p10k" ]]; then
    if [[ ! -d "$HOME/.zsh/themes/powerlevel10k" ]]; then
        print_status "Cloning Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$HOME/.zsh/themes/powerlevel10k" 2>/dev/null \
            && print_success "Powerlevel10k cloned" \
            || print_warning "Could not clone Powerlevel10k — install manually"
    else
        print_success "Powerlevel10k already present"
    fi
fi

# =============================================================================
# 10. COLOR SCHEME
# =============================================================================
print_section "Color Scheme"

# Default = Catppuccin pair (Mocha ↔ Latte). Pre-populated COLOR_THEME survives
# update-mode runs; we re-derive the menu choice below.
COLOR_THEME="catppuccin-mocha"
if [[ -f "$HOME/.config/terminal-color-theme" ]]; then
    source "$HOME/.config/terminal-color-theme" 2>/dev/null || true
fi

echo "Choose your color-scheme PAIR (auto-switches with macOS appearance):"
echo ""
echo "   1) Catppuccin            — Mocha     ↔ Latte           (cool purple)"
echo "   2) Catppuccin Macchiato  — Macchiato ↔ Latte           (medium-dark variant)"
echo "   3) Catppuccin Frappé     — Frappé    ↔ Latte           (lightest dark variant)"
echo "   4) Tokyo Night           — Night     ↔ Day             (deep blue-purple)"
echo "   5) Tokyo Night Storm     — Storm     ↔ Day             (slightly lighter)"
echo "   6) Tokyo Night Moon      — Moon      ↔ Day             (muted purple-dark)"
echo "   7) Rosé Pine             — Main      ↔ Dawn            (warm pink-cream)"
echo "   8) Rosé Pine Moon        — Moon      ↔ Dawn            (deep dark variant)"
echo "   9) Dracula               — Dracula   ↔ Alucard         (classic purple; IDE light side: Rosé Pine Dawn)"
echo "  10) Solarized             — Dark      ↔ Light           (Ethan Schoonover's ergonomic palette)"
echo "  11) Gruvbox               — Dark      ↔ Light           (warm retro earth tones)"
echo "  12) Everforest            — Dark      ↔ Light           (calming forest green)"
echo "  13) Kanagawa              — Wave      ↔ Lotus           (Hokusai-inspired Japanese)"
echo "  14) GitHub                — Dark      ↔ Light           (what github.com uses)"
echo "  15) Nord                  — Nord      ↔ Nord Light      (cool arctic blues; IDE light side: Default Light Modern)"
echo ""

# Precedence: --theme=<key> flag wins, then --update preserves the last
# choice, then interactive prompt, then default (Catppuccin pair).
# The theme_key_to_choice / theme_choice_to_pair / save_theme_choice helpers
# live in lib/theme-lib.sh and are shared with bin/theme-switch.
if [[ -n "$THEME_FLAG" ]]; then
    COLOR_CHOICE="$(theme_key_to_choice "$THEME_FLAG")"
    print_status "Theme pre-selected via --theme=$THEME_FLAG (menu choice $COLOR_CHOICE)"
elif (( UPDATE_ONLY )) && [[ -n "$COLOR_THEME" ]]; then
    COLOR_CHOICE="$(theme_key_to_choice "$COLOR_THEME")"
    print_status "Keeping color scheme: $COLOR_THEME (menu choice $COLOR_CHOICE)"
else
    COLOR_CHOICE="$(ask_value "Pick [1-$THEME_LIB_MAX_CHOICE] (default 1): " "1")"
fi

# Sets $THEME_DARK / $THEME_LIGHT as side-effects.
theme_choice_to_pair "$COLOR_CHOICE" >/dev/null

COLOR_THEME="$THEME_DARK"
GHOSTTY_THEME="dark:$THEME_DARK,light:$THEME_LIGHT"

save_theme_choice "$THEME_DARK" "$THEME_LIGHT"
print_success "Color pair: $THEME_DARK ↔ $THEME_LIGHT (Ghostty: $GHOSTTY_THEME)"

# Populate VSCODE_* + SLACK_THEME globals from the chosen pair. All the theme
# metadata tables (VS_NAME / VS_ICON / VS_EXT / VS_BORDER / VS_SLACK per key)
# live in lib/theme-lib.sh — see `vscode_theme_meta` there. The call below also
# applies the dracula-alucard → rose-pine-dawn IDE-light-side substitution
# (necessary because "Dracula Theme Soft" is still uiTheme=vs-dark, so
# autoDetectColorScheme silently no-ops with it as the light theme).
compute_vscode_pair_metadata "$THEME_DARK" "$THEME_LIGHT"

# Backwards-compat: legacy user hooks that shell out to `_vscode_theme_meta`
# still work — it's now a thin alias for `vscode_theme_meta` from the lib.
_vscode_theme_meta() { vscode_theme_meta "$@"; }

# =============================================================================
# 11. DIRECTORIES
# =============================================================================
print_section "Directories"

mkdir -p ~/.config/ghostty/themes
mkdir -p ~/.config/nvim/lua/themes
mkdir -p ~/.config/nvim/lua
mkdir -p ~/.config/tmux/themes
mkdir -p ~/.config/tmux/scripts
mkdir -p ~/.config/tmux/extras
mkdir -p ~/.config/git
mkdir -p ~/.vim/undo
mkdir -p ~/.zsh/themes
mkdir -p ~/.zsh/plugins
mkdir -p ~/.zsh/completions

print_success "Directories ready"

# =============================================================================
# 12. DOTFILES + CONFIG FILES
# =============================================================================
print_section "Config Files"

# Ghostty — install all theme files, then build config with chosen theme.
for theme_file in "$SCRIPT_DIR/configs/ghostty/themes"/*; do
    cp "$theme_file" ~/.config/ghostty/themes/
done
backup_file ~/.config/ghostty/config
render_ghostty_config "$GHOSTTY_THEME"
print_success "Ghostty config (theme: $GHOSTTY_THEME)"

# Ghostty on macOS also reads ~/Library/Application Support/com.mitchellh.ghostty/config
# and auto-creates a template there on first launch when no other config is found.
# Once that template exists it can shadow ~/.config/ghostty/config and produce
# surprises like "the theme I configured isn't applying". `ensure_ghostty_appsupport_shim`
# from lib/theme-lib.sh keeps the app-support file mirroring our XDG config
# (full content, not a `config-file` redirect — see CLAUDE.md for why a
# redirect trips a known Ghostty "cycle detected" bug) so install.sh remains
# the single source of truth regardless of how Ghostty was launched.
ECHO_OK=print_success ensure_ghostty_appsupport_shim

# Ghostty doesn't watch its config files for changes (upstream "wontfix"),
# so without this, a running Ghostty keeps its old colors until the user
# manually reloads (Cmd+Shift+,) or restarts. Nudge it now if it's running.
if pgrep -x ghostty >/dev/null 2>&1; then
    reload_ghostty_if_running
    print_success "Ghostty reloaded (running instance picked up the new theme)"
fi

# Zsh
backup_file ~/.zshrc
cp "$SCRIPT_DIR/configs/zsh/zshrc" ~/.zshrc
print_success "Zsh config"

# Prompt
if [[ "$PROMPT_ENGINE" == "p10k" ]]; then
    backup_file ~/.p10k.zsh
    if [[ -f "$SCRIPT_DIR/configs/p10k/p10k-starship-style.zsh" ]]; then
        cp "$SCRIPT_DIR/configs/p10k/p10k-starship-style.zsh" ~/.p10k.zsh
        print_success "Powerlevel10k config"
    else
        print_warning "p10k config not found — run: p10k configure"
    fi
else
    backup_file ~/.config/starship.toml
    cp "$SCRIPT_DIR/configs/starship/starship.toml" ~/.config/starship.toml
    print_success "Starship config"
fi

# Neovim — install init.lua + all theme files (needed by theme-sync)
backup_file ~/.config/nvim/init.lua
cp "$SCRIPT_DIR/configs/nvim/init.lua" ~/.config/nvim/init.lua
cp "$SCRIPT_DIR/configs/nvim/themes/theme_base.lua" ~/.config/nvim/lua/theme_base.lua
for _nvim_theme in "$SCRIPT_DIR/configs/nvim/themes"/*.lua; do
    [[ "${_nvim_theme##*/}" == "theme_base.lua" ]] && continue
    cp "$_nvim_theme" ~/.config/nvim/lua/themes/
done
cp "$SCRIPT_DIR/configs/nvim/themes/${COLOR_THEME}.lua" ~/.config/nvim/lua/active_theme.lua
print_success "Neovim config + theme: $COLOR_THEME (run 'nvim' once to auto-install plugins)"

# Vim
backup_file ~/.vimrc
cp "$SCRIPT_DIR/configs/vim/vimrc" ~/.vimrc
print_success "Vim config"

# ── Tmux mouse / context-menu mode ───────────────────────────────────────────
# Two flavours, chosen here once and saved to ~/.config/terminal-tmux-mouse
# so subsequent --update runs preserve the choice.
#
#   on   "Full tmux mouse mode"  — click panes, drag-resize, wheel-scrolls-
#                                  buffer, right-click context menu, OSC 52
#                                  clipboard pass-through, mouse-in-apps
#                                  (vim/fzf). (Default.)
#   off  "Scroll only"           — tmux owns only the wheel (so scrolling
#                                  shows your actual pane history, not zsh
#                                  command history). Clicks / drag / right-
#                                  click are tmux no-ops. Native Ghostty
#                                  selection: hold ⌥ Option.
#
# Note: a truly "mouse off" mode is offered by neither option because tmux
# always uses the alternate screen, and Ghostty's xterm emulation then
# translates wheel events into Up/Down arrows — which zsh interprets as
# command-history navigation. The "Scroll only" mode picks the smallest
# possible tmux mouse footprint to dodge that.
#
# Either way you can still copy with Prefix + [ -> v -> y, paste with Prefix + ].
TMUX_MOUSE_CHOICE=""
if [[ -f "$HOME/.config/terminal-tmux-mouse" ]]; then
    TMUX_MOUSE_CHOICE="$(cat "$HOME/.config/terminal-tmux-mouse" 2>/dev/null)"
fi

if (( UPDATE_ONLY )) && [[ -n "$TMUX_MOUSE_CHOICE" ]]; then
    print_status "Keeping tmux mouse mode: $TMUX_MOUSE_CHOICE"
else
    echo ""
    echo "Tmux mouse / context-menu behaviour:"
    echo "  1) Full tmux mouse mode  (default — click panes, drag-resize, wheel"
    echo "                            scrolls history, right-click menu, mouse"
    echo "                            in vim/fzf)"
    echo "  2) Scroll only           (tmux owns only the wheel — clicks / drag /"
    echo "                            right-click are no-ops. Hold ⌥ Option for"
    echo "                            Ghostty-native selection.)"
    echo ""
    echo "  Tip: in BOTH modes, hold ⌥ Option while selecting in Ghostty to do"
    echo "       a native terminal selection (good for long wrapped URLs)."
    echo ""
    _tmc_pick="$(ask_value "Pick [1/2] (default 1): " "1")"
    case "$_tmc_pick" in
        2) TMUX_MOUSE_CHOICE="off" ;;
        *) TMUX_MOUSE_CHOICE="on"  ;;
    esac
    echo "$TMUX_MOUSE_CHOICE" > "$HOME/.config/terminal-tmux-mouse"
fi

# Tmux — install config + helper scripts + all theme files + active theme.
# Theme files are color-only token overrides; status-bar/binding logic lives
# in tmux.conf and reads those tokens. Helper scripts back the status bar's
# git-branch and k8s-context segments (with caching + timeout guards).
backup_file ~/.tmux.conf
cp "$SCRIPT_DIR/configs/tmux/tmux.conf" ~/.tmux.conf
for _tmux_theme in "$SCRIPT_DIR/configs/tmux/themes"/*.conf; do
    cp "$_tmux_theme" ~/.config/tmux/themes/
done
cp "$SCRIPT_DIR/configs/tmux/themes/${COLOR_THEME}.conf" ~/.config/tmux-theme.conf
for _tmux_script in "$SCRIPT_DIR/configs/tmux/scripts"/*.sh; do
    cp "$_tmux_script" ~/.config/tmux/scripts/
    chmod +x ~/.config/tmux/scripts/"${_tmux_script##*/}"
done
# Ship both mouse-*.conf snippets (so the user can flip later without re-running
# the installer) and activate the one they picked.
for _tmux_extra in "$SCRIPT_DIR/configs/tmux/extras"/*.conf; do
    cp "$_tmux_extra" ~/.config/tmux/extras/
done
cp "$SCRIPT_DIR/configs/tmux/extras/mouse-${TMUX_MOUSE_CHOICE}.conf" \
   ~/.config/tmux-mouse.conf
print_success "Tmux config + theme: $COLOR_THEME, mouse=$TMUX_MOUSE_CHOICE"

# Git — config (delta, globals, aliases) + global gitignore
backup_file ~/.config/git/gitconfig
cp "$SCRIPT_DIR/configs/git/gitconfig" ~/.config/git/gitconfig
print_success "Git config (delta, globals, aliases)"

# Global gitignore
backup_file ~/.gitignore_global
cp "$SCRIPT_DIR/configs/git/gitignore_global" ~/.gitignore_global
print_success "Global gitignore (~/.gitignore_global)"

# Wire [include] in ~/.gitconfig so our config is actually loaded
# (git does NOT auto-load ~/.config/git/gitconfig — only ~/.config/git/config)
touch ~/.gitconfig
if ! grep -qF "~/.config/git/gitconfig" ~/.gitconfig 2>/dev/null && \
   ! grep -qF ".config/git/gitconfig"   ~/.gitconfig 2>/dev/null; then
    printf '\n[include]\n    path = ~/.config/git/gitconfig\n' >> ~/.gitconfig
    print_success "Git: [include] wired into ~/.gitconfig"
else
    print_success "Git: [include] already present in ~/.gitconfig"
fi

# Cheatsheets
cp "$SCRIPT_DIR/cheatsheets/tmux-cheatsheet.txt" ~/.config/tmux-cheatsheet.txt
cp "$SCRIPT_DIR/cheatsheets/vim-cheatsheet.txt"  ~/.config/vim-cheatsheet.txt
print_success "Cheatsheets"

# theme-switch — fast standalone theme changer that avoids re-running the
# entire installer. Deployed as a symlink to the in-repo script so `git pull`
# in the repo instantly refreshes what `theme-switch` picks up (no re-install
# required). The script self-resolves the symlink to find the repo root and
# then sources lib/theme-lib.sh from there.
mkdir -p ~/.local/bin
if [[ -L ~/.local/bin/theme-switch || -f ~/.local/bin/theme-switch ]]; then
    rm -f ~/.local/bin/theme-switch
fi
ln -s "$SCRIPT_DIR/bin/theme-switch" ~/.local/bin/theme-switch
print_success "theme-switch → ~/.local/bin/theme-switch (run 'theme-switch --help')"

# kubectl + helm completions (static files — no subprocess on every shell start)
if command_exists kubectl; then
    kubectl completion zsh > ~/.zsh/completions/_kubectl 2>/dev/null \
        && print_success "kubectl completions generated" \
        || print_warning "kubectl completion generation failed"
fi
if command_exists helm; then
    helm completion zsh > ~/.zsh/completions/_helm 2>/dev/null \
        && print_success "helm completions generated" \
        || print_warning "helm completion generation failed"
fi

# Render a settings-base.json template into a target settings.json with all
# the placeholders filled in. `render_vscode_settings` (from lib/theme-lib.sh)
# does the actual sed dance; this thin alias keeps the local name stable for
# the Cursor + VS Code call sites just below.
_render_vscode_settings() { render_vscode_settings "$@"; }

# ── Cursor ──────────────────────────────────────────────────────────────────
CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$CURSOR_DIR" ]]; then
    backup_file "$CURSOR_DIR/settings.json"
    _render_vscode_settings \
        "$SCRIPT_DIR/configs/cursor/settings-base.json" \
        "$CURSOR_DIR/settings.json"
    if [[ "$VSCODE_AUTO_DETECT" == "true" ]]; then
        print_success "Cursor settings (auto-detect: dark=$VSCODE_DARK_THEME, light=$VSCODE_LIGHT_THEME)"
    else
        print_success "Cursor settings (theme: $VSCODE_COLOR_THEME)"
    fi
    if command_exists cursor; then
        # Install for both ends of the pair (auto-detect needs both installed;
        # the user might never see dark or light otherwise depending on which
        # mode boots first). ensure_vscode_extensions skips anything already
        # present (via --list-extensions) so repeat installs/--update runs
        # don't touch the network for extensions that are already there.
        ECHO_OK=print_success ensure_vscode_extensions cursor \
            catppuccin.catppuccin-vsc catppuccin.catppuccin-vsc-icons \
            "$VSCODE_THEME_EXT" "$VSCODE_DARK_EXT" "$VSCODE_LIGHT_EXT"
    else
        print_warning "cursor CLI not in PATH — install extensions manually:"
        echo "  cursor --install-extension catppuccin.catppuccin-vsc"
        echo "  cursor --install-extension catppuccin.catppuccin-vsc-icons"
        for _ext in "$VSCODE_THEME_EXT" "$VSCODE_DARK_EXT" "$VSCODE_LIGHT_EXT"; do
            [[ -n "$_ext" ]] && echo "  cursor --install-extension $_ext"
        done
    fi
else
    print_warning "Cursor not found — skipping Cursor config"
fi

# ── VS Code ──────────────────────────────────────────────────────────────────
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_DIR" ]]; then
    backup_file "$VSCODE_DIR/settings.json"
    _render_vscode_settings \
        "$SCRIPT_DIR/configs/vscode/settings-base.json" \
        "$VSCODE_DIR/settings.json"
    if [[ "$VSCODE_AUTO_DETECT" == "true" ]]; then
        print_success "VS Code settings (auto-detect: dark=$VSCODE_DARK_THEME, light=$VSCODE_LIGHT_THEME)"
    else
        print_success "VS Code settings (theme: $VSCODE_COLOR_THEME)"
    fi
    if command_exists code; then
        # Install for both ends of the pair so auto-detect always has the
        # underlying theme available, regardless of which mode boots first.
        ECHO_OK=print_success ensure_vscode_extensions code \
            catppuccin.catppuccin-vsc catppuccin.catppuccin-vsc-icons \
            "$VSCODE_THEME_EXT" "$VSCODE_DARK_EXT" "$VSCODE_LIGHT_EXT"
        code --install-extension esbenp.prettier-vscode                       2>/dev/null && print_success "VS Code: Prettier"              || true
        code --install-extension ms-python.python                             2>/dev/null && print_success "VS Code: Python"                || true
        code --install-extension ms-python.black-formatter                    2>/dev/null && print_success "VS Code: Black formatter"       || true
        code --install-extension golang.go                                    2>/dev/null && print_success "VS Code: Go"                    || true
        code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools  2>/dev/null && print_success "VS Code: Kubernetes"            || true
        code --install-extension redhat.vscode-yaml                           2>/dev/null && print_success "VS Code: YAML"                  || true
    else
        print_warning "code CLI not in PATH — install extensions manually or via Command Palette"
    fi
else
    print_warning "VS Code not found — skipping VS Code config"
fi

# ── Slack ────────────────────────────────────────────────────────────────────
if app_installed "Slack"; then
    echo ""
    print_status "Slack sidebar theme for: $COLOR_THEME"
    echo ""
    echo "    $SLACK_THEME"
    echo ""
    echo "  Apply: Slack → Preferences → Themes → Colors → Custom theme → paste above"
    if command_exists pbcopy; then
        echo "$SLACK_THEME" | pbcopy
        print_success "Slack theme string copied to clipboard — paste and hit Enter in Slack"
    fi
else
    print_warning "Slack not found — skipping Slack theme"
fi

# =============================================================================
# 13. MACOS DEFAULTS
# =============================================================================
print_section "macOS Defaults"

if [[ "$(uname)" == "Darwin" ]] && (( ! UPDATE_ONLY )); then
    echo "Apply sensible macOS developer defaults?"
    echo "  • Fastest key repeat (no lag while holding a key)"
    echo "  • Tap-to-click on trackpad"
    echo "  • Dock: auto-hide, smaller icons, no recent apps"
    echo "  • Finder: show hidden files, all extensions, path bar"
    echo "  • Disable auto-correct / auto-capitalize / smart quotes"
    echo "  • Screenshots: PNG, no shadow, save to Desktop"
    echo "  • Expand save/print panels by default"
    echo "  • No .DS_Store files on network/USB volumes"
    echo ""
    if ask "Apply macOS defaults? [Y/n]" Y; then

        # Key repeat — fastest possible (feels like a proper keyboard)
        defaults write NSGlobalDomain KeyRepeat        -int 2
        defaults write NSGlobalDomain InitialKeyRepeat -int 15

        # Trackpad: tap-to-click
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
        defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

        # Dock
        defaults write com.apple.dock autohide                  -bool true
        defaults write com.apple.dock autohide-delay            -float 0
        defaults write com.apple.dock show-recents              -bool false
        defaults write com.apple.dock tilesize                  -int 48
        defaults write com.apple.dock minimize-to-application   -bool true
        killall Dock 2>/dev/null || true

        # Finder
        defaults write com.apple.finder AppleShowAllFiles              -bool true
        defaults write NSGlobalDomain   AppleShowAllExtensions         -bool true
        defaults write com.apple.finder ShowPathbar                    -bool true
        defaults write com.apple.finder ShowStatusBar                  -bool true
        defaults write com.apple.finder _FXSortFoldersFirst            -bool true
        defaults write com.apple.finder FXDefaultSearchScope           -string "SCcf"
        defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
        killall Finder 2>/dev/null || true

        # Screenshots
        defaults write com.apple.screencapture location       -string "$HOME/Desktop"
        defaults write com.apple.screencapture type           -string "png"
        defaults write com.apple.screencapture disable-shadow -bool true

        # Disable autocorrect / smart quotes / autocapitalize
        defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
        defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled     -bool false
        defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled   -bool false
        defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled  -bool false
        defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

        # Expand save/print panels by default
        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
        defaults write NSGlobalDomain PMPrintingExpandedStateForPrint    -bool true

        # No .DS_Store on network / USB
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        defaults write com.apple.desktopservices DSDontWriteUSBStores     -bool true

        print_success "macOS defaults applied (logout/reboot for all to take effect)"
    else
        print_warning "Skipping macOS defaults"
    fi
fi

# =============================================================================
# 14. POST-INSTALL
# =============================================================================
print_section "Post-install"

# Reload tmux config if a session is running (picks up new theme immediately)
if command_exists tmux && tmux list-sessions &>/dev/null; then
    tmux source-file ~/.tmux.conf 2>/dev/null && print_success "Tmux config reloaded (theme: $COLOR_THEME)"
fi

# Tmux auto-start — in update mode, leave existing setting alone.
if (( UPDATE_ONLY )) && [[ -f ~/.config/terminal-tmux-autostart ]]; then
    print_success "Tmux auto-start: keeping existing configuration"
    TMUX_AUTOSTART=skip
elif (( UPDATE_ONLY )); then
    TMUX_AUTOSTART=skip
else
    echo ""
    echo "Auto-start tmux when opening a new terminal?"
    echo "  1) No (launch tmux manually with: ts, tmux)"
    echo "  2) Attach to 'main' session (or create it)"
    echo "  3) Smart session — named after folder + k8s context (ts)"
    echo ""
    TMUX_AUTOSTART="$(ask_value "Pick [1/2/3] (default 1): " "1")"
fi

case "$TMUX_AUTOSTART" in
  2)
    cat > ~/.config/terminal-tmux-autostart <<'TMUXEOF'
# Auto-start tmux — attach to 'main' or create it
if [[ -z "$TMUX" ]] && [[ -z "$VSCODE_INJECTION" ]] && [[ -z "$CURSOR_TRACE_ID" ]] && [[ -o interactive ]]; then
  tmux attach -t main 2>/dev/null || tmux new-session -s main
fi
TMUXEOF
    print_success "Tmux auto-start: will attach/create 'main' session"
    ;;
  3)
    cat > ~/.config/terminal-tmux-autostart <<'TMUXEOF'
# Auto-start tmux — smart session named after folder + k8s context
if [[ -z "$TMUX" ]] && [[ -z "$VSCODE_INJECTION" ]] && [[ -z "$CURSOR_TRACE_ID" ]] && [[ -o interactive ]]; then
  ts
fi
TMUXEOF
    print_success "Tmux auto-start: smart session (ts)"
    ;;
  skip)
    : ;;  # keep existing setting (update mode)
  *)
    rm -f ~/.config/terminal-tmux-autostart
    print_status "Tmux auto-start: disabled (run 'ts' or 'tmux' manually)"
    ;;
esac

# Podman machine — initialize and start if podman is installed but no machine exists
if (( ! UPDATE_ONLY )) && command_exists podman; then
    if ! podman machine list --format '{{.Name}}' 2>/dev/null | grep -q .; then
        print_status "Initializing Podman machine (one-time setup, downloads ~700MB)..."
        if ask "Initialize Podman machine now? [Y/n]" Y; then
            podman machine init  && print_success "Podman machine initialized" || print_warning "podman machine init failed"
            podman machine start && print_success "Podman machine started"     || print_warning "podman machine start failed"
        else
            print_warning "Skipping — run later: podman machine init && podman machine start"
        fi
    else
        PODMAN_STATE=$(podman machine list --format '{{.LastUp}}' 2>/dev/null | head -1)
        print_success "Podman machine exists ($PODMAN_STATE)"
    fi
fi

# =============================================================================
# 15. HEALTH CHECK
# =============================================================================
print_section "Health Check"

echo "Running post-install verification..."
bash "$SCRIPT_DIR/tests/check.sh" --repo-only || true
echo ""
print_status "Run 'bash tests/check.sh' any time to verify installed tools."

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "   ${GREEN}${BOLD}Bootstrap Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. If Ghostty was already running, it was just reloaded automatically."
echo "     First launch (or if that didn't take): Cmd+Shift+, to reload."
echo "  2. Reload shell:  source ~/.zshrc"
echo "  3. Run 'nvim'  — lazy.nvim auto-installs plugins on first launch"
echo ""
echo "Color pair: $THEME_DARK ↔ $THEME_LIGHT  (auto-switches with macOS appearance)"
echo "  To change:  theme-switch <n|key>       (fast — only touches theme files)"
echo "              theme-switch                (interactive menu)"
echo "              theme-switch --list         (all pairs)"
echo "    Number 1-15 or key: catppuccin, catppuccin-macchiato, catppuccin-frappe,"
echo "                        tokyo-night, tokyo-night-storm, tokyo-night-moon,"
echo "                        rose-pine, rose-pine-moon, dracula,"
echo "                        solarized, gruvbox, everforest, kanagawa, github, nord"
echo ""
echo "Tmux mouse mode: $TMUX_MOUSE_CHOICE"
echo "  To flip later: cp ~/.config/tmux/extras/mouse-<on|off>.conf ~/.config/tmux-mouse.conf"
echo "                 tmux source ~/.tmux.conf"
echo ""
echo "History (powered by atuin — syncs across work + home laptop):"
echo "  atuin register    — create an account for cross-machine sync"
echo "  atuin login       — log in on another machine"
echo "  Ctrl+R            — open atuin fuzzy history search"
echo ""
echo "Useful commands:"
echo "  ts / tsp          — smart tmux session / fzf session picker"
echo "  tsk CLUSTER       — tmux session with isolated KUBECONFIG"
echo "  tka               — kill ALL tmux sessions (asks first)"
echo "  th / vh           — Tmux / Vim cheatsheets"
echo "  kk                — k9s (Kubernetes TUI)"
echo "  kctx / kns        — switch k8s context / namespace"
echo "  lg                — lazygit TUI"
echo ""
echo "Modern CLI (auto-aliased when installed):"
echo "  cat→bat  ls→eza  grep→rg  find→fd  top→btop  df→duf  du→dust  diff→delta"
echo ""
