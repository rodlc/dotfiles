#!/bin/bash
# Install MCP server repositories
set -e

MCP_DIR="${CODE_DIR:-$HOME/Code}"

echo "=====> Installing MCP server repositories to $MCP_DIR"

# Helper function
install_mcp() {
  local name="$1" url="$2" build_cmd="$3"

  if [ -d "$MCP_DIR/$name" ]; then
    echo "-----> $name already exists, skipping"
    return 0
  fi

  echo "-----> Cloning $name..."
  git clone --quiet "$url" "$MCP_DIR/$name"

  if [ -n "$build_cmd" ]; then
    echo "-----> Building $name..."
    cd "$MCP_DIR/$name"
    eval "$build_cmd"
  fi
}

# Notion MCP (Node.js)
install_mcp "mcp-notion-server" \
  "git@github.com:rodlc/mcp-notion-server.git" \
  "npm install --silent && npm run build"

# Gmail MCP (Node.js)
install_mcp "Gmail-MCP-Server" \
  "git@github.com:rodlc/Gmail-MCP-Server.git" \
  "npm install --silent && npm run build"

# Slack MCP (Go)
install_mcp "slack-mcp-server" \
  "git@github.com:rodlc/slack-mcp-server.git" \
  "go build -o slack-mcp-server ./cmd/slack-mcp-server"

# Rails MCP (Ruby)
install_mcp "rails-mcp-server" \
  "git@github.com:rodlc/rails-mcp-server.git" \
  "bundle install --quiet"

# Memory MCP (Python)
install_mcp "mcp-memory-service" \
  "git@github.com:rodlc/mcp-memory-service.git" \
  "pip install -e ."

echo "✓ MCP servers installed"
