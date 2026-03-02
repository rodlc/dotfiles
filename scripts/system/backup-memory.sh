#!/usr/bin/env bash
# Daily memory backup — wrapper for workspace/memory/sync-memory.sh export
# Called by launchd com.rodlecoent.memory-backup (daily 14:30)

set -euo pipefail

# Source environment first (may define WORKSPACE_DIR + GPG_PASSPHRASE)
if [[ -f "$HOME/.env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.env"
fi

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
SYNC_SCRIPT="$WORKSPACE_DIR/memory/sync-memory.sh"

# Validation
if [[ ! -d "$WORKSPACE_DIR" ]]; then
  echo "⚠️  Workspace not found: $WORKSPACE_DIR" >&2
  echo "Skipping backup (likely fresh system)" >&2
  exit 0
fi

if [[ ! -f "$SYNC_SCRIPT" ]]; then
  echo "⚠️  sync-memory.sh not found: $SYNC_SCRIPT" >&2
  exit 1
fi

if [[ -z "${GPG_PASSPHRASE:-}" ]]; then
  echo "⚠️  GPG_PASSPHRASE not set in ~/.env" >&2
  exit 1
fi

# Export memories
echo "🕐 $(date '+%Y-%m-%d %H:%M:%S') — Starting memory backup"
"$SYNC_SCRIPT" export
echo "✅ Backup complete"
