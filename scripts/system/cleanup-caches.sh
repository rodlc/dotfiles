#!/bin/bash
# Cleanup script for macOS caches and temporary files
# Safe cleanup - preserves system-critical caches

set -e

# Update tracker timestamp
TRACKER_FILE="$(dirname "$0")/.cleanup-tracker"
echo "LAST_CLEANUP=$(date +%s)" > "$TRACKER_FILE"

echo "🧹 Starting cache cleanup..."
echo ""

# Calculate sizes before cleanup
before_size=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}')
echo "📊 Current cache size: $before_size"
echo ""

# User caches (safe to delete)
echo "🗑️  Cleaning user caches..."
if [ -d ~/Library/Caches ]; then
    # Clean browser caches (keep current session)
    find ~/Library/Caches -type d -name "*Brave*" -exec rm -rf {} + 2>/dev/null || true
    find ~/Library/Caches -type d -name "*Chrome*" -exec rm -rf {} + 2>/dev/null || true
    find ~/Library/Caches -type d -name "*Firefox*" -exec rm -rf {} + 2>/dev/null || true

    # Clean development caches
    rm -rf ~/Library/Caches/pip 2>/dev/null || true
    rm -rf ~/Library/Caches/yarn 2>/dev/null || true
    rm -rf ~/Library/Caches/npm 2>/dev/null || true
    rm -rf ~/Library/Caches/Homebrew 2>/dev/null || true

    # Clean general app caches (older than 30 days)
    find ~/Library/Caches -type f -mtime +30 -delete 2>/dev/null || true
fi

# Downloads cleanup (files older than 90 days)
echo "📥 Cleaning old downloads (>90 days)..."
if [ -d ~/Downloads ]; then
    find ~/Downloads -type f -mtime +90 -delete 2>/dev/null || true
fi

# Trash cleanup
echo "🗑️  Emptying trash..."
rm -rf ~/.Trash/* 2>/dev/null || true

# Homebrew cleanup
if command -v brew &>/dev/null; then
    echo "🍺 Running Homebrew cleanup..."
    brew cleanup -s 2>/dev/null || true
    brew autoremove 2>/dev/null || true
fi

# Docker cleanup (if installed)
if command -v docker &>/dev/null; then
    echo "🐳 Cleaning Docker..."
    docker system prune -af --volumes 2>/dev/null || true
fi

# Development artifacts cleanup
echo "🔧 Cleaning development artifacts..."
# Node modules in old projects (>180 days)
find ~/Code -type d -name "node_modules" -mtime +180 -exec rm -rf {} + 2>/dev/null || true

# Python cache
find ~/Code -type d -name "__pycache__" -delete 2>/dev/null || true
find ~/Code -type f -name "*.pyc" -delete 2>/dev/null || true

# Ruby cache
find ~/Code -type d -name ".bundle/cache" -exec rm -rf {} + 2>/dev/null || true

# Log files (keep last 30 days)
echo "📝 Cleaning old logs..."
find ~/Library/Logs -type f -mtime +30 -delete 2>/dev/null || true

# Calculate sizes after cleanup
after_size=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}')
echo ""
echo "✅ Cleanup complete!"
echo "📊 Cache size after: $after_size (was: $before_size)"
echo ""

# Show current disk usage
df -h ~ | tail -1 | awk '{print "💾 Disk usage: " $5 " (" $3 " used / " $2 " total)"}'
