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
