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

ensure_unlocked_bw() {
    # DEPRECATED: Use ensure_rbw instead
    # Kept for backwards compatibility only
    if ! bw status 2>/dev/null | grep -q '"status":"unlocked"'; then
        echo "🔐 Bitwarden locked. Unlocking..."
        local session
        session=$(bw unlock --raw 2>&1)
        if [[ $? -ne 0 || -z "$session" ]]; then
            echo "❌ Unlock failed"
            return 1
        fi
        export BW_SESSION="$session"
    fi
    if ! bw sync > /dev/null 2>&1; then
        echo "❌ Sync failed"
        return 1
    fi
}

rbw_edit_notes() {
    # Edit notes of existing item using rbw
    # Usage: rbw_edit_notes "item_name" "content"
    local item_name="$1"
    local content="$2"
    local tmp=$(mktemp)

    # rbw format: line 1 = password (empty for notes), rest = notes
    printf '\n%s' "$content" > "$tmp"
    EDITOR="cp $tmp" rbw edit "$item_name" 2>/dev/null
    local result=$?
    rm -f "$tmp"
    rbw sync -q
    return $result
}

rbw_create_notes() {
    # Create new secure note item using rbw
    # Usage: rbw_create_notes "item_name" "content"
    local item_name="$1"
    local content="$2"
    local tmp=$(mktemp)

    # rbw format: line 1 = password (empty for notes), rest = notes
    printf '\n%s' "$content" > "$tmp"
    EDITOR="cp $tmp" rbw add "$item_name" 2>/dev/null
    local result=$?
    rm -f "$tmp"
    rbw sync -q
    return $result
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
