#!/bin/bash
# Shared functions for bw-* scripts

ENV_FILE="$HOME/.env"
BW_ITEM_SECRETS="Dotfiles Env"

# SSH keys: parallel arrays (BW item name → local file path)
SSH_BW_NAMES=("SSH rodlc")
SSH_LOCAL_PATHS=("$HOME/.ssh/id_ed25519_rodlc")
# SSH_BW_NAMES+=("SSH rodmagic")
# SSH_LOCAL_PATHS+=("$HOME/.ssh/id_ed25519_rodmagic")

ensure_rbw() {
    if ! rbw unlocked &>/dev/null; then
        echo "🔐 rbw locked. Unlocking..."
        rbw unlock
    fi
}
