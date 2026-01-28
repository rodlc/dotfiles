#!/bin/zsh
# Cleanup script for old custom hooks replaced by mcp-memory-service hooks
# Run this after installing new hooks via install.sh

set -e

echo "=====> Cleaning up old custom hooks"

# Remove old custom hooks (replaced by mcp-memory-service)
OLD_HOOKS=(
  "$HOME/.claude/hooks/session-init.sh"
  "$HOME/.claude/hooks/user-prompt-context.sh"
)

for hook in "${OLD_HOOKS[@]}"; do
  if [ -L "$hook" ]; then
    echo "-----> Removing symlink: $hook"
    rm "$hook"
  elif [ -f "$hook" ]; then
    echo "-----> Backing up file: $hook"
    mv "$hook" "$hook.backup"
  fi
done

echo "-----> Old hooks cleaned up"
echo ""
echo "💡 New hooks installed by mcp-memory-service:"
echo "   - ~/.claude/hooks/core/session-start.js"
echo "   - ~/.claude/hooks/core/mid-conversation.js"
echo "   - ~/.claude/hooks/core/session-end.js"
echo "   - ~/.claude/hooks/core/auto-capture-hook.js"
