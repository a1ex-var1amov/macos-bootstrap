#!/usr/bin/env bash
#
# git-branch.sh — print current git branch for a path, with a hard timeout.
#
# Called from tmux status-right. The timeout protects the status bar from
# freezing on slow filesystems (NFS, sshfs, slow disks).
#
# Usage: git-branch.sh [path]   (default: $PWD)

set -u

path="${1:-$PWD}"
[[ -d "$path" ]] || exit 0

if command -v timeout >/dev/null 2>&1; then
    TIMEOUT="timeout 1"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT="gtimeout 1"
else
    TIMEOUT=""
fi

# symbolic-ref handles normal branches. If we're on a detached HEAD (mid-rebase,
# checked out a tag, etc.) it returns nothing — fall back to a short SHA prefixed
# with `:` so the status bar still gives location feedback.
branch=$($TIMEOUT git -C "$path" symbolic-ref --short HEAD 2>/dev/null | head -1 || true)
if [[ -z "$branch" ]]; then
    sha=$($TIMEOUT git -C "$path" rev-parse --short HEAD 2>/dev/null || true)
    [[ -n "$sha" ]] && printf ':%s' "$sha"
else
    printf '%s' "$branch"
fi
exit 0
