#!/usr/bin/env bash
#
# k8s-context.sh — print shortened current kubectl context for tmux status bar.
#
# Mirror of _shorten_k8s_context() in configs/zsh/zshrc. Keep the two in sync.
# Used by status-right in tmux.conf. Output is plain text (no newline).
#
# Caches the result for $CACHE_AGE seconds in a per-user tmpfile so the tmux
# status bar doesn't shell out to kubectl on every render interval.

set -u

CACHE_AGE=5
CACHE_FILE="${TMPDIR:-/tmp}/tmux-k8s-ctx.$(id -u)"

command -v kubectl >/dev/null 2>&1 || exit 0

if [[ -f "$CACHE_FILE" ]]; then
    mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    now=$(date +%s)
    if (( now - mtime < CACHE_AGE )); then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

if command -v timeout >/dev/null 2>&1; then
    raw=$(timeout 1 kubectl config current-context 2>/dev/null || true)
elif command -v gtimeout >/dev/null 2>&1; then
    raw=$(gtimeout 1 kubectl config current-context 2>/dev/null || true)
else
    raw=$(kubectl config current-context 2>/dev/null || true)
fi

if [[ -z "$raw" ]]; then
    : > "$CACHE_FILE"
    exit 0
fi

shorten() {
    local c="$1"

    if [[ "$c" =~ :cluster/([^/]+)$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"; return
    fi

    if [[ "$c" =~ ^gke_.*_([^_]+)$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"; return
    fi

    if [[ "$c" =~ ^api\.([^.]+)\. ]]; then
        printf '%s' "${BASH_REMATCH[1]}"; return
    fi

    if [[ "$c" =~ /api-([^:/]+) ]]; then
        local extracted="${BASH_REMATCH[1]}"
        extracted="${extracted%-com}"
        extracted="${extracted%-io}"
        extracted="${extracted%-org}"
        extracted="${extracted%-net}"
        printf '%s' "$extracted"; return
    fi

    if [[ "$c" =~ ^kubernetes-admin@(.+)$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"; return
    fi

    if [[ "$c" == "docker-desktop" ]]; then
        printf 'docker'; return
    fi

    # User-defined patterns at ~/.config/k8s-context-patterns
    #   Format per line: <substring> <display-name>
    if [[ -f "$HOME/.config/k8s-context-patterns" ]]; then
        local line pat rep
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
            pat="${line%% *}"
            rep="${line#* }"
            if [[ "$c" == *"$pat"* ]]; then
                printf '%s' "$rep"; return
            fi
        done < "$HOME/.config/k8s-context-patterns"
    fi

    if (( ${#c} > 25 )); then
        printf '%s' "${c:0:22}..."
    else
        printf '%s' "$c"
    fi
}

short=$(shorten "$raw")
printf '%s' "$short" > "$CACHE_FILE"
printf '%s' "$short"
