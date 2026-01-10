#!/bin/bash
#
# git-fetch-background.sh - Background git fetch for MOTD
#
# Runs async git fetches with timeout and updates cache files
# Only runs if SSH agent has keys loaded

set -euo pipefail
set +m  # Disable job control (no job completion messages)

CACHE_DIR="$HOME/.cache"
mkdir -p "$CACHE_DIR"

# Only proceed if SSH agent has keys
if ! ssh-add -l &>/dev/null; then
    exit 0
fi

# Fetch and check repo status
check_and_cache_repo() {
    local repo_path="$1"
    local repo_name="$2"
    local alias_push="$3"
    local alias_pull="$4"

    [[ ! -d "$repo_path/.git" ]] && return 0

    local cache_file="$CACHE_DIR/git-status-$repo_name"

    (
        cd "$repo_path" 2>/dev/null || exit

        # Fetch with timeout (no hang)
        timeout 3s git fetch origin main &>/dev/null || true

        local output=""

        # Check uncommitted changes
        if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
            output+="⚠️  $repo_name has uncommitted changes. Run: $alias_push"$'\n'
        fi

        # Check if behind remote
        local behind=$(git rev-list HEAD...origin/main --count 2>/dev/null)
        if [[ "$behind" != "0" && -n "$behind" ]]; then
            output+="🔄 $repo_name outdated ($behind commits). Run: $alias_pull"$'\n'
        fi

        # Write to cache atomically
        echo -n "$output" > "$cache_file.tmp"
        mv -f "$cache_file.tmp" "$cache_file"
    ) &
}

# Check dotfiles and workspace
check_and_cache_repo "$HOME/Code/rodlc/dotfiles" "Dotfiles" "df-push" "df-pull"
check_and_cache_repo "$HOME/Code/rodlc/workspace" "Workspace" "workspace-push" "workspace-pull"

# Wait for all background jobs
wait
