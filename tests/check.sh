#!/usr/bin/env bash
# tests/check.sh — sanity checks for the dotfiles repo
# Usage: bash tests/check.sh
#        Run from any directory; paths are resolved relative to the repo root.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

# ── helpers ──────────────────────────────────────────────────────────────────
ok()      { echo "  [ok] $1";   (( PASS++ )) || true; }
fail()    { echo "  [!!] $1";   (( FAIL++ )) || true; }
skip()    { echo "  [--] $1 (skipped)"; }
section() { echo; echo "── $1"; }

# ── 1. Bash syntax ───────────────────────────────────────────────────────────
section "Bash syntax"

bash -n "$REPO/install.sh" \
    && ok "install.sh" \
    || fail "install.sh has syntax errors"

bash -n "$REPO/tests/check.sh" \
    && ok "tests/check.sh" \
    || fail "tests/check.sh has syntax errors"

# ── 2. Zsh syntax ────────────────────────────────────────────────────────────
section "Zsh syntax"

if command -v zsh &>/dev/null; then
    zsh -n "$REPO/configs/zsh/zshrc" \
        && ok "configs/zsh/zshrc" \
        || fail "configs/zsh/zshrc has syntax errors"
else
    skip "configs/zsh/zshrc (zsh not installed)"
fi

# ── 3. Shellcheck ────────────────────────────────────────────────────────────
section "Shellcheck"

if command -v shellcheck &>/dev/null; then
    # SC2088: tilde-in-quotes — intentional in user-facing print strings
    shellcheck -S warning -s bash -e SC2088 "$REPO/install.sh" \
        && ok "install.sh shellcheck" \
        || fail "install.sh shellcheck warnings/errors"
else
    skip "shellcheck not installed — brew install shellcheck"
fi

# ── 4. Required files exist ──────────────────────────────────────────────────
# Every file the installer copies must be present in the repo.
section "Required files"

REQUIRED_FILES=(
    configs/ghostty/config
    configs/zsh/zshrc
    configs/starship/starship.toml
    configs/p10k/p10k-starship-style.zsh
    configs/vim/vimrc
    configs/nvim/init.lua
    configs/tmux/tmux.conf
    configs/git/gitconfig
    configs/git/gitignore_global
    configs/cursor/settings.json
    configs/vscode/settings.json
    cheatsheets/tmux-cheatsheet.txt
    cheatsheets/vim-cheatsheet.txt
)

for f in "${REQUIRED_FILES[@]}"; do
    [[ -f "$REPO/$f" ]] \
        && ok "$f" \
        || fail "$f is MISSING"
done

# ── 5. No personal / company-specific info ───────────────────────────────────
section "No personal info"

# Patterns that should never appear in tracked config files
PERSONAL_PATTERNS=(
    "nvpark"
    "sc-k8s-"
    "sc-hwinf-"
    "nvidia\.com"
    "rke2-dev"
    "rke2-prod"
)

for pattern in "${PERSONAL_PATTERNS[@]}"; do
    matches=$(grep -r --include="*.zsh" --include="*.sh" --include="*.conf" \
                      --include="*.toml" --include="*.lua" --include="*.json" \
                      --include="*.md" \
                      "$pattern" "$REPO/configs/" "$REPO/install.sh" "$REPO/README.md" \
                      2>/dev/null || true)
    if [[ -z "$matches" ]]; then
        ok "no '$pattern'"
    else
        fail "found '$pattern':"
        echo "$matches" | sed 's/^/       /'
    fi
done

# ── 6. install.sh references only files that exist ───────────────────────────
section "Installer file references"

# Extract every $SCRIPT_DIR/<path> from install.sh.
# Skip: paths with unresolved ${ variables, glob patterns (*/), and bare dirs.
while IFS= read -r relpath; do
    [[ -z "$relpath" ]]         && continue
    [[ "$relpath" == *'${'* ]]  && continue   # unresolved shell variable
    [[ "$relpath" == *'*'* ]]   && continue   # glob wildcard
    [[ -f "$REPO/$relpath" ]]   && ok "$relpath"   && continue
    [[ -d "$REPO/$relpath" ]]   && ok "$relpath (dir)" && continue
    fail "$relpath referenced in install.sh but MISSING from repo"
done < <(grep -oE '\$SCRIPT_DIR/[^"[:space:]]+' "$REPO/install.sh" \
            | sed 's|\$SCRIPT_DIR/||' \
            | sort -u)

# ── 7. Installed tool health check (skipped if --repo-only passed) ────────────
if [[ "${1:-}" != "--repo-only" ]]; then
  section "Installed tools"

  TOOLS_CLI=(
    "bat"    "bat"
    "eza"    "eza"
    "rg"     "ripgrep"
    "fd"     "fd"
    "delta"  "git-delta"
    "btop"   "btop"
    "jq"     "jq"
    "yq"     "yq"
    "fzf"    "fzf"
    "zoxide" "zoxide"
    "starship" "starship"
    "lazygit" "lazygit"
    "atuin"  "atuin"
    "nvim"   "neovim"
    "tmux"   "tmux"
    "gh"     "gh"
  )

  TOOLS_K8S=(
    "kubectl"  "kubectl"
    "k9s"      "k9s"
    "helm"     "helm"
    "kubectx"  "kubectx"
    "stern"    "stern"
    "kubecolor" "kubecolor"
  )

  check_tool() {
    local cmd="$1" pkg="$2"
    if command -v "$cmd" &>/dev/null; then
      local ver
      ver=$("$cmd" --version 2>&1 | head -1 | sed 's/[^0-9.]//g' | grep -oE '[0-9]+\.[0-9]+' | head -1)
      ok "$cmd${ver:+ ($ver)}"
    else
      fail "$cmd not found — brew install $pkg"
    fi
  }

  i=0
  while (( i < ${#TOOLS_CLI[@]} )); do
    check_tool "${TOOLS_CLI[$i]}" "${TOOLS_CLI[$((i+1))]}"
    (( i += 2 ))
  done

  section "Kubernetes tools"
  i=0
  while (( i < ${#TOOLS_K8S[@]} )); do
    check_tool "${TOOLS_K8S[$i]}" "${TOOLS_K8S[$((i+1))]}"
    (( i += 2 ))
  done

  section "Config files installed"
  INSTALLED_CONFIGS=(
    "$HOME/.zshrc"
    "$HOME/.tmux.conf"
    "$HOME/.config/ghostty/config"
    "$HOME/.config/starship.toml"
    "$HOME/.config/nvim/init.lua"
    "$HOME/.config/tmux-theme.conf"
    "$HOME/.config/nvim/lua/active_theme.lua"
    "$HOME/.config/git/gitconfig"
  )
  for f in "${INSTALLED_CONFIGS[@]}"; do
    [[ -f "$f" ]] \
      && ok "${f/#$HOME/~}" \
      || fail "${f/#$HOME/~} is MISSING — run ./install.sh"
  done
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "────────────────────────────────────────────"
printf "  Passed: %d   Failed: %d\n" "$PASS" "$FAIL"
echo "────────────────────────────────────────────"

[[ $FAIL -eq 0 ]]
