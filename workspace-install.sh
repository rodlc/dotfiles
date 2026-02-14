#!/bin/zsh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"

echo "=====> Installing workspace + MCP servers"

# Install Bun if not present (needed for some MCPs)
if ! command -v bun &> /dev/null; then
  echo "-----> Installing Bun"
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
else
  echo "-----> Bun already installed"
fi

# Clone workspace if not present
if [ ! -d "$WORKSPACE_DIR" ]; then
    if [ -f "$HOME/.ssh/id_ed25519_rodlc" ]; then
        echo "-----> Cloning workspace repository"
        mkdir -p "$(dirname "$WORKSPACE_DIR")"
        git clone --recurse-submodules git@github.com:rodlc/workspace.git "$WORKSPACE_DIR"
    else
        echo "❌ SSH key not found. Run install.sh first with Bitwarden."
        exit 1
    fi
else
    echo "-----> Workspace already exists, updating submodules..."
    cd "$WORKSPACE_DIR"
    git submodule update --init --recursive --quiet
fi

# Add WORKSPACE_DIR to ~/.env if not present
if [ -f "$HOME/.env" ]; then
    if ! grep -q "^export WORKSPACE_DIR=" "$HOME/.env"; then
        echo "export WORKSPACE_DIR=\"$WORKSPACE_DIR\"" >> "$HOME/.env"
        echo "-----> Added WORKSPACE_DIR to ~/.env"
    fi
else
    echo "export WORKSPACE_DIR=\"$WORKSPACE_DIR\"" > "$HOME/.env"
    chmod 600 "$HOME/.env"
    echo "-----> Created ~/.env with WORKSPACE_DIR"
fi

echo ""

# Build MCP servers
echo "=====> Building MCP servers"
"$DOTFILES_DIR/claude/install-mcp-servers.sh"

echo ""

# Configure MCPs in ~/.claude.json
echo "=====> Configuring MCP servers"
"$DOTFILES_DIR/claude/mcp-sync.sh" install

echo ""
echo "✓ Workspace + MCPs installed"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code to load MCPs"
echo "2. Run /doctor to verify MCP status"
