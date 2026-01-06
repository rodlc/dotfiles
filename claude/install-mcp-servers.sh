#!/bin/bash
# Install MCP server repositories
set -e

MCP_DIR="${CODE_DIR:-$HOME/Code}"

echo "=====> Installing MCP server repositories to $MCP_DIR"

# Helper function
install_mcp() {
  local name="$1" url="$2" build_cmd="$3" build_check="$4"

  if [ -d "$MCP_DIR/$name" ]; then
    if [ -n "$build_check" ] && [ ! -f "$MCP_DIR/$name/$build_check" ]; then
      echo "-----> $name exists but build incomplete, rebuilding..."
      cd "$MCP_DIR/$name"
      eval "$build_cmd"
    else
      echo "-----> $name already exists, skipping"
    fi
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
  "npm install --silent && npm run build" \
  "build/index.js"

# Gmail MCP (Node.js)
install_mcp "Gmail-MCP-Server" \
  "git@github.com:rodlc/Gmail-MCP-Server.git" \
  "npm install --silent && npm run build" \
  "dist/index.js"

# Slack MCP (Go)
install_mcp "slack-mcp-server" \
  "git@github.com:rodlc/slack-mcp-server.git" \
  "go build -o ./slack-mcp-server ./cmd/slack-mcp-server" \
  "slack-mcp-server"

# Rails MCP (Ruby)
install_mcp "rails-mcp-server" \
  "git@github.com:rodlc/rails-mcp-server.git" \
  "bundle install --quiet" \
  "exe/rails-mcp-server"

# Memory MCP (Python virtualenv)
if [ -d "$MCP_DIR/mcp-memory-service" ]; then
  if [ ! -f "$MCP_DIR/mcp-memory-service/bin/python" ]; then
    echo "-----> mcp-memory-service exists but not a virtualenv, recreating..."
    rm -rf "$MCP_DIR/mcp-memory-service"
  else
    echo "-----> mcp-memory-service already exists, skipping"
  fi
fi

if [ ! -d "$MCP_DIR/mcp-memory-service" ]; then
  echo "-----> Creating mcp-memory-service virtualenv..."
  python -m venv "$MCP_DIR/mcp-memory-service"
  echo "-----> Installing mcp-memory-service..."
  "$MCP_DIR/mcp-memory-service/bin/pip" install --quiet mcp-memory-service
fi

echo "✓ MCP servers installed"
