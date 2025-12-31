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
  local timestamp=$(date +%Y%m%d-%H%M%S)
  /bin/cp -f "$CLAUDE_JSON" "$BACKUP_DIR/claude.json.bak-$timestamp"
  echo "✓ Backup: $BACKUP_DIR/claude.json.bak-$timestamp"
}

# Install: expand variables and merge into ~/.claude.json
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

  # Merge mcpServers into ~/.claude.json
  jq -s '.[0] * {mcpServers: .[1].mcpServers}' \
    "$CLAUDE_JSON" \
    <(echo "$expanded") \
    > "$CLAUDE_JSON.tmp"

  mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
  echo "✓ MCPs installed from dotfiles"
  echo "⚠  Restart Claude Code to apply changes"
}

# Export: extract mcpServers to dotfiles, replace paths with variables
export_config() {
  echo "=====> Exporting MCPs to dotfiles"

  # Extract mcpServers
  local mcp_config=$(jq '{mcpServers: .mcpServers}' "$CLAUDE_JSON")

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
  local active=$(jq '{mcpServers: .mcpServers}' "$CLAUDE_JSON")

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
