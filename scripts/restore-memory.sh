#!/bin/bash
#
# MCP Memory Restore
# Restores latest daily backup from iCloud to ~/.claude/memory-chroma
#
# Usage: ./restore-memory.sh [backup-file]
# If no backup-file specified, uses latest daily backup

set -euo pipefail

MEMORY_DIR="$HOME/.claude/memory-chroma"
ICLOUD_BASE="$HOME/Library/Mobile Documents/com~apple~CloudDocs/MCPMemory"
DAILY_DIR="$ICLOUD_BASE/daily"

# Function to list available backups
list_backups() {
    echo "📋 Available backups:"
    echo ""
    echo "Daily backups:"
    ls -lht "$DAILY_DIR" 2>/dev/null | tail -n +2 | head -5 || echo "  (none)"
    echo ""
    echo "Weekly backups:"
    ls -lht "$ICLOUD_BASE/weekly" 2>/dev/null | tail -n +2 | head -3 || echo "  (none)"
    echo ""
    echo "Yearly backups:"
    ls -lht "$ICLOUD_BASE/yearly" 2>/dev/null | tail -n +2 | head -3 || echo "  (none)"
}

# Check if iCloud directory exists
if [[ ! -d "$DAILY_DIR" ]]; then
    echo "⚠️  iCloud backup directory not found: $DAILY_DIR"
    echo "Make sure iCloud sync is enabled and backups exist."
    exit 1
fi

# Get backup file
if [[ $# -eq 1 ]]; then
    BACKUP_FILE="$1"
    if [[ ! -f "$BACKUP_FILE" ]]; then
        echo "⚠️  Backup file not found: $BACKUP_FILE"
        list_backups
        exit 1
    fi
else
    # Use latest daily backup
    BACKUP_FILE=$(ls -1t "$DAILY_DIR" | head -1)
    if [[ -z "$BACKUP_FILE" ]]; then
        echo "⚠️  No daily backups found"
        list_backups
        exit 1
    fi
    BACKUP_FILE="$DAILY_DIR/$BACKUP_FILE"
fi

echo "📦 Restoring from: $(basename "$BACKUP_FILE")"

# Backup existing memory if it exists
if [[ -d "$MEMORY_DIR" ]]; then
    BACKUP_SUFFIX=$(date +%Y%m%d-%H%M%S)
    echo "⚠️  Existing memory directory found"
    echo "   Moving to: ${MEMORY_DIR}.bak-${BACKUP_SUFFIX}"
    mv "$MEMORY_DIR" "${MEMORY_DIR}.bak-${BACKUP_SUFFIX}"
fi

# Create parent directory
mkdir -p "$(dirname "$MEMORY_DIR")"

# Extract backup
echo "📂 Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$(dirname "$MEMORY_DIR")"

if [[ -d "$MEMORY_DIR" ]]; then
    MEMORY_SIZE=$(du -sh "$MEMORY_DIR" | cut -f1)
    echo "✅ Memory restored: $MEMORY_SIZE"
else
    echo "⚠️  Restore failed: memory directory not found after extraction"
    exit 1
fi
