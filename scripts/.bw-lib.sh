#!/bin/bash
# Shared functions for bw-* scripts

ENV_FILE="$HOME/.env"
BW_ITEM_SECRETS="Dotfiles Env"

ensure_unlocked_bw() {
    # Only for bw CLI (bootstrap, push)
    local status=$(bw status | jq -r .status)

    if [[ "$status" == "locked" ]]; then
        echo "🔐 Bitwarden locked. Unlocking..."
        export BW_SESSION=$(bw unlock --raw)
        if [[ $? -ne 0 ]]; then
            echo "❌ Unlock failed"
            exit 1
        fi
        echo "✅ Unlocked"
    elif [[ "$status" == "unauthenticated" ]]; then
        echo "❌ Not logged in. Run: bw login"
        exit 1
    fi
}

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
