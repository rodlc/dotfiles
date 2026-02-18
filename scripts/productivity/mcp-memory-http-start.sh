#!/bin/bash
# MCP Memory HTTP Server Startup Script
# Wrapper for launchd to start the HTTP server with proper environment

set -e

PROJECT_DIR="$HOME/Code/rodlc/workspace/mcp-servers/mcp-memory-service"
HTTP_MANAGER="$PROJECT_DIR/scripts/service/http_server_manager.sh"

# Ensure the HTTP manager script exists
if [ ! -f "$HTTP_MANAGER" ]; then
    echo "Error: HTTP server manager not found at $HTTP_MANAGER" >&2
    exit 1
fi

# Load .env file if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Override port with environment variable (4242 for this service)
export MCP_HTTP_PORT="${MCP_HTTP_PORT:-4242}"
export MCP_HTTP_ENABLED=true
export MCP_OAUTH_ENABLED=false
export MCP_MEMORY_STORAGE_BACKEND="${MCP_MEMORY_STORAGE_BACKEND:-sqlite_vec}"

# SQLite path for hybrid backend
export MCP_MEMORY_SQLITE_PATH="${MCP_MEMORY_SQLITE_PATH:-$HOME/Library/Application Support/mcp-memory/sqlite_vec.db}"

# Log the configuration
echo "=== MCP Memory HTTP Server Startup ===" >&2
echo "Port: $MCP_HTTP_PORT" >&2
echo "Backend: $MCP_MEMORY_STORAGE_BACKEND" >&2
echo "SQLite Path: $MCP_MEMORY_SQLITE_PATH" >&2
echo "=======================================" >&2

# Change to project directory
cd "$PROJECT_DIR"

# Start the server using the auto-start command
# This will check health and restart if needed
exec "$HTTP_MANAGER" auto-start silent
