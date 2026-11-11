# Launchd services (MCP memory + backup)
install_launchd_services() {
  local role="$1"
  echo "=====> Installing launchd services"
  MCP_MEMORY_SERVICE="$WORKSPACE_DIR/mcp-servers/mcp-memory-service"

  if [ -d "$MCP_MEMORY_SERVICE" ]; then
    mkdir -p "$HOME/Library/LaunchAgents"

    LAUNCHD_SRC="$WORKSPACE_DIR/claude-config/launchd"
    if [ -d "$LAUNCHD_SRC" ]; then
      for plist in "$LAUNCHD_SRC"/*.plist; do
        [ -f "$plist" ] || continue
        local name="$(basename "$plist")"
        local label="${name%.plist}"
        local service="${label#com.rodlecoent.}"
        local agent="$HOME/Library/LaunchAgents/$name"
        local excluded="$(launchd_excluded_reason "$service" "$role")"
        if [[ -n "$excluded" ]]; then
          if [[ -f "$agent" ]]; then
            launchctl bootout "gui/$UID" "$agent" 2>/dev/null || true
            rm "$agent"
            echo "-----> Removed $service ($excluded)"
          else
            echo "-----> Skipped $service ($excluded)"
          fi
          continue
        fi
        local program="$(plutil -extract ProgramArguments.0 raw "$plist" 2>/dev/null)"
        program="${program//__HOME__/$HOME}"
        if [[ ! -e "$program" ]]; then
          echo "-----> Skipped $service (${program:-ProgramArguments} not found)"
          continue
        fi
        backup "$agent"
        sed "s|__HOME__|$HOME|g" "$plist" > "$agent"
        launchctl bootout "gui/$UID" "$agent" 2>/dev/null || true
        # bootout returns before the service is gone; bootstrapping it meanwhile fails with error 5
        for attempt in {1..20}; do
          launchctl print "gui/$UID/$label" &>/dev/null || break
          sleep 0.25
        done
        launchctl bootstrap "gui/$UID" "$agent" || launchd_failed+=("$service")
      done
      echo "-----> Launchd services installed"
    fi

    if [[ "$role" == "reference" ]]; then
      echo "-----> Waiting for memory server..."
      sleep 5
      if curl -s --max-time 2 http://127.0.0.1:4242/api/health > /dev/null 2>&1; then
        echo "-----> ✓ HTTP server running on port 4242"
      else
        echo "-----> ⚠️  HTTP server not responding (check: ~/Library/Logs/mcp-memory-http.log)"
      fi
    fi

    # Memory hooks
    echo "=====> Installing mcp-memory-service hooks"
    if [ -f "$MCP_MEMORY_SERVICE/claude-hooks/install_hooks.py" ]; then
      cd "$MCP_MEMORY_SERVICE/claude-hooks"
      python3 install_hooks.py --natural-triggers
      cd "$DOTFILES_DIR"
      echo "-----> Hooks installed with natural triggers"
    fi
  else
    echo "-----> ⚠️  mcp-memory-service not found, skipping launchd setup"
  fi
}
