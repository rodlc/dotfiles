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

# Helper function to configure upstream remote
configure_upstream() {
  local name="$1" upstream_url="$2"

  if [ ! -d "$MCP_DIR/$name" ]; then
    return 0
  fi

  cd "$MCP_DIR/$name"
  if ! git remote get-url upstream &>/dev/null; then
    git remote add upstream "$upstream_url" 2>/dev/null || true
    # Disable push to upstream (read-only)
    git remote set-url --push upstream DISABLE 2>/dev/null || true
  fi
}

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

# Memory MCP (Python virtualenv via pyenv)
MEMORY_DIR="$MCP_DIR/mcp-memory-service"
if [ -d "$MEMORY_DIR" ]; then
  VENV_DIR="$MEMORY_DIR/.venv"

  if [ ! -f "$VENV_DIR/bin/python" ]; then
    echo "-----> Setting up mcp-memory-service virtualenv..."
    cd "$MEMORY_DIR"

    # Use pyenv Python 3.12 (must have SQLite extensions compiled)
    PYENV_PYTHON="$HOME/.pyenv/versions/3.12.8/bin/python"
    if [ ! -f "$PYENV_PYTHON" ]; then
      echo "❌ Error: pyenv Python 3.12.8 not found"
      echo "   Run: pyenv install 3.12.8 (with SQLite extensions)"
      exit 1
    fi

    # Verify SQLite extension support
    if ! $PYENV_PYTHON -c "import sqlite3; sqlite3.connect(':memory:').enable_load_extension(True)" 2>/dev/null; then
      echo "❌ Error: pyenv Python 3.12.8 missing SQLite extension support"
      echo "   Reinstall with: PYTHON_CONFIGURE_OPTS=\"--enable-loadable-sqlite-extensions\" pyenv install 3.12.8"
      exit 1
    fi

    $PYENV_PYTHON -m venv .venv
    .venv/bin/pip install --quiet --upgrade pip
    .venv/bin/pip install --quiet -e .
    echo "✓ mcp-memory-service installed"
  else
    echo "-----> mcp-memory-service virtualenv already exists, skipping"
  fi
else
  echo "⚠️  mcp-memory-service not found in $MCP_DIR, skipping"
fi

# Configure upstream remotes for forks
echo "-----> Configuring upstream remotes..."
configure_upstream "mcp-notion-server" "git@github.com:makenotion/notion-mcp-server.git"
configure_upstream "slack-mcp-server" "git@github.com:tuananh/slack-mcp.git"
configure_upstream "google-calendar-mcp" "git@github.com:nspady/google-calendar-mcp.git"
configure_upstream "mcp-memory-service" "git@github.com:dosuken123/mcp-memory-service.git"

echo "✓ MCP servers built successfully"
echo ""
echo "Next steps:"
echo "1. Ensure WORKSPACE_DIR is set in ~/.env"
echo "2. Run 'claude-restart' to reload MCP configuration"
