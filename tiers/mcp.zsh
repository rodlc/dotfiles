install_mcp() {
  WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
  # envsubst only sees exported variables
  set -a; source "$HOME/.env" 2>/dev/null; set +a

  # Verify workspace exists
  if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "⚠️  Workspace not found. Run: ./install.sh workspace"
    return 1
  fi

  # Build MCP servers
  echo "=====> Building MCP servers"
  if [ ! -x "$WORKSPACE_DIR/claude-config/scripts/install-mcp-servers.sh" ]; then
    echo "✗ install-mcp-servers.sh not found in $WORKSPACE_DIR/claude-config/scripts"
    return 1
  fi
  "$WORKSPACE_DIR/claude-config/scripts/install-mcp-servers.sh"

  ensure_machine_role
  local role_file="$DOTFILES_ROLE_FILE"
  local role=$(<"$role_file")
  echo "-----> Machine role: $role (change: edit $role_file)"

  # Configure MCPs (expand template → user scope of ~/.claude.json)
  echo "=====> Configuring MCP servers"
  local expanded=$(envsubst < "$WORKSPACE_DIR/.claude/mcp-template.json")
  for name in $(jq -r '.mcpServers | keys[]' <<< "$expanded"); do
    claude mcp remove --scope user "$name" &>/dev/null || true
    claude mcp add-json --scope user "$name" "$(jq -c --arg name "$name" '.mcpServers[$name]' <<< "$expanded")"
  done

  # Memory, typology and WhatsApp servers stay bound to loopback; Tailscale opens them to the tailnet only, no API key to spread
  if [[ "$role" == "reference" ]]; then
    local tailscale=/Applications/Tailscale.app/Contents/MacOS/Tailscale
    if "$tailscale" status &>/dev/null; then
      for port in 4242 4243 4244; do
        "$tailscale" serve --bg --tcp $port tcp://127.0.0.1:$port || echo "⚠️  tailscale serve failed on port $port"
      done
    else
      echo "⚠️  Tailscale not logged in: open Tailscale, log in, then rerun ./install.sh mcp"
    fi
  fi

  local launchd_failed=()
  install_launchd_services "$role"

  # Ollama
  if command -v ollama &>/dev/null; then
    echo "=====> Configuring Ollama"
    for model in qwen3:4b; do
      if ! ollama list 2>/dev/null | grep -q "$model"; then
        echo "-----> Pulling $model..."
        ollama pull "$model"
      else
        echo "-----> $model already present"
      fi
    done
  fi

  # Battery (Apple Silicon only)
  if [[ $(uname -m) == "arm64" ]] && command -v battery &> /dev/null; then
    echo "=====> Configuring Battery (charge limit)"
    if [ ! -f "$HOME/.battery/maintain.percentage" ]; then
      echo "-----> Opening Battery app for initial setup"
      open -a battery
      sleep 3
      echo "-----> Setting charge limit to 80%"
      battery maintain 15-85 2>/dev/null || true
    else
      echo "-----> Battery already configured"
    fi
    echo ""
    echo "💡 Run 'battery visudo' manually for sudo-free operation"
    echo "💡 Disable 'Optimized Battery Charging' in System Settings > Battery"
  fi

  echo ""
  if (( ${#launchd_failed} )); then
    echo "✗ launchctl bootstrap failed for: ${launchd_failed[*]} (see ~/Library/Logs, then rerun ./install.sh mcp)"
  fi
  echo "✓ Tier mcp installed (MCP servers + launchd + memory)"
}
