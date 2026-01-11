#!/bin/bash
# Install/build MCP servers from workspace submodules
# Removed set -e to allow error tracking and continue building remaining MCPs

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
MCP_DIR="$WORKSPACE_DIR/mcp-servers"

# Track build results
declare -A BUILD_RESULTS

echo "=====> Building MCP servers from workspace submodules"
echo "       Workspace: $WORKSPACE_DIR"
echo ""

# Check prerequisites upfront
check_prereqs() {
  local missing=()
  command -v node >/dev/null || missing+=("node (brew install node)")
  command -v npm >/dev/null || missing+=("npm")
  command -v go >/dev/null || missing+=("go (brew install go)")
  command -v bun >/dev/null || missing+=("bun (curl -fsSL https://bun.sh/install | bash)")
  command -v bundle >/dev/null || missing+=("bundle (gem install bundler)")
  [ -f "$HOME/.pyenv/versions/3.12.8/bin/python" ] || missing+=("pyenv python 3.12.8")

  if [ ${#missing[@]} -gt 0 ]; then
    echo "⚠️  Missing prerequisites (some MCPs will be skipped):"
    printf '   - %s\n' "${missing[@]}"
    echo ""
  fi
}

check_prereqs

# Initialize/update submodules
if [ -d "$WORKSPACE_DIR/.git" ]; then
  echo "-----> Updating workspace submodules..."
  cd "$WORKSPACE_DIR"
  git submodule update --init --recursive --quiet
else
  echo "⚠️  Warning: $WORKSPACE_DIR is not a git repository"
  echo "       Skipping submodule update. MCPs must be manually cloned to $MCP_DIR"
fi

echo ""

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

# Helper function to build MCPs with error tracking
build_mcp() {
  local name="$1" build_cmd="$2" build_check="$3" prereq="$4"

  if [ ! -d "$MCP_DIR/$name" ]; then
    BUILD_RESULTS[$name]="skipped (not found)"
    return 0
  fi

  # Check prerequisite command exists
  if [ -n "$prereq" ] && ! command -v "$prereq" >/dev/null 2>&1; then
    BUILD_RESULTS[$name]="skipped (missing $prereq)"
    echo "⚠️  $name: skipping (missing $prereq)"
    return 0
  fi

  if [ -n "$build_check" ] && [ -f "$MCP_DIR/$name/$build_check" ]; then
    BUILD_RESULTS[$name]="already built"
    echo "-----> $name already built"
    return 0
  fi

  echo "-----> Building $name..."
  cd "$MCP_DIR/$name"

  # Capture both stdout and stderr, but suppress on success
  if output=$(eval "$build_cmd" 2>&1); then
    BUILD_RESULTS[$name]="✓ built"
  else
    BUILD_RESULTS[$name]="✗ failed"
    echo "❌ $name build failed"
    echo "$output" | tail -10  # Show last 10 lines of error
  fi
}

# Build Node.js MCPs
build_mcp "mcp-notion-server" \
  "npm install --silent && npm run build" \
  "build/index.js" \
  "node"

build_mcp "Gmail-MCP-Server" \
  "npm install --silent && npm run build" \
  "dist/index.js" \
  "node"

build_mcp "google-calendar-mcp" \
  "npm install --silent && npm run build" \
  "build/index.js" \
  "node"

# Build Go MCP
build_mcp "slack-mcp-server" \
  "go build -o ./slack-mcp-server ./cmd/slack-mcp-server" \
  "slack-mcp-server" \
  "go"

# Build Ruby MCP
build_mcp "rails-mcp-server" \
  "bundle install --quiet" \
  "exe/rails-mcp-server" \
  "bundle"

# Build Bun MCP
build_mcp "mcp-raycast-clipboard" \
  "bun install" \
  "node_modules" \
  "bun"

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
      BUILD_RESULTS["mcp-memory-service"]="skipped (missing python 3.12.8)"
      echo "⚠️  mcp-memory-service: skipping (pyenv Python 3.12.8 not found)"
    else
      # Verify SQLite extension support
      if ! $PYENV_PYTHON -c "import sqlite3; sqlite3.connect(':memory:').enable_load_extension(True)" 2>/dev/null; then
        BUILD_RESULTS["mcp-memory-service"]="✗ failed (SQLite extensions)"
        echo "❌ mcp-memory-service: Python 3.12.8 missing SQLite extension support"
        echo "   Reinstall with: PYTHON_CONFIGURE_OPTS=\"--enable-loadable-sqlite-extensions\" pyenv install 3.12.8"
      else
        if $PYENV_PYTHON -m venv .venv && .venv/bin/pip install --quiet --upgrade pip && .venv/bin/pip install --quiet -e .; then
          BUILD_RESULTS["mcp-memory-service"]="✓ built"
          echo "✓ mcp-memory-service installed"
        else
          BUILD_RESULTS["mcp-memory-service"]="✗ failed"
          echo "❌ mcp-memory-service build failed"
        fi
      fi
    fi
  else
    BUILD_RESULTS["mcp-memory-service"]="already built"
    echo "-----> mcp-memory-service virtualenv already exists, skipping"
  fi
else
  BUILD_RESULTS["mcp-memory-service"]="skipped (not found)"
  echo "⚠️  mcp-memory-service not found in $MCP_DIR, skipping"
fi

# Configure upstream remotes for forks
echo ""
echo "-----> Configuring upstream remotes..."
configure_upstream "mcp-notion-server" "git@github.com:makenotion/notion-mcp-server.git"
configure_upstream "slack-mcp-server" "git@github.com:tuananh/slack-mcp.git"
configure_upstream "google-calendar-mcp" "git@github.com:nspady/google-calendar-mcp.git"
configure_upstream "mcp-memory-service" "git@github.com:dosuken123/mcp-memory-service.git"

# Summary at the end
echo ""
echo "=====> MCP Build Summary"
for name in "${!BUILD_RESULTS[@]}"; do
  echo "       $name: ${BUILD_RESULTS[$name]}"
done

# Count failures (warning only, don't exit)
failures=$(echo "${BUILD_RESULTS[@]}" | grep -o "✗ failed" | wc -l | tr -d ' ')
if [ "$failures" -gt 0 ]; then
  echo ""
  echo "⚠️  $failures MCP(s) failed to build. Check errors above."
  echo "   Failed MCPs will show as 'failed' in Claude Code /doctor"
fi

echo ""
echo "✓ MCP build complete"
echo ""
echo "Next steps:"
echo "1. Ensure WORKSPACE_DIR is set in ~/.env"
echo "2. Restart Claude Code to reload MCP configuration"
