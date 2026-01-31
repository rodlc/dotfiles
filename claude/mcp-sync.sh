#!/bin/bash
# Sync MCP config between dotfiles and ~/.claude.json

set -e

DOTFILES_MCP="$HOME/Code/rodlc/dotfiles/claude/.mcp.json"
CLAUDE_JSON="$HOME/.claude.json"
BACKUP_DIR="$HOME/.claude/backups"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  install    Expand variables and merge mcpServers into ~/.claude.json
  export     Extract mcpServers from ~/.claude.json to dotfiles (replace paths with vars)
  diff       Compare dotfiles template vs active config

Examples:
  $(basename "$0") install   # Install MCPs from dotfiles
  $(basename "$0") export    # Export current MCPs to dotfiles
  $(basename "$0") diff      # Show differences
EOF
  exit 1
}

# Backup ~/.claude.json
backup() {
  mkdir -p "$BACKUP_DIR"
  if [ -f "$CLAUDE_JSON" ]; then
    local timestamp=$(date +%Y%m%d-%H%M%S)
    /bin/cp -f "$CLAUDE_JSON" "$BACKUP_DIR/claude.json.bak-$timestamp"
    echo "✓ Backup: $BACKUP_DIR/claude.json.bak-$timestamp"
  fi
}

# Install: expand variables and merge mcpServers into ~/.claude.json
install() {
  echo "=====> Installing MCPs from dotfiles"

  # Check dependencies
  command -v jq >/dev/null || { echo "Error: jq not installed"; exit 1; }
  command -v envsubst >/dev/null || { echo "Error: envsubst not installed"; exit 1; }

  # Load environment variables
  if [ -f "$HOME/.env" ]; then
    set -a
    source "$HOME/.env"
    set +a
  else
    echo "Warning: ~/.env not found, using shell env only"
  fi

  # Expand variables in template
  local expanded=$(envsubst < "$DOTFILES_MCP")
  local new_servers=$(echo "$expanded" | jq '.mcpServers')

  # Backup current config
  backup

  if [ -f "$CLAUDE_JSON" ]; then
    # Merge mcpServers into existing config
    jq --argjson servers "$new_servers" '.mcpServers = $servers' "$CLAUDE_JSON" > "${CLAUDE_JSON}.tmp"
    mv "${CLAUDE_JSON}.tmp" "$CLAUDE_JSON"
  else
    echo "Error: $CLAUDE_JSON not found"
    exit 1
  fi

  echo "✓ MCPs merged into $CLAUDE_JSON"
  echo "⚠  Restart Claude Code to apply changes"
}

# Export: extract mcpServers to dotfiles, replace paths with variables
export_config() {
  echo "=====> Exporting MCPs to dotfiles"

  # Read from ~/.claude.json
  if [ ! -f "$CLAUDE_JSON" ]; then
    echo "Error: $CLAUDE_JSON not found"
    exit 1
  fi

  local mcp_config=$(jq '.mcpServers' "$CLAUDE_JSON")

  # Replace paths with variables
  mcp_config=$(echo "$mcp_config" | sed \
    -e "s|$HOME|"'${HOME}|g' \
    -e "s|/Users/rodmagic/Code/rodlc/workspace|"'${WORKSPACE_DIR}|g')

  # Backup existing dotfiles template
  [ -f "$DOTFILES_MCP" ] && /bin/cp -f "$DOTFILES_MCP" "${DOTFILES_MCP}.bak"

  # Write to dotfiles
  echo "{\"mcpServers\": $mcp_config}" | jq '.' > "$DOTFILES_MCP"
  echo "✓ MCPs exported to $DOTFILES_MCP"
  echo "⚠  Review changes and commit to git"
}

# Diff: compare dotfiles vs active config
diff_config() {
  echo "=====> Comparing dotfiles vs active config"

  # Load env and expand template
  if [ -f "$HOME/.env" ]; then
    set -a
    source "$HOME/.env"
    set +a
  fi

  local expanded=$(envsubst < "$DOTFILES_MCP")

  if [ ! -f "$CLAUDE_JSON" ]; then
    echo "Error: $CLAUDE_JSON not found"
    exit 1
  fi

  # Pretty print and diff
  diff \
    <(echo "$expanded" | jq -S '.mcpServers') \
    <(jq -S '.mcpServers' "$CLAUDE_JSON") \
    || true
}

# Main
case "${1:-}" in
  install)
    install
    ;;
  export)
    export_config
    ;;
  diff)
    diff_config
    ;;
  *)
    usage
    ;;
esac
