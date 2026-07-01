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

bash -n "$REPO/bin/theme-switch" \
    && ok "bin/theme-switch" \
    || fail "bin/theme-switch has syntax errors"

bash -n "$REPO/lib/theme-lib.sh" \
    && ok "lib/theme-lib.sh" \
    || fail "lib/theme-lib.sh has syntax errors"

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
    # Tmux helper scripts — strict, no exceptions
    for s in "$REPO"/configs/tmux/scripts/*.sh; do
        shellcheck -S warning -s bash "$s" \
            && ok "${s##*/} shellcheck" \
            || fail "${s##*/} shellcheck warnings/errors"
    done
    # Test script itself. SC2088 disabled: we grep tmux.conf for literal `~/...`
    # paths (which are tmux's source-file directives, not shell expansions).
    shellcheck -S warning -s bash -e SC2088 "$REPO/tests/check.sh" \
        && ok "tests/check.sh shellcheck" \
        || fail "tests/check.sh shellcheck warnings/errors"
    # Theme wrapper + shared lib — strict.
    shellcheck -S warning -s bash "$REPO/bin/theme-switch" \
        && ok "bin/theme-switch shellcheck" \
        || fail "bin/theme-switch shellcheck warnings/errors"
    shellcheck -S warning -s bash "$REPO/lib/theme-lib.sh" \
        && ok "lib/theme-lib.sh shellcheck" \
        || fail "lib/theme-lib.sh shellcheck warnings/errors"
else
    skip "shellcheck not installed — brew install shellcheck"
fi

# ── 4. Required files exist ──────────────────────────────────────────────────
# Every file the installer copies must be present in the repo.
section "Required files"

REQUIRED_FILES=(
    configs/ghostty/config-base
    configs/zsh/zshrc
    configs/starship/starship.toml
    configs/p10k/p10k-starship-style.zsh
    configs/vim/vimrc
    configs/nvim/init.lua
    configs/tmux/tmux.conf
    configs/tmux/scripts/git-branch.sh
    configs/tmux/scripts/k8s-context.sh
    configs/tmux/extras/mouse-on.conf
    configs/tmux/extras/mouse-off.conf
    configs/tmux/tmux.local.conf.example
    configs/ssh/config-base
    configs/git/gitconfig
    configs/git/gitignore_global
    configs/cursor/settings-base.json
    configs/vscode/settings-base.json
    cheatsheets/tmux-cheatsheet.txt
    cheatsheets/vim-cheatsheet.txt
    bin/theme-switch
    lib/theme-lib.sh
)

for f in "${REQUIRED_FILES[@]}"; do
    [[ -f "$REPO/$f" ]] \
        && ok "$f" \
        || fail "$f is MISSING"
done

# Tmux helper scripts must be executable (status bar shells them out).
for s in configs/tmux/scripts/*.sh; do
    [[ -x "$REPO/$s" ]] \
        && ok "$s (executable)" \
        || fail "$s is NOT executable — chmod +x"
done

# theme-switch must be executable — deployed as a symlink, so if the source
# in-repo isn't +x, the deployed symlink won't be either.
[[ -x "$REPO/bin/theme-switch" ]] \
    && ok "bin/theme-switch (executable)" \
    || fail "bin/theme-switch is NOT executable — chmod +x"

# Every tmux theme file must define all the @color tokens used in tmux.conf.
section "Tmux theme tokens"

REQUIRED_TOKENS=(@bg @surface @text @subtle @muted @accent @accent2 @ok @warn @err @select)
for theme in "$REPO"/configs/tmux/themes/*.conf; do
    theme_name="${theme##*/}"
    missing=()
    for tok in "${REQUIRED_TOKENS[@]}"; do
        grep -qE "^set -g $tok " "$theme" || missing+=("$tok")
    done
    if (( ${#missing[@]} == 0 )); then
        ok "${theme_name} (all 11 tokens)"
    else
        fail "${theme_name} missing tokens: ${missing[*]}"
    fi
done

# tmux.conf should only reference helper scripts that we actually ship.
# Catches typos / stale paths after refactors.
section "Tmux script references"

while IFS= read -r script_ref; do
    script_name="${script_ref##*/}"
    if [[ -f "$REPO/configs/tmux/scripts/$script_name" ]]; then
        ok "tmux.conf -> scripts/$script_name"
    else
        fail "tmux.conf references missing script: $script_ref"
    fi
done < <(grep -oE '~/.config/tmux/scripts/[a-zA-Z0-9_-]+\.sh' "$REPO/configs/tmux/tmux.conf" | sort -u)

# tmux.conf must source the split-out theme + mouse files so the install.sh
# choices actually take effect.
section "Tmux source-file directives"

for required in "~/.config/tmux-theme.conf" "~/.config/tmux-mouse.conf"; do
    if grep -qF "source-file -q $required" "$REPO/configs/tmux/tmux.conf"; then
        ok "tmux.conf sources $required"
    else
        fail "tmux.conf is missing: source-file -q $required"
    fi
done

# Cursor + VS Code settings-base.json placeholders must each have a matching
# sed `-e "s|__NAME__|...|"` line in the tree. Catches the "added a new
# __PLACEHOLDER__ but forgot to substitute it" class of bug, which would ship
# a broken JSON file to users. The substitution has moved from install.sh into
# `render_vscode_settings` in lib/theme-lib.sh, so we grep both.
section "Cursor/VSCode settings placeholders"

for tmpl in configs/cursor/settings-base.json configs/vscode/settings-base.json; do
    while IFS= read -r placeholder; do
        if grep -qF "s|$placeholder|" "$REPO/install.sh" \
        || grep -qF "s|$placeholder|" "$REPO/lib/theme-lib.sh"; then
            ok "$tmpl uses $placeholder (substituted)"
        else
            fail "$tmpl uses $placeholder but no sed substitution found (install.sh + lib/theme-lib.sh)"
        fi
    done < <(grep -oE '__[A-Z_]+__' "$REPO/$tmpl" | sort -u)
done

# Each theme name picked by the theme resolver (THEME_DARK/THEME_LIGHT in
# `theme_choice_to_pair`) must have matching theme files in ghostty/tmux/nvim.
# Catches "added a new pair but forgot one of the theme files" the moment the
# resolver references something we don't ship. Now lives in lib/theme-lib.sh.
section "Theme files referenced by theme_choice_to_pair"

THEME_NAMES=$(grep -oE 'THEME_(DARK|LIGHT)=[a-z-]+' "$REPO/lib/theme-lib.sh" \
              | sed -E 's|THEME_(DARK\|LIGHT)=||' \
              | sort -u)
for tn in $THEME_NAMES; do
    [[ -z "$tn" ]] && continue
    miss=()
    [[ -f "$REPO/configs/ghostty/themes/$tn"           ]] || miss+=("ghostty")
    [[ -f "$REPO/configs/tmux/themes/$tn.conf"         ]] || miss+=("tmux")
    [[ -f "$REPO/configs/nvim/themes/$tn.lua"          ]] || miss+=("nvim")
    if (( ${#miss[@]} == 0 )); then
        ok "theme files present for: $tn"
    else
        fail "theme '$tn' missing: ${miss[*]} (referenced from lib/theme-lib.sh)"
    fi
done

# Sanity check: THEME_LIB_MAX_CHOICE must match the highest numbered case in
# theme_choice_to_pair. Catches "bumped the case block but forgot the constant".
section "Theme choice bounds"

MAX_IN_LIB=$(grep -E '^THEME_LIB_MAX_CHOICE=' "$REPO/lib/theme-lib.sh" \
             | head -1 | sed 's/^THEME_LIB_MAX_CHOICE=//' | tr -d '"')
# Extract the highest N from `    N) THEME_DARK=... ; THEME_LIGHT=...` lines
# in the theme_choice_to_pair function. The default (*) fallback is skipped.
HIGHEST_CASE=$(awk '
    /^theme_choice_to_pair\(\)/ { in_fn = 1 }
    in_fn && /^\}/               { in_fn = 0 }
    in_fn && /^[[:space:]]+[0-9]+\)/ {
        gsub(/[^0-9]/, "", $1)
        if ($1 + 0 > max) max = $1 + 0
    }
    END { print max }
' "$REPO/lib/theme-lib.sh")
if [[ -n "$MAX_IN_LIB" && -n "$HIGHEST_CASE" && "$MAX_IN_LIB" == "$HIGHEST_CASE" ]]; then
    ok "THEME_LIB_MAX_CHOICE=$MAX_IN_LIB matches highest case in theme_choice_to_pair"
else
    fail "THEME_LIB_MAX_CHOICE=$MAX_IN_LIB but highest case is $HIGHEST_CASE — bump one to match"
fi

# Regression guard: qufiwefefwoyn.kanagawa looked like the "obvious" VS Code
# port of kanagawa.nvim (it's what the neovim plugin's own README points to),
# but it's dark-only AND unavailable through Cursor's Open VSX-backed
# marketplace (`cursor --install-extension` reports "not found"). The pair
# silently fell back to whatever theme was already active — exactly the "many
# pairs aren't working" bug this caught. metaphore.kanagawa-vscode-color-theme
# is the correct id (ships Wave/Dragon/Lotus, installs fine on both editors).
section "Known-bad extension ids"

if grep -q 'VS_EXT="qufiwefefwoyn.kanagawa"' "$REPO/lib/theme-lib.sh"; then
    fail "lib/theme-lib.sh sets VS_EXT to qufiwefefwoyn.kanagawa (unavailable in Cursor's marketplace — use metaphore.kanagawa-vscode-color-theme)"
else
    ok "no VS_EXT=qufiwefefwoyn.kanagawa"
fi

# Regression guard: a `config-file = ~/.config/ghostty/config` redirect written
# into the macOS AppSupport config trips a known Ghostty bug
# (ghostty-org/ghostty#11323) — Ghostty always auto-loads BOTH the XDG config
# and the AppSupport config, so a redirect inside the latter makes it visit
# the XDG file twice in one pass and error "cycle detected". Fix: mirror the
# full rendered content instead (see ensure_ghostty_appsupport_shim).
if grep -q "shim_line='config-file = ~/.config/ghostty/config'" "$REPO/lib/theme-lib.sh"; then
    fail "lib/theme-lib.sh writes a config-file redirect into the Ghostty AppSupport config — this triggers Ghostty's 'cycle detected' error (ghostty-org/ghostty#11323); mirror full content instead"
else
    ok "no Ghostty AppSupport config-file redirect (avoids 'cycle detected' bug)"
fi

# Regression guard: ensure_ghostty_appsupport_shim must strip `config-file`
# lines from the mirrored content before writing it to the AppSupport path.
# Both XDG config and the AppSupport mirror are separately auto-loaded by
# Ghostty as top-level defaults; if BOTH still carried their own `config-file
# = ...config.local` include, config.local would be reached via two
# independent parents in one session — the same diamond shape behind the
# upstream cycle bug, just one level deeper (see prior check + CLAUDE.md).
if grep -A10 "^ensure_ghostty_appsupport_shim()" "$REPO/lib/theme-lib.sh" | grep -q "grep -v '\^config-file'"; then
    ok "ensure_ghostty_appsupport_shim strips config-file lines before mirroring"
else
    fail "ensure_ghostty_appsupport_shim no longer strips config-file lines from the AppSupport mirror — this can re-trigger Ghostty's 'cycle detected' bug via config.local being double-included"
fi

# Regression guard: gh-dash is a `gh` CLI extension (dlvhdr/gh-dash), not a
# Homebrew formula/cask. `brew install gh-dash` / `brew "gh-dash"` always
# fail with "No formulae or casks found for gh-dash".
if grep -qE '^\s*for f in [^#]*\bgh-dash\b' "$REPO/install.sh"; then
    fail "install.sh feeds gh-dash into a brew-install loop — it's a gh extension, not a formula (brew install gh-dash always fails)"
else
    ok "install.sh doesn't brew-install gh-dash"
fi
if grep -q '^brew "gh-dash"' "$REPO/Brewfile"; then
    fail "Brewfile lists gh-dash as a brew formula — it's a gh extension (brew bundle would fail on it)"
else
    ok "Brewfile doesn't list gh-dash as a brew formula"
fi
if grep -q 'gh extension install dlvhdr/gh-dash' "$REPO/install.sh"; then
    ok "install.sh installs gh-dash via gh extension install"
else
    fail "install.sh no longer installs gh-dash via 'gh extension install dlvhdr/gh-dash'"
fi

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
      # Search the whole --version banner (not just line 1): tools like eza
      # print a multi-line banner with the version number on line 2, and
      # `head -1` before the grep used to silently find nothing there. With
      # `set -e` + `pipefail` at the top of this script, that empty match
      # made the *entire* pipeline fail, which killed the whole test run
      # partway through with no error message. `|| true` guards the case
      # where a tool's output has no X.Y-shaped version string at all.
      ver=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)
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

  # Every VS_EXT id in vscode_theme_meta must actually be installed on this
  # machine, IF cursor/code are present. This is what would have caught the
  # Kanagawa bug directly: rendering settings.json with a theme name whose
  # extension was never installed doesn't error anywhere — Cursor/VS Code
  # just silently keep showing whatever theme was already active, which
  # looks exactly like "the switch didn't work". Skipped entirely (like the
  # tool checks above) when neither editor CLI is present.
  section "Theme extensions actually installed"

  VSCODE_EXT_IDS=$(grep -oE 'VS_EXT="[a-zA-Z0-9._-]+"' "$REPO/lib/theme-lib.sh" \
                   | sed -E 's/^VS_EXT="//; s/"$//' | sort -u)

  check_ext_installed() {
    local editor_cmd="$1" ext="$2" installed="$3"
    if printf '%s\n' "$installed" | grep -qiFx "$ext"; then
      ok "$editor_cmd: $ext installed"
    else
      fail "$editor_cmd: $ext NOT installed — run: $editor_cmd --install-extension $ext"
    fi
  }

  for editor_cmd in cursor code; do
    if command -v "$editor_cmd" &>/dev/null; then
      installed_list="$("$editor_cmd" --list-extensions 2>/dev/null || true)"
      for ext in $VSCODE_EXT_IDS; do
        [[ -z "$ext" ]] && continue
        check_ext_installed "$editor_cmd" "$ext" "$installed_list"
      done
    else
      skip "$editor_cmd theme extensions (CLI not found)"
    fi
  done

  # theme-switch is deployed as a symlink into ~/.local/bin. Verify it (a) exists
  # and (b) points at the repo we're running from — a stale symlink to a moved
  # repo path would silently fail.
  TS_LINK="$HOME/.local/bin/theme-switch"
  if [[ -L "$TS_LINK" ]]; then
    TS_TARGET="$(readlink "$TS_LINK")"
    if [[ -x "$TS_TARGET" ]]; then
        ok "~/.local/bin/theme-switch → $TS_TARGET"
    else
        fail "~/.local/bin/theme-switch → $TS_TARGET (target not executable/missing)"
    fi
  elif [[ -x "$TS_LINK" ]]; then
    ok "~/.local/bin/theme-switch (regular file, executable)"
  else
    fail "~/.local/bin/theme-switch missing — run ./install.sh"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "────────────────────────────────────────────"
printf "  Passed: %d   Failed: %d\n" "$PASS" "$FAIL"
echo "────────────────────────────────────────────"

[[ $FAIL -eq 0 ]]
