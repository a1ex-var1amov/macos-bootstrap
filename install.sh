#!/bin/bash
#
# macOS Bootstrap + Terminal Config Installer
# Installs Homebrew, CLI tools, GUI apps, dotfiles, and system defaults
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

print_status()  { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()   { echo -e "${RED}[-]${NC} $1"; }
print_section() { echo -e "\n${BOLD}${CYAN}── $1 ──────────────────────────────────────${NC}"; }

command_exists() { command -v "$1" &>/dev/null; }

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_warning "Backed up $file → $backup"
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
echo "════════════════════════════════════════════════════════"
echo ""

# =============================================================================
# 1. HOMEBREW
# =============================================================================
print_section "Homebrew"

if ! command_exists brew; then
    print_warning "Homebrew not found."
    read -p "Install Homebrew now? [Y/n] " -n 1 -r; echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
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

# =============================================================================
# 2. CLI TOOLS
# =============================================================================
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
MISSING_CLI=()
for f in bat eza ripgrep fd git-delta btop jq yq ncdu duf dust tldr lazygit lazydocker podman podman-compose; do
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
    read -p "Install all missing tools with Homebrew? [Y/n] " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
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
    read -p "Install JetBrainsMono Nerd Font? [Y/n] " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        brew install --cask font-jetbrains-mono-nerd-font && print_success "Nerd Font installed"
    fi
else
    print_success "Nerd Font found"
fi

# =============================================================================
# 3. GUI APPS (CASKS)
# =============================================================================
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
    read -p "Install via Homebrew Cask? [Y/n] " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
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

# =============================================================================
# 4. DEFAULT SHELL → ZSH
# =============================================================================
print_section "Default Shell"

# Prefer the brew-installed zsh (newer) over system /bin/zsh
BREW_ZSH="$(brew --prefix)/bin/zsh"
CURRENT_SHELL="$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')"

if [[ "$CURRENT_SHELL" != "$BREW_ZSH" && "$CURRENT_SHELL" != "/bin/zsh" ]]; then
    print_warning "Default shell is $CURRENT_SHELL"
    read -p "Change default shell to zsh? [Y/n] " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
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

# =============================================================================
# 5. ZPROFILE — Homebrew PATH for all shell contexts
# =============================================================================
# tmux panes start as non-login shells and won't read ~/.zprofile automatically.
# By sourcing ~/.zprofile from ~/.zshrc (if present), we ensure brew is always
# in PATH regardless of whether the shell is login or interactive.
print_section "Zsh Profile"

ZPROFILE="$HOME/.zprofile"
BREW_SHELLENV_LINE='eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null'
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
else
    print_warning "No SSH key found at $SSH_KEY"
    read -p "Generate a new SSH key (ed25519)? [Y/n] " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        read -p "Email for SSH key (default: git email): " SSH_EMAIL_INPUT
        SSH_EMAIL="${SSH_EMAIL_INPUT:-${GIT_EMAIL_INPUT:-${GIT_EMAIL:-$(git config --global user.email 2>/dev/null)}}}"
        if [[ -z "$SSH_EMAIL" ]]; then
            read -p "Email address: " SSH_EMAIL
        fi
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
        read -p "Press Enter once you've added it to GitHub..." -r
    fi
fi

# ~/.ssh/config — ensures key is auto-loaded from macOS keychain after reboot
SSH_CONFIG="$HOME/.ssh/config"
if [[ ! -f "$SSH_CONFIG" ]] || ! grep -q "UseKeychain" "$SSH_CONFIG" 2>/dev/null; then
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    cat >> "$SSH_CONFIG" <<'EOF'

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 "$SSH_CONFIG"
    print_success "~/.ssh/config created (keys persist across reboots)"
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
    print_warning "Git identity not configured"
    read -p "Your full name for git commits : " GIT_NAME_INPUT
    read -p "Your email for git commits     : " GIT_EMAIL_INPUT
    if [[ -n "$GIT_NAME_INPUT" && -n "$GIT_EMAIL_INPUT" ]]; then
        git config --global user.name  "$GIT_NAME_INPUT"
        git config --global user.email "$GIT_EMAIL_INPUT"
        print_success "Git identity set: $GIT_NAME_INPUT <$GIT_EMAIL_INPUT>"
    else
        print_warning "Skipped — set later: git config --global user.name/email"
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
echo "Choose your prompt (same look: directory, git, k8s, langs, time):"
echo "  1) Starship         — cross-shell, fast (default)"
echo "  2) Powerlevel10k    — Zsh-only, Starship-style config"
echo ""
read -p "Pick [1/2] (default 1): " -r PROMPT_CHOICE
PROMPT_CHOICE="${PROMPT_CHOICE:-1}"
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

COLOR_THEME="catppuccin-frappe"
if [[ -f "$HOME/.config/terminal-color-theme" ]]; then
    source "$HOME/.config/terminal-color-theme" 2>/dev/null || true
fi

echo "Choose your color scheme:"
echo ""
echo "  ── Catppuccin ──────────────────────────────────────────────────────"
echo "   1) Catppuccin Frappé     — cool purple-dark (default)"
echo "   2) Catppuccin Macchiato  — cool medium dark"
echo "   3) Catppuccin Mocha      — cool darkest dark"
echo "   4) Catppuccin Latte      — warm light"
echo ""
echo "  ── Tokyo Night ─────────────────────────────────────────────────────"
echo "   5) Tokyo Night           — deep blue-purple dark (Night)"
echo "   6) Tokyo Night Storm     — deep blue, slightly lighter"
echo "   7) Tokyo Night Moon      — muted purple-dark"
echo "   8) Tokyo Night Day       — clean light"
echo ""
echo "  ── Rosé Pine ───────────────────────────────────────────────────────"
echo "   9) Rosé Pine             — warm dark (Main)"
echo "  10) Rosé Pine Moon        — deep dark variant"
echo "  11) Rosé Pine Dawn        — warm light"
echo ""
echo "  ── Dracula ─────────────────────────────────────────────────────────"
echo "  18) Dracula               — classic dark purple"
echo "  19) Dracula Alucard       — official light warm-cream variant"
echo ""
echo "  ── Pairs: auto-switch with macOS appearance (Ghostty only) ─────────"
echo "  12) Catppuccin pair       — Mocha    ↔ Latte  (tmux/nvim: Mocha)"
echo "  13) Tokyo Night pair      — Night    ↔ Day    (tmux/nvim: Night)"
echo "  14) Tokyo Night Storm pair— Storm    ↔ Day    (tmux/nvim: Storm)"
echo "  15) Tokyo Night Moon pair — Moon     ↔ Day    (tmux/nvim: Moon)"
echo "  16) Rosé Pine pair        — Main     ↔ Dawn   (tmux/nvim: Main)"
echo "  17) Rosé Pine Moon pair   — Moon     ↔ Dawn   (tmux/nvim: Moon)"
echo "  20) Dracula pair          — Dracula  ↔ Alucard (tmux/nvim: Dracula)"
echo ""
read -p "Pick [1-20] (default 1): " -r COLOR_CHOICE
COLOR_CHOICE="${COLOR_CHOICE:-1}"

case "$COLOR_CHOICE" in
   2) COLOR_THEME="catppuccin-macchiato"  ; GHOSTTY_THEME="catppuccin-macchiato" ;;
   3) COLOR_THEME="catppuccin-mocha"      ; GHOSTTY_THEME="catppuccin-mocha" ;;
   4) COLOR_THEME="catppuccin-latte"      ; GHOSTTY_THEME="catppuccin-latte" ;;
   5) COLOR_THEME="tokyo-night"           ; GHOSTTY_THEME="tokyo-night" ;;
   6) COLOR_THEME="tokyo-night-storm"     ; GHOSTTY_THEME="tokyo-night-storm" ;;
   7) COLOR_THEME="tokyo-night-moon"      ; GHOSTTY_THEME="tokyo-night-moon" ;;
   8) COLOR_THEME="tokyo-night-day"       ; GHOSTTY_THEME="tokyo-night-day" ;;
   9) COLOR_THEME="rose-pine"             ; GHOSTTY_THEME="rose-pine" ;;
  10) COLOR_THEME="rose-pine-moon"        ; GHOSTTY_THEME="rose-pine-moon" ;;
  11) COLOR_THEME="rose-pine-dawn"        ; GHOSTTY_THEME="rose-pine-dawn" ;;
  12) COLOR_THEME="catppuccin-mocha"      ; GHOSTTY_THEME="dark:catppuccin-mocha,light:catppuccin-latte" ;;
  13) COLOR_THEME="tokyo-night"           ; GHOSTTY_THEME="dark:tokyo-night,light:tokyo-night-day" ;;
  14) COLOR_THEME="tokyo-night-storm"     ; GHOSTTY_THEME="dark:tokyo-night-storm,light:tokyo-night-day" ;;
  15) COLOR_THEME="tokyo-night-moon"      ; GHOSTTY_THEME="dark:tokyo-night-moon,light:tokyo-night-day" ;;
  16) COLOR_THEME="rose-pine"             ; GHOSTTY_THEME="dark:rose-pine,light:rose-pine-dawn" ;;
  17) COLOR_THEME="rose-pine-moon"        ; GHOSTTY_THEME="dark:rose-pine-moon,light:rose-pine-dawn" ;;
  18) COLOR_THEME="dracula"               ; GHOSTTY_THEME="dracula" ;;
  19) COLOR_THEME="dracula-alucard"       ; GHOSTTY_THEME="dracula-alucard" ;;
  20) COLOR_THEME="dracula"               ; GHOSTTY_THEME="dark:dracula,light:dracula-alucard" ;;
   *) COLOR_THEME="catppuccin-frappe"     ; GHOSTTY_THEME="catppuccin-frappe" ;;
esac

echo "export COLOR_THEME=$COLOR_THEME" > ~/.config/terminal-color-theme
print_success "Color scheme: $COLOR_THEME (Ghostty: $GHOSTTY_THEME)"

# Derive VS Code theme name, icon theme, extra extension, border color, and Slack sidebar string
case "$COLOR_THEME" in
  catppuccin-frappe)
    VSCODE_COLOR_THEME="Catppuccin Frappé"
    VSCODE_ICON_THEME="catppuccin-frappe"
    VSCODE_THEME_EXT=""
    VSCODE_BORDER_COLOR="#51576d"
    SLACK_THEME="#303446,#292c3c,#8caaee,#303446,#414559,#c6d0f5,#a6d189,#e78284"
    ;;
  catppuccin-macchiato)
    VSCODE_COLOR_THEME="Catppuccin Macchiato"
    VSCODE_ICON_THEME="catppuccin-macchiato"
    VSCODE_THEME_EXT=""
    VSCODE_BORDER_COLOR="#5b6078"
    SLACK_THEME="#24273a,#1e2030,#8aadf4,#24273a,#363a4f,#cad3f5,#a6da95,#ed8796"
    ;;
  catppuccin-mocha)
    VSCODE_COLOR_THEME="Catppuccin Mocha"
    VSCODE_ICON_THEME="catppuccin-mocha"
    VSCODE_THEME_EXT=""
    VSCODE_BORDER_COLOR="#585b70"
    SLACK_THEME="#1e1e2e,#181825,#89b4fa,#1e1e2e,#313244,#cdd6f4,#a6e3a1,#f38ba8"
    ;;
  catppuccin-latte)
    VSCODE_COLOR_THEME="Catppuccin Latte"
    VSCODE_ICON_THEME="catppuccin-latte"
    VSCODE_THEME_EXT=""
    VSCODE_BORDER_COLOR="#9ca0b0"
    SLACK_THEME="#eff1f5,#e6e9ef,#1e66f5,#eff1f5,#ccd0da,#4c4f69,#40a02b,#d20f39"
    ;;
  tokyo-night)
    VSCODE_COLOR_THEME="Tokyo Night"
    VSCODE_ICON_THEME="catppuccin-mocha"
    VSCODE_THEME_EXT="enkia.tokyo-night"
    VSCODE_BORDER_COLOR="#414868"
    SLACK_THEME="#1a1b26,#16161e,#7aa2f7,#c0caf5,#24283b,#c0caf5,#9ece6a,#f7768e"
    ;;
  tokyo-night-storm)
    VSCODE_COLOR_THEME="Tokyo Night Storm"
    VSCODE_ICON_THEME="catppuccin-mocha"
    VSCODE_THEME_EXT="enkia.tokyo-night"
    VSCODE_BORDER_COLOR="#3b4261"
    SLACK_THEME="#24283b,#1f2335,#7aa2f7,#c0caf5,#292e42,#c0caf5,#9ece6a,#f7768e"
    ;;
  tokyo-night-moon)
    VSCODE_COLOR_THEME="Tokyo Night"
    VSCODE_ICON_THEME="catppuccin-mocha"
    VSCODE_THEME_EXT="enkia.tokyo-night"
    VSCODE_BORDER_COLOR="#444a73"
    SLACK_THEME="#222436,#1e2030,#82aaff,#c8d3f5,#2d3f51,#c8d3f5,#c3e88d,#ff757f"
    ;;
  tokyo-night-day)
    VSCODE_COLOR_THEME="Tokyo Night Light"
    VSCODE_ICON_THEME="catppuccin-latte"
    VSCODE_THEME_EXT="enkia.tokyo-night"
    VSCODE_BORDER_COLOR="#a1a6c5"
    SLACK_THEME="#e1e2e7,#d5d6db,#2e7de9,#e1e2e7,#b6bfe2,#3760bf,#587539,#f52a65"
    ;;
  rose-pine)
    VSCODE_COLOR_THEME="Rosé Pine"
    VSCODE_ICON_THEME="catppuccin-mocha"
    VSCODE_THEME_EXT="mvllow.rose-pine"
    VSCODE_BORDER_COLOR="#403d52"
    SLACK_THEME="#191724,#16141f,#9ccfd8,#191724,#26233a,#e0def4,#31748f,#eb6f92"
    ;;
  rose-pine-moon)
    VSCODE_COLOR_THEME="Rosé Pine Moon"
    VSCODE_ICON_THEME="catppuccin-mocha"
    VSCODE_THEME_EXT="mvllow.rose-pine"
    VSCODE_BORDER_COLOR="#44415a"
    SLACK_THEME="#232136,#1f1d2e,#9ccfd8,#232136,#393552,#e0def4,#3e8fb0,#eb6f92"
    ;;
  rose-pine-dawn)
    VSCODE_COLOR_THEME="Rosé Pine Dawn"
    VSCODE_ICON_THEME="catppuccin-latte"
    VSCODE_THEME_EXT="mvllow.rose-pine"
    VSCODE_BORDER_COLOR="#dfdad9"
    SLACK_THEME="#faf4ed,#fffaf3,#286983,#faf4ed,#dfdad9,#575279,#56949f,#b4637a"
    ;;
  dracula)
    VSCODE_COLOR_THEME="Dracula"
    VSCODE_ICON_THEME="catppuccin-mocha"
    VSCODE_THEME_EXT="dracula-theme.theme-dracula"
    VSCODE_BORDER_COLOR="#44475a"
    SLACK_THEME="#282a36,#21222c,#bd93f9,#282a36,#44475a,#f8f8f2,#50fa7b,#ff5555"
    ;;
  dracula-alucard)
    VSCODE_COLOR_THEME="Dracula At Night"
    VSCODE_ICON_THEME="catppuccin-latte"
    VSCODE_THEME_EXT="dracula-theme.theme-dracula"
    VSCODE_BORDER_COLOR="#cfcfde"
    SLACK_THEME="#fffbeb,#f0ead8,#644ac9,#fffbeb,#cfcfde,#1f1f1f,#14710a,#cb3a2a"
    ;;
esac

# =============================================================================
# 11. DIRECTORIES
# =============================================================================
print_section "Directories"

mkdir -p ~/.config/ghostty/themes
mkdir -p ~/.config/nvim/lua
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

# Ghostty — install all theme files, then build config with chosen theme
for theme_file in "$SCRIPT_DIR/configs/ghostty/themes"/*; do
    cp "$theme_file" ~/.config/ghostty/themes/
done
backup_file ~/.config/ghostty/config
sed "s|^theme = .*|theme = $GHOSTTY_THEME|" \
    "$SCRIPT_DIR/configs/ghostty/config-base" > ~/.config/ghostty/config
print_success "Ghostty config (theme: $GHOSTTY_THEME)"

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

# Neovim — install init.lua + theme support files
backup_file ~/.config/nvim/init.lua
cp "$SCRIPT_DIR/configs/nvim/init.lua" ~/.config/nvim/init.lua
cp "$SCRIPT_DIR/configs/nvim/themes/theme_base.lua" ~/.config/nvim/lua/theme_base.lua
cp "$SCRIPT_DIR/configs/nvim/themes/${COLOR_THEME}.lua" ~/.config/nvim/lua/active_theme.lua
print_success "Neovim config + theme: $COLOR_THEME (run 'nvim' once to auto-install plugins)"

# Vim
backup_file ~/.vimrc
cp "$SCRIPT_DIR/configs/vim/vimrc" ~/.vimrc
print_success "Vim config"

# Tmux — install config + theme override file
backup_file ~/.tmux.conf
cp "$SCRIPT_DIR/configs/tmux/tmux.conf" ~/.tmux.conf
cp "$SCRIPT_DIR/configs/tmux/themes/${COLOR_THEME}.conf" ~/.config/tmux-theme.conf
print_success "Tmux config + theme: $COLOR_THEME"

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

# ── Cursor ──────────────────────────────────────────────────────────────────
CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$CURSOR_DIR" ]]; then
    backup_file "$CURSOR_DIR/settings.json"
    sed \
      -e "s|__VSCODE_COLOR_THEME__|$VSCODE_COLOR_THEME|g" \
      -e "s|__VSCODE_ICON_THEME__|$VSCODE_ICON_THEME|g" \
      -e "s|__VSCODE_BORDER_COLOR__|$VSCODE_BORDER_COLOR|g" \
      "$SCRIPT_DIR/configs/cursor/settings-base.json" > "$CURSOR_DIR/settings.json"
    print_success "Cursor settings (theme: $VSCODE_COLOR_THEME)"
    if command_exists cursor; then
        cursor --install-extension catppuccin.catppuccin-vsc       2>/dev/null && print_success "Cursor: Catppuccin theme ext"  || true
        cursor --install-extension catppuccin.catppuccin-vsc-icons 2>/dev/null && print_success "Cursor: Catppuccin icon ext"   || true
        [[ -n "$VSCODE_THEME_EXT" ]] && \
          cursor --install-extension "$VSCODE_THEME_EXT" 2>/dev/null && print_success "Cursor: $VSCODE_THEME_EXT" || true
    else
        print_warning "cursor CLI not in PATH — install extensions manually:"
        echo "  cursor --install-extension catppuccin.catppuccin-vsc"
        echo "  cursor --install-extension catppuccin.catppuccin-vsc-icons"
        [[ -n "$VSCODE_THEME_EXT" ]] && echo "  cursor --install-extension $VSCODE_THEME_EXT"
    fi
else
    print_warning "Cursor not found — skipping Cursor config"
fi

# ── VS Code ──────────────────────────────────────────────────────────────────
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_DIR" ]]; then
    backup_file "$VSCODE_DIR/settings.json"
    sed \
      -e "s|__VSCODE_COLOR_THEME__|$VSCODE_COLOR_THEME|g" \
      -e "s|__VSCODE_ICON_THEME__|$VSCODE_ICON_THEME|g" \
      -e "s|__VSCODE_BORDER_COLOR__|$VSCODE_BORDER_COLOR|g" \
      "$SCRIPT_DIR/configs/vscode/settings-base.json" > "$VSCODE_DIR/settings.json"
    print_success "VS Code settings (theme: $VSCODE_COLOR_THEME)"
    if command_exists code; then
        code --install-extension catppuccin.catppuccin-vsc                    2>/dev/null && print_success "VS Code: Catppuccin theme ext"  || true
        code --install-extension catppuccin.catppuccin-vsc-icons              2>/dev/null && print_success "VS Code: Catppuccin icon ext"   || true
        [[ -n "$VSCODE_THEME_EXT" ]] && \
          code --install-extension "$VSCODE_THEME_EXT"                        2>/dev/null && print_success "VS Code: $VSCODE_THEME_EXT"     || true
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

if [[ "$(uname)" == "Darwin" ]]; then
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
    read -p "Apply macOS defaults? [Y/n] " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then

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

# Podman machine — initialize and start if podman is installed but no machine exists
if command_exists podman; then
    if ! podman machine list --format '{{.Name}}' 2>/dev/null | grep -q .; then
        print_status "Initializing Podman machine (one-time setup, downloads ~700MB)..."
        read -p "Initialize Podman machine now? [Y/n] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
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

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "   ${GREEN}${BOLD}Bootstrap Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Restart Ghostty (or reload: Cmd+Shift+,)  ← picks up new theme"
echo "  2. Reload shell:  source ~/.zshrc"
echo "  3. Run 'nvim'  — lazy.nvim auto-installs plugins on first launch"
echo ""
echo "Color scheme: $COLOR_THEME"
echo "  To change: run ./install.sh again (section 10) or edit directly:"
echo "    Ghostty : ~/.config/ghostty/config  (theme = <name>)"
echo "    Tmux    : cp configs/tmux/themes/<name>.conf ~/.config/tmux-theme.conf && tmux source ~/.tmux.conf"
echo "    Neovim  : cp configs/nvim/themes/<name>.lua ~/.config/nvim/lua/active_theme.lua"
echo "  Available:
    Catppuccin : catppuccin-frappe  catppuccin-macchiato  catppuccin-mocha  catppuccin-latte
    Tokyo Night: tokyo-night  tokyo-night-storm  tokyo-night-moon  tokyo-night-day
    Rosé Pine  : rose-pine  rose-pine-moon  rose-pine-dawn"
echo ""
echo "History (powered by atuin — syncs across work + home laptop):"
echo "  atuin register    — create an account for cross-machine sync"
echo "  atuin login       — log in on another machine"
echo "  Ctrl+R            — open atuin fuzzy history search"
echo ""
echo "Useful commands:"
echo "  ts / tsp          — smart tmux session / fzf session picker"
echo "  th / vh           — Tmux / Vim cheatsheets"
echo "  kk                — k9s (Kubernetes TUI)"
echo "  kctx / kns        — switch k8s context / namespace"
echo "  lg                — lazygit TUI"
echo ""
echo "Modern CLI (auto-aliased when installed):"
echo "  cat→bat  ls→eza  grep→rg  find→fd  top→btop  df→duf  du→dust  diff→delta"
echo ""
