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

branch=$($TIMEOUT git -C "$path" symbolic-ref --short HEAD 2>/dev/null | head -1 || true)
[[ -n "$branch" ]] && printf '%s' "$branch"
exit 0
