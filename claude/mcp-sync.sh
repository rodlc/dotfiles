#!/bin/bash
# Sync MCP config between dotfiles and ~/.claude.json

set -e

DOTFILES_MCP="$HOME/Code/rodlc/dotfiles/claude/.mcp.json"
CLAUDE_JSON="$HOME/.claude.json"
MCP_JSON="$HOME/.claude/mcp.json"
BACKUP_DIR="$HOME/.claude/backups"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  install    Expand variables and write to ~/.claude/mcp.json
  export     Extract mcpServers from ~/.claude/mcp.json to dotfiles (replace paths with vars)
  diff       Compare dotfiles template vs active config

Examples:
  $(basename "$0") install   # Install MCPs from dotfiles
  $(basename "$0") export    # Export current MCPs to dotfiles
  $(basename "$0") diff      # Show differences
EOF
  exit 1
}

# Backup ~/.claude/mcp.json
backup() {
  mkdir -p "$BACKUP_DIR"
  if [ -f "$MCP_JSON" ]; then
    local timestamp=$(date +%Y%m%d-%H%M%S)
    /bin/cp -f "$MCP_JSON" "$BACKUP_DIR/mcp.json.bak-$timestamp"
    echo "✓ Backup: $BACKUP_DIR/mcp.json.bak-$timestamp"
  fi
}

# Install: expand variables and write to ~/.claude/mcp.json
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

  # Backup current config
  backup

  # Ensure ~/.claude directory exists
  mkdir -p "$(dirname "$MCP_JSON")"

  # Write expanded config directly to ~/.claude/mcp.json
  echo "$expanded" | jq '.' > "$MCP_JSON"

  echo "✓ MCPs installed to $MCP_JSON"
  echo "⚠  Restart Claude Code to apply changes"
}

# Export: extract mcpServers to dotfiles, replace paths with variables
export_config() {
  echo "=====> Exporting MCPs to dotfiles"

  # Read from ~/.claude/mcp.json
  if [ ! -f "$MCP_JSON" ]; then
    echo "Error: $MCP_JSON not found"
    exit 1
  fi

  local mcp_config=$(jq '.' "$MCP_JSON")

  # Replace paths with variables
  mcp_config=$(echo "$mcp_config" | sed \
    -e "s|$HOME|"'${HOME}|g' \
    -e "s|/Users/rodlecoent|"'${HOME}|g' \
    -e "s|/Users/rodlecoent/Code|"'${CODE_DIR}|g')

  # Backup existing dotfiles template
  [ -f "$DOTFILES_MCP" ] && /bin/cp -f "$DOTFILES_MCP" "${DOTFILES_MCP}.bak"

  # Write to dotfiles
  echo "$mcp_config" | jq '.' > "$DOTFILES_MCP"
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

  if [ ! -f "$MCP_JSON" ]; then
    echo "Error: $MCP_JSON not found"
    exit 1
  fi

  local active=$(jq '.' "$MCP_JSON")

  # Pretty print and diff
  diff \
    <(echo "$expanded" | jq -S '.mcpServers') \
    <(echo "$active" | jq -S '.mcpServers') \
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
