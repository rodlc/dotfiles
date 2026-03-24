#!/bin/bash
# Shared functions for bw-* scripts

ENV_FILE="$HOME/.env"
BW_ITEM_SECRETS="Dotfiles Env"

# Source env for overridable config
source "$HOME/.env" 2>/dev/null || true

# SSH keys: parallel arrays (BW item name → local file path)
# Override names via ~/.env: SSH_BW_NAME_RODLC, SSH_BW_NAME_RODLCMAGIC
SSH_BW_NAMES=("${SSH_BW_NAME_RODLC:-SSH rodlc}")
SSH_LOCAL_PATHS=("$HOME/.ssh/id_ed25519_rodlc")
SSH_BW_NAMES+=("${SSH_BW_NAME_RODLCMAGIC:-SSH rodlcmagic}")
SSH_LOCAL_PATHS+=("$HOME/.ssh/id_ed25519_rodlcmagic")

ensure_rbw() {
    if ! rbw unlocked &>/dev/null; then
        echo "🔐 rbw locked. Unlocking..."
        rbw unlock
    fi
    rbw sync 2>/dev/null || true
}

# Fetch SSH private key from BW (SSH Key items → fallback Secure Notes)
# Returns: 0 on success, 1 if not found, 2 if multiple entries exist
get_ssh_key() {
    local err
    rbw get --field=private_key "$1" 2>/dev/null && return 0
    err=$(rbw get "$1" 2>&1) && { echo "$err"; return 0; }
    [[ "$err" == *"multiple entries"* ]] && return 2
    return 1
}

# Fetch SSH public key from BW SSH Key item
get_ssh_pub() {
    rbw get --field=public_key "$1" 2>/dev/null
}
