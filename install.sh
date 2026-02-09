#!/bin/bash
#
# Terminal Config Installer
# Installs Ghostty, Zsh, Starship, Vim, and Tmux configurations
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Backup existing file
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_warning "Backed up $file to $backup"
    fi
}

echo ""
echo "========================================"
echo "   Terminal Config Installer"
echo "========================================"
echo ""

# =============================================================================
# Check and install dependencies
# =============================================================================
print_status "Checking dependencies..."

MISSING_DEPS=()

# Check for Homebrew (macOS)
if [[ "$(uname)" == "Darwin" ]]; then
    if ! command_exists brew; then
        print_error "Homebrew not found. Install from https://brew.sh"
        MISSING_DEPS+=("homebrew")
    fi
fi

# Check for required tools
for cmd in git zsh vim tmux; do
    if ! command_exists "$cmd"; then
        MISSING_DEPS+=("$cmd")
    fi
done

# Check for optional but recommended tools
OPTIONAL_CORE=()
for cmd in starship fzf zoxide; do
    if ! command_exists "$cmd"; then
        OPTIONAL_CORE+=("$cmd")
    fi
done

# Modern CLI replacements
OPTIONAL_CLI=()
for cmd in bat eza ripgrep fd git-delta btop jq yq ncdu duf tldr lazygit lazydocker; do
    # Map package names to command names
    case "$cmd" in
        ripgrep) cmd_check="rg" ;;
        git-delta) cmd_check="delta" ;;
        *) cmd_check="$cmd" ;;
    esac
    if ! command_exists "$cmd_check"; then
        OPTIONAL_CLI+=("$cmd")
    fi
done

# Kubernetes tools
OPTIONAL_K8S=()
for cmd in kubectl kubecolor k9s stern kubectx; do
    if ! command_exists "$cmd"; then
        OPTIONAL_K8S+=("$cmd")
    fi
done

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    print_error "Missing required dependencies: ${MISSING_DEPS[*]}"
    echo ""
    if [[ "$(uname)" == "Darwin" ]] && command_exists brew; then
        echo "Install with: brew install ${MISSING_DEPS[*]}"
    fi
    exit 1
fi

print_success "All required dependencies found"

if [[ ${#OPTIONAL_CORE[@]} -gt 0 ]]; then
    print_warning "Core tools not found: ${OPTIONAL_CORE[*]}"
    if [[ "$(uname)" == "Darwin" ]] && command_exists brew; then
        echo "         brew install ${OPTIONAL_CORE[*]}"
    fi
fi

if [[ ${#OPTIONAL_CLI[@]} -gt 0 ]]; then
    print_warning "Modern CLI tools not found: ${OPTIONAL_CLI[*]}"
    if [[ "$(uname)" == "Darwin" ]] && command_exists brew; then
        echo "         brew install ${OPTIONAL_CLI[*]}"
    fi
fi

if [[ ${#OPTIONAL_K8S[@]} -gt 0 ]]; then
    print_warning "Kubernetes tools not found: ${OPTIONAL_K8S[*]}"
    if [[ "$(uname)" == "Darwin" ]] && command_exists brew; then
        echo "         brew install ${OPTIONAL_K8S[*]}"
    fi
fi

# Check for Nerd Font
print_status "Checking for Nerd Font..."
if ! fc-list 2>/dev/null | grep -qi "nerd\|jetbrains"; then
    print_warning "JetBrainsMono Nerd Font not detected"
    if [[ "$(uname)" == "Darwin" ]] && command_exists brew; then
        echo "         Install with: brew install --cask font-jetbrains-mono-nerd-font"
    fi
fi

echo ""

# =============================================================================
# Offer to install missing tools
# =============================================================================
if [[ "$(uname)" == "Darwin" ]] && command_exists brew; then
    ALL_MISSING=("${OPTIONAL_CORE[@]}" "${OPTIONAL_CLI[@]}" "${OPTIONAL_K8S[@]}")
    
    if [[ ${#ALL_MISSING[@]} -gt 0 ]]; then
        echo ""
        read -p "Would you like to install missing tools with Homebrew? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installing tools..."
            
            if [[ ${#OPTIONAL_CORE[@]} -gt 0 ]]; then
                brew install "${OPTIONAL_CORE[@]}" || true
            fi
            
            if [[ ${#OPTIONAL_CLI[@]} -gt 0 ]]; then
                brew install "${OPTIONAL_CLI[@]}" || true
            fi
            
            if [[ ${#OPTIONAL_K8S[@]} -gt 0 ]]; then
                brew install "${OPTIONAL_K8S[@]}" || true
            fi
            
            # Check for font
            if ! fc-list 2>/dev/null | grep -qi "nerd\|jetbrains"; then
                brew install --cask font-jetbrains-mono-nerd-font || true
            fi
            
            print_success "Tools installed"
        fi
    fi
fi

echo ""

# =============================================================================
# Prompt choice: Starship vs Powerlevel10k (Starship-style)
# =============================================================================
PROMPT_ENGINE="starship"
if [[ -f "$HOME/.config/terminal-fix-prompt" ]]; then
    source "$HOME/.config/terminal-fix-prompt" 2>/dev/null || true
fi
echo ""
echo "Choose your prompt (same look: directory, git, k8s, langs, time):"
echo "  1) Starship  - cross-shell, minimal (default)"
echo "  2) Powerlevel10k (p10k) - Starship-style config, Zsh-only"
echo ""
read -p "Pick [1/2] (default 1): " -r PROMPT_CHOICE
PROMPT_CHOICE="${PROMPT_CHOICE:-1}"
if [[ "$PROMPT_CHOICE" == "2" ]]; then
    PROMPT_ENGINE="p10k"
    print_status "Will install Powerlevel10k with Starship-style config"
else
    PROMPT_ENGINE="starship"
    print_status "Will install Starship"
fi
mkdir -p ~/.config
echo "export PROMPT_ENGINE=$PROMPT_ENGINE" > ~/.config/terminal-fix-prompt
print_success "Prompt choice saved: $PROMPT_ENGINE"
echo ""

# =============================================================================
# Create directories
# =============================================================================
print_status "Creating directories..."

mkdir -p ~/.config/ghostty
mkdir -p ~/.config
mkdir -p ~/.vim/undo
mkdir -p ~/.zsh/themes

print_success "Directories created"

# =============================================================================
# Install configurations
# =============================================================================
print_status "Installing configurations..."

# Ghostty
backup_file ~/.config/ghostty/config
cp "$SCRIPT_DIR/configs/ghostty/config" ~/.config/ghostty/config
print_success "Ghostty config installed"

# Zsh
backup_file ~/.zshrc
cp "$SCRIPT_DIR/configs/zsh/zshrc" ~/.zshrc
print_success "Zsh config installed"

# Prompt: Starship or Powerlevel10k
if [[ "$PROMPT_ENGINE" == "p10k" ]]; then
    # Install Powerlevel10k theme if not present
    if [[ ! -d "$HOME/.zsh/themes/powerlevel10k" ]]; then
        print_status "Cloning Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.zsh/themes/powerlevel10k" 2>/dev/null && \
            print_success "Powerlevel10k cloned" || \
            print_warning "Could not clone Powerlevel10k - install manually: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/themes/powerlevel10k"
    else
        print_success "Powerlevel10k already present"
    fi
    backup_file ~/.p10k.zsh
    if [[ -f "$SCRIPT_DIR/configs/p10k/p10k-starship-style.zsh" ]]; then
        cp "$SCRIPT_DIR/configs/p10k/p10k-starship-style.zsh" ~/.p10k.zsh
        print_success "Powerlevel10k Starship-style config installed"
    else
        print_warning "p10k config not found at configs/p10k/p10k-starship-style.zsh - using default p10k (run p10k configure)"
    fi
else
    backup_file ~/.config/starship.toml
    cp "$SCRIPT_DIR/configs/starship/starship.toml" ~/.config/starship.toml
    print_success "Starship config installed"
fi

# Vim
backup_file ~/.vimrc
cp "$SCRIPT_DIR/configs/vim/vimrc" ~/.vimrc
print_success "Vim config installed"

# Tmux
backup_file ~/.tmux.conf
cp "$SCRIPT_DIR/configs/tmux/tmux.conf" ~/.tmux.conf
print_success "Tmux config installed"

# Cheatsheets
cp "$SCRIPT_DIR/cheatsheets/tmux-cheatsheet.txt" ~/.config/tmux-cheatsheet.txt
cp "$SCRIPT_DIR/cheatsheets/vim-cheatsheet.txt" ~/.config/vim-cheatsheet.txt
print_success "Cheatsheets installed"

# Git config (optional - for delta integration)
mkdir -p ~/.config/git
cp "$SCRIPT_DIR/configs/git/gitconfig" ~/.config/git/gitconfig
print_success "Git config installed (see instructions below to enable)"

# Cursor settings (optional)
CURSOR_SETTINGS_DIR="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$CURSOR_SETTINGS_DIR" ]]; then
    backup_file "$CURSOR_SETTINGS_DIR/settings.json"
    cp "$SCRIPT_DIR/configs/cursor/settings.json" "$CURSOR_SETTINGS_DIR/settings.json"
    print_success "Cursor settings installed"
else
    print_warning "Cursor settings dir not found - install Cursor first, then copy manually:"
    echo "         cp $SCRIPT_DIR/configs/cursor/settings.json ~/Library/Application\\ Support/Cursor/User/"
fi

echo ""

# =============================================================================
# Post-install
# =============================================================================
print_status "Running post-install tasks..."

# Reload tmux config if tmux is running
if command_exists tmux && tmux list-sessions &>/dev/null; then
    tmux source-file ~/.tmux.conf 2>/dev/null && print_success "Tmux config reloaded"
fi

echo ""
echo "========================================"
echo -e "   ${GREEN}Installation Complete!${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Restart Ghostty (or press Cmd+Shift+, to reload)"
echo "  2. Reload your shell: source ~/.zshrc"
echo "  3. Try the cheatsheets: th (tmux) or vh (vim)"
echo ""
echo "Useful commands:"
echo "  ts          - Smart tmux session (auto-named)"
echo "  tsp         - Pick tmux session with fzf"
echo "  th          - Tmux cheatsheet"
echo "  vh          - Vim cheatsheet"
echo "  kk          - k9s (Kubernetes TUI)"
echo "  kctx/kns    - Switch k8s context/namespace"
echo ""
echo "Modern CLI aliases (if tools installed):"
echo "  cat -> bat, ls -> eza, grep -> rg, find -> fd"
echo "  top -> btop, df -> duf, diff -> delta"
echo ""
echo "To enable git delta integration, add to ~/.gitconfig:"
echo '  [include]'
echo '      path = ~/.config/git/gitconfig'
echo ""
