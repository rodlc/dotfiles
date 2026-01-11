#!/bin/bash
# Shared functions for bw-* scripts

ENV_FILE="$HOME/.env"
BW_ITEM_SECRETS="Dotfiles Env"
BW_ITEM_SSH="SSH Key"

ensure_rbw() {
    # Check rbw is unlocked (no action needed, just verify)
    if ! rbw unlocked &>/dev/null; then
        echo "🔐 rbw locked. Unlocking..."
        rbw unlock
    fi
}

check_freshness() {
    local marker="$HOME/.env.bw-synced"
    if [[ -f "$ENV_FILE" && -f "$marker" ]]; then
        if [[ "$ENV_FILE" -nt "$marker" ]]; then
            echo "⚠️  ~/.env modified locally since last sync"
            echo "   Use 'bw-push' to push to Bitwarden, or 'bw-pull --force' to overwrite"
            return 1
        fi
    fi
    return 0
}
