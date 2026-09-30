#!/bin/bash
# Shared functions for bw-* scripts

ENV_FILE="$HOME/.env"
BW_ITEM_SECRETS="Dotfiles Env"

# Source env for overridable config
source "$HOME/.env" 2>/dev/null || true

ensure_rbw() {
    if ! rbw unlocked &>/dev/null; then
        echo "🔐 rbw locked. Unlocking..."
        rbw unlock
    fi
    local sync_err
    sync_err=$(rbw sync 2>&1) && return 0
    # rbw reports a revoked refresh token (invalid_grant) as a missing access_token JSON field
    if [[ "$sync_err" == *"access_token"* ]]; then
        echo "🔄 Bitwarden session revoked. Purging local cache and logging in again..."
        rbw purge && rbw login && sync_err=$(rbw sync 2>&1) && return 0
    fi
    echo "⚠ rbw sync failed: $sync_err" >&2
    return 1
}
