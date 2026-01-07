#!/bin/bash
#
# MCP Memory Backup with GFS Rotation
# Backs up ~/.claude/memory-chroma to iCloud with Grandfather-Father-Son rotation
#
# Rotation: 7 daily, 21 weekly, 6 yearly
# Schedule: Daily at 14:30 (via launchd)

set -euo pipefail

MEMORY_DIR="$HOME/.claude/memory-chroma"
ICLOUD_BASE="$HOME/Library/Mobile Documents/com~apple~CloudDocs/MCPMemory"
DAILY_DIR="$ICLOUD_BASE/daily"
WEEKLY_DIR="$ICLOUD_BASE/weekly"
YEARLY_DIR="$ICLOUD_BASE/yearly"

MAX_DAILY=7
MAX_WEEKLY=21
MAX_YEARLY=6

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DAY_OF_WEEK=$(date +%u)  # 1-7 (Monday-Sunday)
DAY_OF_MONTH=$(date +%d)

# Create directories
mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$YEARLY_DIR"

# Check if memory directory exists
if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "⚠️  Memory directory not found: $MEMORY_DIR"
    exit 1
fi

# Create daily backup
BACKUP_NAME="memory-backup-${TIMESTAMP}.tar.gz"
DAILY_BACKUP="$DAILY_DIR/$BACKUP_NAME"

echo "📦 Creating backup: $BACKUP_NAME"
tar -czf "$DAILY_BACKUP" -C "$(dirname "$MEMORY_DIR")" "$(basename "$MEMORY_DIR")"

BACKUP_SIZE=$(du -h "$DAILY_BACKUP" | cut -f1)
echo "✓ Backup created: $BACKUP_SIZE"

# Promotion logic
if [[ "$DAY_OF_WEEK" == "7" ]]; then
    # Sunday: promote to weekly
    echo "📅 Sunday: promoting to weekly backup"
    cp "$DAILY_BACKUP" "$WEEKLY_DIR/$BACKUP_NAME"
fi

if [[ "$DAY_OF_MONTH" == "01" ]]; then
    # First of month: promote to yearly
    echo "📅 First of month: promoting to yearly backup"
    cp "$DAILY_BACKUP" "$YEARLY_DIR/$BACKUP_NAME"
fi

# Cleanup old backups
cleanup_old_backups() {
    local dir=$1
    local max=$2
    local count=$(ls -1 "$dir" 2>/dev/null | wc -l | tr -d ' ')

    if [[ $count -gt $max ]]; then
        echo "🧹 Cleaning up $dir (keeping $max)"
        ls -1t "$dir" | tail -n +$((max + 1)) | xargs -I {} rm "$dir/{}"
    fi
}

cleanup_old_backups "$DAILY_DIR" "$MAX_DAILY"
cleanup_old_backups "$WEEKLY_DIR" "$MAX_WEEKLY"
cleanup_old_backups "$YEARLY_DIR" "$MAX_YEARLY"

echo "✅ Backup complete"
