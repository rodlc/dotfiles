#!/bin/bash
# Install/build MCP servers from workspace submodules
set -e

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
MCP_DIR="$WORKSPACE_DIR/mcp-servers"

echo "=====> Building MCP servers from workspace submodules"
echo "       Workspace: $WORKSPACE_DIR"

# Initialize/update submodules
if [ -d "$WORKSPACE_DIR/.git" ]; then
  echo "-----> Updating workspace submodules..."
  cd "$WORKSPACE_DIR"
  git submodule update --init --recursive --quiet
else
  echo "⚠️  Warning: $WORKSPACE_DIR is not a git repository"
  echo "       Skipping submodule update. MCPs must be manually cloned to $MCP_DIR"
fi

# Helper function to build MCPs
build_mcp() {
  local name="$1" build_cmd="$2" build_check="$3"

  if [ ! -d "$MCP_DIR/$name" ]; then
    echo "⚠️  $name not found in $MCP_DIR, skipping"
    return 0
  fi

  if [ -n "$build_check" ] && [ -f "$MCP_DIR/$name/$build_check" ]; then
    echo "-----> $name already built, skipping"
    return 0
  fi

  echo "-----> Building $name..."
  cd "$MCP_DIR/$name"
  eval "$build_cmd"
}

# Notion MCP (Node.js)
build_mcp "mcp-notion-server" \
  "npm install --silent && npm run build" \
  "build/index.js"

# Gmail MCP (Node.js)
build_mcp "Gmail-MCP-Server" \
  "npm install --silent && npm run build" \
  "dist/index.js"

# Google Calendar MCP (Node.js)
build_mcp "google-calendar-mcp" \
  "npm install --silent && npm run build" \
  "build/index.js"

# Slack MCP (Go)
build_mcp "slack-mcp-server" \
  "go build -o ./slack-mcp-server ./cmd/slack-mcp-server" \
  "slack-mcp-server"

# Rails MCP (Ruby)
build_mcp "rails-mcp-server" \
  "bundle install --quiet" \
  "exe/rails-mcp-server"

# Raycast Clipboard MCP (Bun/TypeScript)
build_mcp "mcp-raycast-clipboard" \
  "bun install" \
  "node_modules/.bin/bun"

# Memory MCP (Python virtualenv) - Special case
MEMORY_DIR="$MCP_DIR/mcp-memory-service"
if [ -d "$MEMORY_DIR" ]; then
  if [ ! -f "$MEMORY_DIR/bin/python" ]; then
    echo "-----> mcp-memory-service exists but not a virtualenv, setting up..."
    cd "$MEMORY_DIR"
    python -m venv .
    ./bin/pip install --quiet -e .
  else
    echo "-----> mcp-memory-service virtualenv already exists, skipping"
  fi
else
  echo "⚠️  mcp-memory-service not found in $MCP_DIR, skipping"
fi

echo "✓ MCP servers built successfully"
echo ""
echo "Next steps:"
echo "1. Ensure WORKSPACE_DIR is set in ~/.env"
echo "2. Run 'claude-restart' to reload MCP configuration"
